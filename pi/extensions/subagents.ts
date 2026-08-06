import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type SubagentMode = "readOnly" | "write";

type AgentSummary = {
  name: string;
  path: string;
  description: string;
};

const DEFAULT_TIMEOUT_MS = 10 * 60 * 1000;
const MAX_TIMEOUT_MS = 60 * 60 * 1000;

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "list_subagents",
    label: "List Subagents",
    description: "List custom subagents available to pi from the shared harness",
    promptSnippet: "List custom subagents available in the user's shared harness",
    promptGuidelines: [
      "Use list_subagents when you need to choose the correct specialist before delegating.",
    ],
    parameters: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
    async execute(_toolCallId, _params, _signal, _onUpdate, _ctx) {
      const agents = await discoverAgents();
      const text = agents.length === 0
        ? "No subagents found. Expected markdown files in $HOME/dotfiles/ai/shared/agents/."
        : agents
          .map((agent) => `- ${agent.name}: ${agent.description || "No description"}`)
          .join("\n");

      return {
        content: [{ type: "text", text }],
        details: { agents },
      };
    },
  });

  pi.registerTool({
    name: "run_subagent",
    label: "Run Subagent",
    description: "Run one custom subagent from the user's shared harness in a separate pi process",
    promptSnippet: "Delegate focused search, edit, review, build, or test work to a custom subagent",
    promptGuidelines: [
      "Use run_subagent for project code edits, heavy codebase search, long-running checks, and specialist review when a matching subagent exists.",
      "Choose mode=readOnly for investigation/review and mode=write only when the subagent must modify files.",
      "Keep run_subagent tasks focused and include expected output format, relevant files, constraints, and verification commands.",
      "Do not claim delegation happened unless run_subagent returned successfully.",
    ],
    parameters: {
      type: "object",
      properties: {
        agent: {
          type: "string",
          description: "Subagent name without .md, e.g. code-reviewer, kotlin-engineer, compose-developer",
        },
        task: {
          type: "string",
          description: "Focused task for the subagent. Include constraints, paths, expected output, and verification requirements.",
        },
        mode: {
          type: "string",
          enum: ["readOnly", "write"],
          description: "readOnly for investigation/review, write for file edits. Default: readOnly.",
          default: "readOnly",
        },
        timeoutSeconds: {
          type: "number",
          description: "Timeout in seconds. Default: 600, max: 3600.",
          default: 600,
        },
        model: {
          type: "string",
          description: "Optional pi model selector passed to --model, e.g. sonnet:low.",
        },
      },
      required: ["agent", "task"],
      additionalProperties: false,
    },
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const mode = normalizeMode(params.mode);
      const timeoutMs = normalizeTimeout(params.timeoutSeconds);
      const agent = await loadAgent(params.agent);

      onUpdate?.({
        content: [{ type: "text", text: `Launching ${agent.name} (${mode})...` }],
        details: { agent: agent.name, mode },
      });

      const prompt = buildPrompt({
        agentName: agent.name,
        agentBody: agent.body,
        task: params.task,
        cwd: ctx.cwd,
        mode,
      });

      const result = await runPiProcess({
        cwd: ctx.cwd,
        prompt,
        mode,
        model: params.model,
        timeoutMs,
        signal,
      });

      return {
        content: [{ type: "text", text: result }],
        details: {
          agent: agent.name,
          mode,
          timeoutMs,
        },
      };
    },
  });
}

async function discoverAgents(): Promise<AgentSummary[]> {
  const agentsDir = getAgentsDir();
  let entries: string[];

  try {
    entries = await fs.readdir(agentsDir);
  } catch {
    return [];
  }

  const agents = await Promise.all(
    entries
      .filter((entry) => entry.endsWith(".md"))
      .sort()
      .map(async (entry) => {
        const filePath = path.join(agentsDir, entry);
        const body = await fs.readFile(filePath, "utf8");
        return {
          name: path.basename(entry, ".md"),
          path: filePath,
          description: extractDescription(body),
        };
      }),
  );

  return agents;
}

async function loadAgent(name: string): Promise<{ name: string; body: string }> {
  const safeName = name.trim().replace(/\.md$/, "");
  if (!/^[a-zA-Z0-9_-]+$/.test(safeName)) {
    throw new Error(`Invalid subagent name: ${name}`);
  }

  const filePath = path.join(getAgentsDir(), `${safeName}.md`);
  try {
    return {
      name: safeName,
      body: await fs.readFile(filePath, "utf8"),
    };
  } catch (error) {
    const agents = await discoverAgents();
    const available = agents.map((agent) => agent.name).join(", ") || "none";
    throw new Error(`Subagent not found: ${safeName}. Available: ${available}`, { cause: error });
  }
}

function getAgentsDir(): string {
  return path.join(process.env.HOME ?? "", "dotfiles/ai/shared/agents");
}

function extractDescription(body: string): string {
  const frontmatter = body.match(/^---\n([\s\S]*?)\n---/);
  const source = frontmatter?.[1] ?? body;
  const description = source.match(/^description:\s*["']?([\s\S]*?)["']?\s*$/m)?.[1]
    ?? source.match(/^#\s+(.+)$/m)?.[1]
    ?? "";

  return description
    .replace(/\\n/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 300);
}

function normalizeMode(value: unknown): SubagentMode {
  return value === "write" ? "write" : "readOnly";
}

function normalizeTimeout(value: unknown): number {
  const seconds = typeof value === "number" && Number.isFinite(value) ? value : DEFAULT_TIMEOUT_MS / 1000;
  return Math.min(Math.max(seconds * 1000, 1000), MAX_TIMEOUT_MS);
}

function buildPrompt(args: {
  agentName: string;
  agentBody: string;
  task: string;
  cwd: string;
  mode: SubagentMode;
}): string {
  const permissions = args.mode === "write"
    ? "You may edit project files as needed. Keep the diff minimal and run focused verification when practical."
    : "Read-only mode: do not edit, write, create, delete, format, or modify project files. Investigation commands are allowed.";

  return [
    `You are the custom subagent \`${args.agentName}\` launched by the pi main orchestrator.`,
    "This subprocess is the delegated specialist, not the main orchestrator. Do the delegated work directly with the tools allowed for this run; do not delegate it again unless the task explicitly asks for nested delegation.",
    `Working directory: ${args.cwd}`,
    `Mode: ${args.mode}`,
    permissions,
    "",
    "## Subagent definition",
    args.agentBody,
    "",
    "## Delegated task",
    args.task,
    "",
    "## Required response",
    "Return a concise report in Russian unless the delegated task explicitly asks otherwise.",
    "Include: STATUS (DONE/BLOCKED/FAILED), SUMMARY, FILES touched/read, VERIFICATION, and NEXT STEPS if any.",
  ].join("\n");
}

function runPiProcess(args: {
  cwd: string;
  prompt: string;
  mode: SubagentMode;
  model?: string;
  timeoutMs: number;
  signal?: AbortSignal;
}): Promise<string> {
  return new Promise((resolve, reject) => {
    const tools = args.mode === "write"
      ? "read,bash,edit,write,grep,find,ls"
      : "read,bash,grep,find,ls";

    const cliArgs = [
      "-p",
      "--no-session",
      "--tools",
      tools,
    ];

    if (args.model?.trim()) {
      cliArgs.push("--model", args.model.trim());
    }

    cliArgs.push(args.prompt);

    const child = spawn("pi", cliArgs, {
      cwd: args.cwd,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    let finished = false;

    const timeout = setTimeout(() => {
      if (finished) return;
      child.kill("SIGTERM");
      reject(new Error(`Subagent timed out after ${Math.round(args.timeoutMs / 1000)} seconds`));
    }, args.timeoutMs);

    const abort = () => {
      if (finished) return;
      child.kill("SIGTERM");
      reject(new Error("Subagent aborted"));
    };

    args.signal?.addEventListener("abort", abort, { once: true });

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (error) => {
      finished = true;
      clearTimeout(timeout);
      args.signal?.removeEventListener("abort", abort);
      reject(error);
    });

    child.on("close", (code) => {
      finished = true;
      clearTimeout(timeout);
      args.signal?.removeEventListener("abort", abort);

      if (code === 0) {
        resolve(stdout.trim() || "Subagent completed with empty output.");
      } else {
        reject(new Error(stderr.trim() || `Subagent exited with code ${code}`));
      }
    });
  });
}

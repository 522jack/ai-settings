# Runtime Adapter Rules

This harness is agent-agnostic at the contract level and runtime-specific only at the adapter
level. Shared rules and skills describe **what must happen**; each coding agent runtime maps that
contract to its own tools.

## Contract Vocabulary

Use these canonical terms in shared rules, skills, and agents:

| Contract term | Meaning |
|---|---|
| Main session | The orchestrator that talks to the user, owns synthesis, and coordinates work. |
| Specialist | Any delegated worker: subagent, side thread, worktree agent, reviewer, tester, or runtime-specific equivalent. |
| Project instructions | The repo-local and global instruction files available to the runtime: `AGENTS.md`, `CLAUDE.md`, `README.agent.md`, or equivalent. |
| Runtime tool | A capability exposed by the current agent environment: shell, web, MCP, browser, mobile device, code review, etc. |
| Skill command | A named workflow such as `check`, `finalize`, or `acceptance`; slash syntax is only one runtime's invocation style. |
| Adapter limitation | A missing runtime feature that prevents the ideal workflow; it must be stated explicitly and replaced with the closest safe equivalent. |

## Adapter Mapping

| Contract | Claude Code | Codex | Generic fallback |
|---|---|---|---|
| Project instructions | `CLAUDE.md` plus imported rules | `AGENTS.md` plus skills/rules | Read every available instruction file explicitly. |
| Specialist delegation | `Task` / custom agents / `Explore` | multi-agent tools when available; load the selected profile from `~/dotfiles/ai/shared/agents/` into the delegation packet | Use a separate worktree/process if available; otherwise state the limitation and keep the work local only when safe. |
| Codebase search specialist | `Explore` or configured search agent | `explorer` subagent when available | Use indexed search first; avoid broad raw grep. |
| User choice tool | `AskUserQuestion` | `request_user_input` when available, otherwise one concise chat question | Ask in chat; never park user-resolvable questions in files. |
| Skill invocation | Slash command or Skill tool | Installed skill from `~/.codex/skills` | Follow the `SKILL.md` manually. |
| Runtime QA | mobile/browser MCP tools | available MCP/tools, Playwright/browser/mobile plugins | Real device/browser actions where possible; document missing capability. |
| Hook enforcement | Claude hooks in `settings.json` | Codex sandbox/approvals plus manual session-start sync | Shell guard scripts run manually or through the runtime's hook mechanism. |

## Legacy Aliases

Older shared skills may still use Claude-era names directly. Until those files are migrated, interpret
them through this table rather than literally:

| Legacy name | Contract term |
|---|---|
| `Task tool`, `Agent tool` | Specialist delegation |
| `Explore` | Codebase search specialist |
| `AskUserQuestion` | User choice tool |
| `EnterPlanMode` / `ExitPlanMode` | Runtime planning/checkpoint mechanism |
| `/check`, `/finalize`, `/acceptance`, `/create-pr`, `/drive-to-merge` | Skill command |
| `CLAUDE.md` | Project instructions |
| `mcp__mobile__*` | Runtime QA/mobile-device tool |

## Writing Portable Rules

- Shared files must name the contract first. Runtime names like `Task tool`, `Explore`, `CLAUDE.md`, `AskUserQuestion`, `/check`, or `mcp__mobile__*` may appear only as examples or adapter mappings.
- If a shared workflow depends on a runtime-only capability, provide a fallback path or an explicit "adapter limitation" outcome.
- Path-scoped rules with YAML frontmatter apply conditionally. If the runtime does not enforce frontmatter, the agent must apply them only when the current task touches matching files or domain areas.
- A specialist's output contract must be stable across runtimes: artifact paths, verdict values, and required fields matter more than the tool that produced them.
- Never assume tool names exist. Discover what is available in the current runtime, then map the contract to the best available tool.

## Domain Profiles

Android/KMP/Gradle rules are allowed to stay first-class because this harness is optimized for
that work. They are still **domain profiles**, not universal core:

- `kotlin-style.md`, `gradle-style.md`, and `android-cli.md` apply when file paths or project markers match.
- Non-Android stacks should ignore Android-specific commands unless the task explicitly concerns Android tooling.
- Shared workflows such as `check`, `finalize`, and `acceptance` must keep non-Android fallback behavior intact.

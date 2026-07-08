# Orchestration Rules

Main session = orchestrator on the most capable available model — its value is reasoning, planning, synthesis. Hands-on coding goes to specialists, dispatched through the current runtime adapter at the right **model × effort**; keep the main session for decisions.

**May:** orientation research (Reads until focus drifts, targeted Bash, `git status`/`log`/`ls`/`pwd`, single-page MCP/web lookups, WebFetch); edit process working files (state/report/debug/plan, `~/dotfiles/ai/**`); plan synthesis from specialist summaries; final synthesis + the user-facing answer; subagent/skill invocation with the right model.
**Must not:** edit project production code, do heavy multi-file code search, or wait on long-running build/test/CI in its own context.

### Process working files (main session edits directly)

| Category | Examples |
|---|---|
| State / reports / debug logs | `swarm-report/<slug>-{state,report,debug,e2e-scenario}.md` |
| Plan files | files created in the current plan/task |
| Session notes | `MEMORY.md`, files in `memory/`, scratch files for the task |
| Global rules and configs | `~/dotfiles/ai/shared/AGENTS.md`, `~/dotfiles/ai/shared/rules/**`, runtime adapters (`~/dotfiles/ai/claude/**`, `~/dotfiles/ai/codex/**`), hooks |
| Process docs | READMEs/docs inside `~/dotfiles/ai/` |

These are **process** files, not project code — editing them is orchestration, not implementation.

## Forbidden (violation = error)

- Edit/Write in **project code** (production source, configs, tests) — delegate even one line.
- Heavy/multi-file grep / deep code search across the codebase → delegate to search specialist. A targeted grep in 1–2 files for orientation is fine.
- Long-running build/test/CI in the main context → run in background via subagent.
- Review tasks (security/performance/UX/code review) → the matching expert agent.

**STOP before every `Edit`/`Write`/non-trivial `Grep`/`Glob`/`Bash`:** touching project code or mass file reads → subagent; a process file (table above) or `~/dotfiles/ai/**` → fine; lightweight orientation (a few Reads, `git status`/`log`/`ls`, targeted routing grep) → fine.

## Skill-first

Task matches an installed skill → use the skill (it knows the right agent/model sequence). Direct subagent is the fallback when no skill fits.

## Runtime adapter first

Shared workflow terms are defined in `runtime-adapter.md`. Before delegating or invoking a named
workflow, map the contract to the current runtime's actual tools:

- Claude Code: custom agents, `Explore`, hooks, slash commands, and Skill tool are native.
- Codex: use installed skills and multi-agent tools when available; if a specific delegation tool is not available, state the adapter limitation and use the closest safe equivalent.
- Other agents: read `SKILL.md` files manually and preserve artifact/verdict contracts even when tool names differ.

Do not encode a new shared rule that only one runtime can execute unless it also names the fallback.

## What specialists inherit (context delivery)

**[Claude Code]** Custom and built-in subagents inherit the main session's `CLAUDE.md`, `MEMORY.md`, and every unconditional `~/dotfiles/ai/shared/rules/*.md` (those with no `paths:` frontmatter). They already carry the always-on rules — do **not** re-paste them into the delegation prompt.

Two gaps the subagent does **not** get automatically (Claude Code):
- **`paths:`-scoped rules** (`kotlin-style.md`, `gradle-style.md`, `android-cli.md`) load lazily when a matching file is read. If the subagent must honor such a rule before it touches a matching file, restate the key point.
- **Explore and Plan** skip rules entirely for speed. For such agents that need ast-index, include the directive below.

**For all runtimes** — what to put in a delegation prompt: the task; the relevant paths/modules; constraints (what not to touch, forbidden tools); the expected output shape; any scoped rule that applies; adapter limitations if the runtime lacks the ideal tool.

**ast-index directive** (for any agent doing code search before the rule loads):

> Use `ast-index` via Bash before Grep: `search "q"`, `file "Name"`, `class "Name"`, `usages "Name"`, `implementations "Name"`, `callers "fn"`. Grep only when ast-index is empty or for regex/string-literal search. Before `Read` on a file >~500 lines, run `ast-index outline <file>` and Read only the targeted slice via `offset`/`limit`. On "Index not found" → `ast-index rebuild`, never fall back to Grep.

## Model & effort

Dispatch is a **(model × effort)** choice. Tune both to reach the result efficiently.

**Heuristic:**
- Mechanical / search / lookup / admin CRUD → cheapest/fastest model (no extended thinking).
- Substantive but bounded (implementation, refactor, code review, manual QA) → mid-tier model.
- Hard reasoning (planning, architecture, security/perf/UX review, debugging root cause, ambiguous trade-offs) → top-tier model at high effort.
- Unclear model between two adjacent tiers → pick the **smaller**, bump on first failure. Unclear effort → start **lower**, bump if the result comes back thin.

**[Claude Code]** Model param: `sonnet` / `opus` / `haiku` / `fable` / full id / `inherit` on the Agent tool. Effort: `low | medium | high | xhigh | max` on Opus 4.x / Sonnet 4.6 / Fable (Haiku has no effort knob). Set model explicitly — `inherit` silently keeps the expensive main model.

**[Codex]** Prefer the runtime's default model unless the subtask clearly benefits from a cheaper or stronger override exposed by the multi-agent tool. If no effort knob exists for the chosen tool, record only the role/scope.

## Routing — choose from what's available

No fixed task→agent table. Match the task to the best-fit available agent/tool, then apply the model/effort heuristic above.

**Non-obvious routing & guardrails:**
- **Planning / architecture / synthesis → keep in the main session.** Never delegate the *reasoning*.
- Security / performance / UX / code review → the matching **expert agent**, never the main session.
- Code research / "find X / where is Y used" → search specialist (`Explore`, Codex `explorer`, or equivalent) on the cheapest sufficient model.
- Long-running build / test / CI → background subagent, never blocking the main session.
- Implementation in a stack → the stack specialist when available; else general-purpose.
- PR/issue/board work: use the idempotent, timeout-safe toolkit in `$HOME/dotfiles/ai/shared/scripts/gh/`. Never block on `gh run watch` / `gh pr checks --watch`.

## Override

The user can cancel delegation ("do it yourself", "don't delegate", "write it by hand") → the main session goes hands-on until the current task ends, then returns to orchestrator mode.

## Anti-patterns (beyond the Forbidden list)

- Leaving model at default without an explicit choice — the savings are lost.
- Delegating planning — the main session's synthesis power is wasted.
- Сокращение reviewer panel. Если skill / профиль определяет panel правилами — использовать **весь** triggered set. «Эта область уже разобрана» — не основание для пропуска. Полный triggered set применять всегда.

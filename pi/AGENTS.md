# Pi Adapter

This adapter applies the shared orchestration contract to pi.

## Runtime mapping

- Pi main session is the orchestrator: it talks to the user, owns reasoning, planning, and synthesis.
- Use pi tools (`read`, `bash`, `edit`, `write`) only within the limits of the shared orchestration rules.
- When configured subagent extension tools are available, delegate codebase search, project code edits, long-running checks, and review tasks to those subagents.
- Use `list_subagents` to discover available specialists when unsure; use `run_subagent` to launch one.
- If no subagent tool is available, state that limitation clearly and use the closest safe pi capability instead of pretending delegation happened.
- Skills are available as `/skill:name`; use an installed skill when its description matches the task.
- Runtime-specific Claude/Codex/Gemini tool names in shared rules are examples. Map them to pi extension tools or pi commands where possible.

## Shared orchestration rules

@$HOME/dotfiles/ai/shared/rules/runtime-adapter.md
@$HOME/dotfiles/ai/shared/rules/orchestration.md

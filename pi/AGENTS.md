# Pi Adapter

This adapter applies the shared orchestration contract to pi.

## Runtime mapping

- Before a new task, read and apply the execution mode section in `$HOME/dotfiles/ai/shared/AGENTS.md`.
- In single-agent mode, execute directly with pi tools (`read`, `bash`, `edit`, `write`).
- In subagent mode, use the configured subagent extension for broad codebase search, project code edits, long-running checks, and independent review.
- Use `list_subagents` to discover available specialists when unsure; use `run_subagent` to launch one.
- If the user chooses subagents and no delegation tool is available, state the limitation and wait for their decision.
- Skills are available as `/skill:name`; use an installed skill when its description matches the task.
- Runtime-specific Claude/Codex/Gemini tool names in shared rules are examples. Map them to pi extension tools or pi commands where possible.

## Shared orchestration rules

@$HOME/dotfiles/ai/shared/rules/runtime-adapter.md
@$HOME/dotfiles/ai/shared/rules/orchestration.md

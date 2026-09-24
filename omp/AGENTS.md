# Oh My Pi Adapter

This adapter applies the shared orchestration contract to Oh My Pi (OMP).

## Shared contract

@$HOME/dotfiles/ai/shared/AGENTS.md

## Runtime mapping

- The OMP main session is the orchestrator: it owns user communication, planning, coordination, and synthesis.
- Delegate with `task`: use agent `task` for implementation, `scout` for read-only codebase research, and `reviewer` for review. Before delegation, read the applicable profile from `$HOME/dotfiles/ai/shared/agents/` and include its relevant instructions in the delegation packet; those Claude-oriented profiles are sources, not native OMP agent definitions.
- Use `ask` only for a user decision that cannot be resolved from repository context or tools.
- Use `read`, `grep`, and `glob` for inspection; `edit` for surgical changes; `write` for new files or whole-file replacement; and `bash` for external commands. Use `browser` for interactive web UI and `eval` for programmable or persistent scenarios.
- Skills are discovered natively from `~/.omp/agent/skills/<name>/SKILL.md`. When a skill matches, read `skill://<name>` before following it.
- OMP does not inherit Claude hooks, settings, credentials, models, extensions, or custom-agent schemas. Use available OMP tools or the closest safe equivalent, run required shared guard scripts manually, and state any material adapter limitation rather than claiming unavailable behavior.

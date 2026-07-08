# Codex Adapter

Codex consumes the shared harness through `~/.codex/AGENTS.md` and `~/.codex/skills/*`.

The shared contract is defined in `shared/rules/runtime-adapter.md`. Codex-specific behavior:

- `setup.sh` symlinks `shared/AGENTS.md` to `~/.codex/AGENTS.md`.
- `setup.sh` symlinks every `shared/skills/<name>/` directory to `~/.codex/skills/<name>/`.
- Codex currently does not use the Claude hook system. At session start, run
  `bash "$HOME/dotfiles/ai/shared/scripts/auto-pull.sh"` unless the runtime already did it.
- For delegation, use Codex multi-agent tools when available. If a requested shared workflow names
  Claude-specific tools (`Task`, `Explore`, slash commands), map them through
  `runtime-adapter.md` instead of treating the Claude name as mandatory.
- Guard scripts in `shared/scripts/` are still canonical. If Codex cannot attach them as hooks,
  run the relevant script manually or rely on Codex sandbox/approval enforcement and state the
  adapter limitation when it matters.


# Oh My Pi Adapter

Oh My Pi (OMP) consumes the shared harness through `~/.omp/agent/AGENTS.md` and `~/.omp/agent/skills/*`.

The shared contract is defined in `shared/AGENTS.md` and `shared/rules/runtime-adapter.md`. OMP-specific behavior:

- `setup.sh` symlinks `omp/AGENTS.md` to `~/.omp/agent/AGENTS.md`.
- `setup.sh` symlinks every `shared/skills/<name>/` directory to `~/.omp/agent/skills/<name>/`, where OMP discovers its native `SKILL.md`. Re-running setup replaces those symlinks idempotently; a pre-existing real `AGENTS.md` or skill directory is backed up under `.backup/<timestamp>/` before replacement.
- The main session orchestrates. Delegation uses OMP's `task` tool with `task`, `scout`, or `reviewer` agents as appropriate.
- Shared profiles in `shared/agents/` remain delegation sources: the main session reads the selected profile into the delegation packet. They are not copied to `~/.omp/agent/agents` because their Claude-oriented frontmatter is not the OMP agent schema.
- Setup does not overwrite `~/.omp/agent/config.yml`, credentials, models, hooks, or extensions, and it does not install Claude hooks or settings for OMP.
- If a shared workflow depends on an unavailable hook or runtime feature, use the closest safe OMP tool, run the relevant guard script manually when required, and report the adapter limitation.

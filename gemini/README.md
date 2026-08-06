# Gemini in Android Studio Adapter

`setup.sh` installs the shared harness resources for Gemini Agent Mode in Android Studio:

- `~/AGENTS.md` stays runtime-neutral and imports `shared/global-neutral.md`.
- `gemini/AGENTS.md` is the Gemini-specific adapter. Import it from Gemini-specific configuration or a project-local `AGENTS.md` when Gemini needs adapter behavior.
- `~/.agents/skills/<skill>` contains a physical copy of each directory in `shared/skills/`, so Agent Mode can discover skills globally. Re-run `setup.sh` after changing a shared skill.

Gemini selects a skill from its `description` when relevant, or a user can invoke one in the chat with `@skill-name`.

For a project outside the home directory, add this file at the project root:

```md
@/absolute/path/to/dotfiles/ai/gemini/AGENTS.md
```

Keep project-specific instructions in the project's own `AGENTS.md`. Android Studio combines those instructions with the global neutral harness and any explicitly imported Gemini adapter.

The adapter intentionally does not install Claude hooks or Codex-only configuration: Gemini Agent Mode has its own tools and permission model.

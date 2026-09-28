# Global neutral AI rules

This file is intentionally runtime-neutral. It must not import Gemini-, Codex-, Claude-, or Pi-specific adapters.
Runtime adapters are installed in their own harness-specific locations.

## Non-negotiable rules

- Язык общения — русский.
- **Никогда не обходить git-хуки** (`--no-verify`, `--no-gpg-sign`, `-c commit.gpgsign=false` и т.п.) без явного запроса пользователя. Если хук падает — расследовать и устранять корневую причину.
- **Никогда не коммитить и не пушить напрямую в main/master/develop продуктовых проектов.** `auto-pull.sh` только подтягивает изменения и никогда не коммитит/пушит. Репозиторий конфигурации `$HOME/dotfiles/ai` можно коммитить и пушить только по явному запросу пользователя или через явно запущенный `sync.sh`.
- **Force push — только через `--force-with-lease` или `--force-if-includes`.** Обычный `--force` запрещён.

## Shared engineering rules

@$HOME/dotfiles/ai/shared/rules/communication.md
@$HOME/dotfiles/ai/shared/rules/code-policies.md
@$HOME/dotfiles/ai/shared/rules/logging.md
@$HOME/dotfiles/ai/shared/rules/dependencies.md
@$HOME/dotfiles/ai/shared/rules/external-sources.md
@$HOME/dotfiles/ai/shared/rules/kotlin-style.md
@$HOME/dotfiles/ai/shared/rules/gradle-style.md
@$HOME/dotfiles/ai/shared/rules/android-cli.md
@$HOME/dotfiles/ai/shared/rules/qa-and-testing.md
@$HOME/dotfiles/ai/shared/rules/task-types.md
@$HOME/dotfiles/ai/shared/rules/task-execution.md
@$HOME/dotfiles/ai/shared/rules/workflow.md
@$HOME/dotfiles/ai/shared/rules/ast-index.md

## Configuration synchronization

`auto-pull.sh` runs at session start (or manually when the runtime has no SessionStart hook).
It pulls remote changes but never commits or pushes. If local changes exist, pulling is skipped;
the user can review them and explicitly run `sync.sh` to commit and push:

```bash
bash "$HOME/dotfiles/ai/shared/scripts/sync.sh"
```

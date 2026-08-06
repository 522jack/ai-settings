# Global neutral AI rules

This file is intentionally runtime-neutral. It must not import Gemini-, Codex-, Claude-, or Pi-specific adapters.
Runtime adapters are installed in their own harness-specific locations.

## Non-negotiable rules

- Язык общения — русский.
- **Никогда не обходить git-хуки** (`--no-verify`, `--no-gpg-sign`, `-c commit.gpgsign=false` и т.п.) без явного запроса пользователя. Если хук падает — расследовать и устранять корневую причину.
- **Никогда не коммитить и не пушить напрямую в main/master/develop продуктовых проектов.** Исключение: репозиторий конфигурации `$HOME/dotfiles/ai` синхронизируется скриптами `auto-pull.sh` / `sync.sh` и может жить на `master`; это исключение не переносится на рабочие кодовые репозитории.
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

Скрипты синхронизации находятся в `~/dotfiles/ai/shared/scripts/`. Если текущий рантайм агента
не имеет SessionStart-хука для этого репозитория, при начале сессии выполни:

```bash
bash "$HOME/dotfiles/ai/shared/scripts/auto-pull.sh"
```

Для пуша изменений конфигурации:

```bash
bash "$HOME/dotfiles/ai/shared/scripts/sync.sh"
```

@$HOME/dotfiles/ai/shared/AGENTS.md

## Правила (Claude-specific)

@$HOME/dotfiles/ai/shared/rules/orchestration.md
@$HOME/dotfiles/ai/shared/rules/ast-index.md

## Синхронизация ~/dotfiles/ai

`~/dotfiles/ai` — git-репозиторий, синхронизируемый между машинами через `csync`.

- Использовать `$HOME/dotfiles/ai/...` в конфигах/хуках. Никогда не хардкодить `/Users/<username>/...`.
- После редактирования любого отслеживаемого файла (AGENTS.md, CLAUDE.md, settings.json, хуки) — запустить `csync` для коммита и пуша. Не оставлять локальные незакоммиченные изменения.
- При «SETTINGS CONFLICT» в начале сессии: файлы `*.remote` содержат удалённую версию. Смержить их в локальный файл (объединить дополнения с обеих сторон, сохранить наиболее полное значение), удалить `.remote`, затем `csync`.

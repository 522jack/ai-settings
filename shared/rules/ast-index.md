# Правила поиска по коду

Все задачи навигации по коду покрывают три инструмента. Выбирать подходящий; полный синтаксис смотреть через `ast-index --help` или `ast-index <command> --help`.

## Матрица решений

| Задача                                         | Инструмент                              |
|------------------------------------------------|-----------------------------------------|
| Найти class / interface / struct               | `ast-index class "Name"`                |
| Найти любой symbol по имени                    | `ast-index symbol "Name"`               |
| Универсальный поиск (symbol + file + refs)     | `ast-index search "query"`              |
| Найти все использования symbol                 | `ast-index usages "Name"`               |
| Найти все references (defs + imports + usages) | `ast-index refs "Name"`                 |
| Найти subclasses / implementors                | `ast-index implementations "Interface"` |
| Иерархия class/type                            | `ast-index hierarchy "ClassName"`       |
| Кто вызывает function                          | `ast-index callers "functionName"`      |
| Дерево вызовов                                 | `ast-index call-tree "fn" --depth 3`    |
| Зависимости module                             | `ast-index deps "module-name"`          |
| Обратные dependents                            | `ast-index dependents "module-name"`    |
| Symbols в file                                 | `ast-index outline path/to/File.kt`     |
| Public API модуля                              | `ast-index api "module-path"`           |
| Потенциально неиспользуемые symbols            | `ast-index unused-symbols`              |
| Поиск TODO/FIXME/HACK                          | `ast-index todo`                        |
| Поиск по regex / string literal                | **Grep**                                |
| Поиск содержимого comments                     | **Grep**                                |
| Разрешение типов, выведенные types             | **LSP hover**                           |
| Перейти к определению (type-aware)             | **LSP goToDefinition**                  |
| Точная иерархия вызовов                        | **LSP incomingCalls / outgoingCalls**   |

## Правила приоритета

1. **ast-index FIRST** для любой задачи «найти X» — структурированные результаты, 1–11 мс.
2. **LSP**, когда нужно семантическое разрешение типов (hover, точное определение, generics).
3. **Grep** ТОЛЬКО для regex patterns, string literals, comments или если ast-index вернул пустой результат.
4. **НИКОГДА** не запускать Grep «для полноты» после того, как ast-index вернул результаты.

## Жёсткие правила — без исключений

- **НИКОГДА не использовать Grep для поиска по имени class, function, interface, variable или любого code symbol.** Это всегда область ast-index.
- **НИКОГДА не использовать Glob для поиска source file по имени class/module.** Использовать `ast-index search` или `ast-index class`.
- Если ast-index сообщает «Index not found» — остановиться и инициализировать индекс: выполнить `ast-index rebuild` через Bash (работает из любого agent, включая Explore, у которого нет Skill tool) или соответствующий skill `ast-index:initialize-*`, если доступен Skill tool. Затем повторить поиск. НЕ переходить к Grep и НЕ пропускать поиск.
- Grep разрешён ТОЛЬКО для: string literals в code, regex patterns, comment text, config values, log messages.

## Чтение больших файлов

- Перед `Read` любого файла длиннее ~500 строк сначала выполнить `ast-index outline <file>`, затем читать только нужный фрагмент через `offset` / `limit`. Outline даёт карту символов для выбора точного диапазона — не читать большие файлы целиком.

## Проверка при старте сессии

Если напоминание сессии содержит `⚠ AST INDEX NOT AVAILABLE` — для этого проекта индекс не инициализирован. Перед любым поиском по коду:
1. Определить тип проекта (Android/iOS/Web/Rust и т. д.).
2. Инициализировать индекс: `ast-index rebuild` через Bash или соответствующий skill `ast-index:initialize-*`, если доступен Skill tool.
3. Только после этого продолжать навигацию по коду.

## Актуальность индекса — автоматически

Индекс поддерживается актуальным хуками; при обычной работе ручной `update` не нужен:

- **SessionStart** выполняет `ast-index update` (incremental reconcile) или `rebuild`, если индекс отсутствует, затем запускает detached daemon `ast-index watch` для проекта в единственном экземпляре. Watcher отслеживает **все** изменения файлов — editor, subagent, terminal, `git pull`/`checkout`/`rebase`, build output — и обновляет индекс инкрементально. `watch` сам обеспечивает один экземпляр на проект, поэтому повторный запуск безопасен и ничего не делает. Репозиторий конфигурации `~/.claude` намеренно исключён из watcher (его индекс всё равно строится для поиска hooks/scripts).
- **PostToolUse:EnterWorktree** (`hooks/ast-index-bootstrap-worktree.sh`) инициализирует индекс только что открытого worktree и запускает собственный watcher — ast-index привязан к worktree и не переносится.
- **SessionEnd** (`hooks/ast-index-stop-watch.sh`) останавливает watcher проекта сессии — находит процесс `ast-index watch` по рабочему каталогу (сохранённый в watch lock PID ненадёжен) и завершает его. Best-effort: Claude Code SessionEnd **не** срабатывает на `/exit` или `/clear` и может быть пропущен при жёстком завершении терминала, поэтому watcher может пережить сессию.

Watchers в любом случае самограничены: `watch` обеспечивает один экземпляр на проект, поэтому повторное открытие проекта использует существующий watcher вместо запуска второго. В худшем случае остаётся один лёгкий watcher на каждый отдельный проект, открытый после перезагрузки; устаревший lock оставшегося watcher сам исправляется при следующем запуске.

Если subagent всё ещё получает «Index not found» в code worktree, он должен выполнить `ast-index rebuild` (у него есть Bash) — никогда не переходить к Grep.

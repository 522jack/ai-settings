# Поиск по коду

Для поиска символов/файлов сначала `ast-index`: `search`, `symbol`, `class`, `file`, `usages`, `refs`, `implementations`, `hierarchy`, `callers`, `call-tree`, `deps`, `dependents`, `api`, `outline`. Синтаксис уточнять через `--help`. LSP — для выведенных типов и точного семантического разрешения.

Grep разрешён для regex/string literals/comments/config/log messages либо пустого результата индекса; не запускать его «для полноты» после найденных результатов. Не искать code symbols через Grep или source file по class/module через Glob.

При `Index not found` выполнить `ast-index rebuild` и повторить запрос. При недоступном инструменте или неподдерживаемом языке явно отметить adapter limitation и использовать узкий доступный поиск; тяжёлый поиск делегировать. Ошибка индекса не равна его недоступности.

Перед чтением code file длиннее ~500 строк получить `ast-index outline <file>` и прочитать целевой диапазон. Для неструктурных docs/config и недоступного outline выбрать узкий фрагмент доступным инструментом.

При смене worktree, отсутствии/устаревании индекса или работе над hooks прочитать [обслуживание индекса](references/ast-index-operations.md). Не предполагать, что watcher уже работает в текущем адаптере.

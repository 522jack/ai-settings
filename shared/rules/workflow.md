# Рабочий процесс по риску

Skills — доступные workflows, а не обязательная цепочка для любого diff. Явно запрошенный skill выполнять по его контракту; project instructions, hooks и CI остаются обязательными независимо от уровня риска.

## Preparation — до реализации

Определить scope, source of truth (задача/AC/spec/repro/design/доступный baseline), применимые rules, риск и минимальные существующие проверки. При неизвестном API прочитать `external-sources.md`; при dependency change — `dependencies.md`. Зафиксировать intended behavior и ограничения, если formal baseline отсутствует. Правила создания тестов и mobile QA: [qa-and-testing.md](qa-and-testing.md).

## Уровни и фазы

| Уровень | Критерий | Обязательные фазы |
|---|---|---|
| mechanical | Документация, config без изменения логики, очевидное механическое изменение без изменения поведения | preparation → изменение → targeted existing checks |
| ordinary | Ограниченное изменение поведения без признаков high-risk | preparation → implementation → targeted existing checks → независимый review → исправления и повтор затронутых проверок |
| high-risk | Auth/security/permissions, потеря/целостность данных или schema migration, concurrency, публичный API/CLI/протокол, архитектурные границы либо сопоставимый радиус последствий | preparation → implementation → checks → полный `finalize` → `acceptance` |

При сомнении, затрагивающем безопасность/данные/контракты, выбрать high-risk. Малый diff не доказывает малый риск. В preparation кратко назвать выбранный уровень и основание; переоценить при изменении scope.

Targeted checks — релевантные существующие build/lint/typecheck/tests или проверка документа/конфига. Не запускать автоматически полный suite, если проект этого не требует. Build проверяет компиляцию, а review — намерение; не выдавать их за доказательство runtime behavior.

Независимый review выполняет другой specialist, проверяя diff и контракт; автор исправляет реальные замечания. Review без исправления найденных blockers не закрывает ordinary. `finalize` для high-risk выполняет полный review→fix→simplify по своему skill; одиночный review его не заменяет. `acceptance` после него сверяет итог с source of truth и отмечает ограничения проверки. Explicit opt-in и отсутствие инструментов не маскировать словом PASS.

## Повторное использование проверок

Переиспользовать результат только для неизменённых exact code (commit/tree/diff или hash проверенных файлов), scope/AC, команды и environment/toolchain/dependencies. Отчёт должен содержать эти основания. После исправления повторить затронутые проверки; изменённый код нельзя закрыть старым PASS. Не сокращать обязательный triggered panel запрошенного skill или high-risk workflow без его явного разрешения.

## PR и завершение

Реализацию продукта вести в feature branch/worktree. Draft PR открывать, если это входит в задачу; pipeline сам не разрешает push/merge. Promotion draft→ready и другие внешние действия выполнять в пределах уже полученной авторизации; при её отсутствии запросить подтверждение на готовом результате. `drive-to-merge` запускать по запросу, а не автоматически.

Для bug fix сохранить root cause и доступное воспроизведение в `swarm-report/<slug>-debug.md` при необходимости отдельного артефакта. Финальный ответ краткий: результат, проверки, ограничения; подробная specialist receipt — в артефакте, если она нужна workflow.

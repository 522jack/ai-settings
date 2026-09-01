Referenced from: `plugins/developer-workflow/skills/acceptance/SKILL.md` (§Step 1: Gather Inputs).

# Acceptance — ветви источников и frontmatter spec

Подробная логика разрешения входных данных для шага 1. Acceptance требует хотя бы одного
источника проверки (spec, test plan или `debug.md`); этот файл описывает условия срабатывания
каждой ветви и создаваемые ею артефакты.

## 1.1 Источник spec (необязателен, если предоставлен test plan или debug.md)

Принимайте любую комбинацию: макеты Figma, PRD / требования, список критериев приёмки,
описание PR, issue GitHub/Linear. Прочитайте все предоставленные источники.

**Прочитайте frontmatter spec.** Если он есть, загрузите `platform`, `surfaces`, `risk_areas`,
`non_functional`, `acceptance_criteria_ids`, `design.figma`. These drive the conditional
триггеры шага 3 и два инвариантных защитных правила базового плана:

- наличие `ui` в `surfaces` принудительно добавляет `manual-tester` в fan-out, если есть источник
  сценария, даже когда шаг 0 обнаружил non-UI проект (гибридные продукты с UI- и non-UI-поверхностями);
- если `surfaces` задан, но не содержит `ui`, а проект определён как UI, это означает, что spec
  явно исключает UI — пропустите `manual-tester`, даже если `has_ui_surface` равно true, и укажите
  это в секции Check Plan receipt.

Если у spec нет frontmatter (spec до итерации 2, внешний spec или issue в виде обычного текста),
каждое условие по умолчанию имеет значение «не вызвано», а `surfaces` считается не заданным;
выполняются только базовые проверки, зависящие от `has_ui_surface`. Это сохраняет обратную совместимость.

## 1.2 Поиск доступных артефактов (параллельно)

Перед выбором ветви прочитайте следующее одним пакетным набором вызовов Read. Каждый элемент
может завершиться ошибкой, трактуемой как отсутствие, — это ожидаемо:

- `swarm-report/<slug>-test-plan.md` (receipt)
- `docs/testplans/<slug>-test-plan.md` (permanent)
- `swarm-report/<slug>-debug.md` (bug-fix reproduction steps)

Вместе со встроенными входными данными и источниками spec срабатывает одна из ветвей ниже. Запишите
выбранную ветвь как `test_plan_source` в receipt.

### Ветвь 1 — Receipt присутствует (`test_plan_source: receipt`)

**Условие:** существует `swarm-report/<slug>-test-plan.md`.

Прочитайте YAML frontmatter receipt и загрузите `permanent_path`. Интерпретируйте `review_verdict`
согласно каноническому определению в `generate-test-plan/SKILL.md` §Receipt: считайте
`PASS` / `WARN` / `skipped` as proceed; `FAIL` and `pending` as blockers that escalate
возвращаемыми вызывающему коду и эскалируйте их, рекомендуя пересмотр через `multiexpert-review` до
повторного запуска acceptance. Передайте **постоянный файл** `manual-tester` как основной источник test-plan.
Если receipt содержит поле `platform:`, используйте его как дополнительный вход для политики
переопределения шага 0.

### Ветвь 2 — постоянный файл существует без receipt (`test_plan_source: mounted`)

**Условие:** ветвь 1 не сработала **и** `docs/testplans/<slug>-test-plan.md` существует
на диске без соответствующего receipt.

При вызове без upstream receipt acceptance отвечает за mount-receipt. Создайте
mount-receipt в `swarm-report/<slug>-test-plan.md` по каноническому формату из
`generate-test-plan/SKILL.md` §Receipt. Примените mount-переопределения: `status: Mounted`,
`review_verdict: skipped`, `source_spec: existing (pre-orchestration)`. Derive
`phase_coverage` по заголовкам фаз постоянного файла; опустите поле, если покрытие нельзя надёжно
определить. Передайте постоянный файл `manual-tester`.

### Ветвь 3 — доступен встроенный test plan, spec или `debug.md` (`test_plan_source: on-the-fly`)

**Условие:** ветви 1 и 2 не сработали **и** вызов предоставляет встроенный test plan,
источник spec, `swarm-report/<slug>-debug.md` или любую их комбинацию.
`debug.md` трактуется как источник, подобный spec, для проверки исправления ошибки, если нет receipt или
permanent test plan exists, so this branch also covers the standalone "debug-only" case.

Четыре режима:

- **Только test plan (без spec / debug.md)** — выполнить как есть; вердикт зависит от pass/fail TC.
- **Test plan + spec и/или debug.md** — выполнить план, сопоставить его со spec или шагами
  воспроизведения, сообщить пользователю об очевидных пробелах («spec/debug упоминает X, но test plan
  это не покрывает — добавить TC?»).
- **Только spec (без test plan)** — создать test plan по spec: определить тестируемые потоки,
  написать случаи с префиксом TC, уровнями/шагами/ожидаемыми результатами, представить на утверждение
  и скорректировать по обратной связи.
- **Только `debug.md` (без test plan и spec)** — вывести E2E из инвертированных шагов воспроизведения
  (инверсию выполняет шаг 2); записать `test_plan_source: on-the-fly`. Не создавать TC на лету сверх того,
  что уже создаёт шаг 2.

### Ветвь 4 — ничего не доступно (`test_plan_source: absent`)

**Условие:** нет receipt, постоянного файла, встроенного test plan, источника spec и
`swarm-report/<slug>-debug.md` (путь исправления ошибки).

Перейдите к §Step 1.5 Source-Missing Gate в SKILL.md. Не выполняйте проверки.

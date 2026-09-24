# Правила QA и тестирования

Решения по тестированию для всего проекта и всех стеков.

## 0. Стратегия проверки

Для каждой задачи с изменением кода определить минимальную механическую проверку существующими средствами проекта. По умолчанию это L0/L1 и запуск уже существующих релевантных тестов; создание новых тестов, test fixtures, snapshot baselines и test infrastructure выполняется **только по явному запросу пользователя**.

### Пирамида проверки

Уровни применяются по необходимости, а не как обязательная лестница:

| Уровень | Название | Описание |
|---|---|---|
| L0 | Build | проект — или только необходимая часть — компилируется |
| L1 | Static analysis | lint, type check, code review, dependency audit |
| L2 | Unit tests | существующие быстрые тесты без устройства |
| L3 | UI tests | существующие автоматические тесты, требующие emulator/device |
| L4 | E2E tests | существующий полный автоматизированный flow |
| L5 | Manual verification | runtime QA на работающем приложении |

**Новые тесты — opt-in.** Не добавлять и не расширять тестовое покрытие автоматически для feature, bug fix, migration, public API или пробела coverage. Можно рекомендовать конкретный тест и риск его отсутствия, но писать его только после явной просьбы пользователя. Существующие тесты разрешено запускать по умолчанию; если запрошенное изменение закономерно меняет контракт, обновить уже существующие assertions/fixtures вместе с кодом, не расширяя покрытие.

**Mobile L5 — только opt-in.** Не запускать ручное тестирование, приложение, emulator, simulator или physical device для Android/iOS без явной просьбы пользователя в текущей задаче. Это относится также к снятию screenshots и behavioral baseline с устройства. Когда пользователь просит такую проверку, закрыть её самостоятельно через текущий runtime adapter (`android`, mobile MCP, `manual-tester` или ближайший эквивалент); emulator/simulator предпочтительнее физического устройства, если реальное hardware не требуется.

### Сбор логов L5 — фильтровать, ограничивать, маскировать

Когда L5 читает runtime logs тестируемого приложения (logcat / `os_log` / server logs) как сигнал проверки, обязательны три правила:

- **Опира́ться на детерминированный verifier, а не на текст лога.** Pass/fail определяется test exit code, build result или screenshot/`assert_visible`. Лог — это *диагностическая гипотеза*, объясняющая **почему**; никогда не единственный сигнал pass/fail (логи шумные и нестабильные). Crash scan дополняет детерминированную проверку, но не заменяет её.
- **Фильтровать и ограничивать до передачи в context.** Никогда не направлять raw logs в диалог — это переполняет context и тонет в шуме. Для pass/fail scan использовать level ≥ ERROR; ограничивать по package/PID на Android (`--pid=$(adb shell pidof -s PKG)`, `get_logs(level="E", package=…)`), по `subsystem` на iOS (`simctl log show --predicate 'subsystem=="<bundleId>"'`); ограничивать объём (`-m N` / `tail` / last-N); большой output → в файл или `ctx_batch_execute`, агент читает путь, а не bytes. Паттерны сбоев: Android `FATAL EXCEPTION` / `AndroidRuntime: FATAL` / ANR / unhandled NPE; iOS `fault`/`error`.
- **Удалять secrets до передачи.** Логи, которые агент *читает*, подчиняются тому же правилу «что никогда не попадает в лог», что и записываемые им логи ([[logging]]): никогда не передавать в context raw `.env`, `curl -v` или `Authorization` headers; маскировать `Bearer .*`, `*_TOKEN`, `*_KEY`, PII. OWASP LLM06 — собранные логи достигают model provider.

### Одноразовые тесты проверки

Одноразовый тест считается написанием теста и поэтому создаётся только по явному запросу пользователя. После запуска удалить его, если пользователь не просил сохранить покрытие.

## 1. Покрытие Public API

Изменение public symbol само по себе не требует создания теста. Если пользователь явно запросил тесты или coverage audit, сопоставлять public symbol с тестом в порядке: (1) `Foo.kt` ↔ `FooTest.kt` / `FooTests.swift` / `Foo.test.ts`; (2) имя symbol встречается в test file того же модуля; (3) явная annotation (`@CoveredBy("...")`). В остальных запусках отсутствие такого теста — неблокирующая рекомендация, а не gate.

## 2. Система приоритетов тестов

Классифицировать каждый случай: **P0** release-critical (crash, data-loss, security, payment, auth — ошибка блокирует release); **P1** AC-driven (один тест на каждый AC-N из spec, названный по этому AC); **P2** happy path (один самый распространённый успешный flow на surface); **P3** edges (границы, empty, locale/timezone, большие inputs, races). P4 (cosmetic/exploratory) исключается из формальных планов — только `bug-hunt`.

## 3. Лёгкий test plan для Non-UI

Когда выполняются **все три** условия — нет mockups, surface относится к API/library/CLI (без end-user UI), review `ux-expert` не входит в scope — убрать разделы, основанные на mockup, и покрыть только: input validation (types, ranges, malformed), state transitions (input → observable change), error paths (какое exception/error code и когда). Пропустить viewport / accessibility / visual-regression.

## 4. Автор исправляет сломанные существующие тесты в том же запуске

Если запрошенное изменение ломает существующий тест, обновить его в том же PR, когда тест фиксирует изменившийся контракт, либо исправить production-код, когда это регрессия. Это не разрешает автоматически добавлять новые test cases. `@Ignore` / `xit` / `t.Skip` запрещены без ссылки на tracked issue; никаких «merge red» или «fix later».

## 5. Тестовая инфраструктура — определяется проектом

Конкретные runner, task names и commands — ответственность **проекта**; читать их из runtime instruction files проекта (`<repo>/AGENTS.md`, `<repo>/CLAUDE.md` или эквивалента) или build config, а не из универсальной таблицы здесь. Если проект их не задаёт, выводить из root marker files (`build.gradle*` / `Package.swift` / `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `Makefile`) и build config — и **блокировать работу и спрашивать**, если ошибочно предположение о Xcode scheme/destination, Python runner flags или модуле, которому принадлежат изменённые files в monorepo.

## 6. Источник истины для проверки

Обязательный результат планирования — определяет «готово», по нему `/acceptance` проверяет контракт.

| Тип | Когда использовать | Artifact |
|---|---|---|
| Task / requirements | явный AC или ясная задача | plan notes / AC list |
| Spec | слишком велик для удержания в голове; traceable ACs | `/write-spec` → `docs/specs/<slug>-spec.md` |
| Test plan | структурированные исполнимые cases | `/generate-test-plan` → `docs/testplans/<slug>-test-plan.md` |
| Design mockups | визуальные ACs UI/UX | Figma в spec `design.figma` или screenshots |
| Debug artifact | только bug-fix — repro steps являются контрактом | `swarm-report/<slug>-debug.md` |
| Behavioral baseline | migration / «shouldn't affect behavior» | зафиксирован до изменений (см. [[task-types]] § Before-state baseline) |

**Behavioral baseline:** для «shouldn't affect behavior» / migration использовать уже доступные passing tests, сохранённые API snapshots, требования или предоставленные screenshots. Снимать новый baseline через mobile emulator/simulator/device можно только по явной просьбе пользователя. Если доступного baseline нет, задокументировать intended behavior, отсутствие runtime baseline и риск; это не должно автоматически запускать manual QA.

**Отсутствующий источник:** если source of truth нет и создать его невозможно без opt-in действий, задокументировать в плане intended behavior, почему нет formal source и какой доступный proxy используется. `/acceptance` может выполнить code/build проверки без mobile manual QA; предложить пользователю отдельный opt-in запуск, но не блокировать реализацию только из-за его отсутствия.

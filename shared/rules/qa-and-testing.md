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

### Сбор логов L5

Единая политика фильтрации, ограничения объёма, redaction и детерминированного verifier — [logging.md](logging.md). Для Android ограничивать package/PID, для iOS — subsystem; crash scan дополняет проверку, но не заменяет её.

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

Конкретные runner, task names и commands — ответственность **проекта**; читать их из runtime instruction files проекта (`<repo>/AGENTS.md`, `<repo>/CLAUDE.md` или эквивалента) или build config, а не из универсальной таблицы здесь. Если проект их не задаёт, выводить из root marker files (`build.gradle*` / `Package.swift` / `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `Makefile`) и build config — и исследовать доступные targets/runner/module при неоднозначности. Спрашивать только если доступные данные не позволяют безопасно выбрать команду; продолжать независимую работу.

## 6. Источник истины для проверки

Source of truth определяет «готово»; при high-risk или явно запрошенном запуске `acceptance` проверяет этот контракт.

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

## Hooks, CI и риск

Проектные hooks/CI — обязательные проверки: targeted checks не отменяют их. Уровни mechanical/ordinary/high-risk, порядок review/finalize/acceptance и условия переиспользования результата определены в [workflow.md](workflow.md).

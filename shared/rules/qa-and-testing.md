# Правила QA и тестирования

Решения по тестированию для всего проекта и всех стеков.

## 0. Обязательная стратегия тестирования

Для каждой задачи с изменением кода на этапе планирования определяется стратегия тестирования — применимые уровни pyramid и инструменты. Для пропуска нужна веская причина («нет кода, только markdown»); «простая» / «быстрое исправление» / «очевидно» не принимаются.

### Пирамида проверки

Уровни строго последовательны — каждый требует успешного прохождения предыдущего. Начинать с L0; переход выше требует обоснования.

| Уровень | Название | Описание |
|---|---|---|
| L0 | Build | проект — или только необходимая часть (релевантное app/module, не всегда весь repo) — компилируется. Без этого дальнейшие шаги бессмысленны. |
| L1 | Static analysis | lint, type check, code review, dependency audit — применяется всегда |
| L2 | Unit tests | быстрые, без устройства, для чистой логики |
| L3 | UI tests | автоматические, требуют emulator/device |
| L4 | E2E tests | полный автоматизированный flow |
| L5 | Manual verification | runtime QA tools / эквивалент `manual-tester` на работающем приложении |

**L5 обязателен для:** library version bumps (даже patch), tech/framework migrations, изменений infra-layer (network, storage, auth, DI), любых задач «не должны повлиять на поведение» — проверять в runtime, не предполагать.

**L5 — закрывать самостоятельно и автономно.** Не «оставлять пользователю для запуска». Управлять приложением через текущий runtime adapter: mobile MCP (`mcp__mobile__*`), Codex/browser/mobile tools, Playwright, `manual-tester` или ближайший эквивалент реального устройства/browser. По умолчанию использовать emulator/simulator; физическое устройство — только когда изменение требует настоящего оборудования, которое emulator не воспроизводит (biometric HAL, camera, NFC, GPS, sensor fusion). Проверять доступность эмпирически (`adb devices -l`, `emulator -list-avds`, `xcrun simctl list`) — никогда не объявлять L5 невыполнимым теоретически; если нужный AVD/image не установлен, но его легко получить, установить и запустить. Самостоятельно собрать/установить APK, пройти flow и сымитировать inputs. Участие пользователя — **крайний вариант** — только при реальных блокерах: недоступные агенту credentials, backend в закрытой/VPN сети или поведение, существующее только на физическом оборудовании.

### Сбор логов L5 — фильтровать, ограничивать, маскировать

Когда L5 читает runtime logs тестируемого приложения (logcat / `os_log` / server logs) как сигнал проверки, обязательны три правила:

- **Опира́ться на детерминированный verifier, а не на текст лога.** Pass/fail определяется test exit code, build result или screenshot/`assert_visible`. Лог — это *диагностическая гипотеза*, объясняющая **почему**; никогда не единственный сигнал pass/fail (логи шумные и нестабильные). Crash scan дополняет детерминированную проверку, но не заменяет её.
- **Фильтровать и ограничивать до передачи в context.** Никогда не направлять raw logs в диалог — это переполняет context и тонет в шуме. Для pass/fail scan использовать level ≥ ERROR; ограничивать по package/PID на Android (`--pid=$(adb shell pidof -s PKG)`, `get_logs(level="E", package=…)`), по `subsystem` на iOS (`simctl log show --predicate 'subsystem=="<bundleId>"'`); ограничивать объём (`-m N` / `tail` / last-N); большой output → в файл или `ctx_batch_execute`, агент читает путь, а не bytes. Паттерны сбоев: Android `FATAL EXCEPTION` / `AndroidRuntime: FATAL` / ANR / unhandled NPE; iOS `fault`/`error`.
- **Удалять secrets до передачи.** Логи, которые агент *читает*, подчиняются тому же правилу «что никогда не попадает в лог», что и записываемые им логи ([[logging]]): никогда не передавать в context raw `.env`, `curl -v` или `Authorization` headers; маскировать `Bearer .*`, `*_TOKEN`, `*_KEY`, PII. OWASP LLM06 — собранные логи достигают model provider.

### Одноразовые тесты проверки

Тесты не обязаны быть постоянными. Для проверки migration или разового/временного поведения во время реализации допустимо **написать тест, запустить его (подтвердить фактический green), затем удалить** — это проверка без коммита теста. В отличие от §4: §4 запрещает пропускать или удалять тесты, которые вы *сломали* (чужое покрытие); disposable test — созданный вами и принадлежащий вам scaffolding. Оставлять тест постоянным, когда поведение заслуживает постоянного покрытия; использовать одноразовый, когда проверка действительно разовая.

## 1. Ворота покрытия Public API

Изменённый public symbol должен проверяться тестом. «Public» = Kotlin без `@internal`/`private`, Swift `public`/`open`, TS `export`; всё остальное — internal.

**Trivial — тест не нужен:** чистые data carriers (`data class`, Swift `struct` только с stored props, TS interfaces, enums, type aliases); builder DSLs без логики; types, повторно экспортирующие уже протестированный symbol.

**Нет изменения поведения → нет нового теста.** Чистое перемещение/переименование файла, repackaging, relocation symbol или изменение только imports — это **не** «изменение» symbol; существующие тесты + green build уже покрывают его. Никогда не добавлять unit tests поверх перемещения без логики: это over-testing, такой же шум, как over-editing. Ворота срабатывают при изменении поведения или сигнатуры, а не только при смене расположения symbol.

**Сопоставление тестов (порядок приоритета):** (1) file-name `Foo.kt` ↔ `FooTest.kt` / `FooTests.swift` / `Foo.test.ts`; (2) имя symbol встречается в любом test file того же модуля; (3) явная annotation (`@CoveredBy("...")`). Если ничего не найдено → gate fails: написать тест или пометить trivial до прохождения `/check`.

## 2. Система приоритетов тестов

Классифицировать каждый случай: **P0** release-critical (crash, data-loss, security, payment, auth — ошибка блокирует release); **P1** AC-driven (один тест на каждый AC-N из spec, названный по этому AC); **P2** happy path (один самый распространённый успешный flow на surface); **P3** edges (границы, empty, locale/timezone, большие inputs, races). P4 (cosmetic/exploratory) исключается из формальных планов — только `bug-hunt`.

## 3. Лёгкий test plan для Non-UI

Когда выполняются **все три** условия — нет mockups, surface относится к API/library/CLI (без end-user UI), review `ux-expert` не входит в scope — убрать разделы, основанные на mockup, и покрыть только: input validation (types, ranges, malformed), state transitions (input → observable change), error paths (какое exception/error code и когда). Пропустить viewport / accessibility / visual-regression.

## 4. Автор исправляет сломанные тесты в том же запуске — обязательно

Кто ломает существующие тесты, тот исправляет их в том же PR. `@Ignore` / `xit` / `t.Skip` **запрещены** без ссылки на tracked issue в annotation (`@Ignore("flaky on iOS 17 — JIRA-1234")`). Никаких «merge red», «fix later» и `--skip-test-fix`. `/check` — это gate; skip без tracked issue — нарушение hook.

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

**Behavioral baseline:** для «shouldn't affect behavior» / «migrate without breaking» before-state И ЕСТЬ истина. Полное определение — что подходит, что нет и shortcut для test coverage — находится в [[task-types]] § Before-state baseline (единый источник). Кратко: зафиксировать состояние до любого изменения (screenshots / session `manual-tester` / `e2e-scenario.md`), сохранить в `swarm-report/<slug>-baseline.md`, затем `/acceptance` проверяет соответствие after-state состоянию до изменения 1:1. «should be fine» не является source of truth.

**Отсутствующий источник:** если source of truth нет и создать его невозможно, задокументировать в плане: intended behavior (один абзац), почему нет formal source и какой proxy используется (например, manual walkthrough вместо task description). `/acceptance` Step 1.5 блокирует работу, если source не найден, и предлагает upstream skill; обоснование задаёт proxy, но не обходит gate.

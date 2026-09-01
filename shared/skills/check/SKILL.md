---
name: check
description: >-
  Запускайте все механические проверки проекта — build, статический анализ (lint),
  tests и typecheck — одной командой. Это переиспользуемая утилита для любого навыка,
  изменяющего код: write-tests, finalize или прямого вызова пользователем.

  Автоматически обнаруживает инструменты проекта (Gradle, npm/pnpm/yarn, cargo, Swift SPM, Xcode, Python,
  Go, Makefile) и выполняет подходящие команды. Код НЕ изменяет — только проверяет.

  Используйте при запросах: «проверить проект», «запустить тесты», «проверить сборку», «собирается ли?», «smoke check»,
  «убедиться, что ничего не сломано», «проверить ветку», «после редактирования X запустить проверки»,
  «всё ли чисто?», «я что-нибудь сломал?»,
  или когда этап pipeline должен убедиться, что изменения кода ничего не сломали. НЕ используйте для code review
  (это фаза A finalize), функциональной приёмки (используйте acceptance) или исследовательского QA
  (напрямую вызывайте агента manual-tester).
---

# Проверка

Механический проход проверки: обнаружить инструменты проекта, запустить build + lint + typecheck + tests,
сообщить pass/fail по категориям и итоговый вердикт. По умолчанию fail-fast. **Код не изменяется:**
навык выполняет команды и сообщает результат; цикл исправления принадлежит вызывающему коду.

---

## Фаза 1: определите инструменты

Обнаружение файлов-маркеров (`gradlew`, `package.json`, `Cargo.toml`, `Package.swift`, `*.xcodeproj`, `pyproject.toml`, `go.mod`, `Makefile`) выполняется согласно `$HOME/dotfiles/ai/shared/rules/qa-and-testing.md` § Test infrastructure. Указанные ниже значения по умолчанию для стека переопределяют таблицу только там, где одного test runner недостаточно для полной проверки.

Если обнаружено несколько стеков (monorepo), выполните проверки для каждого. Если маркер не найден → эскалируйте вызывающему коду.

---

## Фаза 2: определите команды

### Gradle

`./gradlew check` runs verification but does **not** compile production sources. Always pair with `assemble`:

```
./gradlew assemble check
```

**Android (AGP)** — один `check` обычно запускает только unit-тесты, а `connectedCheck` требует устройства (вне области). Используйте команды для конкретного варианта:

```
./gradlew assembleDebug lintDebug testDebug
```

Detect Android via `android { }` block or `com.android.application` / `com.android.library` plugin. Always honor the wrapper (`./gradlew`); never invoke a system-installed `gradle`. If the wrapper is non-executable, invoke as `sh ./gradlew assemble check` rather than mutating tracked file mode.

### Node (`package.json`)

Прочитайте `scripts` и выполните существующие в таком порядке — **переопределение стека для стандартной последовательности фазы 3**, поскольку JS-проектам редко нужна сборка для обнаружения проблем lint/type/test, а `build` выполняется дольше всего:

1. `lint` (or `lint:all`)
2. `typecheck` (or `tsc` / `type-check`)
3. `test` (or `test:unit`)
4. `build` — only if CI runs it (check `.github/workflows/*.yml`)

Pick the package manager by lockfile: `pnpm-lock.yaml` → `pnpm run`, `yarn.lock` → `yarn`, `package-lock.json` → `npm run`. No `lint`/`test` scripts → escalate.

### Xcode

Никогда не угадывайте scheme или destination. Эскалируйте с сообщением: «Обнаружен Xcode-проект, но команды проверки не настроены. Предоставьте `xcodebuild -scheme <Scheme> test -destination '<destination>'` или настройте их как переопределение проекта». Фаза 3 не может продолжиться без них.

### Python

Проверьте `pyproject.toml` / `setup.cfg` и запускайте только настроенные инструменты — `[tool.ruff]` → `ruff check .`, `[tool.mypy]` → `mypy .`, `[tool.pyright]` → `pyright`, `[tool.pylint]` → `pylint <package>`, `[tool.flake8]` → `flake8 .`, `[tool.pytest.ini_options]` → `pytest`, `[tool.black]` → `black --check .`. Предпочитайте `uv run <tool>`, если есть `uv.lock` или `[tool.uv]`. Не устанавливайте отсутствующие инструменты.

### Другие стеки

- **Rust:** `cargo fmt --check` + `cargo clippy --all-targets -- -D warnings` + `cargo test --all-features` (clippy already type-checks).
- **Swift SPM:** `swift build` + `swift test`; add `swiftlint` or `swift-format lint` if a config file exists.
- **Go:** `go vet ./...` + `go test ./...` + `go build ./...`.
- **Makefile:** `make check` if defined (authoritative); otherwise `make test`. Never both.

---

## Фаза 3: выполните

По умолчанию: **последовательно, fail-fast** в порядке Build → Lint → Typecheck → Tests. При первой ошибке остановитесь, сообщите результат с фрагментом stderr и верните управление вызывающему коду.

### Режимы по запросу

| Флаг | Эффект |
|---|---|
| `--all` | Run every check regardless of earlier failures (PARTIAL verdict if mixed). |
| `--fast` | Skip tests AND the public-API coverage gate; build + lint + typecheck only. |
| `--only <category>` | Single category (`build` / `lint` / `typecheck` / `tests`); coverage gate skipped. |
| `--no-coverage-gate` | Skip Phase 3.5 only. Recorded as `skipped: [coverage]` plus a Notes entry. |

Вызывающий код передаёт режим первым токеном `--<flag>` или естественным языком («fast mode», «only the tests»). Взаимоисключающие флаги → завершение с ясной ошибкой.

### Сбор вывода

Для каждой команды: сохраните код выхода; при ошибке сохраните последние ~50 строк stderr (обрежьте начало); при успехе не включайте stdout в отчёт — достаточно статуса.

---

## Фаза 3.5: gate покрытия публичного API (включён по умолчанию)

Запускается после категории tests. Даже если build / lint / typecheck / tests прошли, новый публичный символ без соответствующего теста проваливает этот gate — это ранняя проверка; поздний аудит находится в фазе D `finalize`.

**Symbol classification, trivial-no-test allow-list, and test-matching priority** — see `$HOME/dotfiles/ai/shared/rules/qa-and-testing.md` § Public-API coverage gate.

**Когда запускается gate:** текущая ветка отличается от удалённой ветки по умолчанию (определите base через `git remote show origin | grep "HEAD branch"`, запасные варианты `main`/`master`/`develop`; работайте с `git diff $(git merge-base origin/<base> HEAD)..HEAD`). Если ветка — default, молча пропустите. `--no-coverage-gate` → запишите `skipped: [coverage]`.

**Per-language matching extras** beyond the global rule:
- Kotlin annotation `@NoTestRequired` or `@Suppress("MissingTest")` satisfies the gate; equivalent line comment `// no-test-required: <reason>` works for Swift / Rust / Go / TS / JS / Python.
- Files under `no-test-harness/` are an escape hatch for legacy modules.

**Вывод:** строка `coverage` в отчёте и массивы блока вердикта. Результат: `PASS` (каждый символ сопоставлен или тривиален), `FAIL` (один или несколько не сопоставлены — перечислите `<file>:<line>: <symbol>` и проверенное правило) или `SKIP` (явное переопределение).

`coverage: FAIL` от `/check` означает, что инженер добавляет тесты, помечает символ как тривиальный или передаёт `--no-coverage-gate` (не рекомендуется, фиксируется). При вызове из `finalize` исправление в том же запуске выполняет инженер, добавивший символ.

---

## Фаза 4: отчёт

Две части: человекочитаемое тело + обязательный машиночитаемый блок сводки в конце.

**Тело:**

- `## Check report` со строками `Stack detected`, `Mode`, `Verdict`.
- `### Results` — по одной строке на проверку с Command / Status / Notes.
- `### Failures` (если есть) — для каждой ошибки: команда, код выхода, фрагмент stderr, предлагаемый следующий шаг.
- `### Summary` — число passed/failed/skipped + общее время.

**Machine-readable trailer** — required, orchestrator/skills tail-parse it:

~~~
verdict: FAIL
passed: [build, coverage]
failed: [lint]
skipped: [tests]
~~~

`verdict` is one of:

- **PASS** — every executed check exit 0 AND coverage gate (when run) matched every new public symbol.
- **FAIL** — at least one executed check non-zero OR coverage gate had unmatched symbols. Default fail-fast: a failure followed by SKIP for remaining categories is still FAIL.
- **PARTIAL** — reserved for `--all` when some passed and some failed.

---

## Правила области

- **В области:** запуск механических проверок; отчёт о результатах; усечение шумного вывода.
- **Вне области:** редактирование кода, предложения исправлений, интерактивные команды, установка отсутствующих инструментов, создание веток, коммиты.
- **Никогда** не исправляйте автоматически форматирование/lint (даже с `--fix`); не изменяйте build-файлы, чтобы скрыть сбой; не запускайте разрушительные операции (`./gradlew clean` только по запросу вызывающего кода).

---

## Эскалация

Остановитесь и сообщите вызывающему коду, когда:

- No recognized tooling AND no commands provided.
- A check hangs or exceeds 15 minutes wall time — abort with a timeout note.
- Auth / network unavailable (private Maven repo down, etc.).
- Build wrapper referenced but missing (e.g., `gradlew` absent) — report; do not regenerate.

Укажите, что обнаружено, что предпринято и что должен решить вызывающий код.

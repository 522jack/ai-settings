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

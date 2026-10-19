## Фаза 3.5: аудит покрытия публичного API (opt-in)

По умолчанию `SKIP`: отсутствие нового теста не проваливает `/check` и не инициирует написание тестов.

Запускать только с `--coverage-gate`, который отражает явную просьбу пользователя написать тесты или выполнить coverage audit. После категории tests сопоставить новые public symbols по правилам `$HOME/dotfiles/ai/shared/rules/qa-and-testing.md` § Public API coverage.

**Когда запускается:** текущая ветка отличается от удалённой ветки по умолчанию. Если ветка — default, записать `SKIP`.

**Per-language matching extras:** Kotlin `@NoTestRequired` / `@Suppress("MissingTest")`; для Swift / Rust / Go / TS / JS / Python — `// no-test-required: <reason>`; `no-test-harness/` остаётся escape hatch legacy-модулей.

**Вывод:** `PASS`, если каждый символ сопоставлен или помечен; `FAIL`, если есть gaps; `SKIP`, если opt-in отсутствует. При `FAIL` предложить конкретные тесты. Создание тестов делегируется вызывающей стороне; сам check остаётся read-only.

---

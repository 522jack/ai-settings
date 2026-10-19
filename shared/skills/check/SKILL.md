---
name: check
description: "Запустить настроенные механические проверки проекта: build, lint, typecheck и существующие тесты. Применять при явном запросе проверки сборки/тестов или вызове check; не заменяет semantic review и функциональную acceptance."
---

# Проверка

Read-only utility: обнаружить команды проекта, выполнить их, вернуть результаты. Исправления принадлежат вызывающей стороне.

1. Прочитайте проектные инструкции, CI и scripts/tasks. Их required checks имеют приоритет над defaults; явный вызов check запускает все обязательные проектные проверки, даже если обычному workflow достаточно targeted checks. Для monorepo учтите каждый обязательный стек.
2. Если команд нет, определите стек по gradlew/package.json/Cargo.toml/Package.swift/Xcode/pyproject.toml/go.mod/Makefile. Прочитайте только соответствующий раздел [stack-commands.md](references/stack-commands.md).
3. Выполняйте последовательно, fail-fast: build → lint → typecheck → tests; порядок Node указан в reference. Сохраняйте команду, exit code, время; при сбое последние ~50 строк stderr. Без мутации code/scope/environment повторно используйте доказанный результат того же состояния, не повторяйте команды между read-only review-фазами.

Режимы: `--all` выполняет весь набор несмотря на ошибки; `--fast` исключает необязательные tests; `--only build|lint|typecheck|tests` ограничивает необязательные категории. Required checks/hook/CI эти флаги не отключают; конфликт запроса с обязательными проверками сообщите явно. Несовместимые флаги — ошибка.

`--coverage-gate` допустим только после явного запроса tests/coverage audit: тогда прочитайте [coverage.md](references/coverage.md). По умолчанию coverage SKIP; отсутствие новых тестов не FAIL.

Отчёт: stack, mode, состояние code/scope/env, команды со статусом, failures и passed/failed/skipped + время. Завершите машинным trailer:

```yaml
verdict: PASS | FAIL | PARTIAL
passed: [build]
failed: []
skipped: [coverage]
```

PASS = все выполненные и обязательные проверки прошли, запрошенный coverage выполнен. FAIL = ошибка или обязательная проверка не выполнена; fail-fast skips не превращают FAIL в PARTIAL. PARTIAL только для `--all` с mixed результатом.

Не изменяйте код/форматирование/build-файлы, не устанавливайте tools, не создавайте ветки/коммиты. `clean` только по запросу. При missing wrapper, неизвестных командах, auth/network block или зависании >15 минут остановите проблемную команду и сообщите evidence и необходимый следующий шаг; не обходите hooks/CI.

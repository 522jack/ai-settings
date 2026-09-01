# Правила логирования

Логирование — часть production behavior, а не украшение для debug. Добавлять, удалять или изменять
логи только если задача требует наблюдаемости, диагностики, аудита или меняется logging contract
существующего кода.

## Постоянные логи

- Использовать существующие в проекте logger, levels, structured fields и redaction helpers.
- Никогда не вводить новый logging framework без явного одобрения dependency.
- Логировать стабильные события и контексты ошибок, а не шумные шаги реализации.
- Сохранять семантику cancellation: не подавлять exceptions только ради логирования.
- Никогда не логировать secrets, tokens, credentials, raw auth headers, private keys, full cookies, payment data или ненужные PII.
- Маскировать чувствительные значения до их попадания в tool output, runtime logs, screenshots, reports или model context.

## Временные диагностические логи

Временные логи разрешены только для проверки или отладки конкретной задачи.

- Помечать их через `// TEMP-LOG: <reason>` или эквивалентный стиль комментария.
- Удалять их до `finalize`, если пользователь явно не просит оставить.
- Если временный лог раскрывает чувствительные данные, не добавлять его. Вместо этого использовать scoped assertions, counters или redacted diagnostics.

## Сбор логов агентами

- Фильтровать до чтения: ограничивать по package, PID, subsystem, test run или request id.
- Ограничивать объём: last-N lines, level filters или путь к сохранённому artifact вместо raw streams в чате.
- Считать логи только диагностическим свидетельством. Pass/fail всё равно определяет детерминированный verifier: test exit code, build result, visible UI assertion, API response assertion или benchmark result.

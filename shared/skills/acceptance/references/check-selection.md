# Acceptance fan-out selection

Проверить diff по контракту, если нет применимого результата ревью. В одиночном режиме провести саморевью. В режиме с субагентами привлечь независимого reviewer по риску или требованию. Для mobile/non-UI использовать build smoke, если нет применимого результата сборки. Web/desktop UI проверить по существующему исполнимому сценарию. Android/iOS runtime QA выполнять только по явному запросу.

| Evidence/trigger | Narrow check |
|---|---|
| acceptance_criteria_ids | BA AC evidence coverage |
| design.figma + UI | UX design alignment |
| non_functional.a11y + UI | UX a11y; merge with design in one agent |
| auth/payment/PII/data migration/security risk | security |
| SLA/perf-critical | benchmark/performance |
| Public API/CLI contract, architecture change or ≥3 actual modules | architecture |
| Build configuration changed | build-engineer |
| CI/release/Docker/IaC changed | devops |

Cache path pass once, content diff on demand; include working tree state. Public contract examples: exports/index/public/open symbols/routes/controllers/proto/GraphQL/OpenAPI/CLI flags. Одно перемещение/упоминание не равно contract change: при ambiguity выяснить узким чтением, не устраивать полный audit автоматически.

Выбирайте только проверки по фактическим рискам. В одиночном режиме используйте критерии применимых ролей самостоятельно. В режиме с субагентами независимые проверки можно запускать параллельно. Build smoke не заменяет обязательные команды проекта.

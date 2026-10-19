# Acceptance fan-out selection

Base: independent code-reviewer, если нет exact-state upstream review; build smoke для mobile/non-UI, если exact-state required build result ещё отсутствует; web/desktop UI → manual-tester по существующему исполнимому сценарию. Android/iOS manual-tester добавляется только explicit mobile runtime QA request.

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

Включайте только triggered roles с отдельным сигналом; exact-state уже проверенные роли можно reuse. Risk policy high-risk требует full applicable finalize+acceptance, а не всех специалистов независимо от diff. Одновременно независимые checks запускайте параллельно; prompts из subcheck-prompts.md читайте только для выбранных check sections. Build smoke read-only не заменяет required project checks и не устанавливает tools.

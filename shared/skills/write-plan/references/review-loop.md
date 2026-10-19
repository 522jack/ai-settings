# Review gate плана

Ревью автора не заменяет независимого критика. Для ordinary/mechanical bounded plan один соответствующий independent reviewer; `--quick` облегчает investigation, не отменяет review. High-risk auth/security/data loss/schema/concurrency/public API/CLI/architecture → multiexpert-review, profile implementation-plan, только реально relevant perspectives.

```text
profile: implementation-plan
slug: <slug>
---
docs/plans/<slug>/plan.md
```

Reviewer получает plan+tasks+scope+source evidence. Проверяет concrete affected paths/contracts, checkable acceptance, relevant failure cases, hidden scope, mapping AC→tasks, Verification & Sources. Не требует новых тестов/mobile QA без opt-in. Findings должны содержать location+concrete failure.

Max 3 содержательных cycles: PASS → gate; CONDITIONAL → локально исправить major, после cap оставить non-blocking note; FAIL → исправить blocker и повторить affected review после реальной мутации. Unchanged plan reuse, не очередной panel. Remaining blocker после cap → review_verdict escalate, status draft, blocking Open Questions; сохранить audit state.

Дополнительный hostile implementer только когда остаётся значимая неопределённость исполнимости/сложные взаимодействия после primary review, не всегда. Один специалист на riskiest task: входы→state→выход→errors→cleanup; найти места, где нужно угадать contract; максимум 15 конкретных gaps. Указанное уже в плане — no action; локальное уточнение внести; substantive user choice — chat/headless escalation. После contract change повторить affected review.

Не использовать planning review как обязательную downstream-цепочку для всей реализации. Final implementation verification идёт risk route, explicit навыки/hooks/CI сохраняются.

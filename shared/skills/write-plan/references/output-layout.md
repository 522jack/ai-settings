# План: расположение и handoff

| File | Purpose |
|---|---|
| docs/plans/<slug>/plan.md | Постоянный technical approach/decisions/risk/verification |
| docs/plans/<slug>/tasks.md | Постоянные T-N/dependencies/files/acceptance/checks |
| docs/plans/<slug>/progress.md | Журнал исполнения/checklist/learnings |
| swarm-report/<task-slug>.md, раздел Plan | Краткие scope/evidence/review cursor; done после завершения |

Plan draft→approved лишь когда review не содержит blockers; review_verdict pending→pass|conditional|escalate. Main обновляет status/cursor в разделе Plan; отдельные state-файлы не создавать и прежние пользовательские artifacts не удалять. Новые permanent files git add; commit исключительно при current authorization.

Handoff без --interactive: path/review/task count/первый шаг. --interactive требует запрошенного checkpoint. При planning-only scope предложить исполнение; при уже разрешённом implementation продолжать через специалиста. Downstream verification по risk route из SKILL.md, не обязательная check→finalize→acceptance цепочка для малого изменения. create-pr/finalize находят plan по каноническому slug path.

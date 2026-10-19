# Research state/report

После решения consortium (≥2 независимых нужных направления) создайте `swarm-report/research-<slug>-state.md` до fan-out:

```markdown
# Research State: <topic>
Slug: <slug>
Status: investigating | awaiting-clarification | done
Started: <date>
## Scope
Topic / Context / Constraints
## Expert Tracks
- [ ] <track> — launched | skipped: reason
## Findings
<raw artifacts/results; internal>
```

Обновляйте checklist при возврате каждого gatherer, перечитывайте перед resume. Временные данные — корень swarm-report; готовый deliverable только `swarm-report/research/research-<slug>.md`. Вопросы/ответы пользователю — чат, в state сохраняются только принятые scope/constraints/decisions, не отложенные просьбы.

После синтеза и разрешения user-resolvable blockers сохраните:

```markdown
# Research: <topic>
Date: <date>
Experts consulted: <tracks>
Auto-review mode: business-analyst | tech-sanity
## Problem / Question Summary
## Approaches Found
<2–3 viable options, trade-offs, evidence, compatibility; reasons if only one>
## Library / Dependency Recommendations
<only relevant; source/date/version/CVE/license>
## Risks and Concerns
<severity>
## Recommendation
<evidence-based choice>
## Known Unknowns
<only external factual gaps, owner/when; omit if none>
## Sources
<URLs/code/doc coordinates>
```

Comparison table only if helps decision. Unknown feasibility must be marked hypothesis until minimal empirical experiment; absence of evidence не доказывает невозможность. Закройте state done; chat содержит рекомендацию, основные факты/ограничения, ссылку и следующий шаг. Sources cite near associated claims where runtime requires them.

# PoLL mechanism: prompts, state, routing

State `swarm-report/multiexpert-review-<slug>-state.md`; slug caller→artifact frontmatter→filename→timestamp. Legacy plan-review-state.md можно читать и копировать в новое имя, не удалять legacy автоматически. State: source/profile/profile_source/cycle 1..3/status, artifact summary, selected agents, completed review artifact paths, verdict history, code/artifact/scope/environment state. Перечитывайте при resume и пропускайте completed exact-state steps.

Reviewer prompt skeleton:

```text
You are reviewing a {artifact_type} as a {agent_role} expert.
Artifact: {same full verbatim artifact for each reviewer}
{profile Prompt augmentation}
Task: review from your domain; compare applicable Non-negotiables first.
Output:
Summary: 2–3 sentences.
Domain Relevance: high | medium | low.
Issues: severity critical|major|minor; confidence high|medium|low;
issue with location/concrete failure, suggestion.
Respond in artifact language.
```

Все reviewers получают одинаковый полный артефакт и применимые инструкции, не результаты друг друга. Prompt skeleton механизм фиксирует; профиль лишь augmentation. Non-negotiable violation = critical confidence 100 независимо от domain/threshold.

Reviewer discovery: реальные доступные profiles/built-ins, не phantom agents. Short-name collision order same caller plugin → developer-workflow sibling → other; ambiguity после этого AMBIGUOUS_REVIEWER. Roster primary + matching optional_if, отсутствующих фиксировать. Empty primary/optional → tech-match minimal useful roster, обычно 2–3, не искусственная квота. One allowed только profile.allow_single_reviewer; zero или required panel unavailable → NO_REVIEWERS_AVAILABLE. Уже указанный/авторизованный roster не требует confirmation; interactive choice лишь когда состав действительно меняет охват/стоимость.

Aggregation:
- critical high confidence → blocker;
- тот же concrete issue от ≥2 независимых reviewers → critical;
- major high domain relevance → important improvement;
- contradictions → uncertainty, не молчаливый выбор;
- minor/low confidence single review → suggestion; low domain relevance снижает вес.

Verdicts из profile alphabet: PASS no blockers/important; CONDITIONAL no blockers + important; WARN по secondary conditions profile; FAIL blocker. Output содержит Blockers/Important Improvements/Suggestions/Uncertainties/Consensus. One reviewer → no invented cross-consensus, marker `Review Mode: single-perspective`.

Source routing по profile: file edit-in-place; conversation inline revise (существенные user choices в чат); plan_mode соответствующий runtime adapter. Недоступный tool не имитировать. Receipt fields/path из profile, не добавлять invented schema. FAIL → исправить разрешённый artifact, повторить affected reviewers тем же locked profile после реальной мутации; максимум 3 cycles. CONDITIONAL исправлять локально по profile, user decision только на настоящем trade-off; WARN не блокирует. Повтор unchanged artifact не создаёт новый cycle/evidence. Persistent genuine blockers после лимита → escalation. Не исправлять product code вне этой documentation review задачи.

Errors первая строка `[multiexpert-review ERROR] CATEGORY: details`: UNKNOWN_PROFILE_HINT, FORBIDDEN_PROFILE_FIELD, NO_REVIEWERS_AVAILABLE, AMBIGUOUS_REVIEWER, PROFILE_INVENTORY_MISMATCH, ROUTING_NOT_SUPPORTED. Это infrastructure/contract error, не semantic FAIL.

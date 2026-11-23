# PoLL mechanism: prompts, state, routing

При передаче или возобновлении main ведёт раздел `Document review` по `$HOME/dotfiles/ai/shared/rules/task-report.md`. Специалисты возвращают результаты в ответе. Slug задачи стабилен. Slug документа храните отдельно, если нужно различать несколько артефактов.

State в одном fenced YAML блока раздела с ключом `document_review`: records по artifact key с source/profile/profile_source/cycle 1..3/status, artifact identity, selected/completed agents, check evidence и compact verdict history, scope/environment. При resume перечитайте запись соответствующего документа и пропускайте completed exact-state steps. После completion сверните cursor до итогового verdict/evidence и необходимых gates; не перезаписывайте review других документов, `## Acceptance` или `## Test plan`. Reviewer responses — краткие findings, не полные transcripts.

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

Выберите маршрут по профилю: правка файла, inline-ревью или планирование. Существенные решения остаются за пользователем. Заполняйте профильные поля в указанном артефакте, если они нужны следующему этапу. При входе через общий отчёт проверяйте его связанный постоянный документ. Повторяйте только затронутые проверки после исправления. Если блокер сохраняется после трёх содержательных циклов, сообщите о нём. Продуктовые правки вне scope документного ревью.

Errors первая строка `[multiexpert-review ERROR] CATEGORY: details`: UNKNOWN_PROFILE_HINT, FORBIDDEN_PROFILE_FIELD, NO_REVIEWERS_AVAILABLE, AMBIGUOUS_REVIEWER, PROFILE_INVENTORY_MISMATCH, ROUTING_NOT_SUPPORTED. Это infrastructure/contract error, не semantic FAIL.

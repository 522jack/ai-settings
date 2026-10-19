# Finalize в едином task report

Main обновляет `Review` и `Quality` в `swarm-report/<task-slug>.md` по `$HOME/dotfiles/ai/shared/rules/task-report.md`, при PASS и ESCALATE. Специалисты возвращают receipt в ответе.

`Review`: branch/base, max_rounds/rounds_run, Exit PASS|ESCALATE, выбранные/пропущенные фазы с существенными причинами, reuse со ссылкой на раздел и exact state. Findings — только реальные: severity/confidence/location/failure scenario, исправление или unresolved BLOCK/WARN/NIT. Сохраняйте явно принятые риски отдельно от BLOCK; Non-negotiables не переводите в accepted risk. Сырые diff/logs и повторы результатов не сохраняйте.

`Quality` — компактная downstream receipt:

```yaml
quality:
  status: PASS | FAIL
  date: <ISO8601>
  code_hash: <committed + staged + unstaged + relevant untracked state>
  scope_hash: <task/requirements/review scope>
  environment: <toolchain/config/runtime identity>
  review: "#review"
  checks: "#checks"
  escalate: true  # only ESCALATE
```

Exit PASS → Status PASS; ESCALATE → FAIL. Дата не доказывает freshness: acceptance reuse code review лишь при точном state match. `checks` указывает на конкретные check records с командами, результатами и exact code/scope/environment identity; при отсутствии проверок не выдумывайте evidence. Разделы связывайте ссылками, не копируйте findings. Legacy finalize/quality files можно читать, новые по старым путям не создавайте.

Chat: verdict, rounds, основные fixes либо unresolved BLOCK, ссылка на task report и необходимое решение. Actual commits отмечайте только если разрешены и выполнены.

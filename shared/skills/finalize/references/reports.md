# Finalize artifacts

Запишите при PASS и ESCALATE:

`swarm-report/<slug>-finalize.md`: date, branch/base, code_hash/scope_hash/environment identity, max_rounds/rounds_run, Exit PASS|ESCALATE, selected/skipped phases + reasons, reused checks with artifact/state, findings severity/confidence/location/failure scenario, fixes, unresolved BLOCKs, remaining WARN/NIT, explicitly acknowledged risks, actual commits (если разрешены).

`swarm-report/<slug>-quality.md` — downstream receipt:

```markdown
# Quality receipt: <slug>
Status: PASS | FAIL
Date: <ISO8601>
Code hash: <committed + staged + unstaged + relevant untracked state>
Scope hash: <task/requirements/review scope>
Environment: <toolchain/config/runtime identity>
Detail: swarm-report/<slug>-finalize.md
Escalate: true  # only ESCALATE
```

Exit PASS → Status PASS; ESCALATE → FAIL. Date сохраняется для legacy consumers, но сама дата не доказывает freshness: acceptance может reuse code review лишь при точном state match.

Chat: verdict, rounds, основные fixes или unresolved BLOCK, ссылка на receipt, необходимое решение. Не вставляйте полный log. Явно принятое решение пользователя о риске храните отдельно от unresolved BLOCK; Non-negotiables не переводите в accepted risk.

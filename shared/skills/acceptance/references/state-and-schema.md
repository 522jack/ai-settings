# Acceptance state/check schema

До запуска сохраните `swarm-report/<slug>-acceptance-state.md`: Status planning|running|aggregating|done, Cycle N of 3, Started, Base, code_hash/diff_hash, scope_hash/spec_hash/test_plan_hash, environment identity, Planned Checks с trigger, Completed Checks с artifact+verdict, Aggregated Verdict History. После возврата каждой проверки отметьте её; resume перечитывает state, не запускает уже завершённое точное состояние. На новой мутации reset только affected checks, остальные — Re-used with evidence. Done — операционная история, автоматически не удалять.

Каждая planned check пишет `swarm-report/<slug>-acceptance-<check>.md`:

```yaml
---
type: acceptance-check
check: manual | code | build | ac-coverage | design | a11y | security | performance | architecture | build-config | devops
agent: <profile or tool>
verdict: PASS | WARN | FAIL | SKIPPED
severity: critical | major | minor | null
confidence: high | medium | low | null
domain_relevance: high | medium | low | null
diff_hash: <current full code state digest or null>
scope_hash: <requirements/AC/scenario scope>
environment: <toolchain/dependencies/config/runtime identity and check command>
blocked_on: <necessary input/access or null>
---
```

WARN/FAIL обязаны указывать severity/confidence/domain_relevance; PASS/SKIPPED null. Hash включает committed/staged/unstaged/relevant untracked state, не только base...HEAD. Scope учитывает requirements/AC/scenario и изменения spec/test-plan; environment — также команду проверки. Compute один раз для конкретного состояния; изменение любого input требует нового digest. `diff_hash` имя сохраняется для compatibility. Один файл на check даже если один агент покрывает design+a11y. Для reused review/build artifact сохраняется ссылка на конкретные evidence/state неизменного checked code+scope+environment; общего хэша без такого evidence недостаточно. Legacy receipt без достаточного exact-state evidence не reuse. Unchanged FAIL сохраняется без retry; для intentional policy skip пишите reason, не masquerade PASS.

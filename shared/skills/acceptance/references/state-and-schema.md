# Acceptance state/check schema

Прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md`. Main хранит state и результаты только под `## Acceptance` в `swarm-report/<task-slug>.md`; специалисты возвращают текст и не пишут отчёт. Task-slug наследуется от задачи, не меняется на check/cycle. Другие разделы и их статусы сохраняются. Новые state/per-check/JSON/log-файлы не создаются; legacy читается только как вход при необходимости.

До запуска сохраните компактный state в том же блоке `acceptance`: status planning|running|aggregating|done, cycle N of 3, started, base, code_hash/diff_hash, scope_hash/spec_hash/test_plan_hash, environment, planned checks с trigger, completed checks с verdict/evidence и краткую verdict history. После возврата каждой проверки обновите её строку; resume перечитывает раздел и пропускает завершённые exact-state checks. При мутации reset только affected checks, остальные — reused с evidence. После done сверните resume cursor и историю до краткого итога, сохраняя необходимые gate metadata и evidence; operational status не подменяет aggregated verdict.

Для каждой проверки main сохраняет отдельную запись в таблице результатов и machine metadata в единственном именованном блоке `acceptance` fenced YAML внутри раздела (не frontmatter файла):

```yaml
acceptance:
  status: planning | running | aggregating | done
  verdict: VERIFIED | FAILED | PARTIAL | null
  cycle: 1
  checks:
    code: # manual|code|build|ac-coverage|design|a11y|security|performance|architecture|build-config|devops
      agent: <profile or tool>
      verdict: PASS | WARN | FAIL | SKIPPED
      severity: critical | major | minor | null
      confidence: high | medium | low | null
      domain_relevance: high | medium | low | null
      diff_hash: <current full code state digest or null>
      scope_hash: <requirements/AC/scenario scope>
      environment: <toolchain/dependencies/config/runtime identity and check command>
      blocked_on: <necessary input/access or null>
      evidence: <command/result or pointer to existing evidence>
```

WARN/FAIL указывают severity/confidence/domain_relevance; PASS/SKIPPED null. Hash включает committed/staged/unstaged/relevant untracked state, не только base...HEAD. Scope учитывает requirements/AC/scenario и spec/test-plan; environment — также команду проверки. Compute один раз для конкретного состояния; изменение input требует нового digest. Имя `diff_hash` сохраняется для compatibility. Design+a11y сохраняются отдельными check records, даже при одном исполнителе. Для reuse сохраняйте pointer/evidence неизменного checked code+scope+environment; общий хэш без evidence недостаточен. Legacy receipt без exact-state evidence не reuse. Unchanged FAIL сохраняется без retry; intentional policy skip содержит reason, не PASS.

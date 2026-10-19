Referenced from: `plugins/developer-workflow/skills/acceptance/SKILL.md` (§Step 4: Aggregate and Write Receipt).

# Acceptance — агрегация, формат receipt и маршрутизация

Сначала прочитайте check metadata из `## Acceptance` общего `swarm-report/<task-slug>.md` (verdict, severity, confidence, domain_relevance, blocked_on). Подробности нужны только для non-PASS; не копируйте raw output.

Если planned result отсутствует, запишите `FAIL`, `blocked_on: per-check result missing`. Не отбрасывайте проверку; отдельного поля `error` нет. Main — единственный писатель, reviewers возвращают результаты текстом.

## Агрегация — правила PoLL

Acceptance использует тот же протокол агрегации, что и `multiexpert-review` (см.
`multiexpert-review/SKILL.md`, §«Step 4 — Synthesize verdict»). Вход имеет форму по проверкам
(не по рецензентам), логика свёртки идентична:

| Signal | Action |
|---|---|
| **Серьёзность `critical`** в любой проверке с `confidence: high` | → Blocker. Aggregated Status = `FAILED`. |
| **Одинаковая проблема** (тот же file:line или тот же AC id), независимо поднятая 2+ проверками | → Повысить до `critical` независимо от индивидуальной серьёзности. Если одну проблему видят несколько специалистов, она реальна. |
| **Серьёзность `major`** в проверке с `domain_relevance: high` | → Important. Aggregated Status = `PARTIAL`, если ранее не повышен. |
| **Противоречащие вердикты** (один `PASS`, другой `FAIL` для одного элемента) | → «Неопределённость — требуется решение». Aggregated Status = `PARTIAL`, противоречие перечисляется в receipt. |
| **Серьёзность `minor`** или **`low` confidence** в одной проверке | → Note, не blocker. Не влияет на Aggregated Status. |
| Проверка с **`low` domain_relevance**, сообщившая о проблеме | → Note с меньшим весом. |

**Серьёзность ошибок (P0–P3) остаётся основным направлением маршрутизации** для вызывающего кода. Любая ошибка P0/P1,
сообщённая любой проверкой, напрямую переводит результат в `FAILED` независимо от правил PoLL выше;
PoLL добавляет правила для случаев, не покрываемых одной серьёзностью ошибки (например,
FAIL покрытия AC без связанной ошибки P0).

## Aggregated Status — итоговая таблица

| Вход | Aggregated Status |
|---|---|
| Все проверки `PASS` или `SKIPPED`, нет ошибок P0–P3 и blocker PoLL | `VERIFIED` |
| Любая ошибка P0/P1 **или** blocker PoLL (critical с высокой уверенностью либо эскалация 2+ агентов) | `FAILED` |
| Только ошибки P2/P3, **или** important от PoLL, **или** противоречащие вердикты, **или** любой иначе не классифицированный `WARN` | `PARTIAL` |
| `manual-tester` вернул `WARN` с `blocked_on` | `PARTIAL`, с отображением `blocked_on` в Summary |

## Формат receipt

Main обновляет только `## Acceptance` в `swarm-report/<task-slug>.md`. Не создавайте acceptance/check/state файлы. Краткий формат:

```markdown
## Acceptance
- Status: VERIFIED | FAILED | PARTIAL; cycle: N/3; date: <date>.
- Inputs: spec/AC/repro, permanent test plan; test_plan_source: receipt|mounted|on-the-fly|absent.
- Context: project_type, platform override, ecosystem, mobile_manual_requested; pointers на upstream sections.
- Identity: diff_hash, spec_hash, test_plan_hash, scope_hash, environment/command.
- State: planning|running|aggregating|done; planned/completed checks и компактная verdict history.

| Check / trigger | Agent / tool | Verdict | Severity / confidence / relevance | Evidence / blocked_on |
|---|---|---|---|---|
| code / changed code | code-reviewer | PASS | null | command/result или существующий pointer |

- Findings: P0–P3 / file:line или AC, краткое последствие и исправление; convergence и contradictions по необходимости.
- TC: total / passed / failed / blocked; bug fix: repro steps и воспроизводится ли после fix.
- Recommendation: Ship / Do not ship / Ship with known issues — причина, ограничения и следующий шаг.
```

Machine metadata/state размещайте fenced YAML внутри этого раздела по [state-and-schema.md](state-and-schema.md), не вторым frontmatter. Check records для manual/code/build/ac-coverage/design/a11y/security/performance/architecture/build-config/devops независимы. Summary 1–3 предложения; для PARTIAL с blocked_on сначала blocker. Evidence подтверждает точный checked code + scope + environment, включая working tree; HEAD/Date и общий hash недостаточны для reuse. Legacy результаты — только read и только с достаточным evidence. Подробности repeat — [re-verification.md](re-verification.md).

## Маршрутизация (потребляется вызывающим кодом)

- **VERIFIED** → `create-pr` (или пометить существующий PR готовым к ревью).
- **FAILED** с P0/P1 и очевидной причиной → исправить в ветке, используя список ошибок,
  затем повторить затронутые проверки acceptance на изменённом состоянии. Максимум 3 содержательных цикла; unchanged FAIL сохраняется без retry.
- **FAILED** с P0/P1 и неясной причиной → сначала исследовать первопричину (debug в plan-mode),
  затем исправить и повторить.
- **FAILED** с P0/P1, требующей регрессионного покрытия → добавить в test plan `## Regression TC`,
  затем исправить и повторить.
- **PARTIAL** только с P2/P3 или WARN — спросить пользователя: исправить сейчас или отправить с известными проблемами
  (продолжить к `create-pr`, включив их в описание PR).
- **PARTIAL** с `blocked_on` — показать blocker; не продолжать до его устранения.

Referenced from: `plugins/developer-workflow/skills/acceptance/SKILL.md` (§Step 4: Aggregate and Write Receipt).

# Acceptance — агрегация, формат receipt и маршрутизация

Сначала прочитайте frontmatter каждого `swarm-report/<slug>-acceptance-<check>.md` (verdict +
severity + confidence + domain_relevance + blocked_on). Читайте тело только если
`verdict != PASS`. Не вставляйте тела артефактов — ссылайтесь на них.

**Отсутствующий артефакт проверки.** Шаг 2.5 записывает заглушку для пропущенного `code-reviewer`; шаг 3.3
записывает артефакт даже при сбое build-smoke. Если запланированный артефакт проверки всё же
отсутствует во время агрегации, считайте проверку `verdict: FAIL` с
`blocked_on: per-check artifact missing` — не отбрасывайте её молча. `blocked_on` —
каноническое поле для отображения нерешённых условий согласно схеме проверки; отдельного поля
`error:` нет.

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

Save to `swarm-report/<slug>-acceptance.md`. Legacy fields preserved; new sections appended.

```markdown
# Acceptance: <slug>

**Status:** VERIFIED / FAILED / PARTIAL
**Date:** <date>
**Type:** Feature / Bug fix
**Project type:** <project_type>
**Project type override:** <spec | user | none>
**Ecosystem:** <ecosystem>
**Spec source:** [что использовано]
**Test plan:** [разрешённый постоянный путь / создан на лету / none]
**test_plan_source:** receipt | mounted | on-the-fly | absent
**Context artifacts:** [пути к upstream-артефактам, использованным как вход — например, research.md, debug.md, write-tests.md, quality.md]

## Idempotency Hashes
- `diff_hash`: <sha256 of `git diff <base>...HEAD`>
- `spec_hash`: <sha256 of the spec file bytes, or `null` if no file spec>
- `test_plan_hash`: <sha256 of the permanent test plan, or `null`>

Эти три хэша определяют таблицу решений Re-verification Loop; downstream-оркестраторам
не нужно их читать.

## Check Plan
- список выполненных проверок, по одной в строке, с их триггером;
- например, `business-analyst` (покрытие AC) — вызвано из-за spec.acceptance_criteria_ids;
- например, `ux-expert` — не вызван (нет design.figma).

## Check Results

| Check | Agent / Tool | Verdict | Severity | Confidence | Artifact |
|---|---|---|---|---|---|
| Ручной QA | manual-tester | … | … | … | swarm-report/<slug>-acceptance-manual.md |
| Ревью кода | code-reviewer | … | … | … | swarm-report/<slug>-acceptance-code.md |
| Покрытие AC | business-analyst | … | … | … | swarm-report/<slug>-acceptance-ac-coverage.md |
| Дизайн | ux-expert | … | … | … | swarm-report/<slug>-acceptance-design.md |
| A11y | ux-expert | … | … | … | swarm-report/<slug>-acceptance-a11y.md |
| Безопасность | security-expert | … | … | … | swarm-report/<slug>-acceptance-security.md |
| Производительность | performance-expert | … | … | … | swarm-report/<slug>-acceptance-performance.md |
| Архитектура | architecture-expert | … | … | … | swarm-report/<slug>-acceptance-architecture.md |
| Конфигурация сборки | build-engineer | … | … | … | swarm-report/<slug>-acceptance-build-config.md |
| DevOps | devops-expert | … | … | … | swarm-report/<slug>-acceptance-devops.md |
| Smoke сборки | bash | … | … | … | swarm-report/<slug>-acceptance-build.md |

## Convergence signals
Issues, независимо поднятые 2+ проверками. Самый сильный сигнал реальных проблем.
Для каждой укажите одной строкой file:line или AC id и список проверок, которые её отметили.

## Summary
[1–3 предложения. Если PARTIAL с blocked_on — сначала укажите blocker. Если есть convergence
signal — упомяните его в первом предложении.]

## Test Results
- Total: [n] | Passed: [n] | Failed: [n] | Blocked: [n]

## Bugs Found
[Перечислите по серьёзности — сначала P0, затем P1, P2, P3. Для каждой укажите ссылку на
артефакт проверки, который о ней сообщил.]

## Bug Reproduction Check (bug fix only)
- Шаги воспроизведения из debug.md: [выполнены / неприменимо]
- Ошибка воспроизводится после исправления: [да / нет]

## Recommendation
[Ship / Do not ship / Ship with known issues — и почему]
```

## Маршрутизация (потребляется вызывающим кодом)

- **VERIFIED** → `create-pr` (или пометить существующий PR готовым к ревью).
- **FAILED** с P0/P1 и очевидной причиной → исправить в ветке, используя список ошибок,
  затем повторить acceptance. Максимум 3 итерации.
- **FAILED** с P0/P1 и неясной причиной → сначала исследовать первопричину (debug в plan-mode),
  затем исправить и повторить.
- **FAILED** с P0/P1, требующей регрессионного покрытия → добавить в test plan `## Regression TC`,
  затем исправить и повторить.
- **PARTIAL** только с P2/P3 или WARN — спросить пользователя: исправить сейчас или отправить с известными проблемами
  (продолжить к `create-pr`, включив их в описание PR).
- **PARTIAL** с `blocked_on` — показать blocker; не продолжать до его устранения.

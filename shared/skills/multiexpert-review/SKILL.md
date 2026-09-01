---
name: multiexpert-review
description: >-
  Используй, когда пользователь хочет проверить план, спецификацию или test-plan
  группой независимых экспертных агентов (протокол PoLL — Panel of LLM Evaluators)
  до коммита.
  Триггеры: "review the plan", "review the spec", "review the test-plan",
  "multi-expert review", "panel review", "validate the approach", "sanity check this",
  "what did I miss?", "review the spec", "review the test-plan",
  "evaluate the plan". Не используй для code review (используй code-reviewer).
---

# Мультиэкспертная проверка

Механизм независимой проверки артефакта документации (плана, спецификации, test-plan и т. п.) несколькими агентами с последующим синтезом консенсуса. Семантика, специфичная для артефакта, находится в **profiles** в `profiles/<name>.md`. Этот механизм не зависит от типа артефакта: он обнаруживает и маршрутизирует, но никогда не встраивает критерии одного типа артефакта в собственное тело.

Протокол — PoLL (Panel of LLM Evaluators): независимая параллельная проверка каждым агентом, структурированный вывод с severity/confidence, синтез с учётом confidence, а разногласия явно помечаются как "requires decision", а не разрешаются молча.

Перед формированием мнения каждый проверяющий агент должен сопоставить артефакт с разделами `## Non-negotiables` в применимых файлах инструкций рантайма (`AGENTS.md`, `CLAUDE.md` или эквивалентных: в корне проекта, глобальных и специфичных для плагина). Любой предлагаемый подход, нарушающий обязательное требование, автоматически считается blocker — critical severity, confidence 100; на него не распространяются фильтр отчётности и обсуждение компромиссов.

## Инварианты механизма (профили не могут их переопределить)

Профили MUST NOT объявлять следующие параметры — это константы механизма:

- **Структура вывода проверки** — Summary / Domain Relevance / Issues с severity+confidence+issue+suggestion (зафиксирована в prompt шага 3)
- **Правила агрегации** — convergence → escalate, contradictions → surface, confidence-weighting (зафиксированы на шаге 4)
- **Переходы конечного автомата** — зафиксированы в этом файле
- **Ограничение цикла пересмотра** — максимум 3 цикла (константа механизма)
- **Каркас шаблона prompt проверки** — профили дополняют его через `## Prompt augmentation`, но не заменяют

Список запрещённых полей frontmatter и поведение при ошибке `FORBIDDEN_PROFILE_FIELD` см. в `profiles/README.md`.

## Рабочий процесс

Прочитать артефакт и определить профиль → найти агентов, предварительно выбрать их по `profile.reviewer_roster` → параллельно запустить агентов для независимой проверки → собрать проверки → синтезировать вердикт (агрегация механизма + предоставленный профилем алфавит вердиктов) → представить вердикт и обновить receipt (если он есть у профиля) → PASS: завершить; CONDITIONAL / WARN: действовать по политике профиля; FAIL → исправить артефакт в источнике → повторить проверку (вернуться к параллельной проверке с теми же агентами и зафиксированным профилем).

**Запрещено:** пропускать Read+Detect → Review или повторно запускать определение профиля в цикле ≥2 (профиль фиксируется в цикле 1).

**Ограничение циклов:** всего 3 (первичная проверка + 2 повторные). Если после цикла 3 всё ещё FAIL → передать вопрос пользователю.

## Сохранение состояния (устойчивость к compaction)

Сохраняй состояние в `./swarm-report/multiexpert-review-<slug>-state.md` (или в `multiexpert-review-<YYYYMMDD-HHMM>-state.md`, если slug неизвестен). Следуй соглашениям шаблона постоянного состояния из инструкций проекта текущего рантайма.

**Источник slug** (в порядке приоритета): явные аргументы вызывающей стороны (`slug:`), `slug:` во frontmatter артефакта, имя файла артефакта без расширения, запасной вариант с timestamp.

**Чтение legacy:** если файл с slug не существует, попробуй `./swarm-report/plan-review-state.md` (legacy-файл из периода до переименования). Если он найден, скопируй содержимое в новое имя со slug и продолжай работать с ним. Не удаляй legacy-файл — это решает пользователь. Всегда записывай данные в новое имя со slug.

Структура файла состояния:

```markdown
# Multi-Expert Review State
Source: {plan_mode | file:<path> | conversation}
Profile: {implementation-plan | test-plan | spec | ...}   # locked at cycle 1
Profile source: {caller_hint | frontmatter | path | signature | user_prompt}
Cycle: {1 | 2 | 3} of 3
Status: {detecting | reviewing | synthesizing | fixing | done}

## Artifact Summary
{goal, technologies, scope — extracted in Step 1}

## Selected Agents
- {agent1} (recommended)
- {agent2} (recommended)

## Reviews Completed
- [x] {agent1} — {N critical, M major, K minor}
- [ ] {agent2} — pending

## Verdict History
### Cycle 1: {PASS | CONDITIONAL | FAIL | WARN}
- Blockers: {list}
- Improvements: {list}
```

Перед каждым действием перечитывай файл — пропускай завершённые шаги.

## Шаг 1 — Прочитать артефакт и определить профиль

Ищи артефакт в следующем порядке: (1) активный вывод Plan Mode в переписке, (2) ссылка на файл (пользователь указывает на `.md`), (3) встроенное описание в переписке, (4) спросить пользователя. Зафиксируй источник — он понадобится на шаге 5.

**Определи профиль** — следуй цепочке приоритетов в `profiles/README.md` §Detection precedence (канонический источник). Механизм применяет семантику ошибок из этого раздела: `UNKNOWN_PROFILE_HINT` при неизвестной подсказке вызывающей стороны; никогда не выполняй молчаливый переход к профилю по умолчанию. Фиксация профиля на цикл, проверка профиля (negative-list) и проверка рассогласования инвентаря также описаны в `profiles/README.md` — применяй их при каждом вызове до шага 2.

## Шаг 2 — Найти и выбрать агентов

### Поиск

Находи реальных агентов через `Glob("**/agents/*.md")` и встроенных subagents из system prompt. Прочитай frontmatter каждого агента для подтверждения. Никогда не выдумывай phantom agents.

**Разрешение коллизии short-name:** предпочитай первое совпадение в следующем порядке: (1) тот же плагин, что и у вызывающей стороны, (2) соседний плагин `developer-workflow-*`, (3) любой другой источник. Если неоднозначность сохраняется → заверши с явной ошибкой `[multiexpert-review ERROR] AMBIGUOUS_REVIEWER: short-name <name> resolves to <paths>`. Это отличается от `NO_REVIEWERS_AVAILABLE`. Семейство гарантирует уникальность short-name — это срабатывает только при конфликтах вне семейства.

### Выбор по профилю

Используй `profile.reviewer_roster`:

- **`primary`** — обязательный состав. Включай установленных агентов, отсутствующих пропускай.
- **`optional_if`** — для каждой записи включай агента, если regex `when` совпадает с содержимым артефакта И агент установлен.
- **Пустой primary + нет совпадений optional** — перейди к выбору по tech-match (на это опирается implementation-plan profile): просканируй артефакт на ключевые слова технологий, оцени агентов по совпадению технологий / ценности для конкретной проблемы / покрытию пробелов и рекомендуй 2–3.

### Защита от единственного проверяющего

Выбран ровно 1 агент:
- `profile.allow_single_reviewer: true` → продолжай. Вердикт содержит маркер `## Review Mode: single-perspective` (только в тексте вывода; схемы receipt объявляются профилем и не включают `review_mode`).
- `profile.allow_single_reviewer: false` → заверши с явной ошибкой `[multiexpert-review ERROR] NO_REVIEWERS_AVAILABLE: profile <name> requires panel, only <agent> available`.

0 агентов → та же ошибка `NO_REVIEWERS_AVAILABLE` независимо от флага.

### Подтверждение пользователя

Используй `AskUserQuestion` с `multiSelect: true`; сначала укажи рекомендуемых агентов и однопредложное обоснование. Если в prompt пользователя названы конкретные агенты (например, "review with kotlin-engineer"), пропусти подтверждение выбора и используй их.

## Шаг 3 — Параллельная независимая проверка

Запусти каждого выбранного агента в **одном сообщении** (параллельно) через tool `Agent`.

### Prompt проверки (каркас механизма)

```
You are reviewing a {artifact_type} as a {agent_role} expert.

## The Artifact
{full_artifact_text}

{PROFILE_PROMPT_AUGMENTATION}

## Your Task
Review this artifact from the perspective of your expertise. Be specific and actionable.

## Required Output Format

### Summary
2-3 sentence overall assessment from your perspective.

### Domain Relevance
One of: high | medium | low — how much this artifact touches your expertise.

### Issues
For each issue:

**Issue N: {short title}**
- **severity**: critical | major | minor
- **confidence**: high | medium | low
- **issue**: what the problem is (1-2 sentences)
- **suggestion**: what to do instead (1-2 sentences)

Severity: critical = blocks implementation; major = significantly affects quality/perf/maintainability; minor = nice-to-have.
Confidence: high = squarely in your domain; medium = relevant but could be wrong; low = outside core expertise.

Respond in the same language the artifact is written in.
```

`{PROFILE_PROMPT_AUGMENTATION}` подставляется из раздела профиля `## Prompt augmentation` (пусто, если раздел не определён).

### Инвариантные правила

- **Никогда не передавай проверку одного агента другому** — независимость является главным смыслом процесса.
- **Все агенты получают одинаковый текст артефакта** — без саммари и интерпретаций.
- **Каркас prompt зафиксирован механизмом** — профили только добавляют текст через augmentation, но не заменяют его.

## Шаг 4 — Синтезировать вердикт

Прочитай все проверки. Правила агрегации механизма (не переопределяются):

| Signal | Action |
|--------|--------|
| Critical severity, high confidence | Blocker |
| Same issue from 2+ agents independently | Escalate to critical regardless of individual severity |
| Major severity, high domain_relevance | Important improvement |
| Contradicting opinions between agents | Surface as "Uncertainty — requires decision"; never silently pick one |
| Minor severity OR low confidence (single agent) | Suggestion |
| Low domain_relevance flag | Note, weight lower |

Профиль предоставляет `verdicts` (алфавит, например `[PASS, CONDITIONAL, FAIL]` или `[PASS, WARN, FAIL]`) и `severity_mapping` (для профилей на основе чеклиста, таких как пункты a-e в test-plan).

### Формат вердикта

```
## Multi-Expert Review Verdict: {PASS | CONDITIONAL | WARN | FAIL}

### Blockers (must fix)
- {issue} — raised by {agent(s)}, severity: critical / Suggestion: {what to do}

### Important Improvements (strongly recommended)
- {issue} — raised by {agent(s)}, confidence: {level}

### Suggestions (nice to have)
- {issue}

### Uncertainties (requires your decision)
- {topic} — {Agent A} says X, {Agent B} says Y

### Consensus
{what all agents agreed on}

## Review Mode: single-perspective       # only when single-reviewer path was taken
```

**Случай одного агента:** пропусти разделы перекрёстного сопоставления. Представь проблемы напрямую; добавь маркер `## Review Mode: single-perspective`.

### Критерии вердикта

- **PASS** — blocker отсутствуют, важных улучшений нет, есть только незначительные предложения
- **CONDITIONAL** (только в алфавитах, содержащих его) — blocker отсутствуют, но важные улучшения существенно повлияли бы на качество
- **WARN** (только в алфавитах, содержащих его) — blocker устранены, но нарушены вторичные пункты (например, test-plan (d)/(e)); pipeline продолжается
- **FAIL** — есть blocker

## Шаг 5 — Действия после проверки

### Маршрутизация исправлений

Согласно `profile.source_routing`:

| Source | Действие (по умолчанию) |
|--------|------------------|
| **Plan Mode** | `EnterPlanMode` со списком проблем |
| **File** | Напрямую отредактируй файл (добавь `## Issues to Resolve` или перестрой текст на месте) |
| **Conversation** | Сначала покажи проблему с самой высокой severity, задавай ОДИН вопрос за раунд и разбирай пункты по очереди. Никогда не выводи весь список сразу. |

Профили могут переопределять действия или помечать их как `N/A` для неподдерживаемых источников.

### Интеграция с receipt

Если присутствует `profile.receipt`, разреши `receipt.path_template`, подставив `<slug>`, затем запиши каждое поле `receipt.fields_to_update` с выведенным значением (например, `review_verdict: WARN`, `review_warnings: [...]`, `review_blockers: [...]`). Для путей `swarm-report/...` — создай файл, если его нет (с соблюдением receipt-контракта generate-test-plan). Если `profile.receipt` отсутствует, пропусти запись receipt.

### Обработка вердикта

- **PASS** — подтверди готовность артефакта; заверши работу.
- **CONDITIONAL** — представь улучшения в чате списком (максимум 5; если их больше, сгруппируй по категориям). Задай ОДИН вопрос, если требуется решение пользователя. После подтверждения исправь по `source_routing`.
- **WARN** — pipeline продолжается; механизм записывает предупреждения в receipt; цикл пересмотра не запускается.
- **FAIL** — без дополнительных вопросов исправь по `source_routing`; автоматически повтори проверку теми же агентами и профилем; обнови файл состояния, указав цикл N и новый вердикт. Если после цикла 3 всё ещё FAIL → передай вопрос пользователю.

## Семантика ошибок

Все ошибки механизма выводятся с таким префиксом строго в первой строке:

```
[multiexpert-review ERROR] <CATEGORY>: <details>
```

Категории:

- `UNKNOWN_PROFILE_HINT` — подсказка вызывающей стороны отсутствует в инвентаре
- `FORBIDDEN_PROFILE_FIELD` — frontmatter профиля содержит запрещённое поле
- `NO_REVIEWERS_AVAILABLE` — после поиска/фильтрации не осталось агентов либо требуется панель, но доступен только один агент
- `AMBIGUOUS_REVIEWER` — после разрешения коллизии семейства short-name соответствует нескольким файлам агентов
- `PROFILE_INVENTORY_MISMATCH` — список в README и наличие `profiles/*.md` расходятся
- `ROUTING_NOT_SUPPORTED` — механизм достиг шага 5 с источником, объявленным профилем как `N/A` в `source_routing`

Потребители (например, `write-spec`) распознают этот префикс, чтобы отличать ошибки механизма от обычных вердиктов проверки FAIL.

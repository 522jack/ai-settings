Referenced from: `plugins/developer-workflow/skills/write-spec/SKILL.md` (§Phase 3 Write Spec Draft).

# Шаблон черновика spec

```markdown
---
type: spec
slug: {slug}
date: {YYYY-MM-DD}
status: draft
# Optional fields — leave blank when not applicable. Consumed by `acceptance`
# (choreography) and by `generate-test-plan` (platform-aware coverage).
platform: []                     # Canonical values: [android], [ios], [web], [desktop], [backend-jvm], [backend-node], [cli], [library], [generic]. May be multi-value for cross-platform features.
surfaces: []                     # e.g. [ui], [api], [cli], [background-job]. Drives which acceptance checks run.
risk_areas: []                   # e.g. [auth], [payment], [pii], [data-migration], [perf-critical]. Each entry triggers a conditional expert in acceptance.
non_functional:                  # Optional block. Each present entry triggers an expert check.
  sla:                           # e.g. p99 < 150ms. Triggers performance-expert.
  a11y:                          # e.g. wcag-aa. Triggers ux-expert a11y mode.
acceptance_criteria_ids: []      # e.g. [AC-1, AC-2, AC-3]. Each AC in the list MUST appear as a bullet in §Acceptance Criteria.
design:                          # Optional.
  figma:                         # e.g. https://www.figma.com/file/XXX. Triggers ux-expert design-review.
  design_system:                 # Optional reference to a design system doc.
---

# Spec: {Название функциональности}

Date: {YYYY-MM-DD}
Status: draft
Slug: {slug}

---

## Контекст и мотивация

{2–4 предложения: что делает функциональность, кто получает пользу и почему сейчас.
Напишите «почему», которое останется понятным через 6 месяцев.}

## Критерии приёмки

Функциональность завершена, когда выполнены ВСЕ следующие условия. Каждому критерию присваивается
стабильный ID `AC-N`. Список `acceptance_criteria_ids` во frontmatter **не обязателен** для
обратной совместимости, но если он задан, то ДОЛЖЕН включать каждый перечисленный здесь ID `AC-N`
и ничего больше; именно его `acceptance` использует для проверок покрытия AC через `business-analyst`.
Пустой `acceptance_criteria_ids` отключает условный запуск business-analyst.

- [ ] **AC-1** — {Concrete, observable behavior — not internal state}
- [ ] **AC-2** — {Another criterion}
- [ ] **AC-3** — {Error / edge case criterion}
- [ ] **AC-4** — {Performance criterion with specific numbers, if relevant}
- [ ] **AC-5** — {Compatibility criterion, if relevant}

**Авторитетное определение готовности.** Реализующий агент сверяется с этим списком
до отметки любой задачи как завершённой.

## Предусловия

Шаги, которые должны быть завершены ДО начала реализации. Каждый пункт либо уже выполнен,
либо является явной задачей для реализующего агента или человека.

| Предусловие | Статус | Владелец | Примечания |
|--------------|--------|-------|-------|
| {e.g., Create FCM project in Firebase console} | ⬜ Todo / ✅ Done | Human / Agent | {how to do it} |
| {e.g., Add notification entitlement to app} | ⬜ Todo | Agent | {file to modify} |

*(Удалите эту секцию, если вне изменений кода предусловий нет.)*

## Затронутые модули и файлы

| Модуль / файл | Тип изменения | Примечания |
|---------------|-------------|-------|
| {path or module name} | New / Modified / Deleted | {what changes and why} |

Ключевые точки интеграции:
- {Interface or class that new code must implement or call}
- {Existing service or repository that will be extended}

## Технический подход

{Высокоуровневое описание того, КАК будет реализована функциональность — не код, но достаточно,
чтобы направить архитектуру:
- какой паттерн использовать (существующий или новый);
- поток данных: источник → преобразование → назначение;
- ключевые новые абстракции (классы, интерфейсы, модули);
- стратегия обработки ошибок;
- подход к управлению состоянием (если применимо к UI).}

## Технические ограничения

Правила, которым реализующий агент должен следовать без отклонений:

- {Must use X library — already in project}
- {Must NOT add new dependencies without approval}
- {Must follow Y pattern used elsewhere}
- {Must support API level Z+}
- {Must be KMP-compatible / Android-only}
- {No blocking operations on the main thread}

## Принятые решения

Решения, зафиксированные в spec. Реализующий агент НЕ пересматривает их.

| Решение | Выбор | Обоснование |
|----------|--------|-----------|
| {What was decided} | {The choice} | {Why this over alternatives} |

## Вне области работ

В рамках этого spec НЕ будет реализовано:

- {Behavior or feature explicitly excluded}
- {Edge case deferred to a future spec} *(owner: {team/person}, target: {Phase N / separate spec})*
- {Migration or compatibility concern left out}

## Открытые вопросы

Нерешённые вопросы, которые реализующий агент должен обработать или эскалировать:

- [ ] {Question} — *blocking / non-blocking*
  - Options: {A}, {B}
  - Recommendation: {preferred}

Если их нет: напишите «None — spec is complete.» и удалите эту секцию.

## Будущие фазы

*(Только если функциональность разделена на фазы)*

**Phase 2 — {name}:** {brief description, why deferred}
**Phase 3 — {name}:** {brief description}

Описываются отдельно после реализации фазы 1 и её проверки в production.
```

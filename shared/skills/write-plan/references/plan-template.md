# Шаблоны планов

Скопируйте каждый блок буквально в соответствующий файл под `docs/plans/<slug>/` и заполните каждый
placeholder. Три файла разделены по сроку жизни: `plan.md` и `tasks.md` — стабильный дизайн;
`progress.md` — изменяемый журнал выполнения (разделение в стиле Cline — рабочие изменения никогда
не должны переписывать дизайн).

---

## `docs/plans/<slug>/plan.md`

```markdown
---
type: plan
slug: <kebab-case>
date: <YYYY-MM-DD>
status: draft           # draft → approved (set by Phase 4 on PASS/CONDITIONAL); stays draft on escalate (review_verdict carries escalate, not this field)
spec: docs/specs/<YYYY-MM-DD>-<slug>.md    # real path if a spec exists (date is the spec's own date, format matches write-spec output); if no spec exists, write: none — do NOT invent a path
risk_areas: []          # subset of [auth, payment, pii, data-migration, perf-critical] — advisory only; reviewer selection is driven by the plan's prose (Technical Approach / Risks), so risks must also be described there for the matching expert (e.g. security-expert) to be triggered
review_verdict: pending # pending → pass | conditional | escalate (set by Phase 3)
review_blockers: []     # filled by the review loop when blockers remain
---

# План: <title>

## Контекст и решение
<2–4 предложения: что создаётся и почему это уже решено. Добавьте ссылку на spec / research /
запрос, в котором это решено. Этот план описывает КАК, а не ЧТО — не обсуждайте область заново.>

## Технический подход
<Конкретный дизайн. Архитектура, поток данных, ключевые типы/интерфейсы, точки интеграции в
существующей кодовой базе (укажите file:line по результатам исследования). Этого должно хватать,
чтобы реализующему агенту не пришлось повторять исследование.>

## Затронутые модули и файлы
| Путь | Изменение | Примечание |
|---|---|---|
| `<path>` | New / Modified / Renamed / Deleted | <what changes and why> |

## Принятые решения
| Решение | Обоснование | Отклонённые альтернативы |
|---|---|---|
| <what we chose> | <because…> | <X because…> |

## Риски и меры снижения
| Риск | Серьёзность | Мера |
|---|---|---|
| <risk> | critical / major / minor | <how the plan handles it> |

## Проверка и источники
<Как проверяется ЗАВЕРШЁННАЯ реализация — контракт, с которым сверяется `/acceptance`. Отличается
от `check` для каждой задачи в tasks.md: тот доказывает каждую задачу, этот — что всё изменение
завершено и корректно. Обязательный раздел — план без него нельзя утвердить (qa-and-testing §6, §0).>

| Источник истины | Тип | Статус | Достаточен для проверки? |
|---|---|---|---|
| <path / link / "baseline captured at swarm-report/<slug>-baseline.md"> | spec / test-plan / requirements / before-state baseline / Figma-or-screenshots / debug-repro | present / to-capture-before-impl / absent | yes — <why it lets someone who's never seen the system confirm "done"> / no — <gap + how it's closed before implementation> |

**Стратегия тестирования (уровни пирамиды):** всегда L0 build + <применимые уровни, например L1 static,
L2 unit, L3 UI, L5 manual> — <одна строка: почему эти уровни нужны для изменения>. L5 обязателен для
обновлений библиотек, миграций и изменений infra-слоя (network/storage/auth/DI). Если пропущен уровень,
который матрица маршрутизации помечает обязательным, назовите его и зафиксированное исключение
(qa-and-testing §1/§4) — никогда не пропускайте молча.

> Поле `spec:` во frontmatter содержит только ссылку на spec для инструментов; эта секция — полный
> человекочитаемый контракт проверки, поэтому перечисляйте каждый источник, а не только spec. Для
> исправления ошибки источником является `swarm-report/<slug>-debug.md`; для миграции/задачи «поведение
> не должно измениться» — baseline исходного состояния, снятый **до** любого редактирования
> (task-types § Before-state baseline).

## Вне области работ
- <что этот план ЯВНО НЕ делает, с владельцем/целью отсрочки, если применимо>

## Открытые вопросы
- [blocking] <вопрос, на который нужно ответить до/во время реализации>
- [non-blocking] <вопрос, который можно решить во время реализации>
```

---

## `docs/plans/<slug>/tasks.md`

Упорядоченный чек-лист с учётом зависимостей. Каждая задача достаточно мала, чтобы реализовать И
проверить её за один сфокусированный проход, и содержит условие приёмки, проверяемое без человеческого
суждения — это делает автономное выполнение безопасным.

```markdown
# Задачи: <title>

> Plan: ./plan.md · Spec AC referenced inline as AC-N

## T-1 — <short title>
- after: none
- files: `<path>`, `<path>`
- acceptance: GIVEN <precondition> WHEN <action> THEN <observable result>   (or: THE SYSTEM SHALL <…>)
- check: <test name / grep / build target that proves acceptance>   (satisfies AC-1)

## T-2 — <short title>
- after: T-1
- files: `<path>`
- acceptance: <Given/When/Then or SHALL statement>
- check: <how it is verified>   (satisfies AC-2, AC-3)
```

Формулировка приёмки: для поведения предпочитайте Given/When/Then, для инвариантов/ограничений —
«THE SYSTEM SHALL …» (EARS). Всегда связывайте приёмку с конкретной `check` — именем теста, grep или
целью build/lint — никогда с «выглядит правильно».

---

## `docs/plans/<slug>/progress.md`

Инициализируйте одним неотмеченным пунктом на задачу и пустым журналом выводов. Реализующий агент
обновляет его по мере работы; он сохраняет состояние между сессиями и запусками со свежим контекстом
(поэтому остановка/возобновление или автономный цикл не теряют позицию).

```markdown
# Прогресс: <title>

> Plan: ./plan.md · Tasks: ./tasks.md

## Статус
- [ ] T-1 — <short title>
- [ ] T-2 — <short title>

## Выводы
<!-- Добавляйте одну строку на завершённую задачу: неожиданности, подводные камни, решения во время реализации.
     Это память, сохраняющаяся при сбросе контекста. -->
```

---
name: write-spec
description: "Сформировать постоянную спецификацию функции с проверяемыми AC, границами работ и техническими решениями. Использовать для запроса spec/design doc или сложного неясного контракта; не запускает research-консорциум/панель автоматически для малой правки и не заменяет план реализации."
---

# Спецификация

Для разового запуска достаточно результата в чате или запрошенного документа. Если результат нужен другому этапу или для возобновления, обновите раздел по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Вход: feature goal, предложенный approach, constraints. Сохраняйте пользовательский intent; альтернативы рекомендуйте по evidence, не заменяйте его scope односторонне. Наследуйте task slug, kebab-case только при отсутствии; постоянный `docs/specs/YYYY-MM-DD-<slug>.md`, resume state в разделе `Spec` task report.

1. Определите цель/подход/ограничения, существующие source documents. Scope ambiguity с существенно разными объёмами → один вопрос с конкретными вариантами/рекомендацией. Не добавляйте backend/compliance/subsystems лишь из возможной ассоциации; фиксируйте реально необходимую hidden complexity.
2. Исследуйте только нужные части проекта. В одиночном режиме сделайте это сами. В режиме с субагентами подключайте подходящего исполнителя при существенном пробеле. Для сложных вопросов используйте применимую часть [research-prompts.md](references/research-prompts.md).
3. Интервью только для unanswered contract choices; [interview-rounds.md](references/interview-rounds.md) читайте при потребности в structured rounds/phase scoping. Известное не спрашивайте; используйте current authorization. Unresolved blocker нельзя превращать в non-blocking по таймеру/числу вопросов; headless передайте caller конкретное решение.
4. Перед drafting прочитайте [spec-template.md](references/spec-template.md). Frontmatter type/slug/date/status и applicable platform/surfaces/risk_areas/non_functional/acceptance_criteria_ids/design сохраняет downstream schema. AC stable AC-N, проверяемое поведение; affected modules/files, prerequisites, technical approach/constraints, rationale, Out of Scope/Open Questions/Future Phases. Детализируйте interaction mechanics, errors/compatibility ровно настолько, насколько требуется контрактом.
5. Проверьте AC, scope, незакрытые вопросы и наблюдаемые переходы. Саморевью достаточно для ограниченной спецификации без требования независимой проверки. Для высокого риска в режиме с субагентами используйте релевантные перспективы `multiexpert-review`. Если независимость обязательна, зафиксируйте отсутствующую проверку как блокирующую.
6. Исправьте реальные замечания и повторите только затронутые проверки. При нерешённом блокере сохраните draft и укажите необходимое решение.
7. Представьте reviewable summary (goal, key AC, decisions, risks/path). Если принятие spec уже разрешено и нет unresolved choices — approved без повторного approval gate; иначе получите необходимое продуктовое решение по конкретному черновику. [output-layout.md](references/output-layout.md) нужен при сохранении/handoff; state done, new files git add. Commit/push только explicit текущая авторизация.

Результат — spec, не product implementation/new tests/mobile QA. Следующие steps только внутри уже разрешённой задачи. Conflicting requirements, critical access отсутствует или scope не удалось ограничить → конкретное evidence/decision; feasibility утверждение требует минимального реального эксперимента до definitive verdict.

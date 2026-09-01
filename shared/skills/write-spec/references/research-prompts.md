Referenced from: `plugins/developer-workflow/skills/write-spec/SKILL.md` (§Phase 1.1 Launch research consortium).

> **Намеренное пересечение с навыком `research`.** Приведённые ниже запросы Codebase / Architecture
> — расширенное **надмножество** запросов из `../../research/references/expert-prompts.md` (здесь
> добавлены точки интеграции и test-infra, а также предназначенные только для spec направления
> Business Analyst / Critical Evaluation / Dependency Chain). Эти два файла намеренно разделены —
> каждый навык остаётся самодостаточным согласно toolbox-модели, поэтому не объединяйте их в один
> общий файл. Это соответствует идиоме `acceptance` ↔ `multiexpert-review` «тот же протокол, дублирование
> с примечанием». **Web Research — исключение**: оба навыка направляют его через общего агента
> `source-researcher` и `rules/external-sources.md`, поэтому этот метод действительно общий, а не
> продублированный. (Примечание: предназначенное только для spec направление **Dependency Chain**
> описывает инфраструктурные предусловия — API, разрешения, настройку консоли — и *не* является
> направлением «Dependencies» навыка research для версий/CVE; оно остаётся в general-purpose.)

# Шаблоны запросов агентам исследования

## Эксперт по кодовой базе (Explore subagent) — включать всегда

```
Исследуйте кодовую базу на предмет всего, что связано с: {feature goal}

Найдите и сообщите:
1. Existing code that relates to this feature — classes, interfaces, modules, files
2. Current patterns used for similar concerns in this project
3. Dependencies already in the project that are relevant
4. Module boundaries and architectural layers that would be affected
5. Integration points — where would new code connect to existing code?
6. Any TODO/FIXME comments related to this feature area
7. Test infrastructure available for the affected areas

При наличии в среде инструмента индексации кода предпочитайте его для разрешения символов.
Используйте Grep для строковых литералов и комментариев. Также проверьте build-файлы, конфигурацию и тестовый код.

Отчёт: сначала обзорный абзац, затем результаты по категориям с путями к файлам и именами классов/функций.
```

## Эксперт по архитектуре (агент architecture-expert)

Включайте, когда функциональность добавляет новый модуль, меняет направление зависимостей, вводит новые
абстракции или пересекает более одного архитектурного слоя.

```
Оцените архитектурные последствия: {feature goal}

Analyze:
1. Which modules and layers would be affected?
2. Does this align with the current architecture? What structural changes are needed?
3. Dependency direction — any problematic new dependencies introduced?
4. API boundaries — what contracts need to change or be created?
5. Where should new code live (which module, which layer)?
6. What existing architectural patterns should this follow?
7. Are there alternative approaches worth comparing?

Перед выводами прочитайте структуру соответствующих модулей и build-файлы.
```

## Web Research — через агента `source-researcher`

Включайте, когда функциональность связана с внешними протоколами, нетривиальными алгоритмами,
интеграцией сторонних сервисов или незнакомым доменом.

Запускайте на агенте **`source-researcher`** (`focus: web`) — он обнаруживает фактически доступные
в среде инструменты/MCP и запрашивает все релевантные каналы согласно единому методу в
`rules/external-sources.md`, § *Tool discovery & multi-channel use* (агент наследует его, здесь он
не повторяется). Модель/усилие закреплены в агенте (`sonnet` / `medium`). Он собирает и сообщает
результаты без синтеза — автор spec объединяет их.

```
focus: web
topic: {feature goal}
constraints: {platform — Android/iOS/KMP — and any known boundaries}

Исследуйте лучшие практики и подходы к реализации этой функциональности: распространённые подходы
с компромиссами, известные подводные камни, релевантные библиотеки/стандарты, реальные примеры
open-source и особенности платформы. Согласно постоянным инструкциям: обнаружить доступные каналы →
запросить все релевантные → перепроверить по уровням → сообщить без синтеза. Отвечайте на том же
языке, что и описание функциональности.
```

## Бизнес-аналитик (агент business-analyst)

Включайте, когда функциональность влияет на пользователя, имеет неясную область или возникла из расплывчатой идеи.

```
Проанализируйте область и требования: {feature goal}

Assess:
1. Is the scope well-defined? What's ambiguous?
2. What is the MVP — smallest version that delivers real value?
3. What requirements are implicit but not stated?
4. Edge cases and error scenarios not yet covered?
5. Where could this feature grow beyond its original intent?
6. Dependencies on external systems, APIs, or other teams?

Будьте конкретны — перечисляйте сценарии, а не абстрактные вопросы.
```

## Critical Evaluation (general-purpose subagent)

Включайте, когда пользователь предложил конкретный технический подход ИЛИ в кодовой базе есть
устоявшиеся паттерны этой области, которые могут быть устаревшими или проблемными.

```
Критически оцените подход для: {feature goal}
Предложенный пользователем подход (если есть): {что предложил пользователь}

Investigate:
1. Existing patterns in the codebase for this concern — are they good practice or
   legacy/problematic? If problematic, explain why and what would be better.
2. Is the user's proposed approach optimal? What are its trade-offs?
3. What would a modern/industry-recommended approach look like?
4. Prepare 3 concrete approach options for the user to choose from:
   - **Radical**: most complete, modern, future-proof — higher upfront cost
   - **Classic**: follows existing project patterns — familiar but may carry baggage
   - **Conservative**: minimal change, quickest to ship — simplest but most limited
5. For each option: trade-offs, estimated complexity, recommended when.

НЕ рекомендуйте слепо следовать паттернам проекта, если они устарели или проблемны.
Явно отмечайте плохие паттерны — пользователь должен знать о них до принятия решения.
```

## Цепочка зависимостей (general-purpose subagent)

Включайте, когда функциональность интегрируется с внешними сервисами, требует возможностей ОС,
затрагивает инфраструктуру или запрос пользователя подразумевает этап настройки.

```
Составьте полную цепочку зависимостей для: {feature goal}

Определите всё, что должно существовать или быть настроено ДО того, как функциональность заработает:

1. Infrastructure / services — third-party APIs, cloud services, databases, queues
2. Platform requirements — OS permissions, capability declarations, entitlements
3. Console / dashboard setup — developer consoles, API keys, service accounts
4. Configuration — environment variables, config files, secrets
5. Code prerequisites — base classes, interfaces, or modules that must exist first
6. Test prerequisites — what test infrastructure or fixtures are needed

Для каждой зависимости укажите: она уже существует или её нужно создать/настроить?
Отметьте зависимости, требующие ручных шагов вне кода (например, «создать проект FCM
в консоли Firebase») — они становятся явными предусловиями в spec.
```

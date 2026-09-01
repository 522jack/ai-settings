# multiexpert-review — контракт профиля

Профили настраивают `multiexpert-review` для конкретных типов артефактов (plan, test-plan, spec и т. д.). Движок (`../SKILL.md`) не зависит от типа артефакта; вся логика для конкретных артефактов находится здесь.

## Канонический перечень

```
PROFILE_INVENTORY = [implementation-plan, test-plan, spec]
```

(На момент написания существуют все три профиля: `implementation-plan.md`, `test-plan.md`, `spec.md`.)

Этот список **является источником истины**. Движок читает его при запуске, разбирая этот файл. Для добавления профиля нужно: (1) создать `profiles/<name>.md`, (2) добавить `<name>` в список выше в том же коммите. Несоответствие (файл существует, но отсутствует в списке, или запись есть без файла) → движок завершается ошибкой `[multiexpert-review ERROR] PROFILE_INVENTORY_MISMATCH: <name> <direction>`.

**Формат для парсера (контракт движка):** движок сопоставляет первую строку этого файла, удовлетворяющую регулярному выражению `^PROFILE_INVENTORY\s*=\s*\[([^\]]+)\]\s*$`. Группа захвата разделяется по `,`, а из каждого элемента удаляются пробельные символы. Строка ОБЯЗАТЕЛЬНО должна находиться внутри ограждённого блока кода (``` ```), чтобы изменения прозы выше случайно не совпали с ней. Редакторы этого файла должны сохранять точное имя переменной `PROFILE_INVENTORY`, токен `=` и однострочную форму `[...]` — без многострочных массивов, кавычек и завершающих запятых.

## Схема профиля (frontmatter)

Each `profiles/<name>.md` starts with YAML frontmatter declaring:

```yaml
---
name: <implementation-plan | test-plan | spec | ...>     # must match inventory entry
description: <однострочное человекочитаемое описание>

detect:
  frontmatter_type: [...]              # artifact frontmatter `type:` values that trigger this profile
  path_globs: [...]                    # filesystem globs, e.g. "docs/specs/**"
  structural_signatures: [...]         # regex patterns; ALL must match for signature-based detection

reviewer_roster:
  primary: [agent-name, ...]           # mandatory roster; missing agents are skipped per AC-S5
  optional_if:                         # conditional additions
    - when: "<regex over artifact content>"
      agent: <agent-name>

allow_single_reviewer: true | false    # required; if false, engine fails when only 1 agent available

verdicts: [PASS, CONDITIONAL, FAIL] | [PASS, WARN, FAIL]
                                       # verdict alphabet — engine enforces one of these two sets

severity_mapping:                      # optional; used for rubric-checklist profiles (e.g. test-plan)
  - items: ["<id>", ...]
    severity: critical | major | minor

source_routing:
  plan_mode: <action>                  # e.g. EnterPlanMode, edit-in-place, inline-revise
  file: <action>
  conversation: <action>

receipt:                               # OPTIONAL section — absence means no receipt is written
  path_template: "<path with <slug> placeholder>"
  fields_to_update: [<field>, ...]
---

## Критерии
(критерии ревью для конкретного артефакта в Markdown; агенты оценивают по ним)

## Дополнение запроса
(необязательный дополнительный текст, добавляемый в запрос на ревью шага 3 для этого профиля)
```

## Запретный список — поля, ЗАПРЕЩЁННЫЕ в frontmatter профиля

Эти аспекты принадлежат движку; профили **не должны** объявлять ни одного из следующих полей:

- `output_schema` — структура вывода ревью (Summary / Domain Relevance / Issues) фиксирована движком;
- `aggregation_strategy` — правила синтеза (сходимость, противоречия, взвешивание по уверенности) фиксированы движком;
- `state_transitions` — переходы конечного автомата фиксированы движком;
- `revise_loop_cap` — максимум 3 циклов фиксирован движком;
- `review_prompt_template` — каркас запроса шага 3 фиксирован движком; профили используют секцию `## Prompt augmentation` для добавочных настроек.

Наличие любого запрещённого поля → движок отказывается загружать профиль: `[multiexpert-review ERROR] FORBIDDEN_PROFILE_FIELD: profile <name> declares forbidden field <field>`.

## Приоритет обнаружения (шаг 1 движка)

1. **Явная подсказка вызывающего кода** — префикс аргументов `profile: <name>\n---\n`. Обе строки ОБЯЗАТЕЛЬНО должны начинаться с **нулевой колонки** (без начальных пробелов/отступа — движок сопоставляет `^profile:\s+(\S+)\s*$` в строке 1 и `^---\s*$` в строке 2). Места вызова, встраивающие этот блок в списки Markdown или документы, должны убрать отступ у примера, чтобы участники могли копировать его буквально без лишних отступов. Неизвестное `<name>` → громкая ошибка `UNKNOWN_PROFILE_HINT`.
2. **Тип frontmatter** — значение `type:` в YAML frontmatter артефакта; выигрывает первый профиль, в чьём списке `detect.frontmatter_type` есть это значение.
3. **Маска пути** — путь к файлу артефакта; выигрывает первый профиль с совпадающей `detect.path_globs`.
4. **Структурные сигнатуры** — все регулярные выражения в `detect.structural_signatures` должны совпасть с содержимым артефакта. Выигрывает первый профиль, для которого совпали все сигнатуры.
5. **Запасной вариант — спросить пользователя** — движок показывает `AskUserQuestion` с вариантами `PROFILE_INVENTORY`. Никогда не выбирайте значение молча.

## Фиксация профиля между циклами

Выбранный профиль записывается в файл состояния в цикле 1. В циклах ≥2 движок читает профиль **только** из файла состояния. Любая подсказка профиля в аргументах повторного вызова игнорируется, а в Verdict History добавляется предупреждение: `Cycle <N> ignoring profile hint '<value>' — locked to '<locked>' since cycle 1`. Это не громкая ошибка — движок продолжает работу с зафиксированным профилем.

## Маршрутизация источника — семантика `N/A`

Когда профиль объявляет источник как `N/A` (например, `source_routing.plan_mode: N/A` в профиле test-plan), он утверждает, что источник неприменим к этому типу артефакта. Если движок всё же встречает этот источник на шаге 5 (например, test-plan каким-то образом поступает как артефакт Plan Mode), движок завершается громкой ошибкой `[multiexpert-review ERROR] ROUTING_NOT_SUPPORTED: profile <name> does not support source <source>`. Эта категория использует единый префикс ошибок — потребители могут обнаруживать её как любую другую ошибку движка.

## Сопоставление серьёзности — соглашение об идентификаторах элементов

Профили, чьи критерии — это **помеченный чек-лист** с короткими ID (например, элементы test-plan `(a)`–`(e)`), ДОЛЖНЫ использовать соответствующие односимвольные или короткие ID в `severity_mapping.items` — `["a", "b", "c"]`. Профили с **секционным** списком именованных вопросов (например, `acceptance_criteria`, `prerequisites`, `out_of_scope` в spec) ДОЛЖНЫ использовать эти именованные идентификаторы. Движок рассматривает значения `items` как непрозрачные строки — допустимы оба соглашения. Это соглашение улучшает читаемость трассировки: вывод Issues каждого агента должен содержать ID в начале заголовка (`issue: (a) AC coverage violated …` или `issue: acceptance_criteria partial …`), чтобы агрегация синтезатора и квитанции оставались доступными для поиска.

## Семантика секции receipt

- **Присутствует** — после синтеза шага 4 движок обновляет файл, соответствующий `receipt.path_template` (с подстановкой `<slug>`), устанавливая каждому полю из `fields_to_update` соответствующее значение вердикта.
- **Отсутствует** — движок полностью пропускает запись receipt. Используйте это для профилей, чей артефакт не имеет контракта receipt (например, spec, вердикт которого `write-spec` потребляет напрямую). `implementation-plan` объявляет receipt: он записывает вердикт обратно во frontmatter самого плана в `docs/plans/<slug>/plan.md`.

## Семантика ошибок (единая для движка)

Все ошибки движка выводят точный префикс `[multiexpert-review ERROR] <CATEGORY>: <details>` в первой строке ответа. Потребители (например, `write-spec`) обнаруживают этот префикс, чтобы отличать ошибки движка от обычных вердиктов ревью FAIL. Категории:

- `UNKNOWN_PROFILE_HINT` — вызывающий код передал подсказку, которой нет в перечне;
- `FORBIDDEN_PROFILE_FIELD` — frontmatter профиля нарушает запретный список;
- `NO_REVIEWERS_AVAILABLE` — отсутствуют все агенты из roster; `allow_single_reviewer: false` и остался только 1 агент; либо roster пуст и нет совпадения по технологиям;
- `AMBIGUOUS_REVIEWER` — короткое имя после разрешения с учётом семейства соответствует нескольким файлам агентов (см. шаг 2 `SKILL.md` движка);
- `PROFILE_INVENTORY_MISMATCH` — перечень в README и наличие файлов в `profiles/` расходятся;
- `ROUTING_NOT_SUPPORTED` — движок достиг шага 5 с источником, который профиль объявил как `N/A`.

---
name: spec
description: Профиль спецификаций функциональности (docs/specs/<date>-<slug>.md). Панель business-analyst + architecture-expert. Критерии проверяют фальсифицируемые AC, границы области, явные решения и реалистичность предусловий.

detect:
  frontmatter_type: [spec]
  path_globs:
    - "docs/specs/**"
  structural_signatures: []

reviewer_roster:
  primary: [business-analyst, architecture-expert]
  optional_if:
    - when: "auth|token|encryption|PII|credential"
      agent: security-expert
    - when: "SLA|latency|throughput|budget|performance"
      agent: performance-expert
    - when: "a11y|accessibility|user-facing|UI|UX"
      agent: ux-expert

allow_single_reviewer: false

verdicts: [PASS, CONDITIONAL, FAIL]

severity_mapping:
  - items: [acceptance_criteria, prerequisites]
    severity: critical
  - items: [out_of_scope, decisions_made, affected_modules]
    severity: major
  - items: [open_questions_tagged, technical_approach_detail]
    severity: minor

source_routing:
  plan_mode: N/A
  file: edit-in-place
  conversation: inline-revise
---

## Критерии

Рецензенты оценивают spec по этим критериям. Каждый пункт содержит в скобках **ID элемента** (соответствует `severity_mapping.items`) — используйте ID буквально в начале каждого заголовка Issue, чтобы агрегация синтезатора и квитанции оставались доступными для поиска.

### Critical — без этого spec невозможно реализовать

- **(acceptance_criteria) Acceptance Criteria фальсифицируемы** — каждый AC является grep-проверкой, diff-проверкой, разбором YAML, запуском фикстуры или утверждением о структурной эквивалентности. «Выглядит правильно» или «должно быть быстро» недопустимо. Реализующий агент должен однозначно понимать, когда каждый AC выполнен.
- **(prerequisites) Предусловия реалистичны и полны** — у каждого предусловия есть статус (Done / Todo), владелец (Human / Agent) и конкретный критерий выхода (как проверить выполнение). Никаких расплывчатых «всё готово».

### Major — spec реализуем, но без этого рискован

- **(out_of_scope) Out of Scope указан явно** — есть секция «Out of Scope» с перечнем того, что НЕ будет сделано. Замалчивание или неявное указание границ = нарушение.
- **(decisions_made) У принятых решений есть обоснование** — у каждого зафиксированного решения есть строка/колонка «Rationale». «Мы выбрали X» без «потому что Y» = нарушение.
- **(affected_modules) Затронутые модули/файлы перечислены полностью** — таблица со всеми изменяемыми файлами, типом изменения (New / Modified / Renamed / Deleted) и примечаниями. Пропущенные файлы → реализующий агент перепланирует работу посреди реализации.

### Minor — spec реализуем, но недостаточно ясен

- **(open_questions_tagged) Открытые вопросы помечены как blocking или non-blocking** — у каждого OQ есть явная метка. Немаркированные OQ создают неоднозначность.
- **(technical_approach_detail) Детализация технического подхода** — достаточно проектных деталей, чтобы реализующему агенту не требовалось дополнительное исследование. Высокоуровневое «использовать паттерн X» без конкретных мест/контрактов = minor-проблема.

## Дополнение запроса

Рецензенты: оценивайте spec по приведённым критериям И применяйте общую экспертизу (architecture-expert проверяет направление зависимостей/границы модулей; business-analyst проверяет область/согласованность требований/ценность для пользователя).

**Обязательный формат начала заголовка Issue:** `(<item_id>) <violated | partial | satisfied>: <однострочное резюме>`. Пример: `(acceptance_criteria) violated: AC-R4 grep check unsatisfiable given AC-R6 whitelist`. Это позволяет движку детерминированно сопоставить замечание с `severity_mapping` — Issues без префикса используют серьёзность рецензента и теряют предусмотренное профилем взвешивание.

## Политика вердикта

Соответствует настройкам движка по умолчанию для `[PASS, CONDITIONAL, FAIL]`:

- **PASS** — нет critical-проблем, важных улучшений или есть только minor-предложения;
- **CONDITIONAL** — critical-проблем нет, но нарушены major-пункты критериев (настойчиво рекомендуется исправить до реализации);
- **FAIL** — нарушен любой critical-пункт критериев ИЛИ есть blocker по экспертизе рецензента.

## Без receipt

Профиль spec не записывает receipt. Вердикт — результат уровня разговора, который потребляет цикл шага 4 `write-spec`.

## Обоснование (зачем нужен этот профиль)

До появления этого профиля шаг 4.3 `write-spec` вызывал движок ревью для артефакта spec, а детектор молча классифицировал его как implementation-plan. Критерии implementation-plan — это общее техническое ревью; они специально не проверяют, фальсифицируемы ли AC, явно ли указан Out of Scope, есть ли у решений обоснование и т. д. В результате specs проверялись по критериям, не соответствующим их структуре. Этот профиль устраняет расхождение.

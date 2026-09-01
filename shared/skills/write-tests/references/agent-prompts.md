# Шаблоны запросов агентам

Reference for `write-tests` Phase 4.2 — see `../SKILL.md` for the skill entry point.

Выберите шаблон, соответствующий агенту, выбранному на фазе 4.1, и заполните placeholder `{…}`
данными фаз 1–3. Сохраняйте заголовки секций в точности как написано, чтобы downstream-агенты
надёжно находили нужные места.

Каждый запрос на делегирование должен включать:

1. **Target code paths** — full file paths to the code being tested
2. **Test Infrastructure Summary** — from Phase 2
3. **Test cases to implement** — from Phase 3 plan
4. **Existing test examples** — path to 1-2 representative test files for style reference.
   If no existing tests exist (scaffolding from scratch), set the slot to:
   `"No example available — infer conventions from build config and project naming."`
5. **Test plan** — if one was found in Phase 1.5, include its path
6. **Regression scenario** — in Regression Mode only: the structured bug description from
   Phase 1.1 (`regression-scenario` input). Omit or set to "N/A" in normal mode.

## Шаблон запроса для kotlin-engineer

```
Напишите unit-тесты для следующего кода. В точности соблюдайте существующие соглашения проекта о тестах.

## Целевой код
Прочитайте файлы:
{list of file paths}

## Инфраструктура тестирования
{Test Infrastructure Summary from Phase 2}

## Сценарий регрессии (только в Regression Mode — иначе опустите или укажите «N/A»)
{regression_scenario: root cause + reproduction steps + expected vs actual behavior}

## Тестовые случаи
{list of test cases from Phase 3}

## Эталон стиля
Прочитайте существующий тест для стиля и соглашений: {path to example test}

## Test plan (необязательно)
{путь к test plan из docs/testplans/ или «No test plan available»}

## Требования
- Пишите полные компилируемые тестовые файлы — без TODO и placeholder
- В точности соблюдайте существующие соглашения проекта об именовании, assertions и setup
- Используйте тот же подход к mocking, что и существующие тесты (MockK/Mockito-Kotlin/fakes)
- Покрывайте happy path, edge cases и error paths согласно списку тестовых случаев
- Размещайте тестовые файлы в правильном test source set и package
- Каждая тестовая функция проверяет ровно одно поведение
- Имена тестов описывают проверяемое поведение, а не реализацию
- IF Regression Mode (regression scenario is set): write EXACTLY ONE test for the
  regression scenario above — do NOT sweep for other coverage gaps; add a one-line
  comment on the test function: `// Regression: verifies fix for [root cause]`

Отвечайте на том же языке, что и запрос пользователя.
```

## Шаблон запроса для compose-developer

```
Напишите Compose UI-тесты для следующих composable. Соблюдайте существующие соглашения проекта о тестах.

## Целевые composable
Прочитайте файлы:
{list of file paths}

## Инфраструктура тестирования
{Test Infrastructure Summary from Phase 2}

## Сценарий регрессии (только в Regression Mode — иначе опустите или укажите «N/A»)
{regression_scenario: root cause + reproduction steps + expected vs actual behavior}

## Тестовые случаи
{list of test cases from Phase 3}

## Эталон стиля
Прочитайте существующий тест для стиля и соглашений: {path to example test}

## Test plan (необязательно)
{путь к test plan из docs/testplans/ или «No test plan available»}

## Требования
- Используйте createComposeRule() или createAndroidComposeRule(), как в существующих тестах
- Проверяйте отображение состояния UI, взаимодействия пользователя и изменения состояния
- Используйте semantic matchers (onNodeWithText, onNodeWithTag), а не детали реализации
- Пишите полные компилируемые тестовые файлы — без TODO и placeholder
- В точности соблюдайте существующие соглашения проекта
- IF Regression Mode (regression scenario is set): write EXACTLY ONE test for the
  regression scenario above — do NOT sweep for other coverage gaps; add a one-line
  comment on the test function: `// Regression: verifies fix for [root cause]`

Respond in the same language as the user's request.
```

## Шаблон запроса для swift-engineer

```
Напишите unit-тесты для следующего кода Swift. В точности соблюдайте существующие соглашения проекта о тестах.

## Target code
Read these files:
{list of file paths}

## Test Infrastructure
{Test Infrastructure Summary from Phase 2}

## Regression scenario (Regression Mode only — omit or "N/A" otherwise)
{regression_scenario: root cause + reproduction steps + expected vs actual behavior}

## Тестовые случаи
{list of test cases from Phase 3}

## Эталон стиля
Прочитайте существующий тест для стиля и соглашений: {path to example test}

## Test plan (необязательно)
{путь к test plan из docs/testplans/ или «No test plan available»}

## Требования
- Пишите полные компилируемые тестовые файлы — без TODO и placeholder
- Соблюдайте соглашения проекта об именовании и структуре (Swift Testing `@Test` / `@Suite`
  или XCTest `XCTestCase`) — не смешивайте два подхода в одном файле
- Используйте существующий подход проекта к test doubles (fakes/stubs/spies на протоколах); не
  вводите новую mocking library
- Покрывайте happy path, edge cases и error paths согласно списку тестовых случаев
- Размещайте тестовые файлы в правильном test target / каталоге Tests и namespace модуля
- Для async-кода используйте `async`-тесты и structured concurrency; избегайте хаков с `DispatchSemaphore`
- Каждая тестовая функция проверяет ровно одно поведение; имена описывают поведение, а не реализацию
- IF Regression Mode (regression scenario is set): write EXACTLY ONE test for the
  regression scenario above — do NOT sweep for other coverage gaps; add a one-line
  comment on the test function: `// Regression: verifies fix for [root cause]`

Respond in the same language as the user's request.
```

## Шаблон запроса для swiftui-developer

```
Напишите SwiftUI UI-тесты для следующих представлений. Соблюдайте существующие соглашения проекта о тестах.

## Целевые представления
Прочитайте файлы:
{list of file paths}

## Инфраструктура тестирования
{Test Infrastructure Summary from Phase 2}

## Regression scenario (Regression Mode only — omit or "N/A" otherwise)
{regression_scenario: root cause + reproduction steps + expected vs actual behavior}

## Тестовые случаи
{list of test cases from Phase 3}

## Эталон стиля
Прочитайте существующий тест для стиля и соглашений: {path to example test}

## Test plan (необязательно)
{путь к test plan из docs/testplans/ или «No test plan available»}

## Требования
- Следуйте существующему подходу проекта — unit-тесты в стиле ViewInspector, UI-тесты XCUITest
  или snapshot-тесты — не вводите новую UI-testing library
- Проверяйте отображение состояния представления, взаимодействия пользователя и изменения состояния
- Для запросов предпочитайте accessibility identifiers/labels внутреннему дереву представления
- Пишите полные компилируемые тестовые файлы — без TODO и placeholder
- В точности соблюдайте существующие соглашения проекта
- IF Regression Mode (regression scenario is set): write EXACTLY ONE test for the
  regression scenario above — do NOT sweep for other coverage gaps; add a one-line
  comment on the test function: `// Regression: verifies fix for [root cause]`

Respond in the same language as the user's request.
```

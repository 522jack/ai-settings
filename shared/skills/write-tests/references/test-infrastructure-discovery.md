# Обнаружение инфраструктуры тестирования

Reference for `write-tests` Phase 2 — see `../SKILL.md` for the skill entry point.

Используйте эти таблицы при проверке существующих тестов (3–5 примеров, если доступны) и build-конфигурации,
чтобы подготовить Test Infrastructure Summary для последующей генерации кода. Созданные тесты должны быть
неотличимы от написанных вручную в проекте — не вводите новый фреймворк, библиотеку утверждений или mocking tool.

## Определите фреймворки и библиотеки

| Категория | Что определить | Где искать |
|----------|---------------|---------------|
| Test framework (Kotlin) | JUnit 4, JUnit 5, Kotest | `build.gradle(.kts)` dependencies, existing test imports |
| Test framework (Swift) | Swift Testing (`@Test` / `@Suite`), XCTest (`XCTestCase`), Quick | `Package.swift` dependencies, Xcode test targets, existing test imports |
| Assertion library | Truth, AssertJ, Kotest matchers, kotlin.test, `#expect`, `XCTAssert*`, Nimble matchers | Existing test imports and assertions |
| Mocking / test doubles | MockK, Mockito-Kotlin, manual fakes; protocol-backed fakes/stubs/spies in Swift | Existing test imports, `@MockK`, `mock()`, `Fake*`/`Stub*`/`Spy*` classes |
| Async testing | `kotlinx-coroutines-test` (`runTest`), Turbine; Swift `async` tests, `withCheckedContinuation`, `XCTestExpectation` | Existing test imports, build config |
| UI testing | Compose `createComposeRule`, `compose-ui-test`; ViewInspector, XCUITest, snapshot tests | Existing test imports, build config |
| DI in tests | Hilt test, Koin test, manual construction (both stacks) | Existing test setup patterns |

## Определите соглашения

| Соглашение | Что определить | Как |
|-----------|---------------|-----|
| Naming | `should verb`, `test verb`, backtick names, `given_when_then`, Swift Testing descriptive strings (`@Test("Empty cart shows zero total")`) | Read existing test function / `@Test` names |
| File placement | Kotlin: same package as source, or separate test package; Swift: `Tests/<Target>Tests/` (SwiftPM) or Xcode test target matching the module | Compare test file locations to source |
| Test class naming | `ClassNameTest`, `ClassNameSpec`, `ClassNameTests`; Swift `@Suite` structs or `XCTestCase` subclasses named `<Type>Tests` | Read existing test class / suite names |
| Setup pattern | `@Before`/`@BeforeEach`, `init {}`, builder/factory; Swift Testing `init` / `deinit`, XCTest `setUp` / `tearDown` | Read existing test setup blocks |
| Assertion style | Fluent (`assertThat(x).isEqualTo(y)`) vs plain (`assertEquals`); `#expect(...)` vs `XCTAssertEqual(...)` | Read existing assertions |

## Шаблон Test Infrastructure Summary

Соберите результаты в структурированную сводку, которую агент генерации кода потребляет буквально:

```
## Test Infrastructure Summary

**Platform:** {Kotlin/Android / Swift/iOS / Swift/macOS / KMP}
**Framework:** {JUnit 4 / JUnit 5 / Kotest / Swift Testing / XCTest / Quick}
**Assertions:** {Truth / AssertJ / Kotest matchers / kotlin.test / #expect / XCTAssert / Nimble}
**Test doubles:** {MockK / Mockito-Kotlin / manual fakes / protocol-backed fakes / stubs / spies / none}
**Async testing:** {runTest + Turbine / runTest / runBlocking / async tests / XCTestExpectation / none}
**UI testing:** {compose-ui-test / ViewInspector / XCUITest / snapshot / none}

**Naming convention:** {описание — например, «имена в backtick с префиксом 'should'» или «описательные строки Swift Testing»}
**Class / suite naming:** {например, «ClassNameTest», «@Suite struct FooTests»}
**File placement:** {например, «тот же package в src/test/kotlin/» или «Tests/AuthTests/»}
**Setup pattern:** {например, «@Before с аннотациями MockK» или «init/deinit Swift Testing»}
**Assertion style:** {например, «плавные утверждения Truth» или «#expect с описательными тестами»}

**Example test file:** {path to a representative existing test for reference}
```

Сохраняйте заголовки секций и имена полей стабильными — downstream-запросы предполагают эту структуру.

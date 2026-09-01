# Правила Compose

Специфические для проекта соглашения по Compose и неочевидные подводные камни, выходящие за рамки того, что современная модель пишет по умолчанию. Общие идиомы Compose — `remember` для кэшируемых значений, `rememberSaveable` для изменений конфигурации, `key` у `LazyColumn` для динамических элементов, `derivedStateOf` для производного состояния, подъём состояния, UDF, PascalCase, колбэки `on*` — здесь **не документируются**; полагайтесь на модель и Compose Lint.

В этом файле перечислены только:
- Действительно неочевидные правила, которые модель пропускает без напоминания
- Поведение, зависящее от конфигурации проекта (стабильность при strong skipping)
- Жёсткие рекомендации в случаях, когда вариант модели по умолчанию отличается

О корутинах внутри composable-функций (`LaunchedEffect`, `rememberCoroutineScope`, сбор данных из Flow) см. `coroutines.md`. О стиле языка Kotlin см. `kotlin-style.md`.

---

## Шаблон экрана

Композируемая функция экрана должна быть **без состояния**:

```kotlin
@Composable
internal fun FooScreen(
    state: FooState,
    onAction: (FooAction) -> Unit,
    modifier: Modifier = Modifier,
)
```

- `viewModel()` / `hiltViewModel()` / `koinViewModel()` разрешается **один раз в точке входа навигации** (`FooRoute`), никогда внутри `FooScreen` и никогда внутри повторно используемых общих компонентов.
- Никогда не передавайте `ViewModel` как параметр composable-функции — модель иногда делает это из соображений удобства; это нарушает повторное использование и возможность предварительного просмотра.

## Запрещённые типы параметров

Никогда не принимайте следующие типы в качестве параметров composable-функций:

- `MutableState<T>` — поднимайте как `value: T` + `onValueChange: (T) -> Unit`
- `State<T>` — передавайте значение напрямую
- `ViewModel` — см. раздел «Шаблон экрана» выше

Модель иногда выбирает сокращённый вариант с `MutableState`. Не делайте так.

## Пользовательские модификаторы — Modifier.Node, никогда `composed {}`

`Modifier.composed {}` устарел и примерно на 80% медленнее (выделяет память при каждой композиции и препятствует совместному использованию модификаторов). Модель всё ещё генерирует `composed {}` на основе более старых обучающих данных — явно выбирайте `Modifier.Node`:

| Сценарий | Подход |
|---|---|
| Комбинация существующих модификаторов | Обычная цепочка расширений |
| Нужны анимация или `CompositionLocal` | Фабрика Modifier с `@Composable` |
| Рисование, layout, ввод, семантика | `Modifier.Node` + `ModifierNodeElement` |

```kotlin
private class FooNode(...) : Modifier.Node(), DrawModifierNode {
    override fun ContentDrawScope.draw() { /* ... */ }
}
private data class FooElement(...) : ModifierNodeElement<FooNode>() {
    override fun create() = FooNode(...)
    override fun update(node: FooNode) { /* update fields */ }
}
fun Modifier.foo(...): Modifier = this then FooElement(...)
```

## Стабильность — зависит от конфигурации проекта

Значимость `@Stable` / `@Immutable` зависит от конфигурации Compose Compiler:

- **Режим strong skipping** (по умолчанию в Compose Compiler 2.0+ / Kotlin 2.0+) → аннотации **менее критичны**; компилятор пропускает даже нестабильные параметры. Обычные `List` / `Map` подходят для пропуска. Аннотации по-прежнему полезны как документирование намерения.
- **Strong skipping отключён** (`composeCompiler { enableStrongSkippingMode.set(false) }` или используется более старый компилятор) → аннотации важны. Коллекции нестабильны; используйте `kotlinx.collections.immutable` (`ImmutableList`), если это принято в проекте.

**Всегда следуйте существующему соглашению проекта.** Если существующие классы состояния используют `@Immutable`, добавляйте её к новым классам для единообразия. Проверьте `stability_config.conf` на наличие правил для разных модулей, если этот файл существует.

## Производительность — отложенное выполнение фаз через модификаторы-лямбды

Compose выполняется в три фазы: **Composition → Layout → Drawing**. Перегрузки модификаторов на основе лямбд позволяют среде выполнения пропускать предыдущие фазы, когда обновлять нужно только последующие. Модель часто рефлекторно выбирает перегрузку на основе значения.

```kotlin
// Good — skips composition, runs only in layout
Box(Modifier.offset { IntOffset(offsetX().roundToInt(), 0) })

// Bad — full recomposition every frame
Box(Modifier.offset(x = offsetX.dp, y = 0.dp))

// Good — skips composition + layout, runs only in draw
Box(Modifier.fillMaxSize().drawBehind { drawRect(animatedColor) })

// Bad — recomposes every frame
Box(Modifier.fillMaxSize().background(animatedColor))
```

При передаче часто изменяющегося `State` в модификатор предпочитайте перегрузку с лямбдой (`offset { }`, `drawBehind { }`, `graphicsLayer { }`).

Также передавайте `() -> T` вместо `T`, чтобы отложить чтение в пользовательских composable-функциях, когда значение часто обновляется.

## Побочные эффекты — `rememberUpdatedState` для долгоживущих эффектов

Внутри `LaunchedEffect(Unit)` или `DisposableEffect` параметры-лямбды, захваченные напрямую, будут иметь значение на момент *запуска* эффекта, а не последнее значение. Используйте `rememberUpdatedState`, чтобы поддерживать захваченный колбэк актуальным без перезапуска эффекта:

```kotlin
@Composable
fun FooScreen(onTimeout: () -> Unit) {
    val currentOnTimeout by rememberUpdatedState(onTimeout)
    LaunchedEffect(Unit) {
        delay(5_000)
        currentOnTimeout() // always the latest lambda
    }
}
```

Модель иногда напрямую захватывает исходную лямбду и создаёт ошибку с устаревшим колбэком.

## Исчерпывающий `when` без `else`

`when` для sealed-типа состояния или действия **должен быть исчерпывающим без ветки `else`**. Компилятор должен обнаруживать пропущенные варианты при добавлении нового подтипа. Модель иногда пишет `else -> {}`, чтобы подавить ошибку компилятора, — это незаметно скрывает новые подтипы.

```kotlin
when (action) {
    is FooAction.ItemClicked -> handle(action.id)
    FooAction.Refresh -> refresh()
    // No else — adding a new FooAction subtype must be a compile error.
}
```

## Токены темы — никаких необработанных `dp` / Hex

Если в проекте есть система токенов (`AppDimens.spacingM`, `AppColors.primary`, `AppTypography.titleMedium`), никогда не используйте в коде экранов литералы `dp` или шестнадцатеричные значения цветов напрямую. Используйте токены.

Если в проекте нет токенов и напрямую используется `MaterialTheme.colorScheme.x`, следуйте этому подходу. Обнаружено на шаге 1 в compose-developer.

## Доступность — не только `contentDescription`

Модель добавляет `contentDescription` по умолчанию. Часто упускаются следующие моменты:

- **`Modifier.semantics { role = Role.Button }`** для пользовательских интерактивных composable-функций (обработка нажатия без использования `Button`/`IconButton`)
- **`mergeDescendants = true`** для составных строк, где средство чтения с экрана должно читать заголовок и подзаголовок как единое целое
- **`Modifier.minimumInteractiveComponentSize()`**, когда визуальный элемент меньше 48×48 dp, но остаётся интерактивным

```kotlin
Icon(
    imageVector = Icons.Default.Close,
    contentDescription = stringResource(R.string.close),
    modifier = Modifier
        .clickable(role = Role.Button) { onAction(FooAction.Dismiss) }
        .minimumInteractiveComponentSize(),
)
```

## KMP / Compose Multiplatform

- Никаких `android.*` / `java.*` / `javax.*` / `dalvik.*` в `commonMain`
- Ресурсы через API `org.jetbrains.compose.resources` — **API неоднократно менялся в разных версиях CMP**. Изучите существующее использование ресурсов в проекте; не делайте предположений.
- `expect`/`actual` только для платформенной реализации; логика UI — в `commonMain`
- Перед использованием в общем коде убедитесь, что каждая зависимость имеет KMP-артефакты
- Платформенный UI (обработка касаний на iOS, интеграция SwiftUI / UIKit, desktop) — проверяйте по актуальной документации, не предполагайте форму API

## Предпросмотры — никогда не `ViewModel`

Предпросмотр получает **жёстко заданное состояние**, но никогда не `viewModel()` / репозиторий / реальные данные. Модель иногда подключает VM к предпросмотрам «для реалистичности» — это ломает инструменты разработки и часто делает предпросмотры некомпилируемыми.

Предпросмотры всегда `private` и всегда обёрнуты в composable-функцию темы проекта. Покрытие нескольких состояний (loading / error / empty / populated) — соглашение проекта для предпросмотров экранов.

---
paths:
  - "**/*.gradle.kts"
  - "**/*.gradle"
  - "**/libs.versions.toml"
---

# Правила Gradle Build Script

Применяется только к Gradle build scripts: `*.gradle.kts`, `*.gradle`, `settings.gradle*`, convention plugins в `build-logic/` и `buildSrc/`.

## Конфигурация dependency — по умолчанию `implementation`, `api` только при утечке типов

Для каждой dependency выбирать минимальную конфигурацию, которая обеспечивает работу. Приоритет:

1. **`implementation`** — первый выбор. Dependency используется внутренне; её типы не входят в public API модуля. Потребители не видят её в своём compile classpath, rebuilds остаются изолированными.
2. **`api`** — только когда типы dependency входят в *public* surface модуля и downstream modules должны напрямую ссылаться на эти типы. Конкретно: типы return values с `public`/default visibility, параметры public API, public class hierarchies, annotations на public symbols, generic type arguments в public APIs.
3. **`compileOnly`** / **`runtimeOnly`** — для потребностей Gradle plugin classpath, annotation processors с optional runtime или библиотек, предоставляемых host (Android SDK, plugin runtime).

Применять тот же приоритет к test configurations (`testImplementation` предпочительнее `testApi`) и KMP source sets (`commonMain.dependencies { implementation(...) }` сначала; `api(...)` только если нужен consuming source sets / modules).

### Как выбирать

Dependency относится к `api`, если выполняется **любое** из условий:
- Тип dependency с `public`/default visibility появляется в сигнатуре объявления этого модуля с `public`/default visibility.
- Consumer module иначе пришлось бы повторно объявлять ту же dependency только для ссылки на type, который этот модуль уже exposes.
- Dependency предоставляет public DSL или extension API, который consumers вызывают напрямую через этот модуль.

В противном случае — `implementation`. `public` symbols Kotlin по умолчанию легко пропустить; сначала проверить правило видимости из `kotlin-style.md`, чтобы убедиться, что symbol действительно должен быть public.

### Почему это важно

- `implementation` сохраняет изоляцию classpath Gradle: изменение одного модуля не перекомпилирует downstream consumers, а ABI changes в dep не распространяются дальше.
- `api` — transitive contract: каждый consumer этого модуля получает dep в compile classpath, хочет он этого или нет. Неправильное использование `api` раздувает rebuild graph и создаёт случайную связанность.
- Стоимость исправления позже асимметрична: ужесточение `api` → `implementation` — breaking change для тех, кто полагался на утечку; расширение `implementation` → `api` тривиально.

### Если есть сомнения

Выбирать `implementation`. Ошибка компиляции в consumer module — ясный сигнал расширить конфигурацию; молчаливые transitive leaks — нет.

## Каталоги версий и convention plugins

- Новые dependencies добавлять в `gradle/libs.versions.toml` (или version catalog file проекта). Не хардкодить coordinates в module build scripts.
- Повторяющаяся build configuration должна находиться в convention plugins (`build-logic/`), а не дублироваться в module build scripts.
- В multi-module repos перед добавлением новой dependency в leaf module проверить, не предоставляет ли её уже транзитивно convention plugin или upstream module.

---
paths:
  - "**/*.gradle.kts"
  - "**/*.gradle"
  - "**/AndroidManifest.xml"
  - "**/*.kt"
---

# Правила Android CLI

CLI Google `android` (https://developer.android.com/tools/agents/android-cli) — **основной** инструмент для задач Android platform: он объединяет поиск/получение official docs, project metadata, управление AVD/SDK, захват screen/layout устройства, APK deploy и bundled skills. Проверять доступность в текущем окружении; синтаксис уточнять по установленной версии.

**Применяется, если** в `*.gradle*` есть ссылка на `com.android.{application,library,kotlin.multiplatform.library}`, существует `AndroidManifest.xml` / `local.properties` с `sdk.dir` или вопрос касается Android platform / SDK / Jetpack / Compose / AGP / tooling. В противном случае не действует.

**Доступность:** один раз проверить `command -v android`; если команды нет, использовать Fallback и не повторять вызовы до изменения окружения.

## Матрица решений

| Задача                                                                                 | Команда                                                                                                                                       |
|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Поиск docs Android / Jetpack / Compose / AGP / SDK                                     | `android docs search "<query>"`                                                                                                               |
| Получение страницы документации (URL из `docs search`)                                 | `android docs fetch <url>`                                                                                                                    |
| Метаданные проекта (build targets, APK output paths)                                   | `android describe --project_dir=.`                                                                                                            |
| Дерево UI работающего устройства                                                       | `android layout --pretty`                                                                                                                     |
| Diff дерева UI после действия                                                          | `android layout -d`                                                                                                                           |
| Screenshot устройства                                                                  | `android screen capture -o <path>`                                                                                                            |
| Визуальный выбор UI-элемента (без стабильного id)                                      | `android screen capture -a` then `android screen resolve --screenshot <p> --string "tap on #3"`                                               |
| Список AVD                                                                             | `android emulator list`                                                                                                                       |
| Запуск / остановка / удаление AVD                                                      | `android emulator start <avd> [--cold]` / `stop` / `remove`                                                                                   |
| Создание AVD из профиля (watch / phone / XR…)                                          | `android emulator create <profile>` (`--list-profiles` to enumerate)                                                                          |
| Установка / обновление / удаление / список SDK packages                                | `android sdk install/update/remove/list` |
| Deploy собранного APK                                                                  | `android run --apks <p1,p2…> --activity <name> --device <id> [--debug]` — `--type` = component type (ACTIVITY/SERVICE…), **не** build variant |
| Информация об окружении (SDK path, CLI version)                                        | `android info`                                                                                                                                |
| Scaffold нового проекта (только по явному запросу)                                     | `android create [template] --name <n> --minSdk <v>`                                                                                           |
| Список / поиск bundled skills (только чтение)                                          | `android skills list` / `android skills find <keyword>`                                                                                       |
| Чтение bundled skill как руководства (без install)                                     | `Read ~/.android/cli/skills/**/<skill-name>/SKILL.md`                                                                                         |
| Установка skill (маршрутизация через Skill tool; для проекта через `--project=<path>`) | `android skills add <skill-name> --agent=<agent>`                                                                                             |

> Интеграция с Android Studio (`android studio *`) намеренно не включена — она не используется.

## Маршрутизация относительно существующих инструментов

Команды перечислены в таблицах выше; здесь указано только, когда `android` primary, а когда fallback.

- **Docs:** `android docs search` — единственный курируемый канал guides (как принято / migration / best practice). Для API truth достаточно pinned source/API согласно `external-sources.md`; docs/guides дополняют его при migration, ambiguity или evolving patterns.
- **Bundled skills** (`~/.android/cli/skills/**/SKILL.md`, T2 при проверенном official content) — третий канал guides, **install не нужен**: `find <kw>` → `Read SKILL.md` → structured workflow (~10 шагов). Триггер: миграция / upgrade / узкая область (Wear M3, XR, CameraX, Navigation 3, edge-to-edge, Compose Styles/adaptive, R8, Perfetto, testing-setup, PBL, Engage, AppFunctions, XML→Compose, AGP 9). `last-updated` старше года в evolving стеке → понизить вес. **Не использовать**, когда глобальный Claude Code skill покрывает 1:1 (`agp-9-upgrade` ↔ `kotlin-tooling-agp9-migration`) — глобальный приоритетнее (routable, интегрирован с gates).
- **Device / SDK / AVD / screen / layout:** `android` primary над raw `adb` / `sdkmanager` / `avdmanager` / `emulator` — на raw переходить только при отсутствии нужного флага.
- **Build:** саму сборку выполнять проектным Gradle; `android run` — только для deploy-and-launch уже собранного APK.

## Жёсткие правила

- **Skills: регистрация ≠ доступность.** Файлы уже на диске — `Read` работает всегда, проактивно. `android skills add` / `init` *регистрируют* skill в роутинге Skill tool — **только по явной просьбе** и когда нужно автосрабатывание по триггерам. **Никогда** не выполнять автоматически `android init` / `skills add --all`: это дублирует глобальные skills и ломает routing. Синтаксис: имя позиционное (`--skill=` удалён); флаги `--agent` / `--project` — проверять через usage, не угадывать.
- **Никогда не обновлять автоматически:** при сообщении «A new version available» — одна строка раз в сессию, спросить перед `android update`. (`info`: `version` ядра и `launcher_version` обёртки; отставание launcher нормально.)
- **Device/manual QA:** применять единую [qa-and-testing.md](qa-and-testing.md); наличие CLI не даёт разрешение на device actions.

## Fallback при отсутствии CLI

Крайний случай (CLI отсутствует на машине). Один раз сообщить: «Android CLI not installed — install per the docs URL, or proceeding with fallbacks». Затем:

| Задача              | Fallback                                                                                                         |
|---------------------|------------------------------------------------------------------------------------------------------------------|
| Documentation       | Context7 (`resolve-library-id`) → WebSearch по `developer.android.com` → WebFetch страницы                       |
| Метаданные проекта  | Read `app/build.gradle*` / `settings.gradle*`; `ksrc` для dep sources                                            |
| Layout / screenshot | `adb shell uiautomator dump` + `adb pull /sdcard/window_dump.xml` / `adb exec-out screencap -p > shot.png`       |
| SDK / Emulator      | `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager` / `$ANDROID_HOME/emulator/emulator -list-avds`, `avdmanager` |
| Deploy              | `./gradlew :app:installDebug` затем `adb shell am start -n <pkg>/<activity>`                                     |

## Операционные заметки

Длинный ANSI output фильтровать; syntax/help quirks проверять по установленной версии. Исторические указатели: [экосистемные заметки](references/ecosystem-notes-2026-10-01.md).

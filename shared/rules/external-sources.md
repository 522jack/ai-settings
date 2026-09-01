# Внешние источники

## Маршрутизация источников

| Источник | Использовать для | Не использовать для |
|---|---|---|
| Local code / project files | Первый источник для вопросов о проекте | — |
| `ksrc` | Чтение исходников зависимостей JVM/Gradle (настоящий source jar) | Внутренний код проекта |
| `android docs search`/`fetch` | API truth + guides для Android/Jetpack/Compose/AGP/SDK (курируемый developer.android.com) | не-Android библиотеки |
| `~/.android/cli/skills/**/SKILL.md` | Bundled Android CLI skills — структурированные workflows (migrations; узкие области: Wear/XR/edge-to-edge/Compose styles/R8/Perfetto…). Обнаружение: `android skills find <kw>` → Read SKILL.md. См. `rules/android-cli.md` | API truth для библиотек; не-Android задачи |
| Context7 | Опубликованная документация библиотек/frameworks, текущий API/migration | Код проекта, отладка собственного кода; один провал `resolve-library-id` → остановиться, не искать синонимы |
| `WebSearch`/`WebFetch` | По умолчанию для всего, что не покрыто выше | — |
| Raw README через `raw.githubusercontent.com` | Крайний вариант для конкретного репозитория | — |

Никогда не использовать WebFetch для отрендеренных страниц GitHub (`https://github.com/...`) — HTML шумный и дорогой; использовать raw README.

## Обнаружение инструментов и использование нескольких каналов

Таблица выше называет **классы источников**, а не гарантированный набор инструментов. Фактически доступные инструменты зависят от окружения: могут быть подключены или отсутствовать дополнительные MCP servers, docs/knowledge proxy, platform-specific MCP (например, Mac/desktop server за proxy) или дополнительные search backends. Никогда не предполагать существование названного инструмента и никогда не останавливаться на первом найденном.

Единое правило для каждого потребителя (этого правила, `research` skill, `source-researcher` agent, research в `write-spec`) — сбор сведений состоит из трёх этапов, а не из фиксированного pipeline:

1. **Discover** — составить перечень фактически доступного сейчас: подключённых MCP servers и отложенных tools (через `ToolSearch`), а также встроенных search/fetch. Эмпирически проверено: запущенный subagent может и обнаруживать, и вызывать MCP servers сессии (в том числе разные серверы за один turn), поэтому gather-agent выполняет собственное обнаружение — orchestrator не фиксирует набор инструментов заранее.
2. **Использовать все релевантные каналы параллельно** — для данного класса вопроса запрашивать **каждый** доступный канал, который его обслуживает (согласно составу ролей/стека в разделе *Проверять API библиотеки перед кодом* ниже), а не только один. Один канал = одна точка зрения; важна широта.
3. **Cross-check и tier** — по возможности проверять утверждение по ≥2 каналам и ранжировать по *оценке доверия* (T1/T2 выше T3/T4); показывать расхождения и несовпадения версий, никогда не выбирать молча.

Если целый класс каналов недоступен (нет web search, dependency-intelligence MCP или platform MCP не подключён в этой сессии), явно указать это ограничение в выводе — снижение уверенности должно быть видимым, а не скрытым. Gather-agent добавляет в отчёт фактически использованные каналы (и каждый недоступный класс), чтобы synthesizer знал, какая полнота проверки подтверждает каждый вывод.

## Проверять API библиотеки перед кодом

Обязательно перед Edit/Write кода с внешней библиотекой. Данные обучения устаревают; код проекта — только используемый срез API и может быть legacy/антипаттерном.

**Три роли каналов — дополняют, не исключают; часто нужны параллельно:**
- **API truth** (сигнатуры, семантика, типы, альтернативы) — всегда при написании/правке кода с библиотекой.
- **Guides** (рекомендуемые паттерны, migration, codelabs, troubleshooting, «как принято») — для «как сделать X», «миграция A→B», незнакомого стека, нетривиальной интеграции.
- **Project style & versions** (стиль, pinned версии, подключённые модули) — всегда, отдельным проходом поверх внешних каналов; это **не** API truth.

`→` ниже = fallback внутри одной роли, **не** приоритет между ролями. Запомненные сигнатуры — **никогда** не источник.

**Композиция по стекам** (API truth + Guides — параллельно, если задача нетривиальна):
- **Android:** API truth = `ksrc` + `android docs` параллельно (jar + текущая рекомендация, не «или/или»). Guides = `android docs` + bundled Android CLI skills параллельно (skills = structured workflows для миграций/областей; docs = точечные guides/codelabs). Fallback: Context7 → WebSearch.
- **JVM/Kotlin/KMP/Gradle (не-Android):** API truth = `ksrc` primary → Context7 → WebSearch. Guides = Context7 (Kotlin покрыт неравномерно) → WebSearch. `ksrc` даёт только сорсы — для «как принято» нужен второй канал.
- **Frontend/JS/TS:** оба канала — Context7 primary → WebSearch.
- **Другие (Python/Go/Rust/C#/Swift…):** оба канала — Context7 → WebSearch; экосистемный аналог `ksrc`, если есть.

**Высокая скорость устаревания (оба канала обязательны):** Ktor 3.x, Room (KMP `@Upsert`, multiplatform), SQLDelight, kotlinx.serialization, kotlinx.datetime, Hilt, Koin, Compose Multiplatform, Compose Material3, AGP 8+/9, KSP, Firebase Android (BoM v34+ убрал KTX), Navigation 3.

## Быстро меняющийся declarative UI — guides и changelog перед реализацией

Для **Jetpack Compose, Compose Multiplatform (CMP), SwiftUI** одной проверки «сверить API с версиями» мало: стек меняется быстро, и кроме *какой API есть* нужно знать, *как сейчас рекомендуется делать* (иначе агент пишет устаревший код — `NavigationView` вместо `NavigationStack`, deprecated Compose API). Перед имплементацией нетривиального экрана/компонента в этих стеках пройти три роли — под общим принципом *обнаружения инструментов и использования нескольких каналов* (discover в рантайме → tier → cross-check):

**A. API-truth — какой API реально в версии проекта.** `ksrc` (T1, реальный source jar точной версии; JVM/KMP → Jetpack Compose, CMP core/Material3; не Swift) → документация того же номера / Context7 (T2). SwiftUI: `apple-doc-mcp-server` MCP, когда подключён (T2; ksrc-эквивалента для Apple нет).

**B. Рекомендуемый подход — как делают сейчас.** Официальные reference-приложения (код > документация, T1/T2): `android/nowinandroid`, `android/compose-samples`, `JetBrains/compose-multiplatform/examples`, Apple sample code → What's New / release-notes / roadmap (Android Dev Blog, JetBrains Kotlin Blog, WWDC) + дизайн-канон (Compose API Guidelines, Material 3, Apple HIG) → community (T3/T4, **только cross-check, не единственный источник**): Swift Forums, Hacking with Swift / Sundell / Point-Free, Kotlin Slack, Android Weekly.

**C. Что изменилось / известные проблемы.** `maven-mcp` `dependency-changes` — changelog между версиями (T2; самый богатый сигнал для CMP). Issue-трекеры **по правильному адресу**: Jetpack Compose → **Google IssueTracker** (не GitHub); CMP → GitHub issues (`JetBrains/compose-multiplatform`); SwiftUI → Apple Developer Forums / Feedback Assistant.

**Маршрут для каждого стека:**
- **Jetpack Compose** → `android docs` CLI + developer.android.com release-notes/BOM/roadmap + `ksrc`.
- **Compose Multiplatform** → core Compose выровнен с Jetpack Compose по **major.minor** (эмпирически: CMP 1.11.1 ↔ JC runtime 1.11.2 — minor совпадает, patch свой; CMP релизится позже календарно). **Но отдельные артефакты — Material3 и навигация (`org.jetbrains.androidx.navigation:navigation-compose`) — имеют собственную нумерацию, и KMP-форк может отставать от androidx upstream** (напр. KMP navigation 2.9.2 vs androidx 2.9.8) → версию каждого артефакта проверять отдельно (maven-mcp + CMP GitHub release-таблицы). Для общего Compose API годятся JC-доки / `android docs` / `ksrc` того же major.minor; JetBrains KMP docs / Kotlin Blog / GitHub release-таблицы — для CMP-специфики (iOS/Desktop/resources/`expect`-`actual`) и точного соответствия версий артефактов.
- **SwiftUI** → `apple-doc-mcp-server` (primary, когда подключён) + Apple/WWDC; сайт Apple — SPA, raw WebFetch ненадёжен, предпочитать MCP.

## Рабочий процесс Context7

Шаги при обращении к Context7 (когда именно — см. таблицу «Маршрутизация источников» и состав каналов по стекам выше):

1. Начать с `resolve-library-id` по имени библиотеки + вопросу пользователя — кроме случая, когда дан точный ID в формате `/org/project`.
2. Выбрать лучшее совпадение (ID `/org/project`) по точному совпадению имени, релевантности описания, числу code-сниппетов, репутации источника (High/Medium), benchmark score (выше — лучше). Если результат не подходит — переформулировать (`next.js`, не `nextjs`) или использовать версионный ID, если указана версия.
3. Выполнить `query-docs` с выбранным ID и полным вопросом пользователя (не одним словом).
4. Отвечать по полученной docs.

Один провал `resolve-library-id` → стоп, не гнаться за синонимами. Не использовать для: рефакторинга, написания скриптов с нуля, отладки бизнес-логики, code review, общих концепций программирования.

## Оценка доверия

Источник может быть формально primary, а content — устаревший / для другой версии / AI-галлюцинация. Оценить tier до того, как принять сведения.

| Tier | Что означает | Источники |
|---|---|---|
| **T1** эталон истины | артефакт без интерпретации | `ksrc`, код проекта, официальный release artifact |
| **T2** официальная документация | курируемая вендорская docs, releases/changelogs | `android docs`, Context7 для официальных либ, vendor changelog |
| **T3** агрегированный/AI | может галлюцинировать | Context7 для community либ без вендорской docs |
| **T4** случайный web | блоги, StackOverflow, Medium, tutorials | WebSearch, случайный WebFetch |

**Память — не tier.** Авто-память (`MEMORY.md`, recalled facts) и существующий код проекта фиксируют то, что было верно на момент записи, и устаревают — это **не** источник знания об API/версиях/поведении. При пробеле или сомнении перепроверь по T1/T2 (официальный источник), не действуй по памяти. Память годится как указатель «где смотреть», не как факт.

**По умолчанию: T1 + T2 параллельно** для любого Edit/Write с внешней библиотекой — базовый режим, не «при сомнении». Только T1 допустим **только** с явным обоснованием в reasoning: стабильная Java/Kotlin stdlib (не evolving либа); уже виденный символ на той же pinned версии, `ksrc` подтверждает форму, локальный helper / data class без поведения; тривиальное использование (конструктор data class, enum value, константа). «Кажется очевидным» — не обоснование.

**Валидация перед использованием:**
- Версия источника = версии в проекте? Нет → флаг, не использовать без cross-check, отметить в reasoning (T1 = pinned, T2 = current; расхождение = проект отстал или docs про другую major).
- T3/T4 старше года в evolving стеке (Compose/Ktor/AGP/KMP/Hilt/kotlinx.*) — подозрительно, понизить вес.
- T3 aggregated/AI — никогда единственный источник для сигнатур/версий; только в паре с T1 или T2.
- Red flags (понизить tier на 1): источник не указывает версию; сигнатура не воспроизводится в `ksrc`; текст «выглядит сгенерированным» (общие фразы, размытые типы); tutorial/блог без даты.

**Конфликты:**
- **T1 vs T2** — следовать T1 (реально доступно в проекте), отметить расхождение пользователю; при существенном gap — предложить bump через plan-stage gate.
- **T1/T2 vs T3/T4** — T1/T2 выигрывают безусловно.
- **T2 vs T2** (два официальных расходятся) — свежий вендорский changelog > старая docs-страница; непонятно → поднять вопрос, не выбирать молча.

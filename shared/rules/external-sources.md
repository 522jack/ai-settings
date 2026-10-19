# Внешние источники

## Перед кодом с внешним API

Определить pinned версию и стиль проекта. Проверить используемые сигнатуры/семантику по source artifact точной версии (`ksrc` для JVM/Gradle) или официальной versioned API docs. **Один достаточный pinned T1/T2 источник закрывает API truth** для ограниченного изменения; повторная проверка уже изученного API не нужна, если версия, символ и семантика не изменились. Память/training data и примеры собственного кода — указатели, а не доказательство API.

Дополнительные official guides/changelog/source нужны при migration/upgrade, неизвестной семантике, противоречии источников, нетривиальной интеграции или быстро меняющемся паттерне. Для нетривиального declarative UI (Compose/CMP/SwiftUI) проверять recommended approach и изменения relevant API: одной компиляции недостаточно. Не запрашивать все доступные каналы ради количества; расширять исследование до разрешения конкретного вопроса. Explicit research/audit следует своему skill.

## Маршрутизация

| Вопрос | Источник и fallback |
|---|---|
| Проект | локальные instructions/code/config |
| JVM/Kotlin/KMP/Gradle API | pinned source через `ksrc` → official versioned docs/Context7 → official web |
| Android guides/platform | `android docs search/fetch`; scoped `android-cli.md`; bundled skills только для relevant workflow |
| JS/TS/Python/Go/Rust/C#/Swift API | официальный source/versioned docs либо Context7 с проверенной версией |
| Migration/recommended patterns | vendor guides/changelog/sample code; второй источник при неоднозначности |
| Неизвестное | доступный official search/fetch; community только для hypotheses/cross-check |

Использовать реально доступные tools; отсутствие одного MCP не требует обхода всех остальных. GitHub code/README читать через API/raw, избегать шумного HTML. Context7: точный ID либо один `resolve-library-id`, затем `query-docs` с полным вопросом; при неудаче использовать официальный fallback, не гоняться за синонимами.

## Доверие и конфликты

- T1: артефакт/source точной версии, без интерпретации.
- T2: official versioned docs/releases/guides; Context7 оценивать по исходному content, а не названию инструмента.
- T3/T4: aggregated/AI/community — только corroboration, не единственный источник API/версий.

Проверять версию, дату и воспроизводимость сигнатуры. T1 pinned определяет доступный API; current docs другой версии не разрешают молча bump dependency. Расхождение T1/T2 описать; между official источниками выяснить версию/контекст и release notes, не выбирать произвольно. Недоступный необходимый источник или оставшуюся неоднозначность явно отметить.

Для platform-specific migration/version mapping читать [датированные заметки](references/ecosystem-notes-2026-10-01.md); они не заменяют актуальную проверку. Добавление/bump dependency регулируется [dependencies.md](dependencies.md).

# Экосистемные заметки — 2026-10-01

Это указатели для исследования, а не проверенная таблица актуальных версий. Старые числовые примеры Android CLI, количества bundled skills, Compose/CMP/Nav и Firebase удалены из policy: перед использованием получать pinned версии и совместимость из проекта и официальных артефактов.

- Compose Multiplatform core, Material3 и navigation могут иметь независимую нумерацию; не выводить совместимость по совпадению major/minor. Сверять каждый artifact и release compatibility tables.
- Jetpack Compose: developer.android.com release notes и Google IssueTracker. CMP: JetBrains releases/examples/issues. SwiftUI: Apple docs/sample code/WWDC и Developer Forums/Feedback Assistant.
- Android CLI: набор skills, флаги и поведение help зависят от установленной версии; уточнять через `android info` и usage. Не считать прежнее количество skills или отсутствие флага текущим фактом.
- Для migration в Ktor, Room, SQLDelight, kotlinx.*, DI, Compose, AGP/KSP, Firebase и Navigation смотреть changelog точных old/new версий. Наличие знакомого API не доказывает отсутствие migration requirements.

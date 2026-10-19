# Phase 0 — однократное сканирование корректности

Только report по полному diff и незакоммиченным изменениям; без auto-fix и внешних комментариев. Используйте встроенный runtime code-review (в Claude Code `/code-review`, не marketplace `code-review:code-review`). Если инструмент требует номер PR вместо рабочего дерева, запишите marketplace shadow, не передавайте PR и продолжите A. Нет эквивалента → adapter limitation.

Тривиальный diff (один файл, <50 LOC, только рефакторинг, без public API/высокого риска) пропускает scan. `--skip-deep-scan` фиксируется как явно принятый пользователем skip.

`--deep-scan-effort auto|low|medium|high|xhigh|max`: явный выбор приоритетен. Auto по первому совпадению: max — auth/payment/PII/data migration или narrow security trigger; xhigh — infra/network/storage/DI, API ≥2 modules, >500 LOC или >15 files; high — public API/cross-module/>150 LOC/>6 files; иначе medium. Запишите signal+effort.

В цикл Round 1 передавайте findings с конкретным failure_scenario (crash/wrong output/data loss/dropped guard/broken caller). Соглашения оставьте A, cleanup B; дедуплицируйте один дефект+расположение, приоритет A. Scan не повторяется между раундами; новый существенный scope после него требует явно нового scan, а не ложного reuse.

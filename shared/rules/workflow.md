# Рекомендуемый рабочий процесс

Семейство plugins `developer-workflow` — это набор skills по запросу, а не принудительный pipeline. Выбирать нужное задаче; последовательность определяет текущий runtime adapter. Имена skills ниже используют синтаксис со слешем как сокращение; рантаймы без slash commands должны вручную вызывать тот же рабочий процесс из `SKILL.md`.

## Обязательные ворота

**Preparation gate — до любой реализации.** Собрать доступные источники, необходимые для реализации и проверки:
- **Sources of truth:** spec/AC, предоставленные screenshots/Figma, debug-repro, уже существующий behavioral baseline. Не запускать mobile приложение/emulator/simulator/device и не создавать новый test baseline без явного запроса пользователя. Если источника нет, зафиксировать intended behavior и риск вместо блокировки реализации.
- **Knowledge sources:** доверенные docs/source по tier T1–T4 — см. [[external-sources]]. При пробеле или сомнении проверять official source; для неизвестного использовать `research`.
- **Verification + decomposition:** выбрать targeted build/static checks и существующие релевантные tests. Новые тесты, sample/sandbox app, screenshot tests и несколько emulators только предложить; создавать или запускать их можно лишь по явной просьбе пользователя.

Автономность: стандартное решение применять без вопроса. Отдельно спрашивать только о действительно необходимом пользовательском решении; отсутствие opt-in на новые тесты или mobile manual QA означает, что эти действия пропускаются.

**Quality gate — `finalize`.** Обязателен после каждой реализации, в которой писался код, — до объявления задачи завершённой. Finalize отвечает за *то, как написан код*: это полный цикл review→fix→simplify, повторяемый до исчезновения замечаний выше Minor или завершения с ESCALATE, требующим решения пользователя. `code-reviewer` — один из компонентов, которыми управляет цикл; **отдельный запуск code-reviewer НЕ закрывает эти ворота**: после одного review шаги fix и simplify остаются невыполненными. «Код уже отревьюен» не является основанием пропустить `finalize`. Исключения: чистые изменения документации, изменения только конфигурации без логики, однострочные механические изменения с очевидным результатом.

**Acceptance gate — `acceptance`.** Запускается после `finalize` до PR promotion и проверяет реализацию по доступному source of truth. Для Android/iOS базовый acceptance ограничен code review и build smoke; `manual-tester`, emulator/simulator/device и mobile runtime QA добавляются только по явной просьбе пользователя. Для web/desktop действуют обычные runtime checks, если они доступны.

**PR promotion gate — `create-pr --promote`** (draft → ready for review) требует явного подтверждения пользователя. Открытие draft PR — обычная операция; promotion сигнализирует о завершении задачи и делает её видимой reviewers — это действие над общим состоянием.

## Процессы

**Нетривиальные features:**
1. Plan mode → preparation gate: собрать доступные sources of truth, подтвердить knowledge sources, выбрать проверки и декомпозировать. Для неизвестного — сначала research. Опционально `/multiexpert-review`, `/write-spec` или `/write-plan`.
2. Реализовать в feature branch в worktree. Рано открыть draft PR через `/create-pr --draft`.
3. `check` (существующие проверки) → `finalize` → `acceptance` без mobile manual QA → `create-pr --promote` (требуется подтверждение пользователя) → `drive-to-merge`. Новые тесты и mobile manual QA добавлять только по явному запросу.

**Исправления ошибок:**
1. Зафиксировать root cause и доступные шаги воспроизведения в `swarm-report/<slug>-debug.md`.
2. Реализовать исправление → `check` → `finalize` → `acceptance` → PR. Regression test писать только по явной просьбе пользователя; без неё использовать доступное воспроизведение и существующие тесты.

**Exploratory QA без spec:** напрямую вызвать specialist `manual-tester` или эквивалент runtime QA (skill не нужен).

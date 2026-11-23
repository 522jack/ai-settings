---
name: write-plan
description: "Сохранить план реализации уже принятого изменения: technical approach, tasks и проверяемые условия готовности в docs/plans. Использовать по запросу постоянного плана; выбор подхода относится к research, контракт требований — к write-spec. Объём независимого ревью определяется риском."
---

# План реализации

Для разового запуска достаточно результата в чате или запрошенного документа. Если результат нужен другому этапу или для возобновления, обновите раздел по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Вход: принятое изменение, constraints, optional `--from-spec PATH`; не решённый выбор → research, missing complex contract → write-spec. Наследуйте стабильный task slug; только при отсутствии задайте caller/task/branch kebab-case без prefix; найденный spec не меняет slug.

Modes: default сохраняет reviewed plan без human approval pause; `--interactive` добавляет один явно запрошенный checkpoint; `--quick` облегчает bounded investigation/review, не skips mandatory checks. Headless настоящую unresolved design fork передаёт caller, не блокируется question tool.

1. Изучите только нужные части проекта в выбранном режиме. Подключайте профиль или документацию при конкретном пробеле.
2. Сохраните канонический `docs/plans/<slug>/plan.md` по [plan-template.md](references/plan-template.md). Для небольшого плана включите задачи и проверки в тот же файл. Разделение на `tasks.md` используйте для большого плана с отдельными исполнителями или явным требованием. Прогресс храните только при необходимости возобновления по [output-layout.md](references/output-layout.md).
3. Укажите проверки по `$HOME/dotfiles/ai/shared/rules/workflow.md`. Обязательные команды, opt-in для новых тестов и ручного mobile QA действуют в обоих режимах.
4. Проверьте план по [review-loop.md](references/review-loop.md). Если требуется независимое ревью, сохраните draft до результата.
5. PASS либо CONDITIONAL без blocking issues → status approved, review_verdict обновлён, state done. Default не требует confirmation; --interactive checkpoint до approved. User design choice не выдумывать: в interactive chat, headless blocking Open Question+escalate.

Добавьте новые постоянные файлы в git. Сообщите путь, вердикт, риски и первый шаг. Если реализация авторизована, продолжайте в выбранном режиме.

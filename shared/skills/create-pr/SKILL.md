---
name: create-pr
description: "Создать draft/ready PR или MR текущей ветки, обновить его описание (--refresh) либо перевести draft в ready (--promote). Описание берётся из actual diff и доступных артефактов; не выполняет реализацию, quality checks, коммиты или слияние."
---

# Создание PR/MR

Для разового запуска достаточно результата в чате или запрошенного документа. Если результат нужен другому этапу или для возобновления, обновите раздел по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Выберите mode из текущего запроса/сессии; действие PR authorizes соответствующую публикацию, без повторного общего permission gate. Не распространяйте это разрешение на commits, reviewer notifications, code, tests или merge.

| Mode | Preconditions | Detail to load |
|---|---|---|
| --draft | absent или draft | [draft.md](references/draft.md) |
| --refresh | existing, любой status | [refresh.md](references/refresh.md) |
| --promote | existing draft, applicable checks complete | [promote.md](references/promote.md) |
| default | absent; draft/ready intent известен | [default.md](references/default.md) |

Общую CLI/platform/branch/artifact подготовку читайте в [setup.md](references/setup.md); затем только выбранный mode. Lookup errors не равны absent PR. При auth/network/mode violation остановитесь до мутации, покажите evidence. Push только обычный разрешённой ветки и существующих commits; hooks/CI не обходить, main/master/develop product projects не пушить напрямую.

Сформируйте title/body по фактическому diff и проверкам. Используйте шаблон проекта, при необходимости [body-sections.md](references/body-sections.md). Для ready применяйте `$HOME/dotfiles/ai/shared/rules/workflow.md`. Draft и refresh отражают незавершённые проверки. Навык использует доступные результаты.

При update сохраняйте user-edit-start/end blocks, Screenshots/demo verbatim и checked checklist. Не удаляйте human labels/reviewers; refresh их не меняет. Labels только existing applicable; assignment reviewers требует explicit authority. Тело передавайте file/stdin structured argument, не интерполируйте multiline shell text.

User-visible release notes → [release-notes.md](references/release-notes.md), flags --release-notes TEXT / --skip-release-notes REASON. При реальном UI diff прочитайте [visual-change-patterns.md](references/visual-change-patterns.md), используйте existing attachments; не делайте screenshot capture/mobile QA автоматически. Missing screenshots отражайте конкретным limitation, не выдумывайте.

Выход: URL, выполненный mode/status, actual verification/limitations и при partial mutation точный effect. Не создавать follow-up issues/сообщения/merge без соответствующей инструкции.

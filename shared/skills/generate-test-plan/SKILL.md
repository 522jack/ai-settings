---
name: generate-test-plan
description: "Создать приоритизированный документ test plan/QA scenarios с TC, risk areas и AC coverage из spec/design/кода. Использовать при запросе плана проверок или edge cases; не пишет автоматизированные тесты и не запускает приложение, браузер или устройство."
---

# План тестирования

Вход: spec/AC/design/implementation и границы цели. Сопоставьте источники; code-only behavior `[inferred from code]`, расхождения — Findings. Task-slug caller→explicit inline→feature kebab-case выбирается один раз для всей задачи и наследуется подзадачами; slug permanent документа может отличаться от task-slug.

Выход всегда `docs/testplans/<slug>-test-plan.md`, frontmatter type:test-plan/slug, new file git add. Прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md` и [receipt-format.md](references/receipt-format.md): main сохраняет краткий receipt в `## Test plan` общего `swarm-report/<task-slug>.md`, в том числе при самостоятельном запуске. Специалист возвращает текст и не пишет отчёт. Spec.platform копируется в receipt дословно, иначе empty.

При записи прочитайте только применимый вариант [format-templates.md](references/format-templates.md): Standard для UI/mixed, lightweight Given/When/Then для non-UI без Steps/Expected Result columns (отметить Findings). Фазы → один файл, Phase N subsections и receipt phase_coverage. Тесты TC-N последовательны; каждый проверяет отдельный observable outcome, Type + Type rationale обязательны; источники traceable, scope smallest sufficient. Реальная coverage, не квота 15–30 cases.

Типы/tier/source и conditional instrumentation contract — [field-types.md](references/field-types.md), читайте нужный раздел при классификации. Frontmatter/Findings/Risk Areas/Test Cases/Edge Cases/Coverage Matrix/Automation candidates сохраняйте. Non-functional/Instrumentation header обязателен; user-facing/prod-bound и relevant network/payment/auth/jobs/migrations описывают существующий agreed observability contract (logs/metrics/traces/alerts/dashboards), внутренний scope допускает N/A reason. Не навязывайте новые services/stack/requirements; неизвестное значимое решение в чат.

Figma — only если source Figma, с применимым Figma skill prerequisite. Документ runtime TC не разрешает runtime execution: mobile QA и написание новых tests требуют своего opt-in. Review по риску/явному запросу; не запускайте panel автоматически. Отчёт: path, relevant coverage/findings и ограничения; commit/push/следующие skills только соответствующая авторизация.

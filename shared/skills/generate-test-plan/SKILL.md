---
name: generate-test-plan
description: "Создать приоритизированный документ test plan/QA scenarios с TC, risk areas и AC coverage из spec/design/кода. Использовать при запросе плана проверок или edge cases; не пишет автоматизированные тесты и не запускает приложение, браузер или устройство."
---

# План тестирования

Вход: spec/AC/design/implementation и границы цели. Сопоставьте источники; code-only behavior `[inferred from code]`, расхождения — Findings. Task-slug caller→explicit inline→feature kebab-case выбирается один раз для всей задачи и наследуется подзадачами; slug permanent документа может отличаться от task-slug.

Сохраните `docs/testplans/<slug>-test-plan.md` с frontmatter type:test-plan/slug и добавьте в git. Если план передаётся на приёмку или панельное ревью в рамках задачи, сохраните метаданные по [receipt-format.md](references/receipt-format.md).

При записи прочитайте только применимый вариант [format-templates.md](references/format-templates.md): Standard для UI/mixed, lightweight Given/When/Then для non-UI без Steps/Expected Result columns (отметить Findings). Фазы → один файл, Phase N subsections и receipt phase_coverage. Тесты TC-N последовательны; каждый проверяет отдельный observable outcome, Type + Type rationale обязательны; источники traceable, scope smallest sufficient. Реальная coverage, не квота 15–30 cases.

Для короткого плана достаточно рисков, сценариев, ожидаемых результатов и связи с AC. Добавляйте отдельную матрицу, автоматизацию и observability, когда их требует контракт, масштаб или downstream-формат. Для формального ревью используйте применимые поля из [field-types.md](references/field-types.md).

Figma — only если source Figma, с применимым Figma skill prerequisite. Документ runtime TC не разрешает runtime execution: mobile QA и написание новых tests требуют своего opt-in. Review по риску/явному запросу; не запускайте panel автоматически. Отчёт: path, relevant coverage/findings и ограничения; commit/push/следующие skills только соответствующая авторизация.

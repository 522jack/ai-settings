---
name: acceptance
description: "Проверить реализацию по существующим AC/test plan или подтвердить исправление по воспроизведению, объединить evidence в acceptance receipt. Применять по запросу функциональной приёмки или high-risk workflow; не заменяет check и не придумывает отсутствующий контракт."
---

# Приёмка

При разовой приёмке сообщите вердикт, проверенные AC или сценарии, доказательства и ограничения в чате. Для передачи или возобновления используйте раздел `## Acceptance` по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Вход: slug, spec/AC/PR/issue/test plan либо bug reproduction. Без источника проверки остановитесь с missing input: write-spec для требований, generate-test-plan для TC, debug artifact для бага. Исследовательский QA без сценария — отдельный manual-tester, не acceptance.

1. Определите project_type (`android|ios|web|desktop|backend-jvm|backend-node|cli|library|generic`), UI surface, ecosystem. Непустой spec.platform приоритетен: первая платформа каноническая, остальные в platforms; override spec/user фиксируется. Не угадывайте generic UI.
2. Прочитайте relevant spec frontmatter (`platform/surfaces/risk_areas/non_functional/acceptance_criteria_ids/design.figma`) и разделы `## Test plan` и `## Debug` общего отчёта и permanent test plan. Для выбора `test_plan_source: receipt|mounted|on-the-fly|absent` прочитайте [source-branches.md](references/source-branches.md). Dизайн без AC разрешает только design review, не VERIFIED функциональности.
3. Android/iOS runtime QA только при явной просьбе пользователя в текущем запросе (`mobile_manual_requested`); UI/spec/risk/test plan не включают его автоматически. Policy SKIPPED не понижает verdict. Для разрешённого runtime UI check сохраните краткий сценарий под `## Acceptance`; bug scenario инвертирует reproduce в expected fixed behavior. Web/desktop instrumentation проверяйте только если контракт задаёт её; mobile также требует opt-in.
4. Переиспользуйте предыдущую проверку только при совпадении code, scope, команды и среды. Учитывайте working tree и доказательства выполнения. Запись саморевью не закрывает проверку, для которой нужна независимость. Upstream FAIL означает минимум PARTIAL, при блокере FAILED.
5. Выберите проверки по [check-selection.md](references/check-selection.md). В одиночном режиме выполните их самостоятельно. В режиме с субагентами запускайте независимые проверки параллельно и используйте [subcheck-prompts.md](references/subcheck-prompts.md) по необходимости. Если проект или пользователь требует независимого исполнителя, а его нет, запишите проверку как заблокированную.
6. Сведите результаты по [aggregation.md](references/aggregation.md). Отсутствующий обязательный результат исключает VERIFIED. Для сохранения состояния используйте [state-and-schema.md](references/state-and-schema.md). В чате укажите вердикт, доказательства и ограничения.

При исправлении или продолжении применяйте [re-verification.md](references/re-verification.md). Локальные авторизованные исправления выполняйте в выбранном режиме. Повторяйте затронутые проверки после изменения, новые тесты добавляйте по явному запросу. Публикация и принятие остаточного риска требуют соответствующей авторизации.

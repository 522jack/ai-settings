---
name: write-tests
description: "Добавить ретроактивные тесты существующего Kotlin/Compose или Swift/SwiftUI кода либо один регрессионный тест конкретного исправления с RED/GREEN evidence. Использовать по явному запросу новых тестов/coverage; документ test plan и запуск уже существующих тестов относятся к другим навыкам."
---

# Написание тестов

Отчётность: прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md`. Наследуйте стабильный task slug; main обновляет только раздел `Tests` в единственном `swarm-report/<task-slug>.md`. Специалисты возвращают краткую receipt в ответе, не создают отчётные файлы. Resume state хранится в том же разделе; legacy artifacts допустимы только для чтения.

Оркестратор делегирует test code platform engineer. Вход: file/type/module scope, optional test plan, slug; `regression-scenario` включает [regression.md](references/regression.md) вместо широкого coverage analysis. Новые тесты opt-in; не добавлять production fixes под видом тестирования.

1. Разрешите target по code index/узкому Explore, прочитайте relevant code/tests/build config. Неоднозначный target → один вопрос. Для normal mode определите uncovered observable contracts и используйте существующий `docs/testplans/` если подходит; большой scope с неясным приоритетом сузьте по рискам вместе с пользователем.
2. Изучите representative tests целевого модуля; для выбора framework/assertions/mocking/async/UI/DI/paths прочитайте [test-infrastructure-discovery.md](references/test-infrastructure-discovery.md). Передайте инженеру Test Infrastructure Summary. Existing module conventions → existing project → platform default; отсутствующая framework dependency требует авторизации до добавления, не вводите новый стиль автоматически. Неизвестный/неподдерживаемый стек сообщите вызывающей стороне.
3. Составьте короткий internal plan: target, cases, type, expected result, doubles/setup. Минимальный test scope, выявляющий реальный сбой; не зеркалить implementation. Regression mode = один case, без coverage audit.
4. Выберите `kotlin-engineer` (logic/data/ViewModel), `compose-developer` (Compose UI), `swift-engineer` (logic/data), `swiftui-developer` (UI). Прочитайте нужный prompt в [agent-prompts.md](references/agent-prompts.md); передайте target paths, summary, cases, style sample и optional plan. Разделите UI/non-UI ownership. Если специалист недоступен, запишите adapter limitation и необходимый fallback, не заявляйте делегирование.
5. Запустите узкий тест и relevant module suite; project required checks сохраняются. Android/iOS emulator/simulator/device run только при explicit mobile runtime QA request. Создание UI test само по себе не разрешает runtime run; отметьте непроверенную поверхность.

Test bug → исправляет тот же engineer, максимум 3 содержательных попытки с recheck после мутации. Production bug → finding, не исправлять в этой задаче. Intentional contract change может требовать обновления existing test; unintentional break исправляется автором изменения; доказанный pre-existing failure сообщается отдельно. Не скрывайте ошибки @Ignore/skip.

Выход: новые test files добавлены в git, краткая coverage/result summary. Production findings только при наличии → подраздел `Tests / Production findings` task report (location, issue, expected, exposing test, severity). Regression output/diagnosis/commit permissions — [regression.md](references/regression.md). Persistent genuine block → конкретные попытки/препятствие/следующий шаг. Без текущей авторизации commit/push не выполнять.

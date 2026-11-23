---
name: write-tests
description: "Добавить ретроактивные тесты существующего Kotlin/Compose или Swift/SwiftUI кода либо один регрессионный тест конкретного исправления с RED/GREEN evidence. Использовать по явному запросу новых тестов/coverage; документ test plan и запуск уже существующих тестов относятся к другим навыкам."
---

# Написание тестов

Для разового запуска достаточно результата в чате или запрошенного документа. Если результат нужен другому этапу или для возобновления, обновите раздел по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Вход: область файлов, типов или модуля, необязательный test plan. В режиме `regression-scenario` применяйте [regression.md](references/regression.md). Новые тесты только по явному запросу.

1. Разрешите target по code index/узкому Explore, прочитайте relevant code/tests/build config. Неоднозначный target → один вопрос. Для normal mode определите uncovered observable contracts и используйте существующий `docs/testplans/` если подходит; большой scope с неясным приоритетом сузьте по рискам вместе с пользователем.
2. Изучите соседние тесты и следуйте соглашениям модуля. При пробеле прочитайте нужную часть [test-infrastructure-discovery.md](references/test-infrastructure-discovery.md). Новую зависимость согласуйте заранее.
3. Составьте короткий internal plan: target, cases, type, expected result, doubles/setup. Минимальный test scope, выявляющий реальный сбой; не зеркалить implementation. Regression mode = один case, без coverage audit.
4. В одиночном режиме напишите тесты самостоятельно. В режиме с субагентами передайте работу подходящему Kotlin/Compose или Swift/SwiftUI исполнителю по [agent-prompts.md](references/agent-prompts.md), сверив наличие профиля. При недоступном делегировании действуйте по правилам адаптера.
5. Запустите узкий тест и relevant module suite; project required checks сохраняются. Android/iOS emulator/simulator/device run только при explicit mobile runtime QA request. Создание UI test само по себе не разрешает runtime run; отметьте непроверенную поверхность.

Test bug → исправляет тот же engineer, максимум 3 содержательных попытки с recheck после мутации. Production bug → finding, не исправлять в этой задаче. Intentional contract change может требовать обновления existing test; unintentional break исправляется автором изменения; доказанный pre-existing failure сообщается отдельно. Не скрывайте ошибки @Ignore/skip.

Добавьте новые тесты в git. Сообщите охваченный контракт, команды, результаты и найденные дефекты продукта. При передаче используйте раздел `Tests` общего отчёта. Для регрессии следуйте [regression.md](references/regression.md).

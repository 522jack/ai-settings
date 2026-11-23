---
name: evaluate-dependency
description: "Оценить новую библиотеку до добавления: fit, поддержка, версия, CVE и лицензия, получить ADOPT/CAUTION/AVOID. Применять к новому кандидату или запросу выбора; обновление существующей версии/BOM и code security audit — другие задачи."
---

# Оценка зависимости

Для разового запуска достаточно результата в чате или запрошенного документа. Если результат нужен другому этапу или для возобновления, обновите раздел по `$HOME/dotfiles/ai/shared/rules/task-report.md`.

Вход: точный coordinate/package, candidate version и purpose/constraints. Уже declared dependency → version/changelog route, не новый adoption audit. Несколько candidates оценивайте пакетом; ambiguous name сначала разрешить по источникам, существенный choice спросить.

Соберите свежие primary evidence: registry/version/stability, repository/release/support/activity/archive, CVEs конкретной версии, license/owner. JVM Maven dependency-intelligence при доступности; иначе equivalent registry/repo/web и limitation. Unknown не угадывать; дата/источник важны, stars/репутация не заменяют support/security evidence.

Сформулируйте ADOPT | ADOPT WITH CAUTION | AVOID с фактами, рисками и альтернативами. В режиме с субагентами привлекайте dependency-evaluator, если нужна независимая экспертиза.

Сообщите вердикт, определяющие факты и риски. Существенный новый риск лицензии или безопасности предъявите до изменения. Реализация добавления требует отдельной авторизации.

Нетривиальный durable decision main сохраняет кратко в разделе `Dependencies` единого `swarm-report/<task-slug>.md`; quick yes/no достаточно чата. Unresolvable coordinate, active unfixed CVE, отсутствующий critical license/access → evidence, next decision; no automatic install, scope expansion или бесконечный retry.

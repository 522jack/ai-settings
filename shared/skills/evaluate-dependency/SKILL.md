---
name: evaluate-dependency
description: "Оценить новую библиотеку до добавления: fit, поддержка, версия, CVE и лицензия, получить ADOPT/CAUTION/AVOID. Применять к новому кандидату или запросу выбора; обновление существующей версии/BOM и code security audit — другие задачи."
---

# Оценка зависимости

Вход: точный coordinate/package, candidate version и purpose/constraints. Уже declared dependency → version/changelog route, не новый adoption audit. Несколько candidates оценивайте пакетом; ambiguous name сначала разрешить по источникам, существенный choice спросить.

Соберите свежие primary evidence: registry/version/stability, repository/release/support/activity/archive, CVEs конкретной версии, license/owner. JVM Maven dependency-intelligence при доступности; иначе equivalent registry/repo/web и limitation. Unknown не угадывать; дата/источник важны, stars/репутация не заменяют support/security evidence.

Независимый dependency-evaluator получает candidate/purpose+raw signals и возвращает ADOPT | ADOPT WITH CAUTION | AVOID, определяющие факты/риски/alternatives. Если профиль недоступен — честный adapter limitation, не phantom delegation. Сомнительное reviewer утверждение проверьте evidence, не принимайте его слепо; повторяйте affected lookup/review только при новом факте.

Chat: verdict, 2–4 главных сигнала и риск. Adoption ещё не решён → concrete варианты adopt/caution/alternative/reject; уже разрешённое выбранное addition не требует нового общего permission gate, но новый license/security blocker предъявите до него. Сам skill не меняет build-файлы, добавление выполняет специалист в authorised scope.

Нетривиальный durable decision можно сохранить `swarm-report/evaluate-dependency-<slug>.md`; quick yes/no достаточно чата. Unresolvable coordinate, active unfixed CVE, отсутствующий critical license/access → evidence, next decision; no automatic install, scope expansion или бесконечный retry.

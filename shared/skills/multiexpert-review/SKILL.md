---
name: multiexpert-review
description: "Проверить документ плана, spec или test plan независимой экспертной панелью PoLL и объединить findings/разногласия. Применять при явном panel review или high-risk document review; для обычного малого изменения достаточно одного independent semantic review, code review — отдельно."
---

# Мультиэкспертная проверка

Вход: artifact file/inline/активный plan, optional profile/slug/roster. Прочитайте сам артефакт, затем [profiles/README.md](profiles/README.md) для detection precedence/negative fields/inventory и **только выбранный** профиль. Unknown explicit profile не fallback. Profile locked на первом cycle; semantic criteria/roster/verdict alphabet/source routing/receipt определяет он.

Механизм сохраняет неизменными независимость, общий prompt/output, aggregation и max 3 cycles; profiles не переопределяют их. Прочитайте [mechanism.md](references/mechanism.md) при запуске panel для state/prompt/aggregation/routing/errors. Не загружайте все profiles.

Выберите реально доступных reviewers из profile roster с actual triggers; не запускайте speculative experts. Explicit panel сохраняет требуемый profile состав. Risk-based workflow не превращает малую задачу в panel автоматически: ordinary plan/spec может иметь single independent review вне этого навыка. Указанные пользователем reviewers/авторизация действуют; повторной confirmation состава не нужно. Missing required perspective сообщите явно.

Запустите независимых reviewers параллельно. Non-negotiables всегда blocker, одинаковый artifact всем, никаких reviews между агентами. Примените confidence/domain weighting и явное представление противоречий. Fix-loop меняет только разрешённый artifact, rereview после фактического изменения; reuse конкретного состояния допустим, timer/failure-only rerun нет. После 3 содержательных cycles unresolved genuine blocker → evidence+escalation.

Выход: main сохраняет краткий consensus/важные findings/uncertainties и state completion в `## Document review` общего `swarm-report/<task-slug>.md` по `$HOME/dotfiles/ai/shared/rules/task-report.md`; profile receipt обновляет его целевой раздел/permanent документ. Task-slug наследуется и отличается от artifact slug при необходимости. Не расширять scope до реализации, внешних сообщений, новых tests/commits. PASS завершает document review, не означает авторизацию выполнения/публикации.

---
name: specialist-routing
description: "Выбрать профиль специалиста harness для реализации, исследования или проверки и передать scoped task с receipt. Применять при product edit по правилу делегирования или реально необходимой экспертизе; выбирает минимальный набор ролей, не полный review fan-out."
metadata:
  short-description: Направление работы над функциональностью специалистам harness
---

# Маршрутизация к специалистам

Отчётность: прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md`. Наследуйте стабильный task slug; main обновляет только раздел `Delegation` в единственном `swarm-report/<task-slug>.md`. Специалисты возвращают краткую receipt в ответе, не создают отчётные файлы. Resume state хранится в том же разделе; legacy artifacts допустимы только для чтения.

Главная сессия оркестрирует: продуктовый код/config/tests и долгие проверки выполняет специалист; orienting reads/process/config files в разрешённой области остаются у main. Явное user «сделай сам» действует на текущую задачу.

1. Определите task phase/stack/risk; выберите минимальные реально доступные `~/dotfiles/ai/shared/agents/` profiles. Implementation → stack engineer; search/debug → Explore/debugging; review → code-reviewer и only triggered domain expert; runtime → manual-tester, mobile только explicit opt-in.
2. Прочитайте выбранные profiles, не каталог всех агентов. Delegation packet: exact task/AC, owned paths/modules, profile paths, applicable restrictions, relevant source/context, стабильный task slug, expected receipt/verdict в ответе (без записи отчёта специалистом). Независимое review не передавайте автору изменения; непересекающиеся задачи можно parallel.
3. Specialist сообщает actually used profiles, read/changed surfaces, commands/evidence, PASS|PASS_WITH_NOTES|BLOCKED и risks. Missing runtime specialist → ADAPTER_LIMITATION, не заявляйте применение phantom profile.
4. Синтезируйте receipt: Required/Applied profiles, Delegation runtime, Verdicts, Verification state+results, Open risks. Main обновляет раздел `Delegation` в `swarm-report/<task-slug>.md`; отдельные receipts/state/report files не создавать.

Risk gate: mechanical targeted existing checks; ordinary + one independent semantic review; high-risk auth/security/data loss/schema/concurrency/public API/CLI/architecture + finalize/acceptance. Явные skills/project required checks/hooks/CI сохраняются. Reuse лишь конкретное exact code+scope+env состояние; new tests и Android/iOS runtime QA не добавляются автоматически. Делегирование не расширяет scope и external permissions.

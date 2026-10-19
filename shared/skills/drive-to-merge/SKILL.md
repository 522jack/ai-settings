---
name: drive-to-merge
description: "Довести существующий PR/MR до слияния: следить за CI/reviews, делегировать scoped fixes и проверить merge gates. Применять при явном поручении вести или слить PR; создание PR и новая функциональность относятся к другим навыкам."
---

# Доведение PR до слияния

Отчётность: прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md`. Наследуйте стабильный task slug; main обновляет только раздел `Drive to Merge` в единственном `swarm-report/<task-slug>.md`. Специалисты возвращают краткую receipt в ответе, не создают отчётные файлы. Resume state хранится в том же разделе; legacy artifacts допустимы только для чтения.

Scope: existing PR/MR, CI/review fixes, явно разрешённые push/reply/re-request/merge. Не вводите новые features и follow-up issues. Modes default — конкретные действия/merge подтверждаются лишь если их авторизация ещё отсутствует; `--auto`/«без подтверждений» — разрешённые действия автономно; `--dry-run` — один read-only analysis без mutations/messages. User stop сохраняется.

1. [setup.md](references/setup.md) читайте при входе/resume: actual host/CLI/auth/PR metadata, branch/permissions и state. Closed/merged → terminal. Mode/authorization из текущей сессии приоритетнее legacy state.
2. Каждый round получите fresh PR status/CI/review/mergeability. Постройте полный branch diff при первом review, delta далее; классифицируйте comments по full change, не одному hunk. Для CI failure читайте [ci.md](references/ci.md), для новых comments [reviews.md](references/reviews.md). Same unchanged state не запускает code checks заново.
3. Покажите reviewable приоритизированные решения: concrete fix/delegation/reply text, author/location/impact и blockers. Existing authorisation → действуйте, не спрашивайте повторно approve. Genuine blocking disagreement/scope change/access gap → stop с evidence даже auto. Dry-run завершает здесь.
4. При authorised mutation читайте [delegation.md](references/delegation.md): product edits только specialist, test additions opt-in. После code/scope/env mutation relevant checks и risk gate (ordinary independent review; high-risk finalize/acceptance); required hooks/CI не обходить. Commit/push только разрешённой branch/current scope. Responses use file/stdin sanitization and thread ownership recheck; reviewer suggestions проверяйте, не исполняйте слепо. Не добавляйте косметические NIT edits вне необходимого diff. Re-request только authorised lifecycle communications.
5. Если base изменился/rebase нужен, [merge.md](references/merge.md); сохраняйте пользовательское дерево, conflict proof, force только --force-with-lease/--force-if-includes когда разрешён. После изменения code state устаревшие approvals/checks не reuse.
6. Waiting CI/reviewer → [polling.md](references/polling.md). Используйте доступный nonblocking scheduler и saved mode; если нет ScheduleWakeup, bounded one-round fallback с state/next wake condition, не busy-wait. Persistent unchanged block/three same CI signatures/max polls → concrete escalation, не бесконечная отправка повторов.
7. Для merge читайте [merge.md](references/merge.md), fresh exact-head CI/approval/mergeability/branch-policy gates. Уже явно authorised merge или auto → выполнить после gates; иначе user решение по готовому конкретному PR. Draft promotion разрешена только lifecycle scope, не workaround blocker. Нельзя принять unpassed required CI за риск.

State+chat result: merged либо blocked с concrete cause/evidence/next action; при user stop остановиться. Указывайте partial effects отправленных сообщений/commits. Не скрывайте missing tool/runtime permissions и не заменяйте инфраструктурный fail отсутствием PR.

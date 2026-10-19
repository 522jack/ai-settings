---
name: finalize
description: "Выполнить полный цикл независимого ревью качества и узких исправлений текущего diff. Применять по запросу finalize/подготовки к ревью или для high-risk workflow; reviewers выбираются по риску. Механические проверки и функциональная acceptance остаются отдельными навыками."
---

# Финализация

Явный finalize сохраняет полный цикл: однократный deep scan → independent semantic review → scoped simplification → применимые toolkit/domain reviews → fixes/rechecks. Не является автоматическим gate каждого малого изменения: ordinary workflow использует targeted checks и одно независимое semantic review; high-risk (auth/security/data loss/schema/concurrency/public API/CLI/architecture) — finalize + acceptance.

Вход: slug, task/AC, текущая ветка (не переключайте), optional `docs/plans/<slug>/plan.md`/legacy `<slug>-plan.md` или `<slug>-debug.md`. Определите remote default branch, merge-base; материализуйте `swarm-report/<slug>-diff.txt`, включая staged/unstaged/relevant untracked изменения. Зафиксируйте проверяемое состояние code+scope+environment; чужие изменения не присваивайте себе.

Флаги: `--max-rounds N` (≥1, default 3); `--allow-warn` (совместимость, WARN не блокирует); `--deep-scan-effort`, `--skip-deep-scan` → [deep-scan.md](references/deep-scan.md). `--skip-experts` и `--skip-security-review REASON` — явно запрошенные skips с записью причины; не скрывают BLOCK. `--coverage-audit` только после explicit tests/coverage request.

## Цикл

0. Прочитайте [deep-scan.md](references/deep-scan.md) при применимом scan; выполните один раз, дедуплицируйте с A.
1. **A:** независимый `code-reviewer` получает точную задачу, применимые Non-negotiables, context и полный diff. Не пропускайте A молча. Нет доступного reviewer → adapter limitation и escalation.
2. **B:** проход упрощения runtime (`/simplify` или специалист) только в scope diff, без архитектурного редизайна/косметики. Изменения продуктового кода выполняет специалист; runtime auto-edit не отменяет запрет главной сессии. Не делайте лишний рефакторинг ради прохода. При failed simplification отмените только собственную правку, сохранив пользовательское дерево, запишите B reverted; не повторяйте B в том же раунде.
3. **C/D:** определите реальные risk triggers; прочитайте только применимые разделы [reviewers.md](references/reviewers.md), запустите выбранных независимых reviewers. Нет trigger — skip, не фиксированные «три всегда».
4. Исправления BLOCK делегируйте автору/инженеру, только в scope; обязательный adjacent file обновите. New tests только opt-in. После фактической мутации code/scope/env выполните соответствующие проверки; вызов check исполняет required project checks. Read-only переход фазы повторной проверки не требует. Reuse допустим только для точного состояния с конкретным artifact.

BLOCK: critical/major confidence ≥75; Non-negotiable violation всегда BLOCK независимо от confidence. Minor ≥50 — NIT, без авто исправления. Critical security confidence 50 → verify/BLOCK. Не понижайте finding молча.

После failed fix/check допускается одна узкая попытка исправления; не сработала — отмените только собственный patch, исходный finding остаётся BLOCK. Повторите affected review после реальной правки, не все роли по таймеру. PASS при отсутствии BLOCK и зелёных required checks; WARN/NIT перечислить. Persistent genuine BLOCK после default 3 раундов → ESCALATE, с доказательствами попыток. Если ошибка требует нового scope/architecture/access — сообщите сразу, не расширяйте задачу.

При выходе прочитайте [reports.md](references/reports.md), запишите detailed finalize + terse quality receipt. Не коммитьте/пушьте без текущей авторизации, не обходите hooks/CI; не переключайте ветку и не удаляйте пользовательские изменения.

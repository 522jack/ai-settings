---
name: write-plan
description: "Сохранить план реализации уже принятого изменения: technical approach, tasks и проверяемые условия готовности в docs/plans. Использовать по запросу постоянного плана; выбор подхода относится к research, контракт требований — к write-spec. Объём независимого ревью определяется риском."
---

# План реализации

Отчётность: прочитайте `$HOME/dotfiles/ai/shared/rules/task-report.md`. Наследуйте стабильный task slug; main обновляет только раздел `Plan` в единственном `swarm-report/<task-slug>.md`. Специалисты возвращают краткую receipt в ответе, не создают отчётные файлы. Resume state хранится в том же разделе; legacy artifacts допустимы только для чтения. Существующий artifact slug документов может отличаться: сохраните путь и укажите сопоставление с task slug в отчёте.

Вход: принятое изменение, constraints, optional `--from-spec PATH`; не решённый выбор → research, missing complex contract → write-spec. Наследуйте стабильный task slug; только при отсутствии задайте caller/task/branch kebab-case без prefix; найденный spec не меняет slug.

Modes: default сохраняет reviewed plan без human approval pause; `--interactive` добавляет один явно запрошенный checkpoint; `--quick` облегчает bounded investigation/review, не skips mandatory checks. Headless настоящую unresolved design fork передаёт caller, не блокируется question tool.

1. Read-only исследование нужных модулей через Explore; architecture только при границах/layers/API, docs только unfamiliar external API. Не консорциум всегда. Раздел `Plan` task report хранит краткие scope/evidence/progress и resume cursor. Не спрашивайте то, что code/docs отвечают.
2. Для записи прочитайте [plan-template.md](references/plan-template.md) и [output-layout.md](references/output-layout.md). Постоянные `docs/plans/<slug>/plan.md`, `tasks.md`, `progress.md`; source spec только link+AC IDs, не копия требований. Plan содержит paths/types/rationale/risk/out-of-scope и mandatory Verification & Sources; tasks T-N имеют dependencies/affected files/checkable acceptance+check; progress checklist+learnings.
3. Verification risk-based: mechanical targeted existing checks; ordinary + independent semantic review; high-risk + full finalize/acceptance после checks. Required project checks/hooks/CI не отключаются. New tests/infra и mobile emulator/simulator/device QA только explicit request; иначе назвать runtime limitation, не считать policy skip blocker.
4. Прочитайте [review-loop.md](references/review-loop.md): independent reviewer для bounded ordinary plan, panel для high-risk; hostile implementer лишь при значимых remaining execution gaps. Fix unresolved findings в plan/tasks согласованно; только genuine persistent block после max 3 содержательных cycles → escalate/draft с evidence.
5. PASS либо CONDITIONAL без blocking issues → status approved, review_verdict обновлён, state done. Default не требует confirmation; --interactive checkpoint до approved. User design choice не выдумывать: в interactive chat, headless blocking Open Question+escalate.

Новые постоянные файлы добавьте в git; commit/push только текущая explicit authorization и разрешённая ветка. Handoff: путь, verdict, задачи/verification/риски, первый шаг. Запрос «составь план» сам по себе не разрешает product implementation; если она уже входит в задачу — продолжайте через специалиста. Progress ведёт исполнитель, не запускать downstream skills автоматически без scope/показаний.

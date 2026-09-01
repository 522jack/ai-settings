Referenced from: `plugins/developer-workflow/skills/generate-test-plan/SKILL.md` (§Receipt).

# Формат receipt плана тестирования

Когда этот навык вызван с явным аргументом `slug`, помимо постоянного документа создайте
**receipt** в `swarm-report/<slug>-test-plan.md`, который downstream-потребители
(`multiexpert-review`, `acceptance`) смогут читать для gate на основе receipt.

Постоянный файл остаётся источником истины. Receipt — это метаданные и указатель.

Receipt format:

```markdown
---
name: test-plan-receipt
description: Артефакт test plan для <slug>
slug: <slug>
type: test-plan-receipt
status: Draft
permanent_path: docs/testplans/<slug>-test-plan.md
source_spec: <path to spec if any, or "inline spec">
review_verdict: pending
review_warnings: []            # populated by multiexpert-review on WARN — list of short strings
review_blockers: []            # populated by multiexpert-review on FAIL — list of short strings
phase_coverage: [Phase 1, Phase 2, ...]
platform: []                   # optional; inherited from the source spec's `platform:` field when present.
                               # Drives platform-aware TC generation and downstream acceptance checks (e.g.,
                               # skip mobile-only TCs on a backend-only target). Leave empty when the spec
                               # did not set it; acceptance falls back to its project-type heuristic.
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Receipt плана тестирования: <slug>

**Status:** <status>
**Постоянный артефакт:** [`docs/testplans/<slug>-test-plan.md`](../docs/testplans/<slug>-test-plan.md)
**Исходный spec:** <путь или описание>
**Вердикт ревью:** <verdict>
```

## Соглашения о полях

- `status`: `Draft` сразу после генерации; `Ready` после возврата PASS/WARN от multiexpert-review;
  `Approved`, когда пользователь явно утвердил результат; `Mounted`, когда авторский постоянный
  файл принят без повторной генерации.
- `review_verdict`: `pending` at creation; updated by `multiexpert-review` to
  `PASS | WARN | FAIL`; `skipped` on mount (no review occurs).
- `review_warnings` / `review_blockers`: массивы коротких строк, заполненные `multiexpert-review`.
  `review_warnings` is written on WARN verdicts (items d or e of the checklist violated —
  non-blocking); `review_blockers` is written on FAIL (items a, b, or c violated —
  blocks transition to Implement). Both remain empty arrays on PASS / pending / skipped.
  Frontmatter is the single source of truth for review findings — the receipt body does
  not re-list them, keeping downstream YAML parsers authoritative.
- `phase_coverage`: список меток фаз, присутствующих в постоянном файле. Пустой список, если
  функциональность не разделена на фазы.
- `created` / `updated`: даты ISO (`YYYY-MM-DD`). `updated` должен изменяться при изменении
  постоянного файла или любого поля receipt.
- Относительный путь в ссылке Markdown предполагает стандартную структуру соседних каталогов
  `swarm-report/` ↔ `docs/` в корне репозитория.

## Самостоятельный вызов без slug

Когда пользователь напрямую вызывает этот навык (например, «создай test plan для X») без
явного `slug`, receipt **не создаётся**. Постоянный файл всё равно сохраняется под каноническим
именем на основе slug:

- Permanent file generated at `docs/testplans/<slug>-test-plan.md`, where `<slug>` is
  either provided inline or derived from the feature name per the Slug resolution rules
  in SKILL.md. If the plan may later be consumed by `acceptance` (Branch 2 mount), pick
  the eventual slug at creation time so the file is deterministically mountable without
  renaming.
- No `swarm-report/<slug>-test-plan.md` receipt is written.
- No `phase_coverage` or receipt metadata tracked elsewhere.

Самостоятельные вызовы продолжают работать: имя на основе slug — единственный канонический
артефакт. Существующие `docs/testplans/*-test-plan.md`, созданные до этого соглашения, не
переносятся автоматически — люди могут их читать, но mount-логика сопоставляет только точный
путь `<slug>-test-plan.md`.

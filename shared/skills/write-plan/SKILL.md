---
name: write-plan
description: "Создавайте коммитнутый документ плана реализации — автономную замену встроенному plan mode. Исследуйте кодовую базу только для чтения, записывайте постоянный план для ревью (docs/plans/<slug>/plan.md + tasks.md) вместо эфемерного запроса подтверждения, затем запускайте ОБЯЗАТЕЛЬНЫЙ цикл multiexpert-review и исправляйте план до прохождения. По умолчанию паузы на подтверждение человеком нет, поэтому агент может спланировать и выполнить работу от начала до конца; checkpoint включается через --interactive. Используйте при запросах «спланируй это», «составь план», «как это построить», «спланируй реализацию», «разбей на задачи», «спланируй до написания кода» для УЖЕ ПРИНЯТОГО изменения. Предпочитайте этот навык встроенному plan mode, когда план нужно сохранить, проверить экспертами или выполнить автономно. НЕ используйте для решения, ЧТО создавать, или сравнения вариантов (используйте research), написания контракта функциональности/критериев приёмки (используйте write-spec) или тривиальных однострочных правок (просто выполните их)."
---

# План

Превратите уже принятое изменение в **постоянный план реализации, проверенный экспертами**, который
агент может выполнить от начала до конца без остановки для утверждения. Это автономная замена
built-in plan mode: the plan is a file on disk (not an ephemeral `ExitPlanMode` prompt), so it can
be version-controlled, reviewed by a multiexpert panel, referenced by `create-pr` / `finalize`, and
возобновляемая между сессиями.

**Роль:** Tech Lead, переводящий *что* в *как*. Решение уже принято (пользователем, spec или
предыдущим исследованием); этот навык создаёт технический подход, упорядоченный список задач и
приёмку каждой задачи, делающую автономное выполнение безопасным.

**Место в процессе:** `write-spec` отвечает, *что* мы создаём (требования + критерии приёмки). `plan`
отвечает, *как* (дизайн + упорядоченные задачи). Если spec существует, план **ссылается** на него и
никогда не дублирует требования. Если spec нет (небольшое изменение), план работает напрямую с описанием задачи.

**Основные принципы:**

1. **План — документ, а не запрос.** Сохраните его до того, как он понадобится. Эфемерные
   plans cannot be reviewed, diffed, or resumed — that is the limitation this skill removes.
2. **Ревью заменяет утверждение.** Quality gate — обязательный цикл multiexpert-review, а не
   human pause. The default flow is autonomous; a human checkpoint is opt-in (`--interactive`).
3. **У каждой задачи есть проверяемое условие готовности.** Задачи содержат явную приёмку (Given/When/Then
   or "THE SYSTEM SHALL …"). Autonomy is only safe when "done" is checkable, not approved.

### Headless mode (контракт автономности)

`AskUserQuestion` используется **только** если передан `--interactive` или пользователь активно присутствует.
In a headless / non-interactive run, never block on it: surface a genuine design fork to the caller
instead. Before the plan file exists (Phase 1), surface it as a blocking hand-off; after the plan
exists, record it as a `[blocking]` Open Question, set `review_verdict: escalate`, and stop. This
single rule governs every later phase — phases below reference it rather than restating it.

---

## Флаги

| Флаг | Эффект |
|---|---|
| (default) | Autonomous. Investigate → write plan → mandatory review loop → on PASS/CONDITIONAL, hand off to implementation with no human pause. |
| `--interactive` | Add ONE human confirmation checkpoint after the review passes (Phase 4.2). The explicit, opt-in replacement for the `ExitPlanMode` gate. |
| `--quick` | Trivial, well-bounded change: lighter investigation, single-reviewer review (`allow_single_reviewer`). Review is never skipped entirely — a plan without review is the failure mode this skill exists to prevent. |
| `--from-spec <path>` | Anchor the plan to a specific spec instead of auto-discovering one. |

---

## Фаза 0: разбор входа и настройка

### 0.1 Отделите решение от дизайна

Считается, что *что* уже решено. Извлеките:

- **The decided change** — what we are building (from the request, a spec, or research).
- **Source of truth** — auto-discover a spec: newest `docs/specs/*-<slug>.md` whose slug or title
  matches the candidate slug. If `--from-spec <path>` was passed, use that path directly and skip
  auto-discovery (verify the path exists; if not, stop and report). Record the path; the plan
  references it, never restates its AC. The slug is always the branch/task-derived candidate — do
  not parse a slug out of the `--from-spec` filename.
- **Known constraints** — platform, libraries, "no new deps", deadlines.

Если запрос на самом деле *не решён* («использовать X или Y?», «это реализуемо?»), ОСТАНОВИТЕСЬ и
redirect to `research`. If it is a feature contract that has not been written ("what exactly are the
requirements?"), redirect to `write-spec`. This skill plans execution; it does not decide scope.

Создайте slug в kebab-case (`offline-mode`, `push-notifications`). Удалите стандартные префиксы веток
(`feature/`, `fix/`, `chore/`, `claude/`, `hotfix/`). This candidate slug is used consistently
for all output paths (`docs/plans/<slug>/`). If a spec exists under `docs/specs/` whose slug or
title matches the candidate slug, reference it — but do not change the slug; plan, create-pr, and
finalize all resolve the same `docs/plans/<slug>/` path.

### 0.2 Артефакты

Three committed files under `docs/plans/<slug>/` (`plan.md`, `tasks.md`, `progress.md`) plus the
gitignored operational `./swarm-report/plan-<slug>-state.md` (deleted after). `docs/plans/` is
deliberately alongside `docs/specs/` (spec = *what*, plan = *how*); plans live in git because their
value is being reviewable in the PR and resumable later. See
[`references/output-layout.md`](references/output-layout.md) for the full file/lifetime/purpose
table.

---

## Фаза 1: исследование (только чтение)

Как и plan mode, планирование начинается с исследования только для чтения — но результаты сохраняются,
а не отбрасываются. Запустите исследование **одним сообщением** (параллельно), соразмерно изменению:

- **Codebase (Explore)** — always. Existing code, patterns, module boundaries, the exact files and
  symbols this change touches, test infrastructure, related TODOs.
- **Architecture Expert** — when the change adds a module, shifts dependency direction, introduces
  an abstraction, or crosses layers.
- **Web / docs** — only for unfamiliar external APIs, protocols, or non-trivial algorithms the
  codebase doesn't already demonstrate.

Записывайте результаты в `./swarm-report/plan-<slug>-state.md` по мере завершения работы агентов. Не спрашивайте пользователя
anything that investigation can answer. If a genuine design fork appears that investigation cannot
resolve, surface it with `AskUserQuestion` (each option with a recommended pick) — never park
questions in the plan file. The plan file does not exist yet at this phase, so per the **Headless
mode** contract above, a headless run surfaces the blocking fork to the caller (nothing to record
in-file).

`--quick`: пропустите consortium; достаточно одного inline-прохода Explore.

---

## Фаза 2: напишите план

Напишите `plan.md` и `tasks.md` для читателя, который является реализующим агентом и не имеет
дополнительного контекста. Каждое решение должно быть явным и обоснованным; у каждой задачи должно быть
проверяемое условие готовности.

Скопируйте шаблоны из [`references/plan-template.md`](references/plan-template.md) буквально и
заполните каждый placeholder. Структура:

- **`plan.md`** — YAML frontmatter (`type: plan`, `slug`, `date`, `status: draft`, `spec:` link or
  `none`, `risk_areas`, `review_verdict: pending`) + body: Context & Decision, Technical Approach,
  Affected Modules & Files (table: path · change type · note), Decisions Made (with rationale),
  Risks & Mitigations, **Verification & Sources**, Out of Scope, Open Questions (tagged blocking /
  non-blocking). The **Verification & Sources** section is mandatory and must name the source(s) of
  truth that define "done" (spec / test-plan / before-state baseline / Figma / debug-repro),
  assert each is collected and **sufficient** to verify the finished change, and state the testing
  strategy (pyramid levels L0–L5 that apply). For a migration or "shouldn't change behavior" task the
  baseline is captured **before** implementation, not promised — a plan that only names a source
  without confirming it exists and suffices is not done (qa-and-testing §6, §0; task-types
  § Before-state baseline).
- **`tasks.md`** — ordered list `T-N`, each with: short title, dependencies (`after: T-…`), the
  files it touches, and **acceptance** in Given/When/Then or "THE SYSTEM SHALL …" form, plus the
  check that proves it (test name, grep, build target). Tasks are small enough to implement and
  verify in one focused pass.
- **`progress.md`** — initialize with every `T-N` as an unchecked box and an empty Learnings log.

План должен ссылаться на критерии приёмки spec, а не повторять их (указывайте ID `AC-N`); приёмка в
`tasks.md` — это проверка на *уровне реализации*, что каждый AC выполнен.

---

## Фаза 3: обязательный цикл ревью

Ревью — gate, заменяющий утверждение человеком. Оно **обязательно** (в этом весь
point — an unreviewed plan is low quality and must be sent back for rework until it meets the bar).

**Автор против скептика.** Агент, написавший план (фаза 2), заинтересован быстро пройти gate;
quickly; the critic is deliberately separate and adversarial. The reviewers act as a strict-but-fair
red team applying an anti-gaming rubric (reject hand-waving, demand `file:line` evidence, demand
checkable acceptance, hunt missing failure modes) — they look for what is *wrong*, not for reasons
to approve. See [`references/review-loop.md`](references/review-loop.md) for the writer/critic
rationale and the rubric.

Это повторяет фазу 4.3 `write-spec`: вызовите `multiexpert-review` **inline** с явной подсказкой профиля.
План уже является файлом (`docs/plans/<slug>/plan.md`), поэтому движок классифицирует источник как
`file` и редактирует план на месте при FAIL/CONDITIONAL.

Prepend to the review args:

```
profile: implementation-plan
---
docs/plans/<slug>/plan.md
```

(Why the hint and the full loop script: see
[`references/review-loop.md`](references/review-loop.md).)

The `implementation-plan` profile selects 2–3 reviewers by tech-match from the plan content
(e.g. `security-expert` only when the plan touches auth / tokens / user data; `architecture-expert`
only on new modules / dependency-direction / public-API changes). `--quick` permits a single
reviewer.

**Цикл:** запустите цикл ревью — предел и действия по каждому вердикту описаны в
[`references/review-loop.md`](references/review-loop.md). PASS → proceed to Phase 4;
CONDITIONAL/FAIL → the engine edits the plan and re-reviews until the cap.

**Эскалация (единственный автономный STOP):** если после предела остаются блокеры, установите `review_verdict: escalate`, запишите
the unresolved blockers into `## Open Questions` (tagged blocking), retire the state file (see Phase
4.3), and surface them — only for genuine blockers, never for routine polish.

---

## Фаза 3.5: соперничающий проход Red Team

Рецензенты оценивают по критериям; *реализующий агент* обнаруживает пропуски — это другой режим
modes. After the panel passes, run **one** Agent (general-purpose, sonnet) as a hostile implementer
that tries to build from the plan and reports every gap it would hit; feeding findings back is
subject to the **Headless mode** contract above. The full agent brief and per-item handling live in
[`references/review-loop.md`](references/review-loop.md) §Phase 3.5.

Пропускайте только с `--quick` для небольшого, чётко ограниченного изменения без рискованных задач.

---

## Фаза 4: gate

### 4.1 По умолчанию — автономно

On PASS/CONDITIONAL, flip `plan.md` `status` to `approved`, ensure `tasks.md` and `progress.md` are
written, retire the state file, and hand off to implementation **without pausing**. Confirm in one
sentence with the plan path and the first task. This is full autonomy: no `ExitPlanMode`, no
approval prompt.

### 4.2 `--interactive` — checkpoint по запросу

Only when `--interactive` was passed: present a compact summary (plan path, the 3–5 key decisions,
the task count, the review verdict, any non-blocking open questions) and ask for a single go / adjust
confirmation before flipping to `approved`. This is the deliberate, user-requested replacement for
the plan-mode approval gate — present only, never the default.

### 4.3 Эскалация

On `review_verdict: escalate`, do not flip to `approved`. Retire (delete) the state file
`./swarm-report/plan-<slug>-state.md`, surface the blocking open questions, and stop — exactly as
`finalize` escalates on unresolved BLOCKs.

---

## Фаза 5: передача

Keep `progress.md` as the live execution ledger: as each `T-N` completes, check its box and append a
one-line learning. Suggest the next step (implement the tasks; then `/write-tests`, `/check`,
`/finalize`, `/acceptance`).

See [`references/output-layout.md`](references/output-layout.md) for path conventions, the
confirmation message, gitignore notes, and the hand-off rules (do-not-auto-invoke, the toolbox model,
and the Phase 3 / Phase 3.5 built-in exceptions).

---

## Красные флаги / условия STOP

- **Undecided scope** — the request is "which approach?" or "is this feasible?". Redirect to
  `research`; do not plan an undecided change.
- **Missing contract** — a complex feature with no acceptance criteria anywhere. Recommend
  `write-spec` first; a plan without a target is guesswork.
- **Fundamental contradiction** — a constraint makes the change impossible, or two decided
  requirements conflict. Surface it; do not invent a workaround.
- **Missing critical access** — the change needs systems / APIs / credentials not available. List
  what's needed and stop.

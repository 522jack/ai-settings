---
name: acceptance
description: >
  Проверяйте реализацию по её spec (функциональность) или подтверждайте, что ошибка больше не воспроизводится
  (исправление ошибки). Запускайте параллельные проверки и объединяйте вердикты в один receipt.
  Triggers: "test this", "verify against spec",
  "QA the implementation", "run the test plan", "validate acceptance criteria",
  "verify the PR", "verify the fix", "confirm bug is gone", "acceptance",
  "verify this", "test this".
---

# Приёмка

Навык-хореограф. Определяет тип проекта, подтверждает наличие источника проверки, запускает параллельные проверки специализированными агентами и объединяет вердикты в один receipt. Acceptance выполняет существующий контракт проверки — не придумывает проверки. Нет контракта → остановиться и предложить правильный upstream-навык.

Процедурные детали находятся в reference-файлах, загружаемых только при запуске соответствующей фазы. SKILL.md остаётся стабильным контрактом оркестрации.

| Файл | Содержание |
|---|---|
| [`references/source-branches.md`](references/source-branches.md) | Обработка frontmatter спецификации на шаге 1 и четыре ветви `test_plan_source` (receipt / mounted / on-the-fly / absent), переопределения mount-receipt |
| [`references/subcheck-prompts.md`](references/subcheck-prompts.md) | Контракты запросов для агентов на шагах 3.1–3.10 — `manual-tester`, `code-reviewer`, build smoke, `business-analyst`, `ux-expert`, `security-expert`, `performance-expert`, `architecture-expert`, `build-engineer`, `devops-expert` |
| [`references/aggregation.md`](references/aggregation.md) | Правила агрегации PoLL на шаге 4, таблица Aggregated Status, полный шаблон receipt, маршрутизация следующих этапов |
| [`references/re-verification.md`](references/re-verification.md) | Таблица решений Re-verification Loop по `diff_hash`, переопределения при изменении spec/test-plan, правила обратной совместимости |

---

## Терминология

Канонические значения, используемые в этом навыке. `create-pr` и downstream-потребители читают их из receipt.

- **`project_type`** — одно из значений: `android`, `ios`, `web`, `desktop`, `backend-jvm`,
  `backend-node`, `cli`, `library`, `generic`.
- **`has_ui_surface`** — логическое значение, выведенное из `project_type`. True для `android`, `ios`,
  `web`, `desktop`. False в остальных случаях (`generic` → спросить пользователя).
- **`ecosystem`** — стек сборки: `gradle`, `node`, `rust`, `go`, `python`, `xcode`. Используется
  только для выбора команды build smoke; ортогонален `project_type`.
- **Вердикт отдельной проверки** — каждая под-проверка сообщает `PASS | WARN | FAIL | SKIPPED`, а также
  `severity` (`critical | major | minor`), `confidence` (`high | medium | low`) и
  `domain_relevance` (`high | medium | low`) для агрегации.
- **Критичность ошибки** — `P0 | P1 | P2 | P3`. Не изменена по сравнению с предыдущей схемой receipt.
- **Aggregated Status** — `VERIFIED | FAILED | PARTIAL`. Вычисляется; таблица находится в
  `references/aggregation.md` §Aggregated Status.

---

## Шаг 0: определите тип проекта

Определите по build-файлам, манифестам и структуре исходников: Android (`AndroidManifest.xml`, `build.gradle*` с `com.android.application`), iOS (`*.xcodeproj`, `Package.swift` с iOS targets, `Info.plist`), web (`package.json` с фреймворком для браузера), desktop (Compose Desktop, Tauri, Electron), backend (Spring/Ktor/Express без UI), CLI / library (без UI-поверхности). При неоднозначности спросите пользователя. Вывод: `project_type`, `has_ui_surface`, `ecosystem`.

**Политика переопределения.** Если список `platform:` во frontmatter spec непуст, **побеждает spec** —
возьмите первое значение платформы как канонический `project_type`. Если список содержит более
одного элемента, отдельно запишите полный список как `platforms: [...]` в receipt; не изобретайте
`multi-platform` как значение `project_type`. Запишите в receipt `project_type_override: spec`.
Если пользователь исправляет результат определения во время запуска, запишите
`project_type_override: user`.

Чтение файлов шага 0 и шага 1 не пересекается. МОЖНО выполнить оба набора одним пакетным набором Read,
чтобы избежать последовательных round-trip.

---

## Шаг 1: соберите входные данные

Для acceptance нужен хотя бы один источник проверки. Если его нет, шаг 1.5 останавливает процесс.

Прочитайте источники спецификации (Figma, PRD, список AC, описание PR, issue) и загрузите frontmatter
спецификации (`platform`, `surfaces`, `risk_areas`, `non_functional`,
`acceptance_criteria_ids`, `design.figma`).

Проверьте артефакты одним пакетным набором вызовов Read:

- `swarm-report/<slug>-test-plan.md` (receipt)
- `docs/testplans/<slug>-test-plan.md` (permanent)
- `swarm-report/<slug>-debug.md` (bug-fix reproduction)

Выбранный источник активирует одну из четырёх ветвей — `test_plan_source: receipt | mounted |
on-the-fly | absent`. Если `swarm-report/<slug>-debug.md` — единственный доступный источник
проверки, он соответствует ветви 3 (`on-the-fly`) — при проверке исправления ошибки `debug.md`
рассматривается как вход, подобный spec. Полная семантика ветвей, переопределения mount-receipt
и потребители frontmatter спецификации (включая защитные проверки инвариантов `surfaces`) описаны в
[`references/source-branches.md`](references/source-branches.md). Record the selected
branch as `test_plan_source` in the receipt.

**Проверка инструментирования.** Если test plan заканчивается существующей секцией `## Non-functional /
Instrumentation` section that exists and is not `N/A: <reason>` (Log events / Metrics /
Traces / Alerts / Dashboards — see [`generate-test-plan` Field Definitions](../generate-test-plan/SKILL.md#non-functional--instrumentation-mandatory-for-user-facing--prod-bound)),
acceptance проверяет на запущенном приложении, что каждое объявленное event / metric / span
срабатывает при выполнении тестируемого поведения. Несовпадение (объявлено, но не отправлено, или отправлено
с неправильными полями) становится P1-замечанием acceptance и направляется в стандартный цикл FAILED → Implement.
Явное `N/A: <reason>` в секции test-plan пропускает эту проверку.

---

## Шаг 1.5: gate отсутствующего источника

Срабатывает только при `test_plan_source: absent`.

| Ситуация | Предложение |
|---|---|
| Нет spec и плана тестирования (функция) | Запустите `/write-spec` (требования) или `/generate-test-plan` (только тесты), затем повторите запуск. |
| Spec без AC, нет плана тестирования, UI-проект | Запустите `/generate-test-plan` для исполнимых TC или добавьте AC в spec. |
| Исправление ошибки без заметок о воспроизведении | Зафиксируйте корневую причину и воспроизведение в `swarm-report/<slug>-debug.md` (исследование в режиме планирования), затем повторите запуск. |
| В spec есть только `design.figma`, нет плана тестирования, UI-проект | Выполните только дизайн-ревью через `ux-expert`; для функциональной приёмки также запустите `/generate-test-plan`. |

Варианты: (1) создать отсутствующий источник предложенным upstream-навыком и повторить запуск; (2) прервать без receipt.

Исследовательский QA без сценария выполняется прямым вызовом агента `manual-tester` (см. § Step 4b в `agents/manual-tester.md`) — никогда не предлагайте это как fallback внутри acceptance.

После структурированного upstream-шага (`write-spec`, `generate-test-plan`, сохранённый `debug.md`) этот gate срабатывает редко; основной случай — самостоятельные вызовы.

---

## Шаг 2: сохраните E2E-сценарий

Актуально только когда `has_ui_surface == true` и существует источник сценария (test plan, spec с AC или `debug.md`). `manual-tester` требует повторной привязки к этому файлу; acceptance записывает его здесь и перечитывает при агрегации. Средой запущенного приложения (устройство, simulator, emulator, browser) **владеет `manual-tester`** (его Step 0); этот навык не проверяет устройства, не запускает installs и dev-серверы.

Сохраните в `swarm-report/<slug>-e2e-scenario.md`, используя канонический шаблон E2E Scenario из инструкций текущей среды проекта. В начало добавьте поля `Project type: <project_type>` и `Spec source: <what was used>`.

Правило для исправления ошибки: шаги берутся из инвертированного воспроизведения в `debug.md` — «Step X triggers the bug» → «Step X no longer triggers the bug».

---

## Шаг 2.5: проверка дубликатов

Прочитайте `swarm-report/<slug>-quality.md` (upstream receipt качества кода, позволяющий последующему acceptance не дублировать работу). Три случая:

- **`Status: PASS`**, receipt from current branch head → skip `code-reviewer`. Freshness inferred from receipt `Date:` vs the branch commit window; if unconfirmable, do **not** skip. On skip, write a stub at `swarm-report/<slug>-acceptance-code.md` with `verdict: SKIPPED`, `blocked_on: null`, one-line body referencing `<slug>-quality.md`.
- **`Status: FAIL`** → upstream quality loop failed. Run `code-reviewer` anyway; surface `blocked_on: quality-loop failed — see <slug>-quality.md` in Step 4 Summary. Aggregated Status is forced to `PARTIAL` minimum (or `FAILED` if `code-reviewer` itself returns FAIL).
- **Receipt missing** → run `code-reviewer` normally.

Decoupled from the Re-verification Loop `diff_hash` policy ([`references/re-verification.md`](references/re-verification.md)): dedup here is "upstream already ran code-review on this diff"; `diff_hash` idempotency is "previous acceptance run covered this same diff".

Синхронная проверка определяет состав fan-out шага 3 и создаёт заглушку до fan-out.

---

## Шаг 2.6: сохраните состояние fan-out

Сохраните план fan-out и устойчивый к сжатию контекста прогресс в `swarm-report/<slug>-acceptance-state.md` — это операционное состояние, не receipt. Порядок шагов: проверка дубликатов 2.5 → вступление шага 3 разрешает условные триггеры → записать файл состояния с полным `Planned Checks` → тело шага 3 запускает fan-out.

```markdown
# Acceptance State: <slug>

Status: planning | running | aggregating | done
Cycle: <N> of 3              # incremented on Re-verification Loop re-entry
Started: <ISO8601>
Base: <base-branch>
Diff hash: <sha256 of git diff <base>...HEAD>
Spec hash: <sha256 of spec file, or null>
Test-plan hash: <sha256 of permanent test plan, or null>

## Planned Checks
- [ ] manual (triggered by has_ui_surface + scenario)
- [ ] code (triggered by dedup miss)
- [ ] ac-coverage (triggered by spec.acceptance_criteria_ids)
- [ ] security (triggered by spec.risk_areas: [auth])

## Completed Checks
- [x] code — swarm-report/<slug>-acceptance-code.md — PASS

## Aggregated Verdict History
### Cycle 1
Verdict: FAILED
Blockers: <copy from aggregated receipt>
```

**Правила:**

1. Заполняйте только после окончательного формирования полного плана проверок (базовые + все условные триггеры, зависящие от spec и diff), до запуска любых пакетов агентов.
2. Перечитывайте перед каждым важным действием (запуск пакета, агрегация, запись итогового receipt). Выполненные проверки `[x]` не запускаются повторно при возобновлении после сжатия контекста.
3. Ставьте каждой проверке `[x]` путь артефакта и вердикт сразу после записи файла проверки.
4. При повторном входе в Re-verification Loop ([`references/re-verification.md`](references/re-verification.md)): увеличьте `Cycle`, сбросьте `Planned Checks` с новыми хэшами, перенесите пропущенные проверки в `## Re-used from previous cycle` с указателями на артефакты и добавьте новую запись `Aggregated Verdict History` после завершения цикла.
5. `Status: done` превращает файл в доступную только для чтения операционную историю (автоматически не удаляется).

Файл состояния и `<slug>-e2e-scenario.md` независимы: последний является внутренней повторной привязкой `manual-tester`, а файл состояния — собственным курсором fan-out acceptance.

---

## Шаг 3: запустите проверки (параллельный fan-out)

Выберите план проверок по `has_ui_surface` и условным триггерам из frontmatter spec.
Отправьте **одно** сообщение со всеми одновременными вызовами инструментов (вызовы Agent + Bash smoke).
Не ждите возврата одного вызова перед отправкой остальных.

### Базовый план проверок

| `has_ui_surface` | Базовый fan-out |
|---|---|
| `true` | `manual-tester` + `code-reviewer` (unless skipped by Step 2.5) |
| `false` | `code-reviewer` (unless skipped by Step 2.5) + build smoke (Bash) |

### Условные триггеры

Добавляйте в fan-out только при срабатывании триггера. Каждый триггер сопоставлен со специалистом
с узким запросом. Если для агента триггер не сработал, агент не запускается.
Триггеры читаются из frontmatter spec или непосредственно из diff.

| Триггер | Агент | Роль |
|---|---|---|
| непустой `acceptance_criteria_ids` в spec | `business-analyst` | Покрытие AC — каждый `AC-N` имеет свидетельство в diff, списке TC или отчёте manual-tester |
| задан `design.figma` в spec, `has_ui_surface == true` | `ux-expert` design-review | Проверить соответствие UI указанному макету и дизайн-системе проекта |
| задан `non_functional.a11y` в spec, `has_ui_surface == true` | `ux-expert` a11y focus | Аудит доступности по заявленному уровню WCAG |
| `risk_areas` spec включает `auth`, `payment`, `pii` или `data-migration` | `security-expert` | Ревью безопасности по diff и сохранённым изменениям состояния |
| задан `non_functional.sla` **или** `risk_areas` включает `perf-critical` | `performance-expert` | Проверка бенчмарка/регрессии по заявленному SLA |
| diff затрагивает символ публичного API **или** изменения охватывают ≥3 модуля верхнего уровня | `architecture-expert` | Границы модулей, направление зависимостей, контракт публичного API |
| diff затрагивает build-файл (`build.gradle*`, `settings.gradle*`, `pom.xml`, `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`) | `build-engineer` | Корректность build-конфигурации — версии плагинов, wiring задач, добавление зависимостей |
| diff затрагивает CI/release-конфигурацию (`.github/workflows/*`, `.gitlab-ci.yml`, `Dockerfile`, `docker-compose*`, `.circleci/config.yml`, `release.yml`) | `devops-expert` | Здоровье pipeline/release, обработка секретов, rollout-gates |

**Определение триггеров по diff.** Два прохода с кешированием:

1. **Path pass** — `git diff --name-only <base>...HEAD` once, cache the path set; used for all path-only rules (build files, CI/release config, cross-module span).
2. **Content pass (on demand)** — when `architecture-expert` needs to decide "diff touches a public API symbol", read the diff body once via `git diff --unified=0 <base>...HEAD -- <cached-paths>` and cache for the whole run.

Оба кеша живут до конца запуска acceptance — не выполняйте повторную проверку для каждого агента.

**Public API detection heuristic** for `architecture-expert`:
- **Kotlin/Java**: changes under `src/main/` that add/remove/rename `public` / `open` symbols, or touch module-level files (`settings.gradle*`, `Module.kt`, `Dependencies.kt`).
- **TypeScript/JavaScript**: changes to `export` / re-export lines, `index.ts` public entrypoints, or `package.json` `"exports"`.
- **Swift**: `public` / `open` declarations or `Package.swift` `products` / `targets`.
- **HTTP/RPC**: files matching `**/routes/**`, `**/controllers/**`, `**/handlers/**`, `**/api/**`, `*.proto`, `*.graphql`, `openapi.yaml`.
- **Cross-module threshold**: `git diff --name-only` spans ≥ 3 top-level module directories from `settings.gradle*` / `package.json` workspaces / `Cargo.toml` `[workspace]`.

Неоднозначная эвристика → по умолчанию **не** запускайте `architecture-expert` (ложное отрицание безопаснее ложного срабатывания).

При срабатывании обоих триггеров design-review и a11y объедините их в один вызов `ux-expert` с mode `both`. Если триггеров нет → только базовый план (обратная совместимость со spec до итерации 2).

**Будущие итерации** добавят `visual-check` как отдельный соседний навык (не участника fan-out) для пиксельной регрессии.

### Схема артефакта проверки (общая для всех под-проверок)

Каждая под-проверка записывает `swarm-report/<slug>-acceptance-<check>.md` с таким frontmatter:

```yaml
---
type: acceptance-check
check: manual | code | build | ac-coverage | design | a11y | security | performance | architecture | build-config | devops
agent: <agent-name or "bash">
verdict: PASS | WARN | FAIL | SKIPPED
severity: critical | major | minor | null
confidence: high | medium | low | null
domain_relevance: high | medium | low | null
diff_hash: <sha256 of `git diff <base>...HEAD` at the moment the check ran; null for checks that do not depend on the diff>
blocked_on: <optional — what the user must resolve; also used when a planned per-check artifact is missing>
---
```

**Семантика `diff_hash`.** Вычисляется один раз за запуск через `git diff <base>...HEAD | sha256sum`; каждая проверка записывает одно и то же значение. Используется Re-verification Loop ([`references/re-verification.md`](references/re-verification.md)) для решения, какие проверки повторить. Проверки только на Bash (build smoke) записывают тот же хэш. Проверки, чей вердикт не зависит от diff, могут записать `diff_hash: null` — Re-verification Loop никогда не пропускает их только из-за совпадения хэша.

**Имена файлов.** Один файл на значение `check`: `swarm-report/<slug>-acceptance-<check>.md`. Один агент, покрывающий несколько вопросов (например, `ux-expert`), записывает отдельный файл на каждый вопрос.

`severity`, `confidence`, `domain_relevance` are required when `verdict` is `WARN` or `FAIL`; null for `PASS` / `SKIPPED`. These drive the PoLL aggregation in Step 4.

### Контракты запросов для агентов

Содержимое запросов, пути вывода и правила вердиктов для всех под-проверок (3.1 `manual-tester`, 3.2 `code-reviewer`, 3.3 build smoke, 3.4 `business-analyst`, 3.5 `ux-expert`, 3.6 `security-expert`, 3.7 `performance-expert`, 3.8 `architecture-expert`, 3.9 `build-engineer`, 3.10 `devops-expert`) находятся в [`references/subcheck-prompts.md`](references/subcheck-prompts.md).

---

## Шаг 4: объедините результаты и запишите receipt

Apply PoLL rules and the Aggregated Status table from [`references/aggregation.md`](references/aggregation.md) — same protocol as `multiexpert-review`, per-check input shape. Read frontmatter of each per-check artifact first; body only when `verdict != PASS`. Missing per-check artifact → `verdict: FAIL` with `blocked_on: per-check artifact missing`; never silently drop.

Save aggregated receipt at `swarm-report/<slug>-acceptance.md` using the template in `references/aggregation.md` §Receipt format. Downstream routing (VERIFIED / FAILED / PARTIAL) lives in the same reference §Routing.

После сохранения receipt отправьте сводку в чат (≤20 строк):

**VERIFIED:** "Acceptance: VERIFIED. N checks passed." Bullets (max 3): which checks ran, any skipped and why. Next step: `/create-pr` (or `/drive-to-merge` if PR exists).

**FAILED:** "Acceptance: FAILED. N check(s) failed." Bullets (max 5): one failure per bullet with check name + one-line description. ONE question: fix and re-run, or ship as-is accepting risk.

**PARTIAL:** "Acceptance: PARTIAL. N passed, M inconclusive." Bullets: inconclusive checks and why. ONE question: proceed to PR or re-run inconclusive?

Никогда не вставляйте таблицы receipt в чат — файл является аудиторским следом.

---

## Цикл повторной проверки

On fix-loop re-entry (after `FAILED` → fix on the branch → re-run acceptance), compute
`diff_hash_new` and decide which checks to re-run vs reuse, per the decision table in
[`references/re-verification.md`](references/re-verification.md). Spec and test-plan
change overrides (`spec_hash` / `test_plan_hash` mismatch forces `business-analyst` /
`manual-tester`) and back-compat rules are documented there.

Объедините результаты в новый receipt, перезаписав предыдущий. Повторяйте до VERIFIED или
пока пользователь не решит отправить результат как есть.

---
name: finalize
description: >
  Выполните проверку качества кода текущей ветки — многораундовый цикл ревью и исправлений,
  улучшающий способ написания кода, а не его поведение. Запускает однократное встроенное глубокое
  сканирование /code-review, затем code-reviewer, /simplify, необязательный квартет
  pr-review-toolkit и условные экспертные ревью с check между раундами; завершается PASS, когда
  не остаётся находок BLOCK, или ESCALATE после максимального числа раундов.
  Триггеры: "finalize", "run code quality pass", "clean up the code", "prepare for review",
  "polish the code", "tidy up", "harden the implementation".
---

# Финализация

Проверка качества кода текущей ветки. Многораундовый цикл ревью и исправлений, сфокусированный на **том, как** написан код (качество, ясность, устойчивость), а не на **том, что** он делает (функциональная приёмка, которой владеет `acceptance`) или **работает ли** он (build/lint/tests, которыми владеет `/check`).

`finalize` оркестрирует однократное глубокое ревью кода + `code-reviewer` + проход упрощения + необязательный квартет `pr-review-toolkit` + условные экспертные ревью. В Claude Code им соответствуют `/code-review` и `/simplify`; другие runtime должны использовать ближайший доступный эквивалент и фиксировать ограничения адаптера. Ни один из этих этапов по отдельности не обнаруживает весь набор типичных проблем (регрессии удалённого поведения, поломки между файлами, заплатки не того уровня абстракции, переусложнённые абстракции, тихие ошибки, хрупкие типы, слабое покрытие).

Правило **Author fixes broken tests** применяется согласно `$HOME/dotfiles/ai/shared/rules/qa-and-testing.md` § 4. Если `check` между фазами выявляет падение тестов, в том же раунде запускается inline-исправление — его выполняет инженерный специалист, создавший изменение. Завершить раунд нельзя, пока тесты остаются красными.

---

## Входные данные

- **`slug`** — slug задачи для именования артефактов.
- **Состояние ветки** — читает текущую ветку; никогда не переключает её.
- **Артефакт контекста (необязательно)** — якорь `code-reviewer` фазы A: план функции (`docs/plans/<slug>/plan.md`, создаётся `write-plan`; запасной вариант — устаревший `swarm-report/<slug>-plan.md`) или, для исправлений багов, отладочный артефакт (`swarm-report/<slug>-debug.md`).
- **Артефакт diff (производный)** — перед вызовом `code-reviewer` материализуйте diff в `swarm-report/<slug>-diff.txt`. Не зашивайте `origin/main`: определите ветку remote по умолчанию (как в `create-pr` — `git remote show origin | grep "HEAD branch" | awk '{print $NF}'`, запасные варианты `main` / `master` / `develop`), затем выполните `git merge-base origin/<base> HEAD`.

**Флаги допуска (необязательно):**

- `--allow-warn` — остановиться после 1 раунда только с WARN (по умолчанию: PASS при одном WARN, продолжать итерации для BLOCK).
- `--deep-scan-effort <auto|low|medium|high|xhigh|max>` — усилие для глубокого сканирования Phase 0 (по умолчанию `auto`: масштабируется по сигналам риска diff — см. Phase 0 § Effort selection). Явный уровень переопределяет выбор auto в любую сторону.
- `--skip-deep-scan` — полностью пропустить Phase 0 (дословно записывается в `acknowledged risks`). Phase 0 также автоматически пропускается для тривиальных diff.
- `--skip-experts` — пропустить Phase D (редко полезно; эксперты автоматически пропускаются, если ни один триггер не сработал).
- `--max-rounds N` (≥ 1) — переопределить значение по умолчанию 3. Используйте после ESCALATE, чтобы выполнить ещё один раунд без перезапуска.
- `--coverage-audit` / `--skip-coverage-audit` — принудительно включить / выключить `test-coverage-expert` в Phase D. Пропуск не рекомендуется; он дословно записывается в `acknowledged risks`.
- `--skip-security-review "<reason>"` — отключить для этого раунда и `risk_areas`, и триггеры шаблонов. Причина сохраняется дословно. Не рекомендуется; другие эксперты Phase D всё равно запускаются.

---

## Структура раунда

Phase 0 выполняется **один раз** перед циклом. Затем в каждом раунде последовательно выполняются фазы A → B → C → D. Между фазами и после любого auto-fix вызывайте `check`. Накапливайте находки; в конце раунда завершите работу или продолжите.

```
Phase 0 (once, pre-loop) → deep scan → dedup vs Phase A → feed Round 1
Round N:
  A  → code-reviewer          → fix BLOCK → check
  B  → simplification pass    → check
  C  → pr-review-toolkit quartet (parallel, if installed) → fix BLOCK → check
  D  → expert reviews (conditional, parallel)          → fix BLOCK → check
  Any unfixed BLOCK → round N+1 (up to max_rounds, default 3); else PASS
```

**Критерии выхода.** PASS — находок BLOCK нет; WARN / NIT перечислены в отчёте и никогда не блокируют. ESCALATE — после `max_rounds` остаются BLOCK; выведите неразрешённые находки, а вызывающая сторона решает, переопределить их или вернуться к реализации.

**Бюджет раундов.** По умолчанию 3, переопределяется через `--max-rounds N` (≥ 1). Регулярное достижение лимита означает, что нужно настроить порог уверенности `code-reviewer` фазы A (`developer-workflow-experts/agents/code-reviewer.md`), а не молча увеличивать `max_rounds`.

---

## Phase 0 — глубокое сканирование (однократное)

Выполняется **один раз за запуск finalize, перед раундом 1**, а не в каждом раунде. Даёт **полноту обнаружения ошибок** с помощью самого сильного доступного runtime инструмента code-review: построчного поиска багов, аудита удалённого поведения и трассировки между файлами, по возможности с независимым шагом проверки. В Claude Code это встроенный `/code-review`; в других runtime используйте ближайший эквивалент и при его отсутствии запишите `adapter limitation: no deep-scan equivalent`. Его находки по очистке/уровню абстракции/соглашениям пересекаются с Phase B и A и отбрасываются при загрузке (см. Feed into the loop): Phase 0 — слой корректности, а не очистки.

**Пропускайте при тривиальном diff** (тот же порог, что у `test-coverage-expert`): один файл, < 50 LOC, только рефакторинг, без нового public API. Запишите `phase: 0, status: skipped, reason: trivial diff`. Также пропускается по `--skip-deep-scan` (записывается в `acknowledged risks`).

**Вызов.** Вызовите инструмент глубокого сканирования runtime в режиме **report** для diff ветки. В Claude Code используйте **встроенный** `/code-review` — основной навык с неквалифицированным именем `code-review`, а НЕ marketplace-плагин `code-review:code-review` (ему нужен номер PR, и он не умеет проверять рабочее дерево):

- усилие берётся из `--deep-scan-effort` (по умолчанию `auto`, разрешается ниже); **без `--fix`** (triage по severity выполняет цикл исправлений finalize, а не harness), **без `--comment`** (этот gate выполняется до PR в рабочем дереве).
- Harness проверяет diff текущей ветки и незакоммиченные изменения и возвращает JSON-массив находок (`file`, `line`, `summary`, `failure_scenario`), от самых серьёзных к менее серьёзным.

### Выбор усилия (`auto`)

Масштабируйте полноту обнаружения по радиусу воздействия, используя сигналы, которые finalize уже материализовал до цикла: diff (`swarm-report/<slug>-diff.txt`), `risk_areas` артефакта контекста и быстрый проход по diff с таблицей [триггеров security-expert](#security-expert-pattern-triggers). Новых вычислений и агентов не требуется. Явный `--deep-scan-effort` всегда имеет приоритет над `auto`. Проверяйте сверху вниз, **срабатывает первое совпадение**; минимальный уровень — `medium` (всё ниже считается тривиальным diff и уже пропускается выше):

| Уровень | Срабатывает, если выполнено любое условие |
|---|---|
| **max** | ≥ 1 *narrow* security pattern in the diff, OR declared `risk_areas` ∈ {auth, payment, pii, data-migration}, OR a DB-migration path — same bar that triggers a full Phase D security review; a missed bug here is the most expensive. |
| **xhigh** | tech / infra-layer change (network, storage, auth, DI per `$HOME/dotfiles/ai/shared/rules/task-types.md`), OR new public API spanning ≥ 2 modules, OR diff > 500 LOC or > 15 files. High blast radius. |
| **high** | new public API symbol, OR cross-module dependency change, OR diff > 150 LOC or > 6 files. Default for substantive features. |
| **medium** | everything else above the trivial-skip bar — localized change, no risk signal. |

Запишите выбранный уровень и определивший его сигнал в отчёте (`Phase 0 (deep scan): effort=xhigh — reason: infra-layer (network)`), чтобы неожиданные затраты можно было связать с конкретным триггером, а пороги — настроить по реальным запускам.

**Проверка привязки.** В Claude Code неквалифицированный `/code-review` должен обращаться ко встроенному harness полноты обнаружения (эмпирически подтверждено на машине сопровождающего: первым шагом выполняется `git diff` рабочего дерева, а не поиск по номеру PR). В сторонней/публичной установке вместо него может привязаться marketplace shadow; обнаружьте это: если вызванная команда требует номер PR вместо проверки рабочего дерева, привязался неправильный экземпляр → пропустите Phase 0, запишите `reason: /code-review bound marketplace shadow` и продолжите с Phase A. **Никогда не передавайте номер PR, чтобы удовлетворить этот запрос.**

**Передача в цикл — только корректность (избегайте двойной работы).** Phase 0 нужен для того, чего не хватает другим фазам: реальных багов, **регрессий удалённого поведения** и **сломанных мест вызова**, подтверждённых независимым шагом проверки harness. Загружайте ТОЛЬКО такие находки — с `failure_scenario`, описывающим конкретный crash / неправильный результат / потерю данных / удалённую защиту / сломанный caller.

**Остальное отбрасывайте при загрузке**, поскольку этими направлениями владеют другие фазы и *действуют* по ним:
- находки об использовании повторно / упрощении / эффективности / уровне абстракции → **упрощение Phase B** (в Claude Code это `/simplify`), поскольку Phase B применяет исправление, а не только сообщает о нём. Повторное действие здесь удваивает работу.
- находки о соглашениях / инструкциях проекта → **`code-reviewer` Phase A** (владеет соответствием и правилом Non-negotiables-always-BLOCK).
- находки по корректности, пересекающиеся с Phase A → устраните дубликаты (один дефект + одно расположение → оставить один; приоритет у Phase A, поскольку она добавляет контекст соответствия плану / Non-negotiables).

Оставшиеся находки по корректности входят в цикл исправлений **раунда 1** и оцениваются по `failure_scenario` (crash / wrong-output / data-loss / dropped-guard → critical или major BLOCK). Исправления проходят обычный цикл fix → `check`. Phase 0 **не** запускается повторно в следующих раундах.

**Примечание о вычислениях.** Некоторые инструменты глубокого сканирования монолитны и запускают направления очистки, вывод которых мы отбрасываем. Такой избыточный fan-out — цена шага проверки и полноты обнаружения удалённого поведения / проблем между файлами; усилие `auto` ограничивает его. Если профилирование позже покажет, что повторный fan-out очистки доминирует по стоимости, следует уменьшить усилие Phase 0, а не исправлять очистку дважды.

---

## Phase A — семантическое ревью (code-reviewer)

Запустите `code-reviewer` (из `developer-workflow-experts`) с дословным описанием задачи, путём к артефакту плана (`docs/plans/<slug>/plan.md`, иначе устаревший `swarm-report/<slug>-plan.md`), если он существует, и `git diff` всех изменений ветки. Он возвращает PASS / WARN / FAIL с находками по шкале уверенности 0/25/50/75/100 (показываются только находки выше порога).

Нарушения Non-negotiables из применимых файлов инструкций runtime (`AGENTS.md`, `CLAUDE.md` или эквивалента) всегда являются BLOCK независимо от уверенности и никогда не переносятся в "acknowledged risks".

| Severity × confidence | Действие |
|---|---|
| critical ≥ 75 | Немедленно исправьте и повторно запустите `check`. PASS + resolved → BLOCK снят. Если сходимости нет → остаётся BLOCK, раунд завершается без PASS. Никогда молча не понижайте до "acknowledged risk". |
| major ≥ 75 | Исправьте, если это выполнимо. Рефакторинг за пределами diff → escalate; остаётся BLOCK, пока вызывающая сторона не решит проблему или не перенесёт её в "acknowledged risks" при ESCALATE. |
| minor ≥ 50 | NIT в отчёте. Не исправляйте автоматически; никогда не блокирует PASS. |

Вердикт FAIL → в этой фазе есть BLOCK, которые нужно устранить до продолжения.

**Почему Phase A сохраняет отдельный `code-reviewer` наряду с Phase 0.** `code-reviewer` Phase A **не** заменяется общим глубоким сканированием: он отвечает за привязку к плану и правило «нарушение Non-negotiables из инструкций проекта всегда является BLOCK независимо от уверенности», чего общие инструменты code-review надёжно не выполняют. Дополнительная полнота, которую даёт harness глубокого сканирования (удалённое поведение, проблемы между файлами, уровень абстракции, построчная корректность), собирается отдельно в **Phase 0**, устраняется по дубликатам с Phase A, а не заменой reviewer Phase A.

Предыдущая версия этого gate полностью исключала глубокое сканирование, исходя из теории, что «третий общий reviewer поверх Phase A + Phase C только увеличит дублирование». В Claude Code это было опровергнуто эмпирически: `/code-review` обнаружил реальные находки, пропущенные отдельным reviewer и Phase C. Поэтому согласно `$HOME/dotfiles/ai/shared/AGENTS.md` (эмпирические утверждения важнее теории без проверки) harness подключает глубокое сканирование как **однократное с устранением дубликатов (Phase 0)**, а не в каждом раунде. В Claude Code marketplace-плагин `code-review:code-review` по-прежнему намеренно не используется (ему нужен номер PR, и он не проверяет рабочее дерево); Phase 0 корректно деградирует при отсутствии подходящего адаптера глубокого сканирования.

---

## Phase B — упрощение

Вызовите проход упрощения runtime. В Claude Code это `/simplify`. Это параллельный проход по повторному использованию / качеству / эффективности, который **применяет исправления напрямую**. Рассматривайте его как поведенческий контракт; внутренняя структура может измениться. Области: повторное использование (дублированная логика), качество (избыточное состояние, разрастание параметров, протекающие абстракции, stringly-typed, ненужные комментарии), эффективность (повторная работа, неиспользованная конкурентность, раздувание hot path, TOCTOU, утечки). Не проводите предварительное ревью результата — доверьтесь ему, затем запустите `check`.

**При FAIL команды `check` после упрощения:** отмените commit упрощения (или последний commit, если однозначно понятно, что он относится к проходу упрощения), запишите `phase: B, reason: revert` и продолжите с Phase C. Не вызывайте упрощение повторно в том же раунде.

**Смысл бюджета раунда.** Phase B преобразующая, а не генерирующая находки. Revert НЕ создаёт неразрешённый BLOCK и НЕ расходует бюджет — раунд продолжается через C и D. Это отличается от сбоя `/check` после исправления в Phase A/C/D (§Mechanical verification), когда исходная находка остаётся BLOCK.

---

## Phase C — набор инструментов ревью PR (параллельно, необязательно)

Мягкая ссылка на `pr-review-toolkit` (marketplace `claude-plugins-official`). Это не жёсткая зависимость: этот marketplace публикует записи плагинов без полей `version`, из-за чего ломается разрешение semver.

Перед вызовом проверьте доступность агентов `pr-review-toolkit` (например, в реестре Task-агентов). Если какого-либо не хватает → пропустите Phase C, запишите `phase: C, status: skipped, reason: pr-review-toolkit not installed` и продолжите с Phase D. Иначе вызовите применимых агентов **параллельно**:

| Агент | Фокус | Когда запускается |
|---|---|---|
| `pr-review-toolkit:pr-test-analyzer` | Test quality in diff — edge cases, behavioral vs implementation testing | always |
| `pr-review-toolkit:silent-failure-hunter` | Empty catch blocks, swallowed errors, overly broad catches, errors logged but not surfaced | always |
| `pr-review-toolkit:type-design-analyzer` | Can invalid states be represented? Invariants in types? Missing nullability, unsafe unions | always |
| `pr-review-toolkit:comment-analyzer` | Comment accuracy vs code, comment-rot, stale/misleading doc-comments | **only when the diff adds or modifies comments / doc-comments** — skip on pure-logic diffs to keep signal high |

Три агента `always` покрывают направления, которыми не владеет ни одна другая фаза; `comment-analyzer` запускается при изменениях комментариев/документации, поскольку устаревание комментариев менее приоритетно и шумнее остальных трёх направлений — его место оправдано только когда есть комментарии для аудита.

Находки оцениваются по той же шкале 0–100, что и у `code-reviewer` (наследуется через общий prompt). Применяйте цикл исправлений Phase A: BLOCK (critical/major ≥ 75) → fix → `/check`; WARN (minor ≥ 50) → только отчёт; ниже порога → отбросить. Исправления качества тестов, требующие нового тестового кода, делегируйте подходящему инженерному агенту.

---

## Phase D — экспертные ревью (условно, параллельно)

Запускайте экспертов только если diff соответствует их области. Подходящих экспертов запускайте **параллельно**.

| Эксперт | Когда запускается |
|---|---|
| `architecture-expert` | new module, new public API surface, cross-module dependency change, or layered structure violation in diff |
| `security-expert` | spec/plan declared `risk_areas` ∈ {auth, payment, pii, data-migration}, or any pattern in the [Security-expert pattern triggers](#security-expert-pattern-triggers) table below |
| `performance-expert` | hot-path code (rendering, query loops, batch jobs), N+1 patterns, large-buffer allocations, threading/concurrency changes |
| `ux-expert` | UI-surface changes (composables, views, screens), copy / a11y / animation diffs |
| `build-engineer` | Gradle / Bazel / npm / Cargo / Xcode build script changes, plugin upgrades, version-catalog edits |
| `devops-expert` | CI / CD config, GitHub Actions / GitLab pipelines, deploy scripts, Dockerfile, infra-as-code |
| `business-analyst` | spec / requirements / scope changes (rare in finalize — usually fires upstream) |
| `test-coverage-expert` | see [`test-coverage-expert` (conditional)](#test-coverage-expert-conditional) below |

Ни один триггер не сработал → полностью пропустите Phase D в этом раунде.

### Триггеры шаблонов `security-expert`

Обычный триггер по `risk_areas` требует явного объявления в spec/plan; исправления багов и задачи без spec могут его пропустить. Поэтому Phase D дополнительно запускает `security-expert` по шаблонам в diff:

| Категория | Шаблон (путь или содержимое diff) | Уровень |
|---|---|---|
| Network layer | path under `/network/`, `/api/`, `/http/`, `/rpc/`, `/graphql/` | broad |
| Auth / Crypto | path under `/auth/`, `/crypto/`, `/token/`, `/session/` | narrow |
| Credential storage | diff mentions `SharedPreferences`, `EncryptedSharedPreferences`, `Keychain`, `UserDefaults`, `localStorage`, `sessionStorage`, `document.cookie`, `KeyStore` | narrow |
| Supply chain | new dependency line added in `build.gradle*`, `Podfile`, `Package.swift`, `package.json`, `pom.xml`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, `go.mod` | narrow |
| DB migrations | path under `migrations/`, `*.sql`, `Migration.kt`, `schema.prisma`, Flyway / Liquibase configs, `alembic/` | narrow |
| Deserialization | Jackson / Gson / `kotlinx.serialization` config blocks; unsafe Python-pickle usage, `XMLDecoder`, `ObjectInputStream` in diff | narrow |

**Порог (контроль ложных срабатываний):**

- ≥ 1 narrow pattern → полное security review (как при триггере `risk_areas`).
- ≥ 2 broad patterns → полное security review.
- Ровно 1 broad pattern без narrow → **scoped review**: запустите `security-expert` с узким prompt, называющим конкретную поверхность (например, "audit the network layer for regressions only"), а не с полным аудитом. Это снижает цену ложных срабатываний на случайных затрагиваниях.
- Нет шаблона и нет `risk_areas` → security-expert не запускается. Другие эксперты Phase D всё ещё могут быть запущены.

**Переопределение.** `--skip-security-review` (Tolerance flags) отключает на раунд и `risk_areas`, и триггеры шаблонов. Дословно записывается с причиной пользователя в `acknowledged risks` файла `<slug>-finalize.md`. Не рекомендуется.

**Источник.** Шаблоны проверяются по единому diff между merge-base ветки remote по умолчанию и `HEAD` (определяется так же, как в Phase A). Формируйте diff с обнаружением переименований (`git diff -M`). Шаблоны путей сопоставляются с **новым** путём. Шаблоны содержимого diff сопоставляются только с добавленными/изменёнными hunk: чистое переименование без изменения содержимого не соответствует шаблонам содержимого, но может соответствовать шаблонам путей, если файл перемещён в каталог, связанный с безопасностью.

### Обработка экспертных находок

Тот же gate severity × confidence, что и в Phase A. Особенности:

- Критичная для безопасности находка с confidence 50 — используйте **Critical-risk exception** `code-reviewer` (`developer-workflow-experts/agents/code-reviewer.md` § Critical-risk exception): находка включается с маркером `[please verify]` перед `issue`. Считайте её BLOCK; исправьте или escalate.
- Performance / architecture + critical ≥ 75: исправьте, если проблема локальна для diff; escalate, если требуется более широкая переработка.
- Отдельного правила «всегда исправлять при 50» нет: шкала один раз определена в `code-reviewer.md` и наследуется.

### `test-coverage-expert` (условный)

Поздний аудит покрытия, дополняющий ранний gate `check` Phase 3.5 (#154). Обнаруживает заявленные, но не реализованные TC, изменения data layer без integration-тестов и пробелы, пропущенные инженерным специалистом. Правило public API определено в `$HOME/dotfiles/ai/shared/rules/qa-and-testing.md` § 1; система приоритетов (P0–P3) — в § 2.

**Запускайте, если выполнено ЛЮБОЕ условие:** (1) diff добавляет символ public API без соответствующего тестового файла (согласно § 1); (2) `docs/testplans/<slug>-test-plan.md` объявляет TC без соответствующей реализации в тестовых источниках этого slug — сопоставляйте по `Type` TC (#153), а также упоминанию имени / файла; это интерпретирует агент, а не regex; (3) diff затрагивает файлы data layer / repository / service / use-case без добавления или обновления тестов; (4) `--coverage-audit`.

**Пропускайте, если выполнено ЛЮБОЕ условие:** (1) тривиальный diff (один файл, < 50 LOC, без нового public API, только рефакторинг); (2) `--skip-coverage-audit` (дословно записывается в отчёт finalize); (3) для затронутого модуля нет тестовой инфраструктуры — завершите этап с follow-up issue ("add test harness for X"). Никогда не пропускайте молча.

Переиспользует существующих инженерных агентов (`kotlin-engineer` / `swift-engineer` / `compose-developer` / `swiftui-developer`) с prompt для аудита покрытия. Агент читает `docs/testplans/<slug>-test-plan.md`, diff и тестовые файлы; записывает `swarm-report/<slug>-coverage-audit.md`; при пробелах в том же вызове Task пишет недостающие тесты и повторно запускает `/check` (author-fixes-tests, qa-and-testing.md § 4).

**Schema for `swarm-report/<slug>-coverage-audit.md`:**

```markdown
# Coverage audit: <slug>

**Date:** <ISO date>
**Slug:** <slug>
**Triggered by:** new-public-api | tp-tc-mismatch | data-layer-no-tests | --coverage-audit
**Verdict:** PASS | GAPS_RESOLVED | ESCALATE

## Inputs
- Test plan: `docs/testplans/<slug>-test-plan.md` (or `N/A: no test plan`)
- Diff against: `origin/<base>` (commit hash range)
- Test files in diff: <list>

## Cross-reference

| TC ID | Type | Status | Test file |
|---|---|---|---|
| TC-1 | unit | covered | `src/test/.../FooSpec.kt` |
| TC-2 | ui-instrumentation | gap | — |

## Public API audit

| Symbol | File | Status | Test file |
|---|---|---|---|
| `LoginViewModel` | `feature/auth/.../LoginViewModel.kt` | covered | `LoginViewModelTest.kt` |
| `RateLimiter.allow()` | `core/.../RateLimiter.kt` | gap | — |

## Gaps and resolution
- (gap-1) TC-2 `Login error state` — added `LoginScreenInstrumentedTest`.
- (gap-2) `RateLimiter.allow()` — added `RateLimiterTest.allow_blocks_after_threshold`.

## /check after fixes
verdict: PASS
passed: [build, lint, typecheck, tests, coverage]
```

Вердикт → результат Phase D:

- `PASS` — все строки покрыты до аудита; Phase D продолжается с другими экспертами.
- `GAPS_RESOLVED` — агент написал недостающие тесты, `/check` дал PASS. Считается PASS; файл аудита перечисляет исправления для отчёта finalize.
- `ESCALATE` — агент не смог создать пригодный тест за 3 попытки ИЛИ пробел структурно нетестируем. Считается BLOCK; применяется бюджет раундов.

`--skip-coverage-audit` описан в §Inputs; при его установке причина пропуска записывается в `acknowledged risks`.

---

## Механическая проверка между фазами

После **любого** изменения кода в раунде повторно вызовите `/check`. При FAIL:

1. Запишите, исправление какой фазы вызвало ошибку.
2. Выполните узкую правку — **максимум 1 попытка**. На этапе finalize код уже один раз прошёл `/check`, поэтому регрессия означает, что сама правка была неверной; новые попытки усугубляют ситуацию, а не приближают сходимость.
3. Ошибка сохраняется → отмените правку и оставьте исходную находку **как BLOCK** для раунда (не разрешена, учитывается в бюджете). Продолжите остальные фазы; никогда не переименовывайте отменённый BLOCK в "acknowledged risk".
4. Раунд завершился с неразрешёнными BLOCK → следующий раунд. Третий раунд завершился с неразрешёнными BLOCK → ESCALATE.

Не допускайте каскада ошибок `/check` и не используйте revert-and-continue, чтобы молча отправить BLOCK.

---

## Report

Save `swarm-report/<slug>-finalize.md` on exit (PASS or ESCALATE):

```markdown
# Finalize: <slug>

**Date:** <date>
**Rounds run:** N (of 3 max)
**Exit:** PASS | ESCALATE
**Escalation reason:** <only if ESCALATE>

## Rounds

### Round 1
- Phase 0 (deep scan /code-review): `effort=<tier> — reason: <signal>`, N findings after dedup vs Phase A (or `skipped: trivial diff | --skip-deep-scan | bound marketplace shadow`).
- Phase A (code-reviewer): verdict, N findings (K BLOCK, M WARN, L NIT). Fixes: X.
- Phase B (/simplify): Y files changed, auto-fixed.
- Phase C (pr-review-toolkit): per-agent breakdown, or `skipped` if plugin not installed.
- Phase D (experts): triggered: [security-expert, ...]; findings, fixes.
- `/check` after round: PASS | FAIL (reason)

### Round 2 ...

## Unresolved BLOCKs (ESCALATE only)
Findings that could not be fixed and were NOT downgraded — populated only on ESCALATE; lists BLOCKs after `max_rounds` rounds OR BLOCKs whose fix broke `/check` and was reverted. User decides: return to implementation, accept as risk, or re-scope.

| Severity | Confidence | Category | Finding | Phase | Round | File:Line |
|---|---|---|---|---|---|---|
| BLOCK (critical) | 75 | security | Token logged in clear | D | 3 | src/auth/Logger.kt:23 |

## Remaining findings (not auto-fixed)
Non-BLOCK items for reviewer awareness — never block PASS.

| Severity | Confidence | Category | Finding | Phase | File:Line |
|---|---|---|---|---|---|
| WARN | 60 | quality | Inconsistent error logging | A | src/foo/Bar.kt:142 |
| NIT  | 75 | consistency | Unused import in new file | B | ... |

## Acknowledged risks
Findings the user explicitly decided to accept (e.g. at escalation). Not auto-populated — distinct from "Unresolved BLOCKs".

## Commits added during finalize
- <hash> <message>
```

### Quality receipt (terse)

Also save `swarm-report/<slug>-quality.md` on the same exit (PASS or ESCALATE). This is the terse receipt consumed by downstream skills (`acceptance` Step 2.5 dedup probe and `create-pr`'s status table) — the detailed `<slug>-finalize.md` above is the round-by-round log, this is the one-glance gate result.

```markdown
# Quality receipt: <slug>

Status: PASS | FAIL
Date: <date>
Escalate: <true — only on ESCALATE; omit otherwise>
Detail: swarm-report/<slug>-finalize.md
```

Verdict mapping: `Exit: PASS` → `Status: PASS`; `Exit: ESCALATE` → `Status: FAIL` plus `Escalate: true`. `Date:` is mandatory — `acceptance` Step 2.5 infers freshness from `Date:` against the branch commit window; if it cannot confirm, it does NOT skip `code-reviewer`, so `Date:` alone is sufficient and no commit SHA is needed.

### Chat summary on exit (≤20 lines)

**PASS:** "Finalize: PASS after N round(s). Code is ready for acceptance." Bullets — N findings fixed by category (security X, quality Y, style Z); if 0, state so. Next step: `/acceptance`.

**ESCALATE:** "Finalize: ESCALATE after N round(s). X unresolved BLOCK(s) require decision." Bullets (max 5, top by severity): one BLOCK per bullet with category + one-line description. ONE question: which BLOCK first, or pick accept-risk / continue-implementing / re-scope. Options — proceed to `/acceptance` accepting risks, or return to implementation with a new task.

Never paste the report table into chat — the file is for reference.

---

## Scope and escalation

- **In scope:** improving quality of code *related to the current diff*; delegating fixes to engineer agents; `/check` after each mutation.
- **Out of scope:** new features, scope changes, functional acceptance, architectural redesign.
- Keep fixes inside files touched by the original change. Adjacent-file edits only when a finding explicitly requires them (e.g., `pr-test-analyzer` adding a sibling test, `/simplify` extracting a helper).
- Never re-scope under "cleanup" — structural issues beyond narrow-fix reach escalate.
- Never silently skip Phase A — `code-reviewer`'s plan-conformance check is the anchor. If it fails to launch for infrastructure reasons, stop and escalate.

**Escalate (stop and report) when:** unresolved BLOCKs after `max_rounds`; `/check` fix doesn't converge after 1 retry; BLOCK requires refactoring beyond diff scope; expert finding demands architectural change; required engineer agent (e.g. `kotlin-engineer`) is not installed but needed for a fix. State which phase escalated, what is unresolved, and what the caller must decide.

---

## Dependencies

- **Hard** (`plugin.json`): `developer-workflow-experts` — `code-reviewer`, `security-expert`, `performance-expert`, `architecture-expert`.
- **Optional soft-ref** (Phase C auto-skips when absent): `pr-review-toolkit` (marketplace `claude-plugins-official`) — `pr-test-analyzer`, `silent-failure-hunter`, `type-design-analyzer` (always), `comment-analyzer` (only when the diff touches comments / doc-comments).
- **Built-in:** `/code-review` (core recall harness — Phase 0; degrades gracefully if a marketplace shadow binds instead), `/simplify`, `/check`.

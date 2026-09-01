---
name: create-pr
description: >
  Управляйте pull request (GitHub) / merge request (GitLab) текущей ветки на всём жизненном цикле.
  Четыре режима: `--draft` создаёт или обновляет draft PR в начале конвейера, `--refresh`
  обновляет тело существующего PR без изменения статуса, `--promote` обновляет тело и переводит
  draft PR в состояние ready for review, а режим по умолчанию (без флага) создаёт новый PR после
  вопроса draft-or-ready. Описание составляется из доступных артефактов swarm-report (research,
  plan, test-plan, finalize, acceptance), а при их отсутствии используется git log + diff. Вызывайте
  навык, когда пользователь говорит "create PR", "open draft PR", "refresh PR description", "promote to ready",
  "mark PR ready for review", "update the PR", "switch the PR to ready".
---

# Create PR

Управляйте pull request (GitHub) или merge request (GitLab) на всём жизненном цикле — создание draft,
обновление тела в процессе работы и итоговый перевод в ready for review. Описание динамически
составляется из доступных артефактов.

---

## Обзор режимов

| Режим | Когда | Действие | Ошибка, если |
|---|---|---|---|
| `--draft` | После первого коммита в feature-ветке | Создаёт draft PR, если его нет; обновляет тело существующего draft | PR существует и уже готов к ревью |
| `--refresh` | После значимого прогресса (завершён раунд finalize, пройдена acceptance) | Обновляет тело существующего PR (draft или ready) без изменения статуса | PR не существует |
| `--promote` | После всех локальных проверок качества (finalize + acceptance) | Обновляет тело итоговой сводкой, затем переводит draft PR в ready for review | PR не существует или уже готов |
| default | Прямой вызов | При неясности спрашивает draft-or-ready, затем создаёт PR | PR уже существует |

Mode is passed via arguments: `/create-pr --draft`, `/create-pr --refresh`, `/create-pr --promote`, or `/create-pr` for default.

---

## Шаг 1: настройка (все режимы)

```bash
git remote get-url origin                                        # github.com → gh; gitlab → glab
BASE=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
# Fallback order: main → master → develop
BRANCH=$(git branch --show-current)
CURRENT_EMAIL=$(git config user.email)
```

---

## Шаг 2: проверка существующего PR (все режимы)

Не используйте здесь `2>/dev/null` — это молча смешивает ожидаемый случай «PR не существует» с
реальной ошибкой «CLI недоступен / авторизация не удалась». Сохраните stderr и ветвитесь по коду выхода:

```bash
# GitHub
out=$(gh pr view --json url,isDraft,number,body 2>&1); rc=$?
# Код выхода:
#   0              → PR существует; разберите $out как JSON
#   1 + stderr содержит "no pull requests" / "no open pull requests" → PR отсутствует (ожидаемо)
#   любой другой rc или неожиданный stderr → реальная ошибка (CLI отсутствует, нет авторизации, API недоступен)

# GitLab
out=$(glab mr view --output json 2>&1); rc=$?
# Та же схема: rc 0 → MR существует; stderr "no open merge request" → MR отсутствует; иначе → реальная ошибка.
```

**При реальной ошибке (ненулевой rc, не являющемся случаем «PR отсутствует»):** остановитесь и
выведите сохранённый stderr. Не продолжайте так, будто PR отсутствует — это создаст дубликат. Типичные
причины: `gh` / `glab` не установлены или не авторизованы, сбой API, отсутствует токен в sandbox.

Capture on success:
- `PR_EXISTS` — true/false
- `PR_IS_DRAFT` — true/false (if exists)
- `PR_URL` — for output
- `PR_BODY` — current body, used by refresh/promote to preserve manual edits (see Step 7.4)

### Предусловия режимов

| Режим | Предусловие | При ошибке |
|---|---|---|
| `--draft` | PR does not exist, or exists AND `isDraft: true` | If PR exists AND not draft: abort with "PR is already ready for review; use `--refresh` to update the body." |
| `--refresh` | PR exists (draft or ready — `--refresh` does not change status) | If no PR: abort with "No PR found for this branch. Use `--draft` or default to create one first." |
| `--promote` | PR exists AND `isDraft: true` | If no PR: abort with "No PR to promote." If already ready: abort with "PR is already ready for review; use `--refresh` if you want to update the body." |
| default | PR does not exist | If PR exists: print URL, abort. Suggest `--refresh` or `--promote`. |

---

## Шаг 3: отправка ветки (все режимы — если локально есть новые коммиты)

```bash
git rev-parse --abbrev-ref @{u} 2>/dev/null || git push -u origin "$BRANCH"
git push   # no-op if in sync; common for --refresh / --promote
```

Если push завершается ошибкой (non-fast-forward), остановитесь и попросите пользователя вмешаться. Политика force-push определяется глобальными правилами.

---

## Шаг 4: анализ состояния ветки (все режимы — нужен для тела PR)

Параллельно выполните: `git log $BASE..HEAD --oneline`, `git diff --name-only $BASE...HEAD`, `git diff $BASE...HEAD --stat`, `git diff $BASE...HEAD`.

---

## Шаг 5: поиск артефактов конвейера

Ищите в `./swarm-report/` артефакты, соответствующие slug текущей ветки/задачи. Прочитайте существующие:

| Артефакт | Расположение | Назначение в теле PR |
|---|---|---|
| research | `swarm-report/research/research-<slug>.md` | Link + 1-sentence abstract in "Context" section |
| spec | `docs/specs/<YYYY-MM-DD>-<slug>.md` (written by `write-spec`) | Reference as "Specification" |
| plan | `docs/plans/<slug>/plan.md` (written by `write-plan`; falls back to legacy `swarm-report/<slug>-plan.md`) | Reference as "Plan"; task acceptance from `docs/plans/<slug>/tasks.md` feeds "How to test" |
| debug | `swarm-report/<slug>-debug.md` | Root cause + reproduction steps — primary context for bug-fix PRs |
| test plan | `swarm-report/<slug>-test-plan.md` | Reference; test cases become checklist in "How to test" |
| quality | `swarm-report/<slug>-quality.md` | Gate pass/fail summary for status table |
| finalize | `swarm-report/<slug>-finalize.md` | Round-by-round summary for status table |
| acceptance | `swarm-report/<slug>-acceptance.md` | Pass/fail + verified scenarios for "Verification" section |

Разрешение slug:
1. Предпочитайте slug, если вызывающий код передал его аргументом.
2. Иначе используйте имя ветки после удаления распространённого префикса: `feature/`, `fix/`, `hotfix/`, `bug/`, `chore/`, `refactor/`, `docs/`.

Рабочие артефакты в `swarm-report/` исключены из Git; закоммиченные находятся в `docs/` (`docs/specs/`, `docs/plans/`). В любом случае включайте их в тело только как **ссылки** (например, «См. `docs/plans/my-slug/plan.md`»), никогда не вставляйте содержимое inline.

---

## Шаг 6: labels и reviewers (пропустить для `--refresh`)

Устанавливайте labels/reviewers только при **создании** (draft или default) или **promote**. `--refresh` НЕ изменяет labels/reviewers, чтобы не затереть правки пользователя.

### 6.1 Labels

Получите доступные labels:

- **GitHub:** `gh label list --json name,description --limit 100`
- **GitLab:** `glab label list` (resolves project from `git remote get-url origin`; do NOT use `glab api /projects/:fullpath/labels` — glab does not substitute `:fullpath` and the call will 404)

Выбирайте только существующие labels с учётом изменённых путей файлов, типов коммитов и области изменений. Не изобретайте labels.

**Добавляйте, не заменяйте.** Только **добавляйте** labels, которых не хватает согласно diff; никогда не удаляйте labels, установленные людьми вручную. Это сохраняет reviewer / triage / release labels, добавленные между созданием draft и promote.

### 6.2 Reviewers

Пропускайте назначение reviewers для `--draft` и `--promote`. Добавляйте reviewers только в режиме default или по явному запросу.

Для режима default: выберите до 3 авторов, недавно изменявших затронутые файлы, исключите `$CURRENT_EMAIL`, сопоставьте их с именами пользователей платформы и покажите пользователю до добавления.

---

## Шаг 7: составление тела PR

Составление тела зависит от режима.

### 7.1 Банк разделов

Тело составляется из каталога необязательных разделов: What changed, Why / motivation, Artifacts, How to test, **Release Notes** (если обнаружены видимые пользователю изменения), Status, Screenshots / demo, Checklist и завершающий footer Claude Code. Включайте только разделы, применимые к текущему режиму и доступным артефактам.

See [`references/body-sections.md`](references/body-sections.md) for the full section-bank templates with example content and status-table formatting.

### 7.2 Выбор разделов по режиму

| Section | `--draft` | `--refresh` | `--promote` | default |
|---|---|---|---|---|
| What changed | short (plan/task-based, code may be incomplete) | updated from current diff | final, full | full |
| Why / motivation | ✅ | ✅ | ✅ | ✅ |
| Artifacts | ✅ (as they appear) | ✅ (keeps current) | ✅ | ✅ if exist |
| How to test | from plan if exists | from test-plan if exists | full | ✅ |
| Release Notes | placeholder + open question if user-facing | refresh from spec/test-plan if user-visible signals | final entry per detected changelog format | ✅ when user-visible |
| Status | "Implement: in progress" | updated from latest artifacts | all PASS | optional |
| Screenshots | placeholder + prompt user | keep as-is | verify filled | prompt |
| Checklist | unchecked | keep user edits | verify items consistent | unchecked |

### 7.2.1 Release Notes section (user-visible changes)

Captures what users of the plugin / library / app will see, ready to paste into the project's changelog at release time. Emit when any signal is true:

- Spec/clarify/plan frontmatter declares `user-facing: true`, `prod-bound: true`, `breaking: true`, or a `release_notes:` block (optional add-ons; not part of the canonical `write-spec` template).
- Diff touches a public API surface (`/api/`, public functions, exported types in barrel files, plugin manifests, marketplace metadata) — default auto-detection.
- User passed `--release-notes "..."` (always wins).

Format is detected by file presence in the repo:

| Repo file | Format used in PR body |
|---|---|
| `CHANGELOG.md` | Keep-a-Changelog bullet, classified `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security`. Breaking flagged with leading `**Breaking:**` |
| `.changeset/` directory | PR-body shorthand: `type: patch \| minor \| major` + one-line summary. **PR-body representation only, not a valid `.changeset/` entry**; actual file is created at release time per the [Changesets format](https://github.com/changesets/changesets/blob/main/docs/intro-to-using-changesets.md). |
| `RELEASE_NOTES.md` / `docs/CHANGELOG.md` | Same Keep-a-Changelog format as `CHANGELOG.md` |
| None | Plain bullet list under `## Release Notes` |

Text only — `create-pr` does NOT modify changelog files. `--skip-release-notes` opts out (`Release notes: skipped (<reason>)`). The PR receipt records `release_notes: emitted | skipped: <reason> | not-applicable`.

### 7.3 Detect visual changes

Scan changed file paths for platform-specific UI markers (Android/Compose, Compose Multiplatform, Web, iOS/SwiftUI). If any match, include the "Screenshots / demo" section and prompt the user for attachments in `--draft` and `--promote`; `--refresh` preserves existing Screenshots content verbatim.

See [`references/visual-change-patterns.md`](references/visual-change-patterns.md) for the full glob patterns per platform.

### 7.4 Preserve user edits on refresh/promote

When `--refresh` or `--promote` runs and `PR_BODY` is non-empty:

1. Detect manual-edit markers — content between `<!-- user-edit-start -->` and `<!-- user-edit-end -->` is preserved verbatim.
2. Content in Screenshots / demo section preserved verbatim (users paste images there).
3. Checklist items that are **checked** are preserved as checked.

Everything else is regenerated from artifacts + git state.

**Edge case: empty `PR_BODY`** — skip the preserve-step entirely and generate from scratch. Do not fail.

---

## Step 8: Generate title

Mode-aware:

- **`--draft`** — derive from branch + first commit message
- **`--refresh`** — keep existing title unchanged
- **`--promote`** — keep existing title unless user asks otherwise (then use task description or spec)
- **default** — derive from branch + most meaningful commit

Rules when creating/changing the title: strip `feature/` `fix/` `chore/` `refactor/` `docs/` prefixes, convert kebab-case to sentence case, keep under 70 chars, never add "WIP:" or "Draft:" (draft status conveys it).

---

## Step 9: Execute per mode

### 9a. Mode `--draft`

If no PR exists:

```bash
# GitHub
gh pr create --draft \
  --title "<title>" \
  --body "<body>" \
  --base "$BASE" \
  --label "<label>" ...
# Labels optional; no reviewers for draft

# GitLab
glab mr create --draft \
  --title "<title>" \
  --description "<body>" \
  --target-branch "$BASE"
```

If draft already exists → edit body:

```bash
gh pr edit --body "<body>"
glab mr update --description "<body>"
```

Output:
> Draft PR created: `<url>`

### 9b. Mode `--refresh`

```bash
# GitHub
gh pr edit --body "<new-body>"
# GitLab
glab mr update --description "<new-body>"
```

Labels, reviewers, title are **not** touched.

Output:
> PR body refreshed: `<url>`

### 9c. Mode `--promote`

Two sequential operations:

```bash
# 1. Refresh body with final summary
gh pr edit --body "<final-body>"      # or glab mr update --description

# 2. Mark ready
gh pr ready                           # GitHub
# GitLab: --ready on current glab (≥1.32); older glab used --unwip.
# Try --ready first; fall back to --unwip ONLY when stderr shows that
# --ready itself is an unknown flag. Any other error is real — surface it.
GLAB_ERR=$(mktemp)
trap 'rm -f "$GLAB_ERR"' EXIT
if ! glab mr update --ready 2>"$GLAB_ERR"; then
  if grep -qE 'unknown flag:? --ready|flag provided but not defined: -?ready' "$GLAB_ERR"; then
    glab mr update --unwip
  else
    cat "$GLAB_ERR" >&2
    exit 1
  fi
fi
```

Output:
> PR promoted to ready for review: `<url>`

### 9d. Default mode

Ask draft-or-ready if not inferable from conversation, then create with full body + labels + reviewers.

---

## Output templates

**Draft (`--draft` or default → draft):**
> Draft PR created: `<url>`
> Next: complete implementation → `/finalize` → `/acceptance` → `/create-pr --promote` to mark ready.

**Refreshed (`--refresh`):**
> PR body refreshed: `<url>`

**Promoted (`--promote`):**
> PR promoted to ready for review: `<url>`
> Next: invoke `/drive-to-merge` (or `/drive-to-merge --auto`) to autonomously monitor CI, handle review comments, and drive the PR to merge.

**Default ready:**
> PR created: `<url>`
> Next: invoke `/drive-to-merge` to autonomously monitor CI, handle review comments, and drive the PR to merge.

---

## Scope rules

- **In scope:** PR create/edit/ready status transitions; body composition; labels and reviewers on create/promote; title generation on create.
- **Out of scope:** editing code, running tests, running `/check`, managing commits (caller pushes beforehand), merging.
- **Do not** force-push or rewrite history. If push fails — report and let caller resolve.
- **Do not** remove labels or reviewers set by humans. Only add missing ones on `--promote`.
- **Do not** strip manually-added content when refreshing — respect `<!-- user-edit-start/end -->` markers and Screenshots section.

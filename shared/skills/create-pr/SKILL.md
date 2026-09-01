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

# Создание PR

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

Режим передаётся аргументами: `/create-pr --draft`, `/create-pr --refresh`, `/create-pr --promote` или `/create-pr` для режима по умолчанию.

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

При успехе сохраните:
- `PR_EXISTS` — true/false
- `PR_IS_DRAFT` — true/false (если существует)
- `PR_URL` — для вывода
- `PR_BODY` — текущее тело, используемое режимами refresh/promote для сохранения ручных правок (см. шаг 7.4)

### Предусловия режимов

| Режим | Предусловие | При ошибке |
|---|---|---|
| `--draft` | PR не существует или существует, и `isDraft: true` | Если PR существует и не является draft: остановитесь с сообщением "PR is already ready for review; use `--refresh` to update the body." |
| `--refresh` | PR существует (draft или ready — `--refresh` не меняет статус) | Если PR нет: остановитесь с сообщением "No PR found for this branch. Use `--draft` or default to create one first." |
| `--promote` | PR существует, и `isDraft: true` | Если PR нет: остановитесь с сообщением "No PR to promote." Если он уже ready: остановитесь с сообщением "PR is already ready for review; use `--refresh` if you want to update the body." |
| default | PR не существует | Если PR существует: выведите URL и остановитесь. Предложите `--refresh` или `--promote`. |

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
| research | `swarm-report/research/research-<slug>.md` | Ссылка + краткое резюме в 1 предложении в разделе "Context" |
| spec | `docs/specs/<YYYY-MM-DD>-<slug>.md` (создаётся `write-spec`) | Ссылка как "Specification" |
| plan | `docs/plans/<slug>/plan.md` (создаётся `write-plan`; запасной вариант — устаревший `swarm-report/<slug>-plan.md`) | Ссылка как "Plan"; критерии приёмки из `docs/plans/<slug>/tasks.md` попадают в "How to test" |
| debug | `swarm-report/<slug>-debug.md` | Корневая причина + шаги воспроизведения — основной контекст для PR с исправлением бага |
| test plan | `swarm-report/<slug>-test-plan.md` | Ссылка; тестовые сценарии становятся чек-листом в "How to test" |
| quality | `swarm-report/<slug>-quality.md` | Сводка прохождения/непрохождения gate для таблицы статуса |
| finalize | `swarm-report/<slug>-finalize.md` | Сводка по раундам для таблицы статуса |
| acceptance | `swarm-report/<slug>-acceptance.md` | Прохождение/непрохождение + проверенные сценарии для раздела "Verification" |

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
- **GitLab:** `glab label list` (определяет проект по `git remote get-url origin`; НЕ используйте `glab api /projects/:fullpath/labels` — glab не подставляет `:fullpath`, и вызов завершится с 404)

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

Полные шаблоны банка разделов с примерами содержимого и форматированием таблицы статуса см. в [`references/body-sections.md`](references/body-sections.md).

### 7.2 Выбор разделов по режиму

| Раздел | `--draft` | `--refresh` | `--promote` | default |
|---|---|---|---|---|
| Что изменилось | кратко (по плану/задаче, код может быть незавершён) | обновляется по текущему diff | итоговый полный вариант | полный вариант |
| Почему / мотивация | ✅ | ✅ | ✅ | ✅ |
| Артефакты | ✅ (по мере появления) | ✅ (сохраняет текущие) | ✅ | ✅ при наличии |
| Как проверить | из плана, если есть | из test-plan, если есть | полный вариант | ✅ |
| Release Notes | заготовка + открытый вопрос при изменениях для пользователей | обновляются по spec/test-plan при наличии пользовательских сигналов | итоговая запись в обнаруженном формате changelog | ✅ при изменениях для пользователей |
| Статус | "Implement: in progress" | обновлённый по последним артефактам | все PASS | необязательно |
| Скриншоты | заготовка + запрос пользователю | сохраняются как есть | проверка заполнения | запрос |
| Чек-лист | неотмеченный | сохраняет правки пользователя | проверяет согласованность пунктов | неотмеченный |

### 7.2.1 Release Notes section (user-visible changes)

Фиксирует то, что увидят пользователи плагина / библиотеки / приложения; текст можно вставить в changelog проекта при выпуске. Добавляйте раздел, если истинен любой сигнал:

- Frontmatter spec/clarify/plan содержит `user-facing: true`, `prod-bound: true`, `breaking: true` или блок `release_notes:` (необязательные расширения; не входят в канонический шаблон `write-spec`).
- Diff затрагивает публичную поверхность API (`/api/`, публичные функции, экспортируемые типы в barrel-файлах, манифесты плагинов, метаданные marketplace) — автоматическое обнаружение по умолчанию.
- Пользователь передал `--release-notes "..."` (всегда имеет приоритет).

Формат определяется по наличию файлов в репозитории:

| Файл репозитория | Формат в теле PR |
|---|---|
| `CHANGELOG.md` | Пункт Keep-a-Changelog с классификацией `Added` / `Changed` / `Fixed` / `Deprecated` / `Removed` / `Security`. Breaking отмечается префиксом `**Breaking:**` |
| `.changeset/` directory | Сокращённая запись в теле PR: `type: patch \| minor \| major` + однострочное резюме. **Только представление в теле PR, не допустимая запись `.changeset`**; настоящий файл создаётся во время выпуска по [формату Changesets](https://github.com/changesets/changesets/blob/main/docs/intro-to-using-changesets.md). |
| `RELEASE_NOTES.md` / `docs/CHANGELOG.md` | Тот же формат Keep-a-Changelog, что и для `CHANGELOG.md` |
| Нет | Обычный список пунктов под `## Release Notes` |

Только текст — `create-pr` НЕ изменяет файлы changelog. `--skip-release-notes` отключает раздел (`Release notes: skipped (<reason>)`). Receipt PR фиксирует `release_notes: emitted | skipped: <reason> | not-applicable`.

### 7.3 Detect visual changes

Проверьте пути изменённых файлов на маркеры UI конкретных платформ (Android/Compose, Compose Multiplatform, Web, iOS/SwiftUI). При совпадении добавьте раздел "Screenshots / demo" и запросите у пользователя вложения в режимах `--draft` и `--promote`; `--refresh` сохраняет существующее содержимое Screenshots дословно.

Полные glob-шаблоны для каждой платформы см. в [`references/visual-change-patterns.md`](references/visual-change-patterns.md).

### 7.4 Preserve user edits on refresh/promote

Когда выполняется `--refresh` или `--promote` и `PR_BODY` не пуст:

1. Обнаружьте маркеры ручных правок — содержимое между `<!-- user-edit-start -->` и `<!-- user-edit-end -->` сохраняется дословно.
2. Содержимое раздела Screenshots / demo сохраняется дословно (пользователи вставляют туда изображения).
3. Отмеченные (**checked**) пункты чек-листа сохраняются отмеченными.

Всё остальное генерируется заново по артефактам и состоянию git.

**Крайний случай: пустой `PR_BODY`** — полностью пропустите шаг сохранения и сгенерируйте тело с нуля. Не завершайте работу с ошибкой.

---

## Шаг 8: генерация заголовка

С учётом режима:

- **`--draft`** — сформируйте по ветке и сообщению первого коммита
- **`--refresh`** — сохраните существующий заголовок без изменений
- **`--promote`** — сохраните существующий заголовок, если пользователь не попросил иного (тогда используйте описание задачи или spec)
- **default** — сформируйте по ветке и наиболее содержательному коммиту

Правила создания/изменения заголовка: удалите префиксы `feature/` `fix/` `chore/` `refactor/` `docs/`, преобразуйте kebab-case в sentence case, уложитесь в 70 символов, никогда не добавляйте "WIP:" или "Draft:" (это уже передаётся статусом draft).

---

## Шаг 9: выполнение по режиму

### 9a. Mode `--draft`

Если PR не существует:

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

Если draft уже существует → измените тело:

```bash
gh pr edit --body "<body>"
glab mr update --description "<body>"
```

Вывод:
> Draft PR создан: `<url>`

### 9b. Mode `--refresh`

```bash
# GitHub
gh pr edit --body "<new-body>"
# GitLab
glab mr update --description "<new-body>"
```

Labels, reviewers и заголовок **не изменяются**.

Вывод:
> Тело PR обновлено: `<url>`

### 9c. Mode `--promote`

Две последовательные операции:

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

Вывод:
> PR переведён в ready for review: `<url>`

### 9d. Default mode

Если режим draft-or-ready нельзя вывести из разговора, спросите о нём, затем создайте PR с полным телом, labels и reviewers.

---

## Шаблоны вывода

**Draft (`--draft` или default → draft):**
> Draft PR создан: `<url>`
> Далее: завершите реализацию → `/finalize` → `/acceptance` → `/create-pr --promote`, чтобы перевести PR в ready.

**Обновлённый (`--refresh`):**
> Тело PR обновлено: `<url>`

**Переведённый (`--promote`):**
> PR переведён в ready for review: `<url>`
> Далее: вызовите `/drive-to-merge` (или `/drive-to-merge --auto`), чтобы автономно отслеживать CI, обрабатывать комментарии ревью и довести PR до слияния.

**Готовый по умолчанию:**
> PR создан: `<url>`
> Далее: вызовите `/drive-to-merge`, чтобы автономно отслеживать CI, обрабатывать комментарии ревью и довести PR до слияния.

---

## Scope rules

- **Входит в область:** создание/редактирование PR и переходы статуса ready; составление тела; labels и reviewers при создании/promote; генерация заголовка при создании.
- **Не входит в область:** редактирование кода, запуск тестов, запуск `/check`, управление коммитами (вызывающая сторона отправляет их заранее), слияние.
- **Не** выполняйте force-push и не переписывайте историю. Если push завершается ошибкой — сообщите об этом и оставьте решение вызывающей стороне.
- **Не** удаляйте labels или reviewers, установленные людьми. В режиме `--promote` только добавляйте недостающие.
- **Не** удаляйте добавленное вручную содержимое при обновлении — соблюдайте маркеры `<!-- user-edit-start/end -->` и раздел Screenshots.

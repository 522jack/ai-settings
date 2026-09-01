# drive-to-merge — слияние на фазе 5

Вход при условиях: CI полностью зелёный + `reviewDecision == APPROVED` + нет нерешённых тредов, принадлежащих этому навыку + `mergeable == MERGEABLE` + `mergeStateStatus == CLEAN`.

## Перевод draft в готовый PR (до фазы)

If `isDraft == true` when Phase 5 conditions are otherwise met:

- **Режим `--auto`** — автоматически перевести и продолжить:
  ```bash
  # GitHub
  gh pr ready "$PR_NUMBER"
  # GitLab
  glab mr update "$MR_IID" --remove-draft
  ```
  Покажите одну строку уведомления («Переводим PR из draft в готовый») и перейдите к проверкам перед слиянием.

- **Режим по умолчанию** — остановиться и показать: «PR всё ещё draft. Переведите его в ready через `gh pr ready` или введите `stop`.»

## Проверки перед слиянием

1. Повторно проверьте секцию `Commitments` файла состояния — каждая строка с `delegated_to` должна иметь непустой `fix_commit_sha` и `replied: true`.
2. Повторно получите состояние PR (рецензенты могли изменить решение после последнего раунда).
3. Убедитесь, что ветка не разошлась с origin. Если `git status -sb` неожиданно показывает локальную ветку позади/впереди `origin/$HEAD`, пропустите слияние, запишите расхождение и вернитесь к фазе 2.1 ещё на один раунд.

## Итоговое сообщение перед слиянием

Always show (regardless of mode):

```
PR готов к слиянию.

URL:     <PR URL>
Branch:  <head> → <base>
Commits: <N since branch point>
Final CI: ✔ all checks passing
Review:  ✔ approved by <reviewers>
Threads: <T> resolved, 0 unresolved

Предлагаемый способ слияния: squash | merge | rebase   (выберите по соглашению репозитория)
Предлагаемое сообщение коммита:
  <subject>

  <body>
```

**Режим по умолчанию** — добавьте «Ответьте "merge" для выполнения или укажите другой способ/текст сообщения.» и ждите ответа пользователя.

**Режим `--auto`** — добавьте «Выполняем слияние автоматически (режим --auto).» и продолжите без ожидания.

## Финальная перепроверка и выполнение

Перед вызовом API слияния в последний раз перепроверьте состояние — между итоговым сообщением и вызовом API CI мог завершиться ошибкой или подтверждение могло быть снято:

```bash
FINAL=$(gh pr view --json statusCheckRollup,reviewDecision,mergeable,mergeStateStatus)
# При регрессе отмените слияние и вернитесь к фазе 2.1.
```

If the re-check is still green:

```bash
gh pr merge "$PR_NUMBER" --<method> --subject "<subject>" --body "<body>" --delete-branch
# GitLab
glab mr merge "$MR_IID" --<method-flag> --delete-source-branch
```

## Нативный путь auto-merge (CI всё ещё выполняется, режим `--auto`)

When Phase 2.5 would enter Phase 4 polling because CI is still in progress AND mode is `--auto`:

Вместо планирования повторных опросов передайте ожидание платформе:

```bash
# GitHub — requires repo auto-merge enabled + branch protection rules
gh pr merge "$PR_NUMBER" --auto --squash
```

Для GitLab используйте `--when-pipeline-succeeds` **только** если `Merge policy` в файле состояния равен `auto` (личный репозиторий). Для репозиториев `team-strict` пропустите нативный auto-merge и перейдите к обычному опросу (это не блокирует merge trains или очереди без согласия):

```bash
# GitLab — personal / auto policy only
glab mr merge "$MR_IID" --when-pipeline-succeeds
```

При успехе отметьте в файле состояния `Status: waiting-native-auto-merge`, покажите «Нативный auto-merge настроен — платформа выполнит слияние после прохождения проверок. Выходим из цикла.» и остановитесь.

При сбое (например, в репозитории GitHub отключён auto-merge):
- покажите «Нативный auto-merge недоступен (настройка репозитория отключена) — возвращаемся к опросу»;
- обычным образом продолжите к фазе 4.

## После слияния

1. Отметьте в файле состояния `Status: merged`, добавьте время в последнюю запись `Rounds`.
2. Сообщите пользователю URL результата слияния и commit sha.
3. Остановитесь. Дальнейший опрос не нужен.

## Rebase при продвижении base (дополнение к фазе 2.6)

When `mergeStateStatus` is `BEHIND` / `OUT_OF_DATE`:

```bash
git fetch origin
git rebase "origin/$BASE"
```

При чистом rebase запустите локальный навык `check` (build + lint + tests); при успехе выполните push с `--force-with-lease`. При конфликте разрешайте только действительно механические конфликты (перестановка импортов, несвязанные пробелы); иначе покажите blocker — не угадывайте разрешения слияния, затрагивающие логику.

**Ожидаемый побочный эффект.** После push с `--force-with-lease` некоторые репозитории сбрасывают `reviewDecision` с `APPROVED` на `REVIEW_REQUIRED` (настройка защиты ветки «Dismiss stale approvals»). Не считайте это регрессией — повторно запросите ревью по фазе 3.6 и продолжайте цикл. Commit sha в `Commitments.fix_commit_sha` показывает, какие исправления уже прошли ревью, а какие появились после rebase.

# drive-to-merge — Phase 1: настройка

Обнаружение платформы, получение метаданных, предусловия и схема файла состояния. Загружается SKILL.md по мере необходимости.

## 1.1 Обнаружение платформы

Извлеките hostname из URL remote и проверьте соответствующий CLI — не ищите регулярным выражением литералы `github.com` / `gitlab`, поскольку это пропустит GitHub Enterprise Server и самостоятельно размещённый GitLab.

```bash
REMOTE_URL=$(git remote get-url origin)
HOST=$(echo "$REMOTE_URL" | sed -E 's#^(https?://|git@)([^/:]+)[/:].*#\2#')

if gh auth status --hostname "$HOST" >/dev/null 2>&1; then
  PLATFORM=github
elif glab auth status --hostname "$HOST" >/dev/null 2>&1 || glab config get --global gitlab_uri 2>/dev/null | grep -q "$HOST"; then
  PLATFORM=gitlab
else
  echo "Unknown host $HOST — authenticate gh or glab against it and rerun." >&2
  exit 1
fi
```

## 1.2 Получение метаданных PR/MR

```bash
# GitHub
PR_INFO=$(gh pr view --json id,number,baseRefName,headRefName,title,body,isDraft,state,url,\
statusCheckRollup,reviewDecision,mergeable,mergeStateStatus,labels,closingIssuesReferences)
PR_NUMBER=$(jq -r .number <<<"$PR_INFO")
PR_URL=$(jq -r .url <<<"$PR_INFO")
IS_DRAFT=$(jq -r .isDraft <<<"$PR_INFO")
BASE=$(jq -r .baseRefName <<<"$PR_INFO")
HEAD=$(jq -r .headRefName <<<"$PR_INFO")
PR_NODE_ID=$(jq -r .id <<<"$PR_INFO")     # graphql node id from the same call — no extra round-trip
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=${REPO%/*}; REPO_NAME=${REPO#*/}

# Repository node id — needed for thread-ownership re-verify before every POST.
REPO_NODE_ID=$(gh api graphql -f query='query($o:String!,$n:String!){repository(owner:$o,name:$n){id}}' \
  -F o="$OWNER" -F n="$REPO_NAME" --jq '.data.repository.id')
# COPILOT_NODE_ID is resolved lazily in Phase 3.6 and cached in the state file header.

# GitLab
MR_INFO=$(glab mr view --output json)
MR_IID=$(jq -r .iid <<<"$MR_INFO")
MR_URL=$(jq -r .web_url <<<"$MR_INFO")
IS_DRAFT=$(jq -r '.title | startswith("Draft:")' <<<"$MR_INFO")
BASE=$(jq -r .target_branch <<<"$MR_INFO")
PROJECT=$(glab repo view --output json | jq -r '.path_with_namespace | @uri')
```

Если PR/MR уже слит или закрыт — остановитесь и сообщите итоговое состояние.

### Определение политики слияния

После получения метаданных репозитория определите политику слияния для этого запуска. Запишите её в файл состояния как `Merge policy:`.

1. **Явная конфигурация в CLAUDE.md** — проверьте `CLAUDE.md` репозитория (если файл есть) на строку, соответствующую шаблону:
   ```
   Merge policy: auto
   Merge policy: team-strict
   ```
   Use the first match.

2. **Явная конфигурация в `.claude/settings.json`** — проверьте ключ `driveToMerge.mergePolicy`; допустимые значения — `"auto"` или `"team-strict"`.

3. **Запасной вариант: эвристика org vs personal** (только GitHub):
   ```bash
   IS_ORG=$(gh repo view --json isInOrganization -q .isInOrganization)
   # true → team-strict; false → auto
   ```
   For GitLab, default to `team-strict` when the project namespace is a group, `auto` when it is a personal namespace.

Смысл политик:
- `auto` — режим `--auto` пропускает gate слияния и может использовать нативное автоматическое слияние платформы.
- `team-strict` — gate слияния всегда запрашивает подтверждение в любом режиме; для GitLab `--when-pipeline-succeeds` отключён, если пользователь явно не передал `--native-auto-merge` при запуске.

## 1.3 Предусловия

Остановитесь с понятным сообщением, если не выполнено любое из условий:

- Текущая ветка совпадает с head-веткой PR. Если нет — остановитесь с сообщением `checkout <head> first; this skill does not auto-switch branches`.
- Локальная ветка загружена и не отстаёт от remote head (`git fetch origin && git status -sb`).
- `gh auth status` / `glab auth status` — токен действителен.
- Ветка base всё ещё существует на remote.

## 1.4 Файл состояния

`swarm-report/<slug>-drive-state.md`. Slug = `<branch-with-prefix-stripped>-pr<PR_NUMBER>` (e.g. `fix/login` on PR 42 → `login-pr42`). The PR number disambiguates parallel branches that would otherwise produce the same slug (e.g. `feature/login` and `fix/login`, or two re-openings of the same branch).

Проверьте, что `swarm-report/` игнорируется Git, выполнив `git check-ignore -q swarm-report/`; код выхода 0 означает, что каталог игнорируется, ненулевой — что нет. При ненулевом коде остановитесь с сообщением `swarm-report/ is not ignored by git; add swarm-report/ to .gitignore and rerun`. Не изменяйте `.gitignore` автоматически: это создаёт посторонний diff внутри цикла сопровождения PR и может застать пользователя врасплох.

### Схема (Markdown, разбирается машиной при возобновлении)

```markdown
# Drive to Merge — <PR title>

URL: <PR URL>
Platform: github | gitlab
Mode: default | auto | dry-run
Merge policy: auto | team-strict
Principal: <@actor>            # gh api user --jq .login
Repository node id: <graphql node id of the repository>
PR node id: <graphql node id of the pull request>
Copilot node id: <graphql node id of copilot-pull-request-reviewer or `unavailable`>
Started: <ISO8601>
Status: running | waiting-for-user | waiting-native-auto-merge | merged | blocked

## Branch change model
analyzed_through_sha: <abbreviated sha the model is current as of, or empty before first build>

<compact prose summary of what the branch does: areas/files touched, key behaviors, invariants, and contracts introduced — a few lines, refreshed by delta each round>

## Rounds
| # | Started | Trigger | CI | New comments | Actions | Outcome |
|---|---------|---------|----|--------------|---------|---------|

## Commitments (open threads this skill owns)
| thread_id | category | delegated_to | fix_commit_sha | replied | resolved |
|-----------|----------|--------------|----------------|---------|----------|

`fix_commit_sha` holds the abbreviated sha of the commit that addressed the thread (empty string if the thread is dismiss-only, no code change).

## Blockers raised
<empty | list of items the skill surfaced to the user>
```

При каждом возобновлении (новая сессия после сжатия контекста) сначала перечитайте этот файл; не повторяйте анализ, уже отражённый в строке `Commitments`, если reviewer не проявил новую активность. Используйте сохранённую `Branch change model`, а не перестраивайте её по полному diff: перечитайте только delta после `analyzed_through_sha`, но лишь если `analyzed_through_sha` не пуст и `git merge-base --is-ancestor "<analyzed_through_sha>" HEAD` завершается успешно (то есть sha всё ещё является предком после любого rebase). Если sha пуст или проверка предка не пройдена, перестройте модель по полному diff (`git diff "origin/$BASE"...HEAD`) и сбросьте `analyzed_through_sha` на текущий `HEAD`.

### Приоритет режима при возобновлении

`Mode` в файле состояния — авторитетный источник. Новый запуск без флага наследует сохранённый режим; новый запуск с явным флагом **переопределяет** сохранённый режим и переписывает его. Это позволяет пользователю по повторному вызову перевести запуск из `auto` в `default`, но не понижает автономный запуск молча только потому, что был изменён wake-up prompt.

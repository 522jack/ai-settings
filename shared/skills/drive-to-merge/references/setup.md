# drive-to-merge — Phase 1: настройка

Обнаружение платформы, получение метаданных, предусловия и схема раздела `Drive to Merge` task report. Загружается SKILL.md по мере необходимости.

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
# COPILOT_NODE_ID is resolved lazily in Phase 3.6 and cached as drive_to_merge.copilot_node_id in the task report.

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

После получения метаданных репозитория определите политику слияния для этого запуска. Запишите её в раздел `Drive to Merge` task report как `drive_to_merge.merge_policy`.

1. **Явная конфигурация в CLAUDE.md** — проверьте `CLAUDE.md` репозитория (если файл есть) на строку, соответствующую шаблону:
   ```
   drive_to_merge.merge_policy: auto
   drive_to_merge.merge_policy: team-strict
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

## 1.4 Resume в task report

Наследуйте стабильный task slug и путь `swarm-report/<task-slug>.md`; main обновляет только раздел `Drive to Merge` по `$HOME/dotfiles/ai/shared/rules/task-report.md`. Если задача новая, выберите уникальный slug один раз, при необходимости включив номер PR. Не переименовывайте существующую задачу из-за PR/branch. PR URL/number и branch — поля раздела, не новый отчёт. Legacy drive-state можно прочитать, новые записи — только в task report; прежние файлы не удалять.

### Схема resume (именованный YAML-блок раздела)

```yaml
drive_to_merge:
  url: <PR URL>
  platform: github | gitlab
  mode: default | auto | dry-run
  merge_policy: auto | team-strict
  principal: <actor>
  repository_node_id: <GraphQL repository id>
  pr_node_id: <GraphQL PR id>
  copilot_node_id: <GraphQL bot id or unavailable>
  started: <ISO8601>
  status: running | waiting-for-user | waiting-native-auto-merge | merged | blocked
  analyzed_through_sha: <sha or empty before first build>
  round: <current number>
  unchanged_polls: <consecutive count>
  last_ci_signature: <identity for repeated failure detection>
  next_wake_condition: <pending event or timestamp, only while waiting>
  branch_change_model: <compact areas/behaviors/invariants, refreshed by delta>
  commitments:
    - thread_id: <id>
      category: <decision>
      delegated_to: <profile if relevant>
      fix_commit_sha: <sha or empty for dismiss-only>
      replied: false
      resolved: false
  blockers_raised: []
```

Не сохраняйте полные снимки CI/reviews или растущий журнал rounds. Обновляйте текущие counters/cursor, существенные результаты и блокеры; commitments сохраняют идентификаторы и результаты действий, необходимые для идемпотентности. После terminal status сверните resume-поля, сохранив итог, code identity, проверки, существенные риски и поля, нужные downstream gates.

При resume сначала перечитайте раздел; не повторяйте обработку Commitments без новой reviewer activity. Используйте branch_change_model и delta после analyzed_through_sha только если sha задан и `git merge-base --is-ancestor "<analyzed_through_sha>" HEAD` успешен. Иначе перестройте модель по полному diff `git diff "origin/$BASE"...HEAD` и обновите sha на HEAD.

### Приоритет режима при возобновлении

`mode` в разделе — сохранённый режим; запуск без флага наследует его, явный флаг текущего запуска переопределяет и обновляет его. Текущая авторизация пользователя приоритетнее сохранённых данных. Изменение wake-up prompt само по себе не меняет mode.

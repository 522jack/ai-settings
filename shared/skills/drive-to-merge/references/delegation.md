# drive-to-merge — выполнение утверждённых строк на фазе 3

Выполняйте строго в порядке таблицы. По мере выполнения записывайте результат каждой строки прямо в сессии.

## 3.1 Строки редактирования

Применяйте фрагмент напрямую через инструмент Edit (по одному файлу). После всех строк редактирования запустите
навык `check` (build + lint + tests). Если `check` не пройден, верните цикл на фазу 2.2 с новыми ошибками —
не отправляйте сломанный код.

## 3.2 Строки делегирования

Для каждой строки делегирования вызовите названного инженерного агента (`kotlin-engineer`, `compose-developer`,
`swift-engineer`, `swiftui-developer`) через инструмент Task. Запрос содержит:

- The reviewer comment quote.
- The proposed approach from the decision table.
- The files to touch.
- Scope guard: "Touch only the listed files. No new tests, no CI / workflow / build-config edits, no doc rewrites, no dependency changes, no refactors outside the listed files. Report back with a diff summary."

Делегаты выполняются последовательно, а не параллельно, чтобы их изменения не затирали друг друга. После возврата
каждого делегата выборочно проверьте diff; если он затронул что-либо за пределами перечисленных файлов (включая
`.github/`, не упомянутые каталоги тестов, `package.json` / `build.gradle`, docs), отмените эти изменения и покажите blocker.

## 3.3 Строки Ask-in-thread (NEEDS_CLARIFICATION)

Опубликуйте вопрос буквально как ответ в треде. Не разрешайте его. Запишите в `Commitments` файла состояния
`replied: true, resolved: false`.

## 3.4 Строки dismiss (терминальные вердикты)

Для PRAISE / OUT_OF_SCOPE / NO_ACTION / NIT+NO_ACTION:

1. Опубликуйте ответ по готовому шаблону + очищенной однострочной вставке.
2. Разрешите тред.
3. Запишите в `Commitments` файла состояния `replied: true, resolved: true`.

### Доставка ответа — правила безопасности

- Тело всегда передавайте через `jq -n --arg b ... --argjson r ...` в `gh api --input -`. Никогда не используйте `-f body="$TEXT"`.
- Обработка ограничения частоты: при `403` / `429` проверьте `x-ratelimit-remaining`, `x-ratelimit-reset` и `retry-after`. **Основное ограничение** (`x-ratelimit-remaining: 0`) — запланируйте `ScheduleWakeup` на `x-ratelimit-reset` (эпоха UTC) и завершите раунд. **Вторичное ограничение / обнаружение злоупотребления** (`retry-after: N`) — подождите локально `N + 5` секунд и повторите один раз; при повторном сбое покажите blocker. Никогда не тратьте раунд на плотный цикл повторов.
- Очистка вставки: нормализация NFKC → удалить BiDi + форматирующие символы → удалить HTML → удалить shell-метасимволы (`` ` ``, `$(`, `${`) → свернуть переводы строк → нейтрализовать `@mention` (удалить `@`) и cross-ref (`#123` → `issue-123`) → ограничить 120 символами. Если после очистки пусто — убрать вставку и использовать шаблон без неё.
- Ограничьте общую длину тела ответа 280 символами.
- Проверка владения тредом перед POST: запрос узла GraphQL → `pullRequest.number` совпадает, а `repository.id` совпадает с заголовком `Repository node id` файла состояния. При несовпадении пропустите строку, запишите `integrity_mismatch`, прервите раунд (не продолжайте POST для других строк).
- Проверка гонки перед POST: если после получения данных на фазе 2.3 тред разрешил кто-то другой, пропустите его (запишите `already_resolved`).

## 3.5 Commit + push

После строк, меняющих код (edit + delegate): один коммит на логическую группу замечаний рецензента. Сообщение коммита:
`Address review: <short summary>`. Push: обычный `git push` для fast-forward-добавлений; `git push --force-with-lease`
только если история переписана (rebase, amend, fixup squash). Обычный `--force` запрещён.

## 3.6 Повторный запрос ревью после изменений кода

Если любая строка BLOCKING / IMPORTANT действительно изменила код — повторно запросите ревью у всех рецензентов,
чей `state` в текущем снимке раунда был `CHANGES_REQUESTED`.

```bash
# GitHub: request a re-review from a specific user
gh api "repos/$OWNER/$REPO_NAME/pulls/$PR_NUMBER/requested_reviewers" \
  -X POST -F "reviewers[]=<login>"

# Copilot bot — the login is "copilot-pull-request-reviewer[bot]".
# Resolve its node id from the PR's suggestedReviewers / past reviewer pool:
COPILOT_NODE_ID=$(gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        suggestedReviewers { reviewer { login ... on Bot { id } ... on User { id } } }
        reviews(first:50) { nodes { author { login ... on Bot { id } ... on User { id } } } }
      }
    }
  }' -F owner="$OWNER" -F repo="$REPO_NAME" -F pr="$PR_NUMBER" \
  | jq -r '[.data.repository.pullRequest.suggestedReviewers[].reviewer,
            .data.repository.pullRequest.reviews.nodes[].author]
           | map(select(.login=="copilot-pull-request-reviewer"))[0].id // empty')

# Best-effort. If empty — Copilot is not part of this repo's review pool, skip silently.
if [ -n "$COPILOT_NODE_ID" ]; then
  MUTATION_OUT=$(gh api graphql -f query='
    mutation($pr:ID!,$user:ID!){
      requestReviews(input:{pullRequestId:$pr, userIds:[$user]}){
        pullRequest { id }
      }
    }' -f pr="$PR_NODE_ID" -f user="$COPILOT_NODE_ID" 2>&1)
  # Explicit error check — a bot no longer in the review pool returns an `errors` array,
  # not a non-zero exit code. Without this check the failure is silent.
  if jq -e '.errors // empty' <<<"$MUTATION_OUT" >/dev/null 2>&1 || [ -z "$MUTATION_OUT" ]; then
    # Record once, stop trying for the rest of this PR's lifetime.
    # Downgrade state-file header field `Copilot node id:` to the sentinel `unavailable`.
    COPILOT_NODE_ID=""
  fi
fi
```

После определения сохраните `$COPILOT_NODE_ID` в заголовке файла состояния (не запрашивайте его в каждом раунде). Если поиск вернул пустое значение или mutation вернула `errors`, запишите в заголовок sentinel `Copilot node id: unavailable` (единственный предусмотренный схемой способ отметить это; НЕ придумывайте отдельное поле `copilot_unavailable`) и прекратите попытки до конца жизни этого PR.

GitLab: `glab mr update $MR_IID --reviewer <user>` для людей; у GitLab нет полноценного аналога bot-review Copilot — пропустите.

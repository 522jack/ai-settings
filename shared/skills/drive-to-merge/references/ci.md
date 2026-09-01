# drive-to-merge — обработка CI на фазе 2.2

Исследуйте неуспешные проверки, классифицируйте их, повторяйте инфраструктурные сбои и передавайте строки
с исправлениями кода на делегирование в фазу 3.

## Определите id неуспешного запуска workflow (GitHub)

`statusCheckRollup` nodes expose `detailsUrl` of the form
`https://<host>/<owner>/<repo>/actions/runs/<RUN_ID>/job/<JOB_ID>` for GitHub
Actions checks. Parse it directly:

```bash
# Pick the first failed check from statusCheckRollup
FAILED_CHECK=$(jq -r '
  .statusCheckRollup[]
  | select(.conclusion=="FAILURE" or .conclusion=="CANCELLED" or .conclusion=="TIMED_OUT")
  | {name, conclusion, detailsUrl}
' <<<"$PR_INFO" | jq -s 'first')

DETAILS_URL=$(jq -r '.detailsUrl // empty' <<<"$FAILED_CHECK")
RUN_ID=$(echo "$DETAILS_URL" | sed -E 's#.*/runs/([0-9]+).*#\1#')

# Fallback when detailsUrl does not match the /actions/runs/ pattern
# (third-party checks via Checks API, or a check whose detailsUrl points elsewhere):
if ! [[ "$RUN_ID" =~ ^[0-9]+$ ]]; then
  RUN_ID=$(gh run list --branch "$HEAD" --limit 20 \
    --json databaseId,headSha,conclusion \
    --jq '[.[] | select(.headSha=="'"$(git rev-parse HEAD)"'") | select(.conclusion=="failure" or .conclusion=="cancelled" or .conclusion=="timed_out")][0].databaseId // empty')
fi

# If still empty — this is a non-Actions check (external status). Surface to the user
# as a blocker; this skill cannot download logs for arbitrary external check providers.
```

For GitLab: `glab ci view` on the pipeline id from `MR_INFO.head_pipeline.id`, or
`glab api "/projects/$PROJECT/pipelines/<pipeline_id>/jobs"` to enumerate jobs and
`glab api "/projects/$PROJECT/jobs/<job_id>/trace"` to pull a specific job log.

## Процесс для каждой проверки

Для каждой неуспешной проверки (после определения `RUN_ID`):

1. Download the job log:
   - GitHub: `gh run view --log-failed "$RUN_ID"`
   - GitLab: `glab ci trace` on the specific job id
2. Классифицируйте сбой:
   - сбой теста → симптом + путь к упавшему тесту;
   - сбой сборки → файл + ошибка;
   - lint / форматирование → конкретное правило;
   - ошибка инфраструктуры / runner / сети → можно повторить без изменения кода.
3. Выведите в сессии **таблицу сбоя CI**:

   ```
   | Check | Failure | Likely cause | Proposed action | Delegate |
   |-------|---------|--------------|-----------------|----------|
   | build | unresolved reference: Foo | renamed class, import stale | update import at <file:line> | implement |
   | test  | ExpectedFooTest.bar assert | behaviour change in diff | review diff vs test expectation | debug |
   | lint  | ktlint wrapping            | auto-fixable               | run `ktlint --format` | implement |
   | e2e   | network timeout            | flake                      | retry once                | — |
   ```
4. Автоматически повторите инфраструктурный сбой один раз (`gh run rerun "$RUN_ID" --failed`). Настоящие сбои не повторяйте.
5. Для строк с исправлением кода — делегируйте согласно **протоколу делегирования** (см. `references/delegation.md`, § Phase 3).
6. После появления исправлений: выполните push и вернитесь к фазе 2.1.

## Защита от цикла сбоев

Если одна и та же проверка не проходит 3 раунда подряд без нового коммита с диагностикой (та же сигнатура ошибки),
остановитесь и покажите blocker. Запишите его в `Blockers raised` файла состояния и спросите пользователя, что делать.

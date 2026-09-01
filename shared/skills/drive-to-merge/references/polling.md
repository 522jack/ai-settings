# drive-to-merge — опрос на фазе 4 (ScheduleWakeup)

Если раунд завершился состоянием «wait» (CI выполняется или ревью ожидается), решите, использовать ли
нативный auto-merge (немедленно выйти) или запланировать следующий раунд через ScheduleWakeup.

## Нативный путь auto-merge (режим `--auto`, CI всё ещё выполняется)

Когда mode равен `--auto`, **и** `Merge policy` равен `auto`, **и** CI всё ещё выполняется
(нет сбоев, только проверки `IN_PROGRESS` / `PENDING`), передайте ожидание платформе вместо опроса.
Процедура описана в [`references/merge.md`](merge.md), § «Native auto-merge path».

Если нативный auto-merge успешен: выйдите из цикла (без ScheduleWakeup). Если он не сработал (настройка
репозитория отключена), перейдите к обычному ScheduleWakeup ниже.

При политике `team-strict` полностью пропускайте нативный auto-merge независимо от режима; переходите к
ScheduleWakeup.

## Проактивное предложение автономности (режим по умолчанию, долгое ожидание)

Перед планированием ScheduleWakeup в **режиме по умолчанию**, если ожидание будет долгим:

- **Медленный CI** (pipeline ≥5 минут, обнаружен при первом входе в это ожидание): показать один раз —
  > "CI is running (slow pipeline). Type `auto-merge` to set native auto-merge and exit now, or I'll keep polling."
- **Человек-рецензент не отвечает** (два или более последовательных опроса по 1800 секунд без новой активности
  ревью): показать один раз —
  > "No reviewer activity after two rounds. Type `auto-merge` to set native auto-merge and exit, or I'll keep polling."

Если пользователь вводит `auto-merge`: выполните нативный путь auto-merge из `references/merge.md`
и выйдите. После отказа пользователя больше не предлагайте (молча) — максимум одно предложение
на категорию за запуск.

В режиме `--auto` это предложение не нужно — нативный auto-merge автоматически используется выше.

## ScheduleWakeup

Запрос пробуждения строится из сохранённого `Mode` в файле состояния (согласно «Mode precedence on
resume» в `references/setup.md`) — никогда не задаётся жёстко.

```
WAKEUP_PROMPT="/drive-to-merge"
[ "$STATE_MODE" = "auto" ] && WAKEUP_PROMPT="/drive-to-merge --auto"
# dry-run never reaches Phase 4 — it exits after the first decision table.

ScheduleWakeup(
  delaySeconds: <picked>,
  reason:       "drive-to-merge poll: <what we're waiting on>",
  prompt:       $WAKEUP_PROMPT
)
```

## Выбор `delaySeconds`

| Ожидается | delaySeconds |
|---|---|
| CI in progress, fast pipeline known (<5 min) | 270 (stay in cache window) |
| CI in progress, slow pipeline (≥5 min) | 600–1200 |
| Copilot bot review after re-request | 270 (stay in cache window for the first check); if still pending, 600 |
| Human reviewer after re-request | 1800 (30 min) |
| Approved but `mergeStateStatus == BLOCKED` on an unknown reason | 900 |

Избегайте диапазона 280–550 с: после 270 с истекает TTL кеша запроса, но при ожидании менее ~600 с промах кеша не окупается. Выбирайте ≤270 (сохранить кеш прогретым) или ≥600 (зафиксировать более длительное ожидание).

После 6 последовательных опросов без изменения состояния остановитесь, запишите в файле состояния `Blockers raised` и покажите пользователю.

После пробуждения: повторно прочитайте файл состояния и вернитесь к фазе 2.1.

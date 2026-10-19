# Исследовательская QA

## Шаг 4b: exploratory mode (без spec)

Если specification не предоставлена и пользователь хочет просто проверить приложение на проблемы («найди bugs», «проведи QA приложения», «потестируй», «проверь, не сломано ли что-нибудь»), переключитесь с spec-verification на heuristic-driven exploration. Структура шагов 0–3 сохраняется (provisioning, session ID, target connection); шаги 5–9 применяются без изменений. Вместо выполнения шага 4 используйте loop ниже.

### Бюджет scope

| Scope | Screens | Когда |
|---|---|---|
| Quick | ~5 | Один flow, быстрая sanity check |
| Standard | ~15 | По умолчанию — широкий охват core flows |
| Deep | 30+ | Предрелизный sweep, сложное app |

По умолчанию используйте Standard. Используйте Quick, если пользователь говорит «quick check» или называет один flow; Deep — если говорит «full QA» или «before release». Остановитесь, когда бюджет исчерпан или все доступные screens проверены.

### Heuristics исследования

На каждом screen применяйте эти восемь heuristics. Выбирайте input edge case, наиболее вероятный для выявления проблемы на этом screen, — не запускайте все три варианта для каждого field.

- **Visibility of system status** — loading indicators, progress, success confirmations, error messages. Запустите медленную операцию и наблюдайте.
- **Error handling consistency** — invalid input в каждом field; submit пустых forms; включите airplane-mode или остановите dev-server. Helpful error или silent fail.
- **Navigation consistency** — работает back-button, нет dead ends, один screen, доступный разными путями, даёт одинаковый результат.
- **State preservation** — поверните device или измените размер browser; переведите app background-foreground. Сохраняется ли state?
- **Input edge cases** — выберите один для каждого field: строка 200+ символов, special characters (emoji 😀 / RTL مرحبا / `<b>HTML</b>`) или пустая отправка required fields.
- **Empty states** — lists/feeds без данных: осмысленный empty state или похожий на сломанный screen.
- **Performance** — visible lag, janky animation, slow transitions. Отмечайте то, что ощущается неправильным; точное измерение вне scope.
- **Visual consistency** — fonts, spacing, colour, alignment по сравнению с посещёнными screens.

Базовые accessibility checks (шаг 5) сохраняются — touch-target size и unlabelled controls входят в каждый exploratory pass.

### Отчёт в exploratory mode

Вместо одной используйте две категории:

- **Bugs** — явно неправильное behaviour: crashes, broken functionality, data loss, visual defects. Используйте стандартный формат `BUG-[SESSION_ID]-[n]` из шага 6.
- **Observations** — неочевидные bugs, но заслуживающие внимания: confusing UX, inconsistent patterns, missing feedback, slow transitions, questionable design choices. «Разумный пользователь может столкнуться здесь с трудностями». Формат:

```
OBSERVATION-[SESSION_ID]-[n]: [Title]
Screen: [where]
Details: [what you noticed and why it matters to users]
Heuristic: [which heuristic flagged it]
```

Возвращайте main краткую Coverage Map: одна строка на screen/flow, сходные проверки группируйте; main сохраняет её в разделе `Acceptance / Exploratory QA` task report:

```
| # | Screen / Flow | Heuristics applied | Findings |
|---|---|---|---|
| 1 | [name] | [heuristics] | BUG-..., OBS-... or "—" |
```

В exploratory mode **не** выдавайте pass/fail verdict или ship/no-ship recommendation — нет spec, с которой можно сравнивать; вы исследуете, а не выносите оценку.

Специалист возвращает краткую receipt в ответе; main обновляет раздел `Acceptance / Exploratory QA` единого `swarm-report/<task-slug>.md` по `shared/rules/task-report.md`. Наследуйте task slug; session/run IDs — поля раздела, не новые имена файлов. Сохраняйте scope, существенные Bugs/Observations, coverage, проверенное code/scope/environment и ограничения, без сырых транскриптов и пустых findings. Re-exploration: перечитайте этот раздел, повторно проверьте каждый bug (`Fixed` / `Still present` / `Cannot reproduce`), обновите его статус без дубля, затем проверьте соседние области на regressions. Legacy reports можно читать, новые по старым путям не создавать.

---

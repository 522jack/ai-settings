# Regression mode

Вход `regression-scenario`: root cause, reproduce, expected/actual, exact fixed files/commits (`<slug>-debug.md` или caller hint). Один целевой case; пропустить широкое coverage discovery/prioritization. Unit предпочтителен; integration только при необходимых real collaborators. Тест проверяет observable contract, не форму implementation.

## RED/GREEN evidence

1. Определите точные buggy и fixed states по task/debug/diff/history относительно обнаруженной default/base branch; не считать все commits ветки «исправлением». Если ambiguity нельзя разрешить — сообщить NOT_ATTEMPTED с конкретным missing input.
2. Проверяйте исходный buggy state в отдельном temporary worktree/snapshot вне пользовательского рабочего дерева. Перенесите только новые test files и необходимый разрешённый test setup. Сохраните test inputs/toolchain и команды одинаковыми. Незакоммиченный fixed patch зафиксируйте как bytes/hash и применяйте в отдельном snapshot. Не менять user's branch/index/files.
3. Запустите narrow regression test на buggy code: RED именно на assertion сценария, не compilation/setup failure. Затем тот же тест на fixed state → GREEN. При multi-commit/merge fix используйте доказанный buggy state; не принимайте конфликтную сторону автоматически.
4. RED+GREEN → VERIFIED receipt. GREEN на buggy code → INEFFECTIVE: сообщить пропущенный аспект, делегировать изменение дизайна теста, а не спасать ложную assertion. Build/env failure → NOT_ATTEMPTED/FAILED без заявления о RED.
5. Cleanup только task-owned temporary worktree/files после evidence; не использовать reset --hard/clean в пользовательском дереве. Новые test files сохранять и добавлять в git; ineffective case не представлять завершённой защитой.

После VERIFIED выполните relevant существующий suite (не весь проект, если required rules не требуют); mobile runtime QA только при explicit request. Тест не написан / ineffective / still failing after 3 содержательных исправлений → `swarm-report/<slug>-regression-coverage.md`:

```markdown
# Regression Coverage Diagnosis: <slug>
Date: <date>
Status: INEFFECTIVE | FAILED | NOT_ATTEMPTED
## What was tried
<approach, assertion, commands/states>
## Technical obstacle
<concrete failing mechanism>
## To make testable
<required setup/design change; no unsolicited production edit>
```

`swarm-report/<slug>-write-tests.md` содержит filenames, tested state hashes, RED/GREEN commands/results и строку `Regression contract: VERIFIED — RED on <buggy state>, GREEN on <fixed state>` либо реальный non-verified status + diagnosis path. Не заявлять GREEN with fix до реального запуска.

Commit/push только если прямо разрешены текущей задачей/сессией, только разрешённая feature/fix branch; regression mode сам по себе не даёт этой авторизации. Не обходите hooks, не переписывайте историю. При разрешённом commit subject называет конкретный regression scenario.

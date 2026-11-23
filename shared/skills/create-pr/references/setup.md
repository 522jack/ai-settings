# Общая подготовка PR/MR

1. Определите host из origin, используйте gh/glab, remote default BASE (remote symbolic HEAD/show origin; fallback лишь реально существующий main/master/develop), текущую BRANCH и user.email. Не создавать PR с detached HEAD/защищённой default product branch.
2. Получите existing PR URL/draft/body/state. GitHub `gh pr view --json url,isDraft,number,body`; GitLab `glab mr view --output json`. Сохраняйте rc/stderr: только explicit no-open-PR/MR означает absence; auth/CLI/API errors — stop, не создавать duplicate.
3. Проверьте выбранный mode до mutations. Обычный push новых commits разрешён запросом PR лишь в рамках текущей авторизации; никогда не создавать commits автоматически. Если upstream отсутствует — `git push -u origin BRANCH`, иначе push только при локальных новых commits. Non-fast-forward/error → stop с evidence; force/history rewrite вне scope.
4. Analyze log/diff/stat относительно merge-base BASE, including pending changes как uncommitted limitations, не выдавать их за shipped PR code. Slug caller → branch without feature/fix/hotfix/bug/chore/refactor/docs prefixes.
5. Найдите существующие артефакты: `swarm-report/<task-slug>.md`, spec, `docs/plans/<slug>/plan.md` с задачами в нём или в соседнем `tasks.md`, test plan. Отсутствие отчёта допустимо. Не выдумывайте артефакты или результаты.

Применяйте `$HOME/dotfiles/ai/shared/rules/workflow.md` для readiness. Учитывайте результаты только для совпадающего состояния, scope и среды. Навык использует существующие проверки. При отсутствии обязательного результата сообщите ограничение.

# Spec: расположение и handoff

Постоянный deliverable — `docs/specs/YYYY-MM-DD-<slug>.md`, под контролем версий. Дата — день создания spec; slug наследуется от задачи и не меняется при review/save. Создайте `docs/specs/`, если его нет.

Main хранит краткие status, input/constraints, значимые findings/решения, review verdict и resume cursor в разделе `Spec` единственного `swarm-report/<task-slug>.md` по `$HOME/dotfiles/ai/shared/rules/task-report.md`. Специалисты возвращают receipt в ответе. Не копируйте AC и текст spec в отчёт: используйте ссылку и IDs.

При сохранении утверждённого черновика измените frontmatter `status:` с `draft` на `approved`, как предусмотрено SKILL.md. В разделе Spec отмечайте done либо реальный pending status, не создавайте и не удаляйте отдельные state-файлы. Legacy spec-state допустим только для чтения; прежние пользовательские файлы сохраняйте. Новые deliverables добавьте в git, commit/push только при текущей авторизации.

Handoff: путь к spec, цель/ключевые AC/решения, review verdict, открытые риски и первый шаг. Spec самодостаточен для реализации, но planning-only запрос не разрешает её автоматически; продолжайте лишь внутри уже авторизованной задачи.

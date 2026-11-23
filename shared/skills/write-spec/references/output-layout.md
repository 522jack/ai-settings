# Spec: расположение и handoff

Постоянный deliverable — `docs/specs/YYYY-MM-DD-<slug>.md`, под контролем версий. Дата — день создания spec; slug наследуется от задачи и не меняется при review/save. Создайте `docs/specs/`, если его нет.

Если нужен отчёт по `$HOME/dotfiles/ai/shared/rules/task-report.md`, main хранит состояние в разделе `Spec`. Для AC достаточно ссылки и идентификаторов.

При утверждении измените frontmatter `status:` с `draft` на `approved` по правилам SKILL.md. Если ведётся отчёт, отразите текущий статус. Новые deliverables добавьте в git. Commit/push требуют авторизации.

Handoff: путь к spec, цель/ключевые AC/решения, review verdict, открытые риски и первый шаг. Spec самодостаточен для реализации, но planning-only запрос не разрешает её автоматически; продолжайте лишь внутри уже авторизованной задачи.

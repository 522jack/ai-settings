# --refresh

Precondition existing PR (draft or ready). Нет PR → stop, предложить draft/default.
Обновить только body из actual diff/artifacts. Status/title/labels/reviewers неизменны.
Сохранить verbatim user-edit markers, Screenshots/demo, checked checklist. Empty body = regenerate from scratch, не ошибка.
GitHub gh pr edit --body-file FILE; GitLab supported file/stdin body update. Выход URL+updated. Не переводить status и не запускать quality pipeline.

# --draft

Precondition: PR absent или existing draft. Ready PR → error с URL и --refresh.
Создание: gh pr create --draft --title TITLE --body-file FILE --base BASE; glab mr create --draft с поддерживаемым данной CLI способом передачи тела из file/stdin. Existing draft → edit body. Labels лишь существующие и применимые; reviewers не назначать без explicit request. Заголовок из task/branch/первого commit, ≤70 chars, без WIP/Draft prefix.

Body: actual partial changes, motivation, available artifact links, planned verification clearly marked pending, truthful status, existing screenshots/checklist. UI screenshots may be linked/pending; не требовать mobile runtime capture без opt-in. Draft не требует завершённого quality gate. Выход draft URL + progress/remaining checks по риску; не запускать downstream skills автоматически.

# --promote

Precondition existing draft; absent/already ready → stop с URL/--refresh hint. Перед readiness потребуйте evidence, соответствующее risk route и exact state из setup.md; missing required check → сообщить необходимое, не маркировать ready или PASS.
Сохранить title unless user requested change; обновить final body с actual verification/skips/risks. Preserve user markers/screenshots/checked items. Add only missing existing labels, no reviewer assignment unless explicitly requested. UI screenshot отсутствие не запускает mobile runtime QA.
После успешного body update: gh pr ready. GitLab glab mr update --ready; fallback --unwip только если stderr именно unknown --ready flag. Другой error реальный: показать и stop. Если body updated, ready failed — сообщить partial effect без повторного создания.
Выход URL + ready state; дальнейший drive-to-merge лишь предложение, не автоматическая отправка комментариев/слияние.

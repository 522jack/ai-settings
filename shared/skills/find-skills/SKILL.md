---
name: find-skills
description: "Найти и оценить устанавливаемый навык агента, когда пользователь просит навык для конкретной задачи или расширение возможностей. Обычный вопрос «как сделать» не требует поиска навыков; установка выполняется только в явно разрешённой области."
---

# Поиск навыков

Уточните capability/domain, сначала проверьте доступный каталог уже установленных skills. При missing capability найдите кандидатов через skills.sh или `npx skills find QUERY` (доступный approved CLI); не запускайте поиск только потому, что задачу можно выполнить навыком.

До рекомендации прочитайте реальный SKILL.md и источник/репозиторий: scope, внешние permissions, dependencies, supported runtime, качество instructions, maintenance. Popularity/install count/stars — вспомогательные signals, не достаточное доказательство качества; не угадывайте текущие числа.

Представьте минимальный набор: name/purpose, source link, fit/risks, command `npx skills add OWNER/REPO@SKILL` или available skill-installer. Global `-g` только когда user global scope разрешён; `-y` не substitutes authorization. Пользователь уже попросил install выбранного skill → выполните в его scope без нового confirmation, проверив install result; один search request не разрешает установку/обновление всех skills.

No candidate → сообщите lookup limitations и продолжайте исходную задачу доступным способом; custom skill creation предлагайте лишь при repeated useful workflow. Не устанавливайте неизвестный пакет для самого поиска без соответствующей авторизации; не меняйте unrelated skills/config.

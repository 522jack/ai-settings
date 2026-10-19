---
name: context7-mcp
description: "Получить актуальную документацию и примеры конкретной библиотеки/framework через Context7 для API, настройки или реализации с выбранной версией. Упоминание технологии без потребности в документации само по себе не активирует lookup."
---

# Документация библиотек

При необходимости актуального API проверьте доступность Context7. `resolve-library-id`: libraryName из задачи, query конкретный вопрос. Выберите official/primary package и указанную версию; exact name/version важнее benchmark рейтинга. Затем `query-docs` с libraryId и точным query; не повторяйте lookup того же version/question без нового пробела.

Ответ/код основывайте на полученных docs, укажите source/version где существенно. Если Context7 недоступен — официальный documentation/web lookup с явным limitation, не угадывать вызов инструмента и не считать отсутствие результата отсутствием API. Не расширяйте задачу установкой MCP/package или framework migration.

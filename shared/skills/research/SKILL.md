---
name: research
description: "Сравнить технические подходы или проверить реализуемость до реализации с независимым сбором evidence и общим синтезом. Консорциум нужен при двух и более полезных направлениях; узкий поиск по коду, документация одной библиотеки и отладка направляются напрямую."
---

# Исследование

Вход: topic, context и constraints. Не меняйте продуктовый код и не превращайте исследование в разрешение реализации. Выберите только направления, дающие отдельный сигнал:

| Track | Когда | Исполнитель |
|---|---|---|
| Codebase | Existing code/patterns/modules | Explore |
| Architecture | Module/layer/API boundaries | architecture-expert |
| Web | Industry practice/benchmarks/external approaches | source-researcher, focus web |
| Docs | Конкретный внешний API/framework | source-researcher, focus library-docs |
| Dependencies | Добавление/замена JVM/KMP dependency | source-researcher, focus dependency-intelligence |

0–1 направление → выполнить узкую задачу напрямую через соответствующий доступный инструмент/специалиста; не создавать consortium artifacts. Не запускать research автоматически для малой правки. ≥2 → slug kebab-case, прочитайте [artifacts.md](references/artifacts.md) для state/report и [expert-prompts.md](references/expert-prompts.md) только для выбранных tracks. Runtime/profile определяет tools/model; недоступность источников обозначайте, не имитируйте lookup.

Запустите независимые gatherers параллельно; они не видят результаты друг друга и никогда не синтезируют общий вывод. Web/Docs/Dependencies остаются отдельными экземплярами. Только оркестратор объединяет convergence/contradictions/gaps, не сглаживает разногласия. Проверяйте меняющиеся внешние данные первичными источниками; feasibility утверждения проверяйте минимальным экспериментом, если он входит в разрешённую область.

После синтеза прочитайте соответствующий mode в [auto-review.md](references/auto-review.md): product/scope decision → independent business-analyst; чисто technical → tech-sanity. Не запускайте панель по умолчанию.

Уточняйте через доступный chat question tool (или чат при отсутствии инструмента), по одному существенному вопросу за раунд. Уже имеющуюся авторизацию сохраняйте; исследуемые пробелы решайте без пользователя. Блокирующее user решение разрешите до готового отчёта, external unknown храните с evidence/owner. Не задавайте вопросы через файлы.

Выход: ready report `swarm-report/research/research-<slug>.md`, done state, краткий chat verdict/recommendation и следующий шаг в пределах запроса. Scope explosion, конфликт требований, нет viable option, persistent source/access block → evidence и конкретное решение; не расширяйте задачу и не ждите бесконечно.

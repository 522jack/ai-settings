# Структура вывода и передача

## Paths

| Файл | Срок жизни | Коммитится? | Назначение |
|---|---|---|---|
| `docs/plans/<slug>/plan.md` | Постоянный | Да — проверяется в PR | Технический подход, затронутые файлы, решения, риски. |
| `docs/plans/<slug>/tasks.md` | Постоянный | Да | Упорядоченный чек-лист задач с зависимостями и приёмкой каждой задачи. |
| `docs/plans/<slug>/progress.md` | Постоянный (изменяемое содержимое) | Да — журнал выполнения / аудит | Изменяемый статус и журнал выводов. Отделён от стабильного плана, чтобы рабочие изменения не переписывали дизайн. |
| `./swarm-report/plan-<slug>-state.md` | Операционный | Нет (gitignored) — удалить после | Результаты исследования, журнал циклов ревью. После работы удаляется. |

`docs/plans/` намеренно является соседом `docs/specs/`: spec = *что* (требования + AC), plan =
*как* (дизайн + задачи). Оба находятся в git, потому что их ценность — возможность ревью в PR
и возобновления позже; именно этого свойства не хватает встроенному plan mode.

Slug derivation: see `SKILL.md` Phase 0.1.

## Жизненный цикл статуса

`plan.md` frontmatter `status`: `draft` → `approved` (Phase 4 on PASS/CONDITIONAL). On
`review_verdict: escalate`, leave `status: draft` and stop with the blocking open questions
surfaced.

`review_verdict`: `pending` → `pass` | `conditional` | `escalate`, записывается циклом фазы 3 (и
receipt профиля).

## Сообщение подтверждения (по умолчанию, автономный режим)

Одно предложение, например:

> Plan saved to `docs/plans/offline-mode/plan.md` (review: PASS, 7 tasks). Starting with T-1 —
> add the offline cache layer.

Без запроса подтверждения. С `--interactive` покажите краткое резюме и задайте один вопрос «запускать/изменить»
до переключения в `approved`.

## Правила передачи

- **Не** вызывайте downstream-навыки автоматически. Предложите следующий шаг (реализовать задачи; затем
  `/write-tests`, `/check`, `/finalize`, `/acceptance`) and let the user/agent drive — toolbox
  model. (The mandatory Phase 3 inline `multiexpert-review` call and the Phase 3.5 adversarial
  red-team Agent call are the review gate built into this skill, not downstream chains — these are
  the sanctioned in-skill invocations.)
- `progress.md` — текущий журнал: по мере завершения каждого `T-N` отметьте его и добавьте однострочный
  вывод. Реализующий агент коммитит план и код вместе, чтобы в PR был виден план, создавший изменение.
- `create-pr` обнаруживает `docs/plans/<slug>/plan.md` и ссылается на него в теле PR; `finalize`
  привязывает проход `code-reviewer` к тому же плану. Кроме записи файла дополнительная связка не нужна.

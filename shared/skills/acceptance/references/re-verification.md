Referenced from: `plugins/developer-workflow/skills/acceptance/SKILL.md` (§Re-verification Loop).

# Acceptance — цикл повторной проверки

При повторном входе в fix-loop:

1. Повторно проверить текущие inputs и Planned Checks: requirements/AC/scenario, spec/test-plan,
   scope и разрешённые runtime checks могли измениться.
2. Зафиксировать exact code + scope + environment согласно
   [state-and-schema.md](state-and-schema.md): committed/staged/unstaged/relevant untracked code,
   requirements/AC/scenario scope, toolchain/dependencies/config/runtime и команда проверки.
   Вычислить identity один раз для конкретного состояния. `diff_hash` не ограничивается
   `sha256(git diff <base>...HEAD)`; HEAD/Date недостаточны.
3. Для каждой проверки сопоставить её прежние inputs/evidence с текущими:

| Предыдущий вердикт | Evidence проверенного code + scope + environment/command | Действие |
|---|---|---|
| `PASS`, `WARN` или `SKIPPED` | доказано exact-state совпадение и применимость текущему плану | Повторно использовать artifact с pointer/evidence; сохранить прежний verdict. |
| `FAIL` | доказано неизменённое состояние | Сохранить FAIL и прежний evidence без retry. Повтор допустим только для явно запрошенного эксперимента. |
| любой | произошла реальная мутация затронутого code/scope/environment | Повторить затронутую проверку, если она разрешена текущим планом. |
| любой | legacy receipt или недостаточное/нечитаемое exact-state evidence | Не reuse. Получить evidence текущего состояния разрешённой проверкой; известный FAIL сохранять до новой оценки, без автоматического unchanged retry. |

Общий изменившийся хэш не требует повторять unaffected checks: их reuse допустим только
с доказательством неизменности конкретного checked code + scope + environment/command.
Отсутствующий `diff_hash` или один хэш committed diff не доказывает идемпотентность.
При изменении spec/test-plan повторно оценить scope; `business-analyst` и другие affected
checks выполняются для обновлённых требований/сценариев.

4. Для повторно выполненных проверок сохранить свежий artifact и identity/evidence.
   `manual-tester` выполняется только если входит в текущий план: для Android/iOS это требует
   `mobile_manual_requested == true`. Ранее запрошенный mobile run не становится opt-in
   для нового пользовательского запроса. Изменение spec/test-plan или недостающие hashes
   сами по себе не разрешают mobile emulator/simulator/device QA.
5. Агрегировать текущие и reused результаты в `swarm-report/<slug>-acceptance.md`, сохраняя
   WARN/FAIL и pointers на evidence; обновить state и history.
6. Максимум 3 содержательных цикла с реальной мутацией или явно запрошенным экспериментом.
   Unchanged FAIL не создаёт новый цикл. При persistent genuine blocker сохранить evidence
   и эскалировать; unresolved blocker не разрешает ship без соответствующего решения.

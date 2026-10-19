# Метаданные плана тестирования в отчёте задачи

Постоянный `docs/testplans/<slug>-test-plan.md` — источник истины. Main создаёт/обновляет только раздел `## Test plan` в едином `swarm-report/<task-slug>.md` по `$HOME/dotfiles/ai/shared/rules/task-report.md`, сохраняя остальные разделы и статусы. Task-slug наследуется от caller; при самостоятельном запуске выбирается один раз. Специалист возвращает готовый текст main. Отдельных receipt/state/JSON файлов нет; legacy receipt допускается только прочитать.

````markdown
## Test plan
- План: [постоянный документ](../docs/testplans/<slug>-test-plan.md).
- Coverage: <AC/phases кратко>; findings/limitations: <только существенное>.

```yaml
test_plan:
  status: Draft
  permanent_path: docs/testplans/<slug>-test-plan.md
  source_spec: <path or inline spec>
  review_verdict: pending
  review_warnings: []
  review_blockers: []
  phase_coverage: []
  platform: []
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
```
````

YAML выше — именованный блок `test_plan` внутри раздела, **не frontmatter** общего файла. Downstream `multiexpert-review` и `acceptance` читают именно `## Test plan`, а не первый YAML/frontmatter файла и не статусы других фаз.

- `status`: Draft после генерации; Ready после PASS/WARN review; Approved только при явном утверждении пользователя; Mounted для существующего постоянного файла без повторной генерации.
- `review_verdict`: pending при создании, PASS|WARN|FAIL после review, skipped при mount. PASS/WARN/skipped разрешают proceed; FAIL/pending — blockers.
- `review_warnings` — короткие non-blocking нарушения (d/e/g); `review_blockers` — нарушения (a/b/c/f). На PASS/pending/skipped оба пусты. Не дублируйте findings в прозе.
- `phase_coverage`: реально присутствующие фазы; [] без фаз, при mount можно опустить, если невозможно надёжно вывести.
- `platform`: копируется из spec дословно, иначе [].
- `created`/`updated`: ISO date; updated меняется при изменении permanent файла или metadata.

Mount потребитель добавляет эти metadata в тот же раздел: status Mounted, review_verdict skipped, source_spec existing (pre-orchestration). Самостоятельный вызов использует тот же контракт, отдельный task slug для последующего acceptance не создаётся. Существующие permanent документы автоматически не переименовываются.

# Review gate плана

Для ограниченного плана достаточно саморевью, если независимость не обязательна. Для высокого риска в режиме с субагентами используйте `multiexpert-review` с профилем implementation-plan и релевантными перспективами. В одиночном режиме проверьте риски сами и укажите, какие независимые проверки не выполнены. Требуемое независимое ревью блокирует утверждение до результата.

```text
profile: implementation-plan
slug: <slug>
---
docs/plans/<slug>/plan.md
```

Проверяйте план, задачи и источники требований. Сверьте пути, проверяемую приёмку, существенные сценарии отказа, связь AC с задачами и применимые команды. Новые тесты и ручное mobile QA требуют явного запроса.

Max 3 содержательных cycles: PASS → gate; CONDITIONAL → локально исправить major, после cap оставить non-blocking note; FAIL → исправить blocker и повторить affected review после реальной мутации. Unchanged plan reuse, не очередной panel. Remaining blocker после cap → review_verdict escalate, status draft, blocking Open Questions; сохранить audit state.

В режиме с субагентами дополнительный исполнитель оправдан, если осталась существенная неопределённость реализации. Проверяйте конкретный пробел в контракте или цепочке действий.

Не использовать planning review как обязательную downstream-цепочку для всей реализации. Final implementation verification идёт risk route, explicit навыки/hooks/CI сохраняются.

# Phase C/D — выбор по фактическому diff

## C: optional pr-review-toolkit

Проверьте доступность только выбранных агентов, отсутствующих явно SKIP; не устанавливайте plugin автоматически.

| Агент | Когда нужен |
|---|---|
| pr-test-analyzer | Diff меняет существующие тесты или их достоверность |
| silent-failure-hunter | Diff меняет обработку ошибок, fallback, retry или подавление failure |
| type-design-analyzer | Diff меняет типы/инварианты/nullability/unions/public model |
| comment-analyzer | Добавленные/изменённые comments/doc-comments |

Не запускайте всех по умолчанию. Направление, уже покрытое независимым reviewer для того же состояния, повторно не проверяйте. Отсутствие нового теста без opt-in — рекомендация, не BLOCK.

## D: domain review

| Эксперт | Триггер |
|---|---|
| architecture-expert | Новый module/API, dependency direction, layer violation |
| security-expert | auth/payment/PII/migrations или triggers ниже |
| performance-expert | Hot path/N+1/large buffers/threading/concurrency |
| ux-expert | UI/copy/a11y/animation |
| build-engineer | Build scripts/plugins/version catalogs |
| devops-expert | CI/CD/deploy/Docker/IaC |
| business-analyst | Реальное изменение requirements/scope |
| test-coverage-expert | Только explicit tests/coverage + --coverage-audit |

Покройте сработавшие risk areas, сохраняя минимальный набор независимых ролей. Несколько непересекающихся направлений запускайте параллельно с отдельными prompts. Ни одного trigger → SKIP D.

Security triggers по `git diff -M` от merge-base с включением текущих tracked/untracked изменений: путь проверяйте новый, content — только changed hunks.

- Broad: network/api/http/rpc/graphql surface.
- Narrow: auth/crypto/token/session; credential storage (Keychain/KeyStore/preferences/cookie/localStorage); новая dependency; DB migration/sql/schema; unsafe deserialization/config.
- ≥1 narrow, объявленный risk area или ≥2 независимых broad signals → полное security review; один broad → scoped regression review конкретной поверхности; нет сигналов → skip.
- `--skip-security-review REASON` только как явный выбор пользователя на этот раунд: сохраняйте reason дословно. Не превращает unresolved finding в PASS и не отменяет Non-negotiables.

Критичная security finding с confidence 50 помечается `[please verify]`, остаётся BLOCK до проверки/решения. Performance/architecture finding за пределами узкой правки → escalation.

Coverage по умолчанию SKIP (tests not requested), не acknowledged risk. При opt-in агент читает только relevant test plan/diff/tests и возвращает receipt; main обновляет подраздел `Review / Coverage` task report; PASS / GAPS_RESOLVED после check --coverage-gate / ESCALATE если надёжный тест создать не удалось. Test generation делегируется engineer.

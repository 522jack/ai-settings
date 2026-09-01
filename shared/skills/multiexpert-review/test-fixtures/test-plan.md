---
type: test-plan
slug: smoke-test-test-plan-fixture
---

# План тестирования: кеширование профиля пользователя

_Синтетическая фикстура для smoke-тестирования профиля `test-plan`. Приведённые ниже критерии приёмки и тестовые случаи выдуманы для проверки детектора/roster — соответствующего исходного spec в этом репозитории нет._

## Критерии приёмки (выдуманы для этой фикстуры)

- AC-1: `GET /api/users/:id` returns cached result when cache hit
- AC-2: Cache hit rate ≥80% under steady state
- AC-3: p99 latency ≤50ms for cached requests
- AC-4: Cache invalidates on `POST /api/users/:id` update
- AC-5: Redis outage: endpoint falls back to DB, returns 200 with degraded latency

## Тестовые случаи

### TC-1: попадание в кеш при повторном чтении
**Priority:** P0

Шаги:
1. Warm cache by calling `GET /api/users/42`
2. Call `GET /api/users/42` again within 5 minutes

Ожидается: второй вызов возвращает заголовок `X-Cache: HIT`, время ответа <20 мс.

### TC-2: промах кеша при холодном чтении
**Priority:** P1

Шаги:
1. Flush Redis
2. Call `GET /api/users/42`

Ожидается: ответ содержит `X-Cache: MISS`, данные пользователя загружены из БД.

### TC-3: инвалидация кеша при обновлении пользователя
**Priority:** P0

Шаги:
1. Warm cache for user 42
2. POST user update for 42
3. GET user 42 again

Ожидается: ответ содержит `X-Cache: MISS` (инвалидация произошла), отражены новые данные.

### TC-4: fallback при сбое Redis
**Priority:** P1

Шаги:
1. Stop Redis container
2. Call `GET /api/users/42`

Ожидается: 200 OK, ответ загружен из БД, задержка выросла, но остаётся менее 200 мс.

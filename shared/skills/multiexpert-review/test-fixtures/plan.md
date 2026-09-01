---
type: plan
slug: smoke-test-plan-fixture
---

# План: добавить слой кеширования для API профиля пользователя

## Цель

Добавить кеш на базе Redis для endpoint `GET /api/users/:id`, чтобы снизить нагрузку на базу данных в часы пик. Цель: доля попаданий в кеш 80%, задержка p99 менее 50 мс.

## Подход

1. Добавить зависимость клиента Redis (Lettuce) в модуль user-service.
2. Обернуть существующий вызов `UserRepository.findById` паттерном cache-aside в новом декораторе `CachedUserRepository`.
3. TTL: 5 минут. Инвалидация: при обновлении через `POST /api/users/:id`.
4. Метрики: счётчики Micrometer для cache-hit / cache-miss, gauge для использования пула соединений Redis.

## Затронутые модули

- `user-service/src/main/kotlin/com/example/user/repository/` — новый `CachedUserRepository.kt`, подключить через конфигурацию Spring
- `user-service/build.gradle.kts` — добавить `io.lettuce:lettuce-core`
- `user-service/src/main/resources/application.yml` — конфигурация соединения Redis
- `deployment/helm/user-service/values.yaml` — объявление sidecar Redis

## Риски

- Согласованность кеша при развёртывании нескольких экземпляров — обеспечивается TTL, инвалидации через pub/sub нет.
- Сбой Redis ухудшает задержку, но не должен ломать чтение — при недоступности Redis использовать fallback на БД.

## Открытые вопросы

- Нужно ли использовать Redis AUTH / TLS? (Зависит от среды развёртывания — спросить команду инфраструктуры.)

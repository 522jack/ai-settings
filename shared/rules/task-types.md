# Маршрутизация по типам задач

Матрица маршрутизации: тип задачи → source of truth и минимальная проверка существующими средствами проекта.

Политика новых тестов, fixtures, baseline и mobile QA имеет один источник: [qa-and-testing.md](qa-and-testing.md). Глубина review определяется [workflow.md](workflow.md).

## Матрица маршрутизации

| Тип задачи | Source of truth | Проверка по умолчанию |
|---|---|---|
| Feature | Spec / AC list / task | L0–L1 + существующие релевантные tests |
| Bug fix | `debug.md` или описание воспроизведения | воспроизведение доступным без device способом + L0–L1 + существующие tests |
| Tech migration | доступный before-state baseline / requirements | L0–L1 + существующие tests |
| Library version bump | changelog / requirements / существующий baseline | L0–L1 + существующие tests |
| Refactoring | существующие tests или описанный контракт | L0–L1 + существующие tests |
| Infrastructure change (network / storage / auth / DI) | Spec / requirements | L0–L1 + существующие tests |
| UI / design task | Figma / предоставленные screenshots | L0–L1; design/code review |
| Performance optimization | Benchmark baseline — числа до/после | L0 + benchmark measurement |
| Investigation / research | Research output | L1, если создан код |

L0/L1 можно сузить до затронутого app/module. Проектные hooks и CI остаются авторитетными: pipeline не отключает уже настроенные проверки, но сам не создаёт новые тесты без просьбы пользователя.

## Baseline до изменений

Использовать доступный снимок текущего поведения, если он уже существует:

1. passing tests, покрывающие изменяемое поведение;
2. предоставленные screenshots или ранее сохранённая manual QA session;
3. API snapshots, benchmark numbers, требования или AC.

Если baseline отсутствует, описать intended behavior и риск отсутствия runtime-сравнения; ограничения получения baseline — в `qa-and-testing.md`.

### Что не является baseline до изменений

- «Всё должно быть в порядке» — не baseline.
- Code review или static analysis изменения — они проверяют намерение, а не runtime behavior.
- Успешный build — доказывает компиляцию, а не поведение.

# Сценарии и выполнение QA

## Шаг 1: поймите спецификацию

- Прочитайте все предоставленные inputs: mockups, PRDs, acceptance criteria, user stories, feature descriptions.
- Если source неоднозначен или неполон, задайте **один** уточняющий вопрос до продолжения.
- Если spec не предоставлена, выведите ожидаемое behaviour из самого приложения и явно отметьте каждое предположение.

---

## Шаг 2: выберите test strategy

Каждый test suite разделён на три tiers. До написания test cases решите, какие tier(s) запускать:

| Tier | When to run | What it covers |
|------|------------|----------------|
| **Smoke** | При запрошенной общей sanity check или затронутом критическом flow | Все P0-priority flows — необходимые для удобства использования приложения: auth, точка входа в core feature, критические операции с данными |
| **Feature** | После реализации или изменения конкретной feature | Все flows изменённой feature: основной сценарий, edge cases, error states |
| **Regression** | Перед релизом или после крупных рефакторингов | Полный suite по всем features для выявления непреднамеренных побочных эффектов |

Для запрошенной проверки конкретного X выберите **Feature**; добавляйте **Smoke** только для затронутых критических flows или явно запрошенной общей проверки. Если неясность влияет на scope или разрешения, уточните её.

---

## Шаг 3: напишите test cases

Для каждого flow напишите test cases, используя SESSION_ID, определённый на шаге 0.2:

```
TC-[SESSION_ID]-[n]: [Краткое название]
Tier: [Smoke / Feature / Regression]
Target: [Mobile / Web]
Preconditions: [Состояние app, account, необходимая настройка data]
Steps:
  1. [Конкретное действие]
  2. [Конкретное действие]
Expected Result: [Что должно произойти — behaviour + visual]
Spec Reference: [Mockup frame / PRD section / story ID — или "heuristic"]
```

Покройте: happy paths, edge cases, empty states, error states, loading states, back navigation, orientation change (только mobile), responsive breakpoints (только web).

---

## Шаг 4: выполните tests

Проходите test cases с помощью MCP tools ниже. **Каждый шаг — реальное действие, без гипотез.**

### Mobile / Desktop interaction [mobile]

| Цель | Tool |
|------|------|
| Посмотреть текущий screen | `screenshot` |
| Описать содержимое screen с помощью AI / заметить visual anomalies | `analyze_screen` |
| Проверить raw UI element tree | `get_ui` |
| Утвердить, что element виден на screen | `assert_visible` |
| Утвердить отсутствие element на screen | `assert_not_exists` |
| Дождаться появления element (loading states) | `wait_for_element` |
| Нажать по coordinates или element | `tap` / `find_and_tap` / `tap_by_text` |
| Выполнить scroll или swipe | `swipe` |
| Ввести text | `input_text` |
| Нажать hardware keys (back, enter, rotate) | `press_key` |
| Выполнить long-press или double-tap | `long_press` / `double_tap` |
| Скопировать / вставить через clipboard | `copy_text` / `paste_text` / `get_clipboard` / `set_clipboard` |
| Эффективно выполнить sequence actions | `batch_commands` |

### Mobile app lifecycle [mobile]

| Цель | Инструмент |
|------|------|
| Запустить / остановить app | `launch_app` / `stop_app` |
| Проверить active screen (Android) | `get_current_activity` |
| Прочитать crash logs или errors | `get_logs` / `clear_logs` |

### Mobile system & permissions [mobile]

| Goal | Tool |
|------|------|
| Выдать или отозвать permission | `grant_permission` / `revoke_permission` |
| Проверить OS version и screen size | `get_system_info` |
| Получить performance metrics | `get_performance_metrics` |

### Web interaction [web]

| Goal | Tool |
|------|------|
| Перейти к URL | `browser_navigate` |
| Вернуться назад | `browser_navigate_back` |
| Сделать screenshot | `browser_take_screenshot` |
| Проверить DOM / accessibility tree | `browser_snapshot` |
| Нажать element | `browser_click` |
| Ввести данные в field | `browser_type` |
| Заполнить form | `browser_fill_form` |
| Выбрать option в dropdown | `browser_select_option` |
| Навести pointer на element | `browser_hover` |
| Перетащить и отпустить | `browser_drag` |
| Загрузить file | `browser_file_upload` |
| Нажать key (Enter, Tab, Escape…) | `browser_press_key` |
| Обработать alert / confirm / prompt dialogs | `browser_handle_dialog` |
| Изменить размер browser window (responsive breakpoints) | `browser_resize` |
| Проверить network requests (missing calls, errors) | `browser_network_requests` |
| Прочитать console errors / warnings | `browser_console_messages` |
| Выполнить произвольный JavaScript | `browser_evaluate` |
| Работать с несколькими tabs | `browser_tabs` |
| Закрыть browser | `browser_close` |

Для каждого test case записывайте outcome:
- **PASSED** — выполнен, actual result совпадает с expected;
- **FAILED** — выполнен, actual result не совпадает с expected;
- **BLOCKED** — выполнить не удалось (нет test data, broken prerequisite, environment issue); укажите причину.

К каждому результату FAILED или BLOCKED прикрепляйте screenshot или snapshot.

**P0 escalation rule**: если в любой момент найден P0 Blocker, остановите текущую test sequence, немедленно зарегистрируйте bug и спросите пользователя, продолжить ли проверку других flows или сначала дождаться исправления.

---

## Шаг 5: базовые проверки Accessibility

После functional testing проведите отдельный, но лёгкий a11y pass. Используйте `get_ui` (mobile) или `browser_snapshot` (web), чтобы проверить element tree.

Проверьте:
- **Touch targets too small** — интерактивные элементы с явно тесными границами (mobile: меньше ~44×44 dp);
- **Unlabelled interactive elements** — icons, image buttons, FABs без видимого label и без `content-desc` / `aria-label`;
- **Obvious contrast issues** — текст, который трудно читать на фоне (визуальная оценка по screenshot).

Сообщайте как `Type: Accessibility`. Полные a11y audits (screen reader, focus order, dynamic text) относятся к отдельной дисциплине и здесь не входят в scope.

---

## Шаг 6: сообщайте о bugs

Для каждого дефекта используйте SESSION_ID, определённый на шаге 0.2:

```
BUG-[SESSION_ID]-[n]: [Concise title]
Severity: [P0 Blocker / P1 Major / P2 Minor / P3 Cosmetic]
Type: [Functional / Visual / Accessibility / Crash]
Affected Screen/Flow: [Name]
Preconditions: [State required to reproduce]
Steps to Reproduce:
  1. [Step]
  2. [Step]
Actual Result: [What happened]
Expected Result: [What should have happened per spec or heuristic]
Spec Reference: [Mockup / PRD section — or "heuristic"]
Evidence: [Screenshot path]
```

---

## Шаг 7: сводка выполнения tests

После завершения run:

```
Test Run Summary
================
Session: [SESSION_ID]
Date: [date]
App Version / Build: [version]
Device / OS or Browser / URL: [name, OS version or browser + viewport]
Test Tiers Covered: [Smoke / Feature / Regression]
Spec Source: [what was used]

Results:
  Total test cases: [n]
  Passed:  [n]
  Failed:  [n]
  Blocked: [n]

Bugs Found:
  P0 Blockers: [n]
  P1 Major:    [n]
  P2 Minor:    [n]
  P3 Cosmetic: [n]

Accessibility Issues: [n]

Top Issues: [1-3 sentence summary of the most critical problems]
Recommendation: [Ship / Do not ship / Ship with known issues]
```

---

## Шаг 8: цикл re-test / regression

Когда bugs отмечены как fixed, повторите этот loop до teardown:
- повторно выполните только test cases со статусом FAILED или BLOCKED из-за этих bugs;
- убедитесь, что fix работает без regressions в соседних flows;
- обновите status каждого bug: **VERIFIED FIXED** или **STILL FAILING** (с обновлённым screenshot);
- отметьте новые bugs, появившиеся из-за fix.

После каждого re-test cycle выдавайте обновлённую Test Execution Summary. Переходите к шагу 9 только после завершения re-test loop или явного завершения session пользователем.

---

# Подготовка и завершение mobile QA

### 0.2 Подготовка device [mobile]

Прочитайте memory, добавленную в начале сессии, и найдите для этого проекта записи со `status: active`. Это другие запущенные агенты.

**Нет других active sessions (single-agent run):**
1. Вызовите `list_devices` и выберите доступный device.
2. Вызовите `set_device` / `set_target`.
3. Получите **SESSION_ID** из имени device и случайного 4-символьного hex suffix — например, `pixel8-a3f2` или `iphone15-b7c1`.
4. Перейдите к шагу 0.3.

**Обнаружены другие active sessions (parallel run):**
Каждому агенту нужен отдельный target. Создание нескольких emulators разрешено только по явному запросу; иначе выполняйте сценарии последовательно.

- **iOS simulator** (macOS only) — clone the source device via `shell`:
  ```
  xcrun simctl clone <source-udid> "QA-<SESSION_ID>"
  ```
  Capture the returned UDID of the clone, then boot it:
  ```
  xcrun simctl boot <clone-udid>
  ```
  Call `set_device` with the clone UDID. SESSION_ID is derived from `"QA-<clone-udid-prefix>"`.

- **Android emulator** — before creating, list installed system images to pick one that is available:
  ```
  sdkmanager --list_installed | grep system-images
  ```
  Create a fresh AVD from the same API level as the source device:
  ```
  avdmanager create avd -n "QA-<SESSION_ID>" \
    -k "system-images;android-<api>;google_apis;x86_64" \

  ```
  If no suitable system image is installed, ask the user which image to use — do not guess.

  Start the emulator in the background:
  ```
  emulator -avd "QA-<SESSION_ID>" -no-window -no-audio &
  ```
  Wait for it to fully boot (not just connect):
  ```
  adb -s <confirmed-owned-emulator-serial> \
    shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done'
  ```
  Then call `list_devices` to confirm the new emulator appears, and call `set_device` with its serial.

- **Real device** — реальные devices нельзя клонировать; назначайте каждому агенту отдельный физический device. Если доступен только один real device, параллельные запуски невозможны — сообщите пользователю и работайте последовательно.

- **Web** — действий не требуется; каждая browser session по умолчанию изолирована. SESSION_ID использует `web-<suffix>`.

Запишите в memory заявление о session:
```
Session <SESSION_ID> — device: <device-id>, cloned: <yes/no>, status: active
```

### 0.3 Очистите состояние приложения [mobile]

На disposable QA target начинайте с clean install, если сценарий не проверяет сохранённое состояние. Удаление данных на существующем target выполняйте только при явной авторизации пользователя.

**Пропустите этот шаг, если device только что клонирован на шаге 0.2** — новый clone или AVD не содержит установленного приложения, поэтому uninstall не нужен. Сразу переходите к `install_app`.

Для clean install нужен identifier приложения — спросите пользователя, если его нет:
- iOS: **Bundle ID** (e.g. `com.example.app`)
- Android: **Package name** (e.g. `com.example.app`)

Uninstall the existing app, then reinstall:

- **iOS:**
  ```
  xcrun simctl uninstall <device-udid> <bundle-id>
  ```
  Then call `install_app` with the build path.

- **Android:**
  ```
  adb -s <device-serial> uninstall <package-name>
  ```
  Then call `install_app` with the APK path.

Если пользователь явно хочет сохранить existing state (например, повторно проверить конкретную ошибку в существующей account session), пропустите uninstall и просто вызовите `launch_app`.

### 0.4 Подключитесь и проверьте (оба target)

**Mobile [mobile]:**
1. Вызовите `launch_app` — подтвердите запуск приложения.
2. Вызовите `screenshot` — подтвердите видимость экрана.
3. Запишите **app version / build number** (проверьте Settings → About или спросите пользователя, если значение не видно).

**Web [web]:**
1. Вызовите `browser_navigate` с target URL.
2. Вызовите `browser_take_screenshot` — подтвердите загрузку страницы.
3. Вызовите `browser_snapshot` — сохраните accessibility tree.
4. Запишите **page title и URL** как version reference.

### 0.5 Authentication (оба target)

Проверьте, показывает ли app/page login screen или authentication уже выполнена:
- Already logged in → подтвердите активный account; продолжайте.
- Login screen present → до любых действий попросите у пользователя test credentials; не угадывайте и не используйте personal accounts.
- Auth is broken (login screen loops, crashes, redirect loops) → немедленно зарегистрируйте P0 Blocker и остановите testing до исправления.

Если подготовка заблокирована, выполните доступную безопасную диагностику. Когда требуется пользовательский выбор или доступ отсутствует, сообщите BLOCKED; hypothetical testing не является результатом.

---

## Шаг 9: завершение session

После завершения re-test loop и выдачи final summary (или когда пользователь явно завершает session):

1. **Остановите app / закройте browser:**
   - Mobile: call `stop_app`
   - Web: call `browser_close`

2. **Удалите device clone (только если он был создан на шаге 0.2):**
   - iOS simulator:
     ```
     xcrun simctl shutdown <clone-udid>
     xcrun simctl delete <clone-udid>
     ```
   - Android emulator:
     ```
     adb -s <emulator-serial> emu kill
     avdmanager delete avd -n "QA-<SESSION_ID>"
     ```

3. **Запишите финальную memory entry**, отмечающую завершение session:
   ```
   Session <SESSION_ID> — device: <device-id>, cloned: <yes/no>, status: done
   ```
   Не удаляйте предыдущую запись `status: active` — перезапишите её этой записью. Она служит историческим журналом QA runs.

Никогда не пропускайте teardown. Оставленный clone занимает дисковое пространство и засоряет вывод `list_devices` в последующих runs.

---

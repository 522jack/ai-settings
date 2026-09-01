# Зависимости

Никогда не добавлять новую dependency без явного одобрения пользователя. Предпочитать уже имеющееся в проекте. Если новая dependency — единственный разумный вариант, предложить её и ждать разрешения.

**Gradle / JVM:** для чтения исходников dependency использовать `ksrc` (`ksrc --help`), а не искать вручную в каталоге кэша `.gradle/`. Это относится к *инспектированию* deps; редактирование build scripts, когда оно нужно задаче, регулируется `gradle-style.md`.

## Добавление или обновление dependency — обязательный plan-stage gate

Добавление **новой** dependency / plugin или **bumping** существующей — это **решение на этапе планирования**, а не деталь реализации. Нельзя завершить план — и нельзя начинать реализацию — пока библиотека не **изучена**, а версия не **проверена**. План, предлагающий библиотеку без этих результатов, неполон и должен быть пересмотрен до одобрения.

Это правило в равной степени распространяется на Gradle / Maven plugins и library deps — plugin id, version и source repository проходят те же ворота.

### Результаты этапа планирования (должны появиться в плане до одобрения)

Для каждой новой dependency / plugin / bumped version план содержит четыре пункта в следующем порядке:

1. **Identity.** Точный `groupId:artifactId` (или plugin id, или `name@registry` для не-Maven экосистем) + роль (одна строка: что делает, зачем нужен, почему существующие deps проекта не подходят).
2. **Freshness.** Последняя стабильная версия, полученная через `maven-mcp:latest-version` (или `maven-mcp:check-deps` для всего проекта; эквивалентный scanner экосистемы для non-Maven — `npm view <pkg> version`, `pip index versions`, `cargo search` и т. д.). Формат: «latest stable: X.Y.Z». Если последняя версия — pre-release / RC, а stable старше, выбрать stable и явно отметить разрыв. Никогда не фиксировать версию «потому что она была в snippet / blog post / training data».
3. **Vulnerabilities.** Выполнить `maven-mcp:check-deps-vulnerabilities` для выбранной координаты (non-Maven → `npm audit`, `pip-audit`, `cargo audit` и т. д.). Любое попадание CVE / GHSA → остановить план, сообщить severity + advisory ID + fixed-in version, предложить безопасную альтернативу или ждать решения пользователя. «No advisories» — также допустимый результат, его нужно указать.
4. **API surface study.** Прочитать саму библиотеку — для JVM/Kotlin использовать `ksrc` разрешённой версии; для Android также использовать `android docs`; для других экосистем — Context7 / official docs (см. цепочку приоритета API-truth). План должен показывать, что предлагаемая интеграция использует **текущий** API библиотеки, а не запомненную сигнатуру. Для bump, пересекающего major version, или известной evolving library (Ktor, Room, Compose, AGP, Hilt, kotlinx.* и т. д.) также выполнить `maven-mcp:dependency-changes <old> <new>` и отразить в плане breaking changes / migration notes.

Поэтому план должен содержать блок такого вида:

```
Dependency: io.example:foo-bar  — role: <one line>
- latest stable: 1.4.2 (no advisories)
- API: studied via ksrc, entry points: FooBar.create(...), uses kotlinx.coroutines Flow
- Bump diff (1.2.0 → 1.4.2): no breaking changes in public API
```

Нет такого блока → план не готов. Реализацию начинать нельзя.

### Проверка на этапе реализации

К моменту редактирования `libs.versions.toml` / `build.gradle*` / `pom.xml` / `package.json` / `Cargo.toml` версия уже должна быть одобрена в плане. Единственная задача implementing agent на этом этапе: подтвердить, что разрешённая версия всё ещё соответствует плану (повторно получать свежую версию в тот же день не нужно), и внести изменение. **Не** менять версии молча; если проверку свежести нужно повторить, сообщить об этом main session.

### Fallback для экосистемы (без maven-mcp)

Если dependency отсутствует в Maven Central — явно назвать в результате плана scanner экосистемы и использовать его. Не пропускать проверки молча только потому, что `maven-mcp` — неподходящий инструмент. Четыре результата планирования обязательны независимо от стека.

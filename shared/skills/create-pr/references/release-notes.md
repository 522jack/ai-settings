# Release notes in body

Добавить user-visible notes при user-facing/prod-bound/breaking/release_notes signal, фактическом public API/plugin surface change или explicit --release-notes TEXT (приоритет). Не путать любое упоминание api пути с изменением контракта.
CHANGELOG.md / RELEASE_NOTES.md / docs/CHANGELOG.md → Keep-a-Changelog Added/Changed/Fixed/Deprecated/Removed/Security, breaking prefix. .changeset/ → type patch|minor|major + summary в body (не настоящий changeset file). Нет convention → short Release Notes bullets. --skip-release-notes reason → emitted|skipped:reason|not-applicable receipt. Только текст PR: changelog/files не меняются.

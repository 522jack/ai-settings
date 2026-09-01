# create-pr — шаблоны обнаружения визуальных изменений

Referenced from: `plugins/developer-workflow/skills/create-pr/SKILL.md` (§7.3).

Проверяйте пути изменённых файлов на наличие:
- Android/Compose: `*Screen.kt`, `*Composable.kt`, `res/layout/`, `res/drawable/`
- Compose Multiplatform: Kotlin UI patterns + `commonMain` UI dirs
- Web: `*.tsx`, `*.jsx`, `*.css`, `*.scss`, `*.html`
- iOS: `*View.swift`, `*Screen.swift`, `Views/`, `Screens/`, `*.xib`, `*.storyboard`
  (plain `*.swift` is too broad — most Swift files are non-UI; match by suffix/dir)

При обнаружении визуальных изменений включите секцию «Screenshots / demo» и попросите пользователя
(в режимах `--draft` и `--promote`) приложить материалы. `--refresh` сохраняет существующее содержимое Screenshots.

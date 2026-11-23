# Shared AI Harness for Gemini in Android Studio

This adapter applies the shared engineering contract to Gemini Agent Mode.

## Runtime mapping

- Use Android Studio Agent Mode tools for file edits, terminal commands, Gradle, ADB, Logcat, and device interaction.
- Use installed skills when their description matches the task. A user may invoke one explicitly with `@skill-name`.
- If an instruction refers to a runtime-specific Claude or Codex tool that is unavailable, preserve the intent with the closest Android Studio capability. Do not claim that an unavailable tool or hook was run.
- Android Studio does not provide this harness's Claude hooks. Run the relevant guard script manually when the shared rules require it and the Agent Mode terminal permission is available.
- Before a new task, read and apply the execution mode section in `$HOME/dotfiles/ai/shared/AGENTS.md`. In single-agent mode, edit project files within Agent Mode permissions. If the user chooses subagents and delegation is unavailable, report the limitation and wait for their decision.

## Shared rules

@../shared/rules/communication.md
@../shared/rules/code-policies.md
@../shared/rules/logging.md
@../shared/rules/dependencies.md
@../shared/rules/external-sources.md
@../shared/rules/kotlin-style.md
@../shared/rules/gradle-style.md
@../shared/rules/android-cli.md
@../shared/rules/qa-and-testing.md
@../shared/rules/task-types.md
@../shared/rules/task-execution.md
@../shared/rules/workflow.md
@../shared/rules/ast-index.md

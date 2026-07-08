# Logging Rules

Logging is production behavior, not debug decoration. Add, remove, or change logs only when the
task requires observability, diagnostics, auditing, or the existing code's logging contract changes.

## Permanent Logs

- Use the project's existing logger, levels, structured fields, and redaction helpers.
- Never introduce a new logging framework without explicit dependency approval.
- Log stable events and failure contexts, not noisy implementation steps.
- Preserve cancellation semantics: do not swallow exceptions only to log them.
- Never log secrets, tokens, credentials, raw auth headers, private keys, full cookies, payment data, or unnecessary PII.
- Mask sensitive values before they enter tool output, runtime logs, screenshots, reports, or model context.

## Temporary Diagnostic Logs

Temporary logs are allowed only to verify or debug a specific task.

- Mark them with `// TEMP-LOG: <reason>` or the equivalent comment style.
- Remove them before `finalize` unless the user explicitly asks to keep them.
- If a temporary log exposes sensitive data, do not add it. Use scoped assertions, counters, or redacted diagnostics instead.

## Log Capture By Agents

- Filter before reading: scope by package, PID, subsystem, test run, or request id.
- Cap volume: last-N lines, level filters, or a saved artifact path instead of raw streams in chat.
- Treat logs as diagnostic evidence only. A deterministic verifier still decides pass/fail: test exit code, build result, visible UI assertion, API response assertion, or benchmark result.


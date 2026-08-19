---
name: specialist-routing
description: Route non-trivial feature work to the appropriate harness specialist profiles and produce a delegation receipt. Use when implementing, reviewing, testing, or validating a feature that benefits from a specialist.
metadata:
  short-description: Route feature work to harness specialists
---

# Specialist routing

Use this skill for non-trivial feature work. Do not invoke every specialist by default: select only the roles needed by the task, while preserving the mandatory gates from the shared workflow.

## Before delegation

1. Identify the task phase and stack.
2. Select the smallest sufficient specialist set from `~/dotfiles/ai/shared/agents/`:
   - implementation: `kotlin-engineer.md`, `compose-developer.md`, or the closest stack specialist;
   - investigation/debugging: `debugging-expert.md` or `source-researcher.md`;
   - architecture: `architecture-expert.md`;
   - review: `code-reviewer.md`, `security-expert.md`, `performance-expert.md`, or `ui-accessibility-reviewer.md`;
   - runtime/UI verification: `manual-tester.md`.
3. Read each selected profile before preparing the delegation prompt. Do not claim a profile was applied if it was not read.
4. Create a delegation packet containing:
   - task and acceptance criteria;
   - exact paths/modules in scope;
   - selected profile path(s);
   - constraints from the profile and applicable project rules;
   - expected artifact and verdict format.

## Delegation

Pass the delegation packet to the Codex specialist/subagent through the current runtime adapter. The specialist must report:

- profile path(s) actually used;
- files or surfaces inspected/changed;
- checks performed;
- verdict: `PASS`, `PASS_WITH_NOTES`, or `BLOCKED`;
- unresolved risks or required follow-ups.

If the runtime cannot provide a specialist, record `ADAPTER_LIMITATION` and do not present the work as having used a specialist profile.

## Feature completion receipt

Before declaring a non-trivial feature complete, include this receipt in the final synthesis (or in the task report when one exists):

```text
Specialist receipt
- Required profiles: <paths or none, with reason>
- Applied profiles: <paths actually read and used>
- Delegation: <subagent/runtime or ADAPTER_LIMITATION>
- Verdicts: <PASS | PASS_WITH_NOTES | BLOCKED>
- Verification: <check/finalize/acceptance results>
- Open risks: <none or explicit list>
```

An empty `Applied profiles` field is valid only when the task is trivial, documentation-only, or the runtime limitation is explicitly recorded.

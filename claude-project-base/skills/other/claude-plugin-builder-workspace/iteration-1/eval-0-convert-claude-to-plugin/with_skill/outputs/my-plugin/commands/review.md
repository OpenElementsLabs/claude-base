---
description: Review the current git diff and report findings by severity.
---

Review the current working-tree changes.

1. Run `git diff` (and `git diff --staged`) to gather all pending changes. If the
   user passed a target in `$ARGUMENTS` (a file, directory, or ref), scope the
   review to that instead.
2. Delegate the analysis to the `code-reviewer` agent for a focused review.
3. Summarize the findings grouped by severity and list concrete next steps.

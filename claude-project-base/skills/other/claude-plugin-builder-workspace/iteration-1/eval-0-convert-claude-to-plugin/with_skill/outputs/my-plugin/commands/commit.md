---
description: Stage changes and create a conventional-commit message.
---

Create a commit for the current changes.

1. Run `git status` and `git diff` to understand what changed.
2. Stage the relevant files (respect anything the user scoped via `$ARGUMENTS`).
3. Write a Conventional Commits message (`type(scope): summary`) that accurately
   describes the change, with a body when the change is non-trivial.
4. Show the proposed message and create the commit once confirmed.

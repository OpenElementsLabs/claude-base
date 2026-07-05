---
description: Detect and run the project's test suite, then report results.
---

Run the project's tests.

1. Detect the test runner from the project (e.g. `package.json` scripts, `pytest`,
   `mvn test`, `go test`, `cargo test`).
2. Run the suite. If `$ARGUMENTS` names a specific test, file, or pattern, run only
   that subset.
3. Report pass/fail counts and, for any failures, the failing test names and the
   most relevant lines of output.

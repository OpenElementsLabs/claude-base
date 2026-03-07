# Claude Code Base Configuration

This file provides base rules and conventions for Claude Code in Open Elements projects.
Projects that use this as a base can override or extend these rules in their own `CLAUDE.md`.

## Code Quality

- Follow the DRY principle — avoid duplicating logic. Extract shared code into reusable functions or modules.
- Follow the KISS principle — prefer simple, readable solutions over clever or complex ones.
- Remove dead code. Do not leave commented-out code, unused imports, or unreachable branches.
- Keep functions and methods focused — each should do one thing well.
- Prefer meaningful names for variables, functions, and classes. Avoid abbreviations unless they are widely understood (
  e.g., `id`, `url`).
- Do not add code "for future use." Only implement what is currently needed.

## Security

- Never commit secrets, API keys, passwords, or tokens. Use environment variables or secret management tools.
- Always include `.env` in `.gitignore` to prevent accidental commits of local configuration with secrets.
- Validate and sanitize all external input (user input, API responses, file contents).
- Use parameterized queries for database access — never build SQL from string concatenation.
- Keep dependencies up to date to avoid known vulnerabilities.

## Testing

- Write tests for new features and bug fixes.
- Tests should be deterministic — no flaky tests that depend on timing, network, or random state.
- Each test should test one behavior and have a clear name that describes what it verifies.
- Prefer assertion libraries that produce clear failure messages.

## Documentation

- Use GitHub Flavored Markdown (GFM) as the default syntax for all documentation (`README.md`, docs, ADRs, etc.).

## Pull Requests and Reviews

- Keep PRs focused on a single change. Avoid mixing unrelated changes in one PR.
- Write a clear PR description that explains what changed and why.
- Ensure all tests pass before requesting review.
- Address review comments before merging.

## Additional Conventions

Include the relevant documents in your project's `CLAUDE.md` based on what applies:

### Language-Specific

- [Java Conventions](docs/java.md) — code style, build tools, testing, logging, null handling, collections, JPMS, SPI
- [TypeScript Conventions](docs/typescript.md) — technology stack, code style, package manager, testing, linting

### Architecture and Infrastructure

- [Software Quality and Architecture](docs/software-quality.md) — API design, technical integrity, namespace, SBOM, CI
- [Fullstack Architecture](docs/fullstack-architecture.md) — frontend/backend separation, Docker, configuration, pinned tool versions
- [Backend Conventions](docs/backend.md) — REST APIs, OpenAPI, Swagger UI

### Documentation and Repository Setup

- [Repository Setup](docs/repo-setup.md) — required root files (README, LICENSE, CoC, CONTRIBUTING)
- [Project Documentation](docs/documentation.md) — Markdown, MkDocs setup, GitHub Pages deployment, ADRs

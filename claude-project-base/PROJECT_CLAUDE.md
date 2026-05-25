# Claude Code Base Configuration

This file provides base rules and conventions for Claude Code in Open Elements projects.
Projects that use this as a base can override or extend these rules in their own `CLAUDE.md`.

## Core Philosophy

- **Quality over speed.** Getting it right matters more than getting it done fast. Take the time needed for clean APIs,
  proper tests, correct architecture, and polished design.
- **Iterative improvement is expected.** Code and design will evolve through iterations. It is normal and encouraged
  that things change and improve as new features are added or understanding deepens. Do not over-optimize for a "final"
  state on the first pass.

## Code Quality

- Follow the DRY principle — avoid duplicating logic. Extract shared code into reusable functions or modules.
- Follow the KISS principle — prefer simple, readable solutions over clever or complex ones.
- Remove dead code. Do not leave commented-out code, unused imports, or unreachable branches.
- Keep functions and methods focused — each should do one thing well.
- Prefer meaningful names for variables, functions, and classes. Avoid abbreviations unless they are widely understood (
  e.g., `id`, `url`).
- Do not add code "for future use." Only implement what is currently needed.

## Security

- **IMPORTANT**: Never read or write files outside the project directory unless the user explicitly asks for it.
- **IMPORTANT**: Never modify system-level configuration files (shell profiles, system packages, etc.).
- **IMPORTANT**: Never commit, log, or echo secrets, API keys, passwords, or tokens. Use environment variables or secret
  management tools.
- **IMPORTANT**: Always include `.env` in `.gitignore` to prevent accidental commits of local configuration with
  secrets.
- Validate and sanitize all external input (user input, API responses, file contents).
- **IMPORTANT**: Use parameterized queries for database access — never build SQL from string concatenation.
- Keep dependencies up to date to avoid known vulnerabilities.
- See [Security Configuration](.claude/conventions/security.md) for concrete `.claude/settings.json` deny rules, sandbox
  setup, and hook examples.

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

**IMPORTANT**: Only include the documents that are relevant to your project. Do not reference all docs — each referenced
file is loaded into Claude's context and excessive context causes rules to be ignored. A frontend does not need `backend.md`.

Java conventions are provided via the `java-best-practices`, `modern-java`, and `java-api-design` skills — they do not need to be referenced as convention documents.

TypeScript conventions are provided via the `typescript-best-practices` skill — it does not need to be referenced as a convention document.

Typical combinations:

- **Java library**: `software-quality.md`
- **Java backend**: `software-quality.md`, `backend.md`
- **TypeScript frontend**: `software-quality.md`
- **Fullstack application**: `software-quality.md`, `backend.md` — fullstack architecture details (Docker, OIDC, Compose) are provided on demand via the `fullstack-architecture-setup` skill.

Repository setup (required root files like `README.md`, `LICENSE`, `CODE_OF_CONDUCT.md`, `.gitignore`, `.editorconfig`) is provided on demand via the `project-setup` skill.

Available documents:

### Language-Specific

- TypeScript conventions (technology stack, Next.js pitfalls, code style, package manager, testing, linting, i18n, error handling) are provided via the `typescript-best-practices` skill — it does not need to be referenced as a convention document.

### Security

- [Security Configuration](.claude/conventions/security.md) — permission deny rules, sandbox mode, hooks for safety,
  audit logging

### Architecture and Infrastructure

- [Software Quality and Architecture](.claude/conventions/software-quality.md) — API design, technical integrity,
  namespace, SBOM, CI
- Fullstack architecture (frontend/backend separation, Docker, OIDC, pinned tool versions) is provided via the `fullstack-architecture-setup` skill — it does not need to be referenced as a convention document.
- [Backend Conventions](.claude/conventions/backend.md) — REST APIs, OpenAPI, Swagger UI

### Development Workflow

- The spec folder structure, `design.md`/`behaviors.md`/`steps.md` formats, and Drift-Log conventions are loaded on demand by the spec workflow skills (`spec-create`, `spec-flow`, `spec-implement`, `spec-review`, `roadmap-execute`). Do not reference `spec-driven-development.md` as an always-on convention — the skills pull it in when needed.
- [Spec Index](docs/specs/INDEX.md) — central index of all specifications with status, areas, and GitHub issue references.
  Read this file to discover which specs exist and their current state.
- [Roadmap](docs/roadmap.md) — optional high-level project roadmap with checkboxes for each milestone. When present, use
  `/roadmap-execute` to autonomously work through all steps end-to-end (spec creation, implementation, review, commit).

### Build Integrity

- Reproducible builds (version pinning, deterministic output, common pitfalls, build verification scripts) are provided via the `reproducible-builds-check` skill — it does not need to be referenced as a convention document.

### CI/CD

- GitHub Actions workflows are provided via the `github-actions-setup` skill — it does not need to be referenced as a convention document.

### Documentation and Repository Setup

- Repository setup (required root files: `README.md`, `LICENSE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `.gitignore`, `.editorconfig`) is provided via the `project-setup` skill — it does not need to be referenced as a convention document.
- MkDocs project documentation is provided via the `mkdocs-setup` skill — it does not need to be referenced as a convention document.
- Release and upgrade documentation — application release notes (`docs/releases/vX.Y.md`) and AI-executable library upgrade guides (`docs/releases/upgrade-to-X.Y.md`) — is provided via the `release-doc` skill. It does not need to be referenced as a convention document.

### Project-Specific

- [Project-Specific Docs](.claude/conventions/project-specific/README.md) — project-specific conventions and
  documentation (add your own here)

# Claude Base — Project Rules

This repository maintains reusable Claude Code configurations, skills, and documentation for Open Elements projects. The reusable content lives in `claude-project-base/`.

## Purpose of this project

The goal is to provide high-quality base configurations that other projects can adopt. When working on this repository, keep in mind that every rule, convention, and skill you write here will be used across many different projects.

## Repository Structure

- `claude-project-base/CLAUDE.md` — Base template for project conventions
- `claude-project-base/conventions/` — Convention documents (languages, architecture, security, workflows)
- `claude-project-base/skills/` — Reusable Claude Code skills
- `README.md` — Public-facing documentation for users of this repository
- `setup.sh` — Installation script for applying the base configuration to a project

## Setup Script

To apply the base configuration to a project, run from the project root:

```bash
curl -sSL https://raw.githubusercontent.com/OpenElementsLabs/claude-base/main/setup.sh | bash
```

The script copies conventions, skills, hooks, MCP config, and settings into the target project's `.claude/` directory. It merges `CLAUDE.md` intelligently using Claude Code and appends required entries to `.gitignore`. Existing project-specific files (skills, settings, `.mcp.json`) are not overwritten.

When modifying `setup.sh`, ensure it remains idempotent — running it multiple times on the same project must not duplicate or overwrite existing project-specific configuration.

## Writing Guidelines

### For convention documents (`CLAUDE.md`, `conventions/*.md`)

- Write rules that are universally applicable. Do not include project-specific paths, tool versions, or team-specific workflows.
- Each rule should be actionable and verifiable — avoid vague advice like "write clean code."
- Keep rules concise. One sentence per rule where possible.
- Group related rules under clear headings.
- Do not contradict rules from other documents in this repository.
- When a rule applies only to a specific language, it belongs in the language-specific convention (e.g., `conventions/typescript.md`) or skill (e.g., `java-best-practices`), not in the base `CLAUDE.md`.

### For skills (`skills/*.md`)

- Each skill file must have a clear title as H1 heading, a short description, and an `## Instructions` section with numbered steps.
- Skills should be generic enough to work in any project that follows the base conventions.
- Keep skills focused on a single task. Do not combine unrelated actions into one skill.

## Quality Standards

- All files must be valid Markdown with no formatting errors.
- Use consistent heading levels (H1 for title, H2 for sections, H3 for subsections).
- Links between documents must use relative paths within `claude-project-base/`.
- No trailing whitespace, no tabs for indentation in Markdown files.

## What NOT to include

- No project-specific configurations (build scripts, CI pipelines, IDE settings).
- No absolute file paths or machine-specific references.
- No rules that assume a specific framework, library, or tool version.
- No secrets, credentials, or environment-specific values.

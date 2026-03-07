# claude-base

A central collection of Claude Code configurations, skills, and documentation for Open Elements projects. Designed for Java and TypeScript projects, but the base rules apply to any language.

## What is this?

This repository provides reusable building blocks for Claude Code:

- **`CLAUDE.md`** — Base template with general code quality, security, testing, and PR conventions
- **`docs/`** — Language-specific conventions for Java and TypeScript
- **`skills/`** — Custom Claude Code skills that can be used across projects

## How to use in your project

### Option 1: Copy the base configuration

Copy `CLAUDE.md` into your project root and adapt it to your needs. Include the relevant language docs by adding references:

```markdown
# In your project's CLAUDE.md, add at the end:

See also: docs/java.md (from claude-base)
```

### Option 2: Reference as a submodule

Add this repository as a git submodule:

```bash
git submodule add https://github.com/open-elements/claude-base.git .claude-base
```

Then reference the files from your project's `CLAUDE.md`:

```markdown
Also follow the rules in .claude-base/CLAUDE.md and .claude-base/docs/java.md
```

### Using Skills

Copy skills from `skills/` into your project's `.claude/skills/` directory or reference them from this repository.

## Available Documentation

| File | Description |
|------|-------------|
| [CLAUDE.md](claude-project-base/CLAUDE.md) | Base conventions (code quality, security, testing, PRs) |
| [docs/java.md](claude-project-base/docs/java.md) | Java conventions (code style, JUnit 5, SLF4J, null handling) |
| [docs/typescript.md](claude-project-base/docs/typescript.md) | TypeScript conventions (strict mode, linting, testing) |

## Available Skills

| Skill | Description |
|-------|-------------|
| [simplify](claude-project-base/skills/simplify.md) | Review changed code for reuse, quality, and efficiency |

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

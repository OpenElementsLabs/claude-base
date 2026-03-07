# claude-base

A central collection of Claude Code configurations, conventions, and skills for Open Elements projects. The `claude-project-base/` directory is designed to be copied or linked into any project to provide a solid foundation for working with Claude Code.

## What is this?

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), project-level `CLAUDE.md` files define conventions, rules, and context that Claude follows. Writing and maintaining these from scratch for every project is tedious and leads to inconsistencies.

This repository solves that by providing a shared base configuration in `claude-project-base/`:

- **`CLAUDE.md`** — Base conventions for code quality, security, testing, and PRs
- **`docs/`** — Detailed convention documents for languages, architecture, and tooling (selectively included per project)
- **`skills/`** — Reusable Claude Code skills for common tasks

The base `CLAUDE.md` explains which docs to include for different project types (Java library, TypeScript frontend, fullstack app, etc.) so that only relevant context is loaded.

## How to use in your project

### Option 1: Copy the directory

Copy `claude-project-base/` into your project and rename it as needed. Reference it from your project's root `CLAUDE.md`:

```markdown
# In your project's CLAUDE.md
Also follow the rules in claude-project-base/CLAUDE.md
```

### Option 2: Git submodule

Add this repository as a git submodule so you can pull updates:

```bash
git submodule add https://github.com/open-elements/claude-base.git claude-project-base
```

Then reference the base configuration from your project's `CLAUDE.md`:

```markdown
# In your project's CLAUDE.md
Also follow the rules in claude-project-base/CLAUDE.md
```

### Selecting relevant docs

Not every project needs every document. The base `CLAUDE.md` contains guidance on which docs to include based on your project type. Only reference what is relevant — excessive context causes rules to be ignored.

### Using skills

Copy the skills you need from `claude-project-base/skills/` into your project's `.claude/skills/` directory, or reference them directly if using the submodule approach.

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

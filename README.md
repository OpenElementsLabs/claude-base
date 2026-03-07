# claude-base

A central collection of Claude Code configurations, conventions, and skills for Open Elements projects. The `claude-project-base/` directory is designed to be copied into any project to provide a solid foundation for working with Claude Code.

## What is this?

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), project-level `CLAUDE.md` files define conventions, rules, and context that Claude follows. Writing and maintaining these from scratch for every project is tedious and leads to inconsistencies.

This repository solves that by providing a shared base configuration in `claude-project-base/`:

- **`CLAUDE.md`** — Base conventions for code quality, security, testing, and PRs
- **`docs/`** — Detailed convention documents for languages, architecture, and tooling (selectively included per project)
- **`docs/project-specific/`** — Place for your own project-specific documentation
- **`skills/`** — Reusable Claude Code skills for common tasks

The base `CLAUDE.md` explains which docs to include for different project types (Java library, TypeScript frontend, fullstack app, etc.) so that only relevant context is loaded.

## How to use in your project

Copy the `claude-project-base/` directory into your project root:

```bash
# From your project directory
cp -r /path/to/claude-base/claude-project-base ./claude-project-base
```

Then reference it from your project's root `CLAUDE.md`:

```markdown
# In your project's CLAUDE.md
Also follow the rules in claude-project-base/CLAUDE.md
```

After copying, you can freely customize the configuration for your project:

- Add project-specific docs in `claude-project-base/docs/project-specific/`
- Add project-specific skills in `claude-project-base/skills/`
- Adjust the base `CLAUDE.md` to select only the docs relevant to your project

### Keeping up to date

The shared conventions and skills in this repository evolve over time. To pull updates into your project without overwriting your project-specific customizations, use the included **update-claude-base** skill:

```
/update-claude-base
```

This skill fetches the latest version from [github.com/OpenElementsLabs/claude-base](https://github.com/OpenElementsLabs/claude-base) and updates everything except your `docs/project-specific/` directory.

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

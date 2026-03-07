# claude-base

A central collection of Claude Code configurations, conventions, and skills for Open Elements projects. Designed to be integrated into any project's `.claude/` directory.

## What is this?

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), project-level `CLAUDE.md` files define conventions, rules, and context that Claude follows. Writing and maintaining these from scratch for every project is tedious and leads to inconsistencies.

This repository solves that by providing a shared base configuration in `claude-project-base/`:

- **`CLAUDE.md`** — Base conventions for code quality, security, testing, and PRs
- **`conventions/`** — Detailed convention documents for languages, architecture, and tooling (selectively included per project)
- **`conventions/project-specific/`** — Place for your own project-specific documentation
- **`skills/`** — Reusable Claude Code skills for common tasks

The base `CLAUDE.md` explains which conventions to include for different project types (Java library, TypeScript frontend, fullstack app, etc.) so that only relevant context is loaded.

## How to use in your project

Copy the contents of `claude-project-base/` into your project's `.claude/` directory:

```bash
# From your project directory
mkdir -p .claude
cp -r /path/to/claude-base/claude-project-base/conventions .claude/conventions
cp -r /path/to/claude-base/claude-project-base/skills/* .claude/skills/
```

Copy or merge the base `CLAUDE.md` into your project root:

```bash
cp /path/to/claude-base/claude-project-base/CLAUDE.md ./CLAUDE.md
```

The resulting project structure:

```
project-root/
├── CLAUDE.md                          ← base conventions (adapt to your project)
├── .claude/
│   ├── settings.json                  ← permissions and security (see conventions/security.md)
│   ├── conventions/                   ← convention documents
│   │   ├── java.md
│   │   ├── typescript.md
│   │   ├── security.md
│   │   ├── project-specific/          ← your project-specific docs
│   │   └── ...
│   └── skills/                        ← auto-discovered by Claude Code
│       ├── spec-create/
│       ├── quality-review/
│       └── ...
├── specs/                             ← created by /spec-create
└── ...
```

After copying, customize the configuration for your project:

- Edit `CLAUDE.md` to select only the conventions relevant to your project type
- Add project-specific documentation in `.claude/conventions/project-specific/`
- Add project-specific skills in `.claude/skills/`
- Configure security rules in `.claude/settings.json` (see `conventions/security.md`)
- Run `/project-analyze` to auto-generate project context documentation

### Keeping up to date

The shared conventions and skills in this repository evolve over time. To pull updates into your project without overwriting your project-specific customizations, use the included **update-claude-base** skill:

```
/update-claude-base
```

This skill fetches the latest version from [github.com/OpenElementsLabs/claude-base](https://github.com/OpenElementsLabs/claude-base) and updates everything except your `conventions/project-specific/` directory.

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

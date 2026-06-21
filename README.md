# claude-base

A central collection of Claude Code configurations, conventions, and skills for Open Elements projects. Designed to be integrated into any project's `.claude/` directory.

## What is this?

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), project-level `CLAUDE.md` files define conventions, rules, and context that Claude follows. Writing and maintaining these from scratch for every project is tedious and leads to inconsistencies.

This repository solves that by providing a shared base configuration in `claude-project-base/`:

- **`CLAUDE.md`** — Base conventions for code quality, security, testing, and PRs, plus a **Project Context** section that holds your project-specific context (tech stack, features, structure, architecture)
- **`conventions/`** — Detailed convention documents for languages, architecture, and tooling (selectively included per project)
- **`skills/`** — Reusable Claude Code skills, organized by category (`information/`, `tools/`, `workflows/`, `coding/`, `other/`). The setup script flattens these into `.claude/skills/` in the target project so Claude Code's flat skill discovery keeps working.

The base `CLAUDE.md` explains which conventions to include for different project types (Java library, TypeScript frontend, fullstack app, etc.) so that only relevant context is loaded.

## How to use in your project

Run the setup script from your project root:

```bash
curl -sSL https://raw.githubusercontent.com/OpenElementsLabs/claude-base/main/setup.sh | bash
```

This copies conventions, skills, hooks, MCP config, and settings into `.claude/`, merges `CLAUDE.md` using Claude Code, and updates `.gitignore`. Existing project-specific files are not overwritten. The script is safe to run multiple times.

The resulting project structure:

```
project-root/
├── CLAUDE.md                          ← base conventions + Project Context (your project-specific context)
├── .claude/
│   ├── settings.json                  ← permissions and security (see conventions/security.md)
│   ├── conventions/                   ← convention documents
│   │   ├── (java conventions moved to skills: java-best-practices, modern-java, java-api-design)
│   │   ├── (backend conventions moved to skill: java-backend)
│   │   ├── (typescript conventions moved to skill: typescript-best-practices)
│   │   ├── security.md
│   │   ├── software-quality.md
│   │   └── ...
│   └── skills/                        ← auto-discovered by Claude Code
│       ├── _workflow-shared/          ← shared reference docs for the spec workflows (e.g. spec-driven-development.md)
│       ├── spec-create/
│       ├── quality-review/
│       └── ...
├── docs/                              ← project documentation (uniform structure)
│   ├── adr/                           ← architecture decision records (/adr-create)
│   ├── releases/                      ← release notes & upgrade guides (/release-doc)
│   ├── specs/                         ← specifications (/spec-create)
│   └── TODO.md                        ← lightweight backlog of parked ideas (/todo-capture)
└── ...
```

After copying, customize the configuration for your project:

- Edit `CLAUDE.md` to select only the conventions relevant to your project type
- Fill in the **Project Context** section of `CLAUDE.md` with your project's tech stack, features, structure, and architecture (or run `/project-analyze` to generate it automatically)
- Add project-specific skills in `.claude/skills/`
- Configure security rules in `.claude/settings.json` (see `conventions/security.md`)

### Keeping up to date

The shared conventions and skills in this repository evolve over time. To pull updates into your project without overwriting your project-specific customizations, use the included **update-claude-base** skill:

```
/update-claude-base
```

This skill fetches the latest version from [github.com/OpenElementsLabs/claude-base](https://github.com/OpenElementsLabs/claude-base) and updates the shared conventions and skills. Your `CLAUDE.md` — including its **Project Context** section — is merged rather than overwritten, so your project-specific customizations are preserved.

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

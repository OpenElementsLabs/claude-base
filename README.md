# claude-base

A Claude Code **plugin** that bundles Open Elements' shared conventions, skills, and MCP servers so every project gets the same high-quality baseline.

## What is this?

When using [Claude Code](https://docs.anthropic.com/en/docs/claude-code), teams want a consistent set of conventions, workflows, and tooling across all their projects. Maintaining these by hand per project is tedious and drifts out of sync.

`claude-base` solves this by shipping everything as a versioned plugin:

- **`skills/`** — reusable Claude Code skills: coding conventions (`java-best-practices`, `modern-java`, `java-api-design`, `java-backend`, `typescript-best-practices`, `web-frontend-builder`, …), spec-driven development workflows (`spec-create`, `spec-flow`, `spec-implement`, `spec-review`, `quality-review`, `roadmap-execute`, …), project tooling (`project-setup`, `github-actions-setup`, `mkdocs-setup`, …), and Open Elements/domain knowledge skills.
- **`conventions/`** — shared convention documents (`security.md`, `software-quality.md`) that the skills reference via `${CLAUDE_PLUGIN_ROOT}/conventions/…`.
- **`.mcp.json`** — shared MCP servers (GitHub, Maven Central, Docker, drawio, Figma, shadcn, Coolify). Servers you don't configure credentials for simply stay inactive.

## Installation

Install from inside Claude Code:

```
/plugin marketplace add OpenElementsLabs/claude-base
/plugin install claude-base@open-elements
```

Then restart Claude Code (or run `/reload-plugins`).

All skills are **namespaced** under the plugin, e.g. `/claude-base:spec-create`, `/claude-base:quality-review`, `/claude-base:project-analyze`.

### MCP server credentials

Several bundled MCP servers read environment variables (e.g. `GITHUB_PERSONAL_ACCESS_TOKEN`, `FIGMA_API_KEY`, `COOLIFY_API_URL`/`COOLIFY_API_TOKEN`). Set the ones you need in your project's `.claude/settings.local.json` (gitignored — never commit real tokens):

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here",
    "GH_TOKEN": "ghp_your_token_here"
  }
}
```

Servers without credentials just don't start; they don't block anything.

## Keeping up to date

Because the plugin is versioned, updates are delivered when the `version` in `plugin.json` is bumped. Pull the latest release with:

```
/plugin marketplace update open-elements
```

## What is NOT included anymore

Earlier versions of `claude-base` used a `setup.sh` script that copied files into a project and merged a base `CLAUDE.md`. The plugin model replaces that. It intentionally does **not**:

- merge a base `CLAUDE.md` into your project (a plugin-root `CLAUDE.md` is not loaded as context — keep project rules in your own `CLAUDE.md`),
- modify your project's `.gitignore`,
- write a `settings.local.json` for you (see [MCP server credentials](#mcp-server-credentials)).

The old `setup.sh` now only prints these installation instructions.

## Repository layout

```
claude-base/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # marketplace catalog (this repo is its own marketplace)
├── skills/                  # all skills, flat (Claude Code discovers them here)
├── conventions/             # shared convention documents
├── .mcp.json                # shared MCP servers
├── docs/                    # documentation (workflow guide, design docs)
├── dev/                     # dev-only material, not shipped as skills
├── update-skills.sh         # maintainer tool: vendor upstream skills into this repo
└── CHANGELOG.md
```

## For maintainers

- **Vendoring upstream skills:** some skills originate from external repos and declare their provenance in the `metadata` block of their `SKILL.md`. Run `./update-skills.sh` to pull upstream changes into this repo. This is unrelated to distribution.
- **Releasing:** bump `version` in **both** `.claude-plugin/plugin.json` and the `claude-base` entry in `.claude-plugin/marketplace.json`, update `CHANGELOG.md`, and tag the release. Validate with `claude plugin validate ./ --strict`.

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.

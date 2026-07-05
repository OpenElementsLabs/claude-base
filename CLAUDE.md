# Claude Base — Project Rules

This repository **is** a Claude Code plugin: it bundles reusable Claude Code skills, conventions, and MCP servers for Open Elements projects and distributes them through its own marketplace.

## Purpose of this project

The goal is to provide a high-quality base configuration that other projects install as a plugin. When working on this repository, keep in mind that every rule, convention, and skill you write here will be used across many different projects.

## Repository Structure

The repository root is the plugin root (and the marketplace root).

- `.claude-plugin/plugin.json` — plugin manifest (name, version, metadata)
- `.claude-plugin/marketplace.json` — marketplace catalog (lists this plugin, `source: "./"`)
- `skills/` — all reusable Claude Code skills, flat (`skills/<name>/SKILL.md`); discovered automatically
- `conventions/` — shared convention documents (`security.md`, `software-quality.md`); skills reference them via `${CLAUDE_PLUGIN_ROOT}/conventions/…`
- `.mcp.json` — shared MCP servers shipped with the plugin
- `docs/` — documentation (workflow guide, design docs)
- `dev/` — dev-only material that must NOT ship as skills (e.g. eval workspaces, legacy templates)
- `README.md` — public-facing documentation for users of this plugin
- `CHANGELOG.md` — release history
- `setup.sh` — legacy entry point; now only prints plugin installation instructions
- `update-skills.sh` — maintainer tool that vendors upstream skills into this repo (unrelated to distribution)

## Distribution

The plugin is installed from inside Claude Code:

```
/plugin marketplace add OpenElementsLabs/claude-base
/plugin install claude-base@open-elements
```

Skills are namespaced under the plugin, e.g. `/claude-base:spec-create`.

**Releasing:** bump `version` in **both** `.claude-plugin/plugin.json` and the `claude-base` entry in `.claude-plugin/marketplace.json`, update `CHANGELOG.md`, tag the release, and validate with `claude plugin validate ./ --strict`. Users only receive an update when the version is bumped.

The plugin model intentionally does **not** merge a base `CLAUDE.md`, modify a project's `.gitignore`, or provision `settings.local.json` — a plugin-root `CLAUDE.md` is not loaded as context, so ship guidance as skills or `conventions/` instead.

## Writing Guidelines

### For convention documents (`conventions/*.md`)

- Write rules that are universally applicable. Do not include project-specific paths, tool versions, or team-specific workflows.
- Each rule should be actionable and verifiable — avoid vague advice like "write clean code."
- Keep rules concise. One sentence per rule where possible.
- Group related rules under clear headings.
- Do not contradict rules from other documents in this repository.
- When a rule applies only to a specific language, it belongs in the language-specific skill (e.g., `java-best-practices`, `typescript-best-practices`), not in a shared convention document.

### For skills (`skills/<name>/SKILL.md`)

- Each skill must have valid frontmatter with a `name` (kebab-case, matching its directory) and a `description`, plus a clear H1 title and an `## Instructions` section.
- Skills should be generic enough to work in any project that follows the base conventions.
- Keep skills focused on a single task. Do not combine unrelated actions into one skill.
- Reference bundled files (conventions, scripts) with `${CLAUDE_PLUGIN_ROOT}/…`, never with `../` traversal or absolute paths — the plugin is copied to a cache on install.
- Preserve the `metadata` frontmatter block (`source`, `author`, `modifications`, `update`, `upstream_path`) so `update-skills.sh` provenance/update tooling keeps working.

## Quality Standards

- All files must be valid Markdown with no formatting errors.
- Use consistent heading levels (H1 for title, H2 for sections, H3 for subsections).
- Links between documents must use relative paths, or `${CLAUDE_PLUGIN_ROOT}/…` for cross-skill/convention references.
- No trailing whitespace, no tabs for indentation in Markdown files.
- Run `claude plugin validate ./ --strict` after structural changes.

## What NOT to include

- No project-specific configurations (build scripts, CI pipelines, IDE settings).
- No absolute file paths or machine-specific references.
- No rules that assume a specific framework, library, or tool version.
- No secrets, credentials, or environment-specific values.
- Nothing under `dev/` may be discoverable as a skill (no `SKILL.md` at a discoverable path).

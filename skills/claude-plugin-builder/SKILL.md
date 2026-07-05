---
name: claude-plugin-builder
license: Apache-2.0
metadata:
  source: https://github.com/open-elements/claude-base
  author: Open Elements
description: Complete knowledge for building and distributing Claude Code plugins — packaging skills, subagents, hooks, MCP servers, LSP servers, slash commands, and monitors into a versioned, shareable plugin, and publishing them through a marketplace. Use this skill whenever the user wants to build, scaffold, structure, package, validate, or distribute a Claude Code plugin; write or debug a `plugin.json` manifest or a `marketplace.json`; create or host a plugin marketplace; convert an existing `.claude/` configuration into a shareable plugin; or asks how plugins, `${CLAUDE_PLUGIN_ROOT}`, plugin namespacing, or plugin versioning work. Trigger even when the user only says "make a plugin", "share my skills/agents with the team", or "bundle my Claude Code setup" without using the word "plugin".
---

# Build Claude Code Plugins

A **plugin** is a self-contained directory that extends Claude Code with custom functionality — skills, subagents,
hooks, MCP servers, LSP servers, slash commands, background monitors, and themes — that can be versioned, shared across
projects, and distributed to teams or the community through a marketplace.

This skill covers the whole lifecycle: deciding whether to use a plugin, scaffolding it, adding components, testing
locally, validating, and distributing. It is knowledge-dense; the [reference files](#reference-files) hold the complete
schemas so this file stays a working guide. Read the relevant reference before writing a manifest or a component you are
unsure about — the plugin system has exact rules, and guessing produces plugins that silently fail to load.

## Plugin vs. standalone `.claude/`

Both approaches add skills, agents, and hooks. Choose based on distribution, not features:

| Use standalone `.claude/` when      | Use a plugin when                                    |
|:------------------------------------|:-----------------------------------------------------|
| Customizing a single project        | Sharing with a team or the community                 |
| Personal, not shared                | Reusing the same setup across many projects          |
| Experimenting before packaging      | You want versioning and easy updates                 |
| You want short names like `/deploy` | You accept namespaced names like `/my-plugin:deploy` |

Namespacing (`/plugin-name:skill-name`) is not optional for plugins — it prevents collisions when several plugins ship a
skill with the same name. Start standalone for fast iteration, then convert to a plugin when it is ready to share (
see [Converting `.claude/` to a plugin](#converting-claude-to-a-plugin)).

## Core workflow

### 1. Scaffold the plugin

The fastest path is the CLI, which creates a loadable plugin under `~/.claude/skills/<name>/` that auto-loads next
session as `<name>@skills-dir` with no marketplace:

```bash
claude plugin init my-plugin --with skills agents hooks mcp
```

To build a plugin by hand (for a repo, a marketplace, or full control), create the directory and manifest:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json      # ONLY the manifest goes in here
├── skills/              # everything else at the plugin ROOT
├── agents/
└── hooks/
```

Minimal `plugin.json`:

```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

The manifest is optional — with none, Claude Code auto-discovers components in default locations and derives the name
from the directory. Include one when you need metadata, a stable name, or custom component paths. `name` is the only
required field. See `references/plugin-manifest.md` for the full schema.

### 2. Add components

Each component type lives in a default directory at the plugin root and is discovered automatically. This is the map;
see `references/components.md` for the exact format, frontmatter, and rules of each.

| Component        | Default location         | Delivers                                                    |
|:-----------------|:-------------------------|:------------------------------------------------------------|
| Skills           | `skills/<name>/SKILL.md` | Model-invoked capabilities (preferred over `commands/`)     |
| Slash commands   | `commands/*.md`          | Flat markdown commands (legacy; use `skills/` for new work) |
| Subagents        | `agents/*.md`            | Specialized agents Claude can delegate to                   |
| Hooks            | `hooks/hooks.json`       | Event handlers (PreToolUse, PostToolUse, SessionStart, …)   |
| MCP servers      | `.mcp.json`              | External tools and services                                 |
| LSP servers      | `.lsp.json`              | Real-time code intelligence for a language                  |
| Monitors         | `monitors/monitors.json` | Background watchers that notify Claude                      |
| Themes           | `themes/*.json`          | Color themes (experimental)                                 |
| Executables      | `bin/`                   | Binaries added to the Bash `PATH` while enabled             |
| Default settings | `settings.json`          | Applies `agent`/`subagentStatusLine` when enabled           |

To author the skills themselves (writing good `SKILL.md` files, progressive disclosure, description tuning), use the *
*skill-creator** skill. To design MCP servers and subagents, follow the project's MCP and subagent conventions. This
skill focuses on *packaging and shipping* those pieces as a plugin.

### 3. Test locally

Load the plugin directly without installing:

```bash
claude --plugin-dir ./my-plugin        # a directory, a .zip, or repeat the flag for several
```

While iterating, run `/reload-plugins` to pick up changes (reloads skills, agents, hooks, and plugin MCP/LSP servers)
without restarting. Then verify: invoke `/my-plugin:skill-name`, check agents appear in `/context` under Custom Agents,
and confirm hooks fire. A local `--plugin-dir` copy takes precedence over an installed plugin of the same name for that
session. See `references/cli-and-testing.md`.

### 4. Validate

```bash
claude plugin validate ./my-plugin           # checks manifest, frontmatter, hooks.json
claude plugin validate ./my-plugin --strict  # treat warnings (e.g. unknown fields) as errors — use in CI
```

### 5. Distribute through a marketplace

A marketplace is a catalog (`.claude-plugin/marketplace.json`) that lists plugins and where to fetch them. Users add it
once and install individual plugins:

```bash
/plugin marketplace add owner/repo      # or a git URL, or ./local-path
/plugin install my-plugin@marketplace-name
```

Marketplaces support relative-path, `github`, `url`, `git-subdir`, and `npm` plugin sources, private repos, release
channels, and org-managed restrictions. See `references/marketplace.md` for the full schema and hosting guidance.

### 6. Version

Version is the cache key that decides whether an update is delivered:

- **Explicit `version` in `plugin.json`** → users update only when you bump the field. You **must** bump it on every
  release; pushing commits without bumping does nothing. Best for published plugins with release cycles.
- **Omit `version`** → the git commit SHA is used, so every commit is a new version. Best for
  internal/actively-developed plugins.

Follow semantic versioning (`MAJOR.MINOR.PATCH`) when explicit, and keep a `CHANGELOG.md`. Details in
`references/marketplace.md`.

## Critical rules (the common failure modes)

These cause the most "plugin loads but nothing works" problems:

- **Only `plugin.json` goes in `.claude-plugin/`.** `skills/`, `agents/`, `commands/`, `hooks/`, `.mcp.json`, etc. must
  be at the **plugin root**, never inside `.claude-plugin/`. This is the single most common mistake.
- **Reference bundled files with `${CLAUDE_PLUGIN_ROOT}`.** Plugins are copied to a cache on install, so absolute or
  hard-coded paths break. Use the variable in hook commands, MCP/LSP configs, and monitor commands.
- **All manifest paths are relative and start with `./`.** No `../` traversal — files outside the plugin root are not
  copied to the cache and won't resolve.
- **Persist state in `${CLAUDE_PLUGIN_DATA}`, not `${CLAUDE_PLUGIN_ROOT}`.** The root path changes on every update; the
  data directory survives updates.
- **Set a stable skill name.** For a single-skill plugin (a `SKILL.md` at the root), set the frontmatter `name` —
  otherwise the install directory (a version string) becomes the name and changes on every update.
- **A plugin-root `CLAUDE.md` is NOT loaded as context.** Ship instructions as a skill instead.
- **Hook scripts must be executable** (`chmod +x`) and event names are case-sensitive (`PostToolUse`, not`postToolUse`).

## Converting `.claude/` to a plugin

1. Create `my-plugin/.claude-plugin/plugin.json` with at least a `name`.
2. Copy directories up a level: `.claude/skills` → `my-plugin/skills`, same for `agents` and `commands`.
3. Move hooks from `settings.json` into `my-plugin/hooks/hooks.json` (the `hooks` object format is identical).
4. Test with `claude --plugin-dir ./my-plugin`, then remove the originals from `.claude/` to avoid duplicates (
   project/user `.claude/agents/` override same-named plugin agents).

## Building plugins in this repository

This repo (`claude-base`) vendors reusable skills under `claude-project-base/skills/`. When packaging any of that
content as a plugin:

- Keep the existing `metadata` frontmatter block (`source`, `author`, `modifications`) so provenance and the update
  tooling still work.
- Use kebab-case, descriptive plugin and skill names, and set an explicit `version` for anything published to a shared
  marketplace.
- Prefer the `skills/` layout over `commands/` for anything new.

## Reference files

Read the one relevant to your task before writing the corresponding file — each holds the complete, verbatim schema:

- `references/plugin-manifest.md` — `plugin.json`: every field, `userConfig`, `channels`, environment variables,
  path-behavior rules, single-skill layout, default enablement.
- `references/components.md` — how each component (skills, commands, agents, hooks, MCP, LSP, monitors, themes, bin,
  settings) is declared and discovered, including the full hook events and hook types.
- `references/marketplace.md` — `marketplace.json`: schema, plugin entries, all plugin `source` types, strict mode,
  hosting, private repos, versioning and release channels, renames, container seeding, managed restrictions.
- `references/cli-and-testing.md` — every `claude plugin` CLI command, local testing flags, `--debug`, and the full
  troubleshooting table.

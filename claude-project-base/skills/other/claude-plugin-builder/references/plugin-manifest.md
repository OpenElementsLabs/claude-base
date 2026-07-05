# `plugin.json` Manifest Reference

The manifest at `.claude-plugin/plugin.json` defines a plugin's identity and configuration.

**Contents**
- [When you need a manifest](#when-you-need-a-manifest)
- [Complete schema](#complete-schema)
- [Required field](#required-field)
- [Metadata fields](#metadata-fields)
- [Default enablement](#default-enablement)
- [Component path fields](#component-path-fields)
- [Path behavior rules](#path-behavior-rules)
- [Single-skill layout](#single-skill-layout)
- [User configuration](#user-configuration)
- [Channels](#channels)
- [Environment variables](#environment-variables)
- [Persistent data directory](#persistent-data-directory)
- [Unrecognized fields](#unrecognized-fields)

## When you need a manifest

The manifest is **optional**. Without one, Claude Code auto-discovers components in their [default locations](components.md) and derives the plugin name from the directory name. Add a manifest when you need to provide metadata (author, version, license), a stable name, or custom component paths. If you include one, `name` is the only required field.

## Complete schema

```json
{
  "name": "plugin-name",
  "displayName": "Plugin Name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "skills": "./custom/skills/",
  "commands": ["./custom/commands/special.md"],
  "agents": ["./custom/agents/reviewer.md"],
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json",
  "experimental": {
    "themes": "./themes/",
    "monitors": "./monitors.json"
  },
  "dependencies": [
    "helper-lib",
    { "name": "secrets-vault", "version": "~2.1.0" }
  ]
}
```

## Required field

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | string | Unique identifier, kebab-case, no spaces. Used for namespacing components (agent `code-reviewer` in plugin `plugin-dev` appears as `plugin-dev:code-reviewer`). When a marketplace entry lists the plugin under a different name, the **marketplace entry name** is what `enabledPlugins` keys and `/plugin` use. |

## Metadata fields

| Field | Type | Description |
| :--- | :--- | :--- |
| `$schema` | string | JSON Schema URL for editor autocomplete. Ignored at load time. Use `https://json.schemastore.org/claude-code-plugin-manifest.json`. |
| `displayName` | string | Human-readable name shown in `/plugin` and UI (may contain spaces/casing). Falls back to `name`. Not used for namespacing or lookup. Requires v2.1.143+. |
| `version` | string | Semantic version. Setting it pins the plugin so users update only when you bump it. If omitted, the git commit SHA is used and every commit is a new version. If also set in the marketplace entry, `plugin.json` wins. |
| `description` | string | Brief purpose, shown in the plugin manager. |
| `author` | object | `{ "name", "email"?, "url"? }`. |
| `homepage` | string | Documentation URL. |
| `repository` | string | Source code URL. |
| `license` | string | SPDX identifier, e.g. `MIT`, `Apache-2.0`. |
| `keywords` | array | Discovery tags. |
| `defaultEnabled` | boolean | Whether the plugin starts enabled when the user has not chosen. Defaults to `true`. Requires v2.1.154+. |

## Default enablement

Set `defaultEnabled: false` to ship a plugin that installs **disabled** — the user opts in with `claude plugin enable <plugin>` or `/plugin`. Use it for plugins that add cost or connect to external services. It is only the fallback: a user's explicit `enabledPlugins` setting (at any scope) and a dependency requirement both take precedence and persist across updates. The marketplace entry's `defaultEnabled` overrides the manifest value.

## Component path fields

All are optional; each overrides or supplements a default directory (see [Path behavior rules](#path-behavior-rules)).

| Field | Type | Notes |
| :--- | :--- | :--- |
| `skills` | string \| array | Extra skill directories (`<name>/SKILL.md`). **Adds to** the default `skills/` scan. |
| `commands` | string \| array | Flat `.md` command files/dirs. **Replaces** default `commands/`. |
| `agents` | string \| array | Agent files. **Replaces** default `agents/`. |
| `hooks` | string \| array \| object | Hook config path(s) or inline config. |
| `mcpServers` | string \| array \| object | MCP config path(s) or inline config. |
| `outputStyles` | string \| array | Output style files/dirs. **Replaces** default `output-styles/`. |
| `lspServers` | string \| array \| object | LSP configs. |
| `experimental.themes` | string \| array | Theme files/dirs. **Replaces** default `themes/`. |
| `experimental.monitors` | string \| array | Monitor config path(s). **Replaces** default `monitors/`. |
| `userConfig` | object | Values prompted at enable time. See [User configuration](#user-configuration). |
| `channels` | array | Message-injection channels. See [Channels](#channels). |
| `dependencies` | array | Other plugins this one requires, optionally with semver constraints: `[{ "name": "secrets-vault", "version": "~2.1.0" }]`. |

Components under `experimental` (`themes`, `monitors`) have a schema that may change between releases. The top level still works today; `claude plugin validate` warns, and a future release will require the `experimental.*` placement.

## Path behavior rules

Whether a custom path **replaces** or **adds to** the default directory depends on the field:

- **Replaces the default**: `commands`, `agents`, `outputStyles`, `experimental.themes`, `experimental.monitors`. To keep the default and add more, list it explicitly: `"commands": ["./commands/", "./extras/"]`.
- **Adds to the default**: `skills`. The default `skills/` is always scanned; listed dirs load alongside it. (Exception: for a marketplace entry whose `source` resolves to the marketplace root, listing specific subdirectories replaces the default scan.)
- **Own merge rules**: `hooks`, `mcpServers`, `lspServers` — each combines multiple sources per its own section.

For all path fields: paths are relative to the plugin root and start with `./`; multiple paths use arrays; `..` traversal outside the plugin root does not work after install (files are not copied to the cache). From v2.1.140+, a default folder that a manifest key overrides is flagged in `/doctor`, `claude plugin list`, and the `/plugin` detail view.

## Single-skill layout

A plugin that ships exactly one skill can place `SKILL.md` at the **plugin root** with no `skills/` directory and no `skills` manifest field. Claude Code (v2.1.142+) loads it as a single skill automatically. Set the frontmatter `name` field to control the invocation name — without it, the install directory name (a version string for marketplace installs) is used and changes on every update. Use the `skills/` directory layout for any plugin that may grow beyond one skill.

## User configuration

`userConfig` declares values Claude Code prompts for when the plugin is enabled, instead of making users hand-edit `settings.json`:

```json
{
  "userConfig": {
    "api_endpoint": {
      "type": "string",
      "title": "API endpoint",
      "description": "Your team's API endpoint"
    },
    "api_token": {
      "type": "string",
      "title": "API token",
      "description": "API authentication token",
      "sensitive": true
    }
  }
}
```

Keys must be valid identifiers. Option fields: `type` (`string`|`number`|`boolean`|`directory`|`file`, required), `title` (required), `description` (required), `sensitive`, `required`, `default`, `multiple` (string arrays), `min`/`max` (numbers).

Each value substitutes as `${user_config.KEY}` in MCP/LSP configs, hook commands, and monitor commands; non-sensitive values also in skill/agent content. All values are exported to plugin subprocesses as `CLAUDE_PLUGIN_OPTION_<KEY>`. Non-sensitive values are stored in `settings.json` under `pluginConfigs[<plugin-id>].options`; sensitive values go to the system keychain (≈2 KB total limit — keep them small).

## Channels

`channels` lets a plugin inject messages into the conversation (Telegram/Slack/Discord style). Each channel binds to an MCP server the plugin provides:

```json
{
  "channels": [
    {
      "server": "telegram",
      "userConfig": {
        "bot_token": { "type": "string", "title": "Bot token", "description": "Telegram bot token", "sensitive": true },
        "owner_id":  { "type": "string", "title": "Owner ID", "description": "Your Telegram user ID" }
      }
    }
  ]
}
```

`server` is required and must match a key in the plugin's `mcpServers`. The optional per-channel `userConfig` uses the same schema as the top-level field.

## Environment variables

Three variables are substituted inline anywhere they appear in skill/agent content, hook commands, monitor commands, and MCP/LSP configs, and are exported to hook and server subprocesses:

- **`${CLAUDE_PLUGIN_ROOT}`** — absolute path to the plugin's install directory. Use it for every reference to bundled scripts, binaries, and config. **This path changes on every update**, so do not write state here. In shell-form hooks and monitors, wrap in double quotes: `"${CLAUDE_PLUGIN_ROOT}"/scripts/x.sh`; in exec-form hooks, pass via `args`.
- **`${CLAUDE_PLUGIN_DATA}`** — a persistent directory that **survives updates**. Use it for installed dependencies (`node_modules`, venvs), caches, and generated files. Created on first reference.
- **`${CLAUDE_PROJECT_DIR}`** — the project root (same value hooks receive). Use for project-local scripts; wrap in quotes for paths with spaces.

When a plugin updates mid-session, hooks/monitors/MCP/LSP keep using the old path until `/reload-plugins` (hooks, MCP, LSP) or a session restart (monitors).

## Persistent data directory

`${CLAUDE_PLUGIN_DATA}` resolves to `~/.claude/plugins/data/{id}/`, where `{id}` is the plugin identifier with non-`[a-zA-Z0-9_-]` characters replaced by `-` (e.g. `formatter@my-marketplace` → `~/.claude/plugins/data/formatter-my-marketplace/`).

A common pattern installs dependencies once and reuses them across updates. Because the data directory outlives any version, detect a changed dependency manifest by diffing the bundled copy against a stored one:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "diff -q \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package.json\" >/dev/null 2>&1 || (cd \"${CLAUDE_PLUGIN_DATA}\" && cp \"${CLAUDE_PLUGIN_ROOT}/package.json\" . && npm install) || rm -f \"${CLAUDE_PLUGIN_DATA}/package.json\""
          }
        ]
      }
    ]
  }
}
```

The data directory is deleted when the plugin is uninstalled from its last scope (pass `--keep-data` to preserve it).

## Unrecognized fields

Claude Code ignores unknown top-level fields, so one `plugin.json` can double as a VS Code/Cursor/npm/MCPB manifest. `claude plugin validate` reports unknown fields as **warnings** (and suggests near-miss corrections); the plugin still loads. Wrong-type fields (e.g. `keywords` as a string) are **errors**. Use `--strict` in CI to treat warnings as errors.

# `db-tools` Claude Code plugin

Here is a complete plugin that bundles an MCP server (a Node script at `servers/index.js`) and a skill for writing database migrations.

## Directory layout

```
db-tools/
├── .claude-plugin/
│   └── plugin.json                    # the manifest — ONLY this file goes in .claude-plugin/
├── .mcp.json                          # MCP server configuration (plugin root)
├── servers/
│   └── index.js                       # the bundled MCP server (Node, stdio)
└── skills/
    └── writing-migrations/
        └── SKILL.md                   # the migration-writing skill
```

The single most common plugin mistake is putting components inside `.claude-plugin/`. **Only `plugin.json` lives there.** `.mcp.json`, `servers/`, and `skills/` all sit at the **plugin root**.

## Files

### `db-tools/.claude-plugin/plugin.json`

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "db-tools",
  "displayName": "Database Tools",
  "version": "1.0.0",
  "description": "Database tooling for Claude Code: an MCP server for inspecting and querying databases, plus a skill for writing safe, reversible database migrations.",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "license": "Apache-2.0",
  "keywords": ["database", "migrations", "mcp", "sql"]
}
```

- `name` is the only required field; everything else is metadata.
- The skill and MCP server are auto-discovered from their default locations (`skills/` and `.mcp.json`), so no component path fields are needed in the manifest.
- Setting an explicit `version` pins the plugin: users only get updates when you bump it. Follow semantic versioning and bump on every release. Omit `version` if you want every git commit to be treated as a new version instead.

### `db-tools/.mcp.json`

```json
{
  "mcpServers": {
    "db-tools": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/index.js"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

- **`${CLAUDE_PLUGIN_ROOT}`** is mandatory here. Plugins are copied into a cache on install and the path changes on every update, so a hard-coded or relative path to `index.js` would break. The variable always resolves to the current install directory.
- The server is launched with `node`, matching the requested `servers/index.js` script.
- `DATABASE_URL` is passed through from the environment. For a shareable plugin you could instead declare a `userConfig` entry in `plugin.json` and reference it as `${user_config.database_url}` so Claude Code prompts for it at enable time.

### `db-tools/servers/index.js`

A dependency-free stub MCP server that speaks MCP over stdio (newline-delimited JSON-RPC). It advertises two tools — `list_tables` and `run_query` — and returns placeholder responses. Replace the tool bodies with real database access (and, ideally, the official `@modelcontextprotocol/sdk` `McpServer` + `StdioServerTransport`) for production. Full contents are in `db-tools/servers/index.js`.

### `db-tools/skills/writing-migrations/SKILL.md`

A skill whose frontmatter `description` triggers on migration-related requests. It instructs Claude to inspect the live schema via the bundled `db-tools` MCP tools first, then write one focused, reversible (up/down) migration following the expand/contract zero-downtime pattern, with locking and transaction caveats. It creates the shortcut `/db-tools:writing-migrations`. Full contents are in the file.

## Testing and validation

```bash
# Load the plugin locally without installing (a dir, a .zip, or repeat the flag)
claude --plugin-dir ./db-tools

# In the session:
#   - the MCP server "db-tools" starts automatically; its tools appear as MCP tools
#   - invoke /db-tools:writing-migrations
#   - run /reload-plugins after edits to pick up changes without restarting

# Validate the manifest, frontmatter, and configs
claude plugin validate ./db-tools
claude plugin validate ./db-tools --strict   # use in CI (warnings become errors)
```

## Distributing (optional)

To share it, add a marketplace catalog (`.claude-plugin/marketplace.json`) listing `db-tools` and its source, then:

```bash
/plugin marketplace add owner/repo
/plugin install db-tools@marketplace-name
```

## Key rules applied here

- Only `plugin.json` is inside `.claude-plugin/`; `.mcp.json`, `servers/`, and `skills/` are at the plugin root.
- The MCP config references the bundled script with `${CLAUDE_PLUGIN_ROOT}`, never a hard-coded path.
- The skill has a stable `name` in its frontmatter, so its invocation name does not change across updates.
- No `../` traversal and no plugin-root `CLAUDE.md` (which would not be loaded as context — instructions ship as the skill instead).

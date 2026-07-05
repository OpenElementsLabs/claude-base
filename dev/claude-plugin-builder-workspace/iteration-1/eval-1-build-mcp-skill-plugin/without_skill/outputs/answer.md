# db-tools — Claude Code plugin

A single plugin that bundles two things:

1. An **MCP server** (a Node script at `servers/index.js`) that exposes database tools to Claude.
2. A **skill** (`database-migrations`) that teaches Claude how to write safe, reversible migrations.

## Directory layout

```
db-tools/
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest (required)
├── .mcp.json                       # MCP server configuration
├── servers/
│   ├── index.js                    # The MCP server (Node, stdio transport)
│   └── package.json                # Deps for the server (@modelcontextprotocol/sdk)
└── skills/
    └── database-migrations/
        └── SKILL.md                # The migrations skill
```

Key rules of the layout:

- The manifest **must** live at `.claude-plugin/plugin.json`. Everything else (skills, servers, `.mcp.json`) lives in the plugin **root**, one level up from `.claude-plugin/`.
- Skills are auto-discovered from the `skills/` directory. Each skill is its own folder containing a `SKILL.md` with YAML frontmatter (`name` + `description`). The `description` is what triggers the skill, so make it list concrete situations.
- The MCP server is not started by Claude Code directly; it is declared in `.mcp.json` and referenced from the manifest.

## plugin.json

`.claude-plugin/plugin.json`:

```json
{
  "name": "db-tools",
  "version": "0.1.0",
  "description": "Database tooling for Claude Code: an MCP server exposing database operations plus a skill for writing safe, reversible database migrations.",
  "author": { "name": "Open Elements", "email": "info@open-elements.com" },
  "homepage": "https://github.com/OpenElementsLabs/db-tools",
  "license": "Apache-2.0",
  "keywords": ["database", "migrations", "mcp", "sql"],
  "mcpServers": "./.mcp.json"
}
```

- `name` is the only strictly required field, but you should always set `version` and `description`.
- `mcpServers` can either be an inline object or, as here, a **path to an external `.mcp.json`** file. Keeping it in a separate file matches the standard MCP config format and keeps the manifest tidy.

## MCP configuration

`.mcp.json`:

```json
{
  "mcpServers": {
    "db-tools": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/index.js"],
      "env": { "DATABASE_URL": "${DATABASE_URL}" }
    }
  }
}
```

- `${CLAUDE_PLUGIN_ROOT}` is expanded by Claude Code to the absolute path of the installed plugin, so the server resolves correctly no matter where the plugin is installed. Always use it instead of a relative or hard-coded path.
- `command` + `args` launch the stdio MCP server. `env` forwards the database connection string; `${DATABASE_URL}` pulls from the user's environment so no secret is committed.

## The MCP server

`servers/index.js` is a stdio MCP server built on `@modelcontextprotocol/sdk`. It advertises three tools — `run_query`, `list_tables`, `describe_table` — with the bodies stubbed (marked `TODO`) so you can drop in your driver of choice (`pg`, `mysql2`, `better-sqlite3`, …). Note it logs only to **stderr**, because stdout is reserved for the MCP protocol.

Before use, install its dependency from the plugin root:

```bash
cd db-tools/servers && npm install
```

## The migrations skill

`skills/database-migrations/SKILL.md` has frontmatter (`name`, `description`) plus numbered instructions covering: detecting the framework, checking current schema (via the MCP server's `list_tables`/`describe_table`), writing reversible up/down steps, zero-downtime expand/migrate/contract patterns, avoiding mixed DDL+DML transactions, and a done-checklist.

## Installing / testing

1. Add the plugin's parent directory as a marketplace, or install via a marketplace that lists it.
2. Restart Claude Code and confirm with `/plugin` (plugin listed), the MCP server appearing in `/mcp`, and the skill triggering on a migration request.

# CLI, Testing & Debugging Reference

Every `claude plugin` command, plus local testing, validation, and troubleshooting. All CLI commands have interactive `/plugin …` equivalents.

**Contents**
- [Local testing](#local-testing)
- [Plugin CLI commands](#plugin-cli-commands)
- [Marketplace CLI commands](#marketplace-cli-commands)
- [Skills-directory plugins](#skills-directory-plugins)
- [Installation scopes](#installation-scopes)
- [Debugging](#debugging)
- [Troubleshooting](#troubleshooting)

## Local testing

```bash
claude --plugin-dir ./my-plugin        # load a plugin directory (or a .zip, v2.1.128+) for this session
claude --plugin-dir ./a --plugin-dir ./b   # load several — repeat the flag
claude --plugin-url https://example.com/my-plugin.zip   # fetch and load a hosted .zip for this session
```

A `--plugin-dir` copy takes precedence over an installed plugin of the same name (except plugins force-enabled/disabled by managed settings). While iterating, run `/reload-plugins` to pick up changes to skills, agents, hooks, and plugin MCP/LSP servers without restarting. Verify components: invoke `/plugin-name:skill-name`; check agents in `/context` under Custom Agents (or `@`-mention them); confirm hooks fire.

## Plugin CLI commands

### `claude plugin init <name> [options]`
Scaffold a plugin at `~/.claude/skills/<name>/`; auto-loads next session as `<name>@skills-dir`. Options: `--description`, `--author`, `--author-email`, `--with <components...>` (`skills`, `agents`, `hooks`, `mcp`, `lsp`, `output-style`, `channel`), `-f/--force`. Alias: `new`.

### `claude plugin install <plugin> [options]`
Install from a marketplace. `<plugin>` is a name or `plugin@marketplace`. `-s/--scope user|project|local` (default `user`).

### `claude plugin uninstall <plugin> [options]`
Remove an installed plugin. `-s/--scope`, `--keep-data` (preserve `${CLAUDE_PLUGIN_DATA}`), `--prune` (also remove orphaned auto-installed dependencies), `-y/--yes`. Aliases: `remove`, `rm`. By default, uninstalling from the last scope deletes the data directory.

### `claude plugin prune [options]`
Remove auto-installed dependencies no longer required by any plugin (directly installed plugins are never touched). `-s/--scope`, `--dry-run`, `-y/--yes`. Alias: `autoremove`. Requires v2.1.121+.

### `claude plugin enable <plugin>` / `claude plugin disable <plugin>`
Enable/disable without uninstalling. `-s/--scope`. Enable pulls in declared dependencies transitively; disable fails if another enabled plugin depends on the target (the error gives a chained command).

### `claude plugin update <plugin> [options]`
Update to the latest version. `-s/--scope user|project|local|managed`.

### `claude plugin list [options]`
List installed plugins with version, source, and status. `--json`, `--available` (requires `--json`). Interactive `/plugin list` also accepts `--enabled`/`--disabled`; alias `ls`.

### `claude plugin details <name>`
Show a plugin's component inventory (Skills, Agents, Hooks, MCP, LSP) and projected token cost (always-on vs on-invoke).

### `claude plugin validate <path> [--strict]`
Validate a plugin or marketplace directory: manifest schema, skill/agent/command frontmatter, and `hooks/hooks.json`. `--strict` treats warnings (unknown fields, non-kebab names) as errors — use in CI.

### `claude plugin tag [options]`
Create a release git tag for the plugin in the current directory (for dependency version resolution). `--push`, `--dry-run`, `-f/--force`.

## Marketplace CLI commands

### `claude plugin marketplace add <source> [options]`
`<source>`: GitHub `owner/repo` (append `@ref` to pin), a git URL (append `#ref`), a remote URL to a `marketplace.json`, or a local path. URLs must include a scheme (v2.1.196+). `--scope user|project|local`, `--sparse <paths...>` (limit checkout for monorepos).

### `claude plugin marketplace list [--json]`
List configured marketplaces. `--json` includes `name`, `source`, and source-specific fields.

### `claude plugin marketplace remove <name> [--scope <scope>]`
Remove by the marketplace `name` (not the add source). Removing from the last scope uninstalls plugins from it — use `update` to refresh without losing installs. Alias `rm`.

### `claude plugin marketplace update [name]`
Refresh from sources (all marketplaces if `name` omitted). Seed-managed marketplaces are read-only and skipped.

## Skills-directory plugins

Any folder under a skills directory with a `.claude-plugin/plugin.json` loads as `<name>@skills-dir` next session — no marketplace, no install, discovered in place.

| Skills directory | Scope | Loads |
| :--- | :--- | :--- |
| `~/.claude/skills/` | personal | In every project |
| `<cwd>/.claude/skills/` | project | Only after you accept the workspace trust dialog |

Project-scope `@skills-dir` plugins have restrictions: MCP servers go through per-server approval, LSP servers start only after trust, and monitors do not load. They load only from the `.claude/skills/` of the launch directory (they do not walk up to the repo root) — launch from the repo root or `/reload-plugins` after changing directories. Editing a `SKILL.md` takes effect immediately; changes to `hooks/`, `.mcp.json`, `agents/` need `/reload-plugins` or a restart. Remove by deleting the folder or `claude plugin disable my-tool@skills-dir`.

## Installation scopes

| Scope | Settings file | Use case |
| :--- | :--- | :--- |
| `user` | `~/.claude/settings.json` | Personal, across all projects (default) |
| `project` | `.claude/settings.json` | Team, shared via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | Managed settings | Read-only, update only |

## Debugging

`claude --debug` shows which plugins load, manifest errors, skill/agent/hook registration, and MCP server initialization. Checklist: confirm "loading plugin" messages, that each component directory is listed, and that file permissions allow reading.

## Troubleshooting

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| Plugin not loading | Invalid `plugin.json` | `claude plugin validate` — checks manifest, frontmatter, `hooks.json` |
| Skills not appearing | Wrong directory structure | Put `skills/`/`commands/` at the plugin root, not in `.claude-plugin/` |
| Hooks not firing | Script not executable | `chmod +x script.sh`; verify shebang; check event name case; test the script manually |
| MCP server fails | Missing `${CLAUDE_PLUGIN_ROOT}` | Use the variable for all bundled paths; run `claude --debug` for init errors |
| Path errors | Absolute paths used | All manifest paths must be relative and start with `./` |
| LSP `Executable not found in $PATH` | Language server not installed | Install the binary (e.g. `npm install -g typescript-language-server typescript`) |
| Files not found after install | Referenced files outside the plugin dir (`../…`) | Plugins are copied to a cache; keep files inside the plugin, or use symlinks that resolve within the plugin/marketplace |
| Relative-path plugins fail | Marketplace added via direct `marketplace.json` URL | Use `github`/`npm`/`url` plugin sources, or host the marketplace in git |
| Marketplace wiped offline | `git pull` failed and cache was re-cloned | `export CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1`, or seed via `CLAUDE_CODE_PLUGIN_SEED_DIR` |
| Git operation times out | Repo/network exceeds the 120s limit | `export CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS=300000` |

**Common manifest errors**: `name: Required` (missing required field); `Invalid JSON syntax: Unexpected token }` (trailing/missing comma); `Duplicate plugin name "x" found in marketplace`; `plugins[0].source: Path contains ".."` (use paths without `..`). A malformed `hooks/hooks.json` prevents the entire plugin from loading.

## Plugin caching notes

Marketplace plugins are copied to `~/.claude/plugins/cache` (one directory per version). Updated/uninstalled versions are orphaned and removed automatically after 7 days (a grace period for concurrent sessions); Glob/Grep skip orphaned directories. Paths that traverse outside the plugin root do not resolve after install. To share files within a marketplace, use symlinks: those resolving within the plugin's own directory are preserved; those elsewhere in the same marketplace are dereferenced (content copied); those outside the marketplace are skipped for security.

# Marketplace Reference

A **marketplace** is a catalog (`.claude-plugin/marketplace.json`) that distributes plugins with centralized discovery, version tracking, and automatic updates.

**Contents**
- [Workflow](#workflow)
- [marketplace.json schema](#marketplacejson-schema)
- [Plugin entries](#plugin-entries)
- [Plugin sources](#plugin-sources)
- [Strict mode](#strict-mode)
- [Hosting](#hosting)
- [Private repositories](#private-repositories)
- [Requiring a marketplace for a team](#requiring-a-marketplace-for-a-team)
- [Versioning and release channels](#versioning-and-release-channels)
- [Renaming or removing a plugin](#renaming-or-removing-a-plugin)
- [Container seeding](#container-seeding)
- [Managed restrictions](#managed-restrictions)

## Workflow

1. Build one or more plugins.
2. Create `.claude-plugin/marketplace.json` listing them and their sources.
3. Host it (push to GitHub/GitLab/etc., or use a local path).
4. Users add it and install: `/plugin marketplace add owner/repo` then `/plugin install my-plugin@marketplace-name`.
5. Update by pushing changes; users run `/plugin marketplace update`.

A minimal local marketplace tree:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── quality-review-plugin/
        ├── .claude-plugin/plugin.json
        └── skills/quality-review/SKILL.md
```

## marketplace.json schema

```json
{
  "name": "company-tools",
  "owner": { "name": "DevTools Team", "email": "devtools@example.com" },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "./plugins/formatter",
      "description": "Automatic code formatting on save",
      "version": "2.1.0",
      "author": { "name": "DevTools Team" }
    },
    {
      "name": "deployment-tools",
      "source": { "source": "github", "repo": "company/deploy-plugin" },
      "description": "Deployment automation tools"
    }
  ]
}
```

**Required**: `name` (kebab-case, public-facing; each user registers one marketplace per name — re-adding replaces), `owner` (`{ "name", "email"? }`), `plugins` (array).

**Optional**: `$schema`, `description`, `version`, `metadata.pluginRoot` (base dir prepended to relative sources, so `"source": "formatter"` resolves under it), `allowCrossMarketplaceDependenciesOn` (array of other marketplaces plugins here may depend on), `renames` (see [Renaming](#renaming-or-removing-a-plugin), v2.1.193+).

**Reserved names** (cannot be used by third parties): `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `claude-plugins-community`, `claude-community`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `anthropic-agent-skills`, `knowledge-work-plugins`, `life-sciences`, `claude-for-legal`, `claude-for-financial-services`, `financial-services-plugins`, plus names impersonating official ones.

## Plugin entries

Each entry describes a plugin and where to find it. It may include any [`plugin.json` field](plugin-manifest.md) (`description`, `version`, `author`, `commands`, `hooks`, …) plus marketplace-specific fields: `source`, `category`, `tags`, `strict`, `relevance`.

**Required**: `name`, `source`.

**Notable optional**: `displayName` (v2.1.143+), `version` (pins if set — see [Versioning](#versioning-and-release-channels)), `author`, `homepage`, `repository`, `license`, `keywords`, `category`, `tags`, `strict` (see [Strict mode](#strict-mode)), `relevance` (org-allowlisted recommendation signals, v2.1.152+), `defaultEnabled` (overrides the manifest value, v2.1.154+). Component fields (`skills`, `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`) can point to custom paths.

Skills load from the plugin's `skills/` by default; paths in `skills` add to that scan. When several entries share one `skills/` at the marketplace root (`source: "./"`), list specific subdirectories so each entry loads only its own: `"skills": ["./skills/code-review", "./skills/docs"]` — with a marketplace-root source these listed paths become the complete set.

## Plugin sources

Set in each entry's `source` field. After fetching, plugins are copied into `~/.claude/plugins/cache`.

| Source | Type | Fields | Notes |
| :--- | :--- | :--- | :--- |
| Relative path | string (`"./my-plugin"`) | — | Local dir within the marketplace repo; must start with `./`; resolved against the marketplace root. |
| `github` | object | `repo`, `ref?`, `sha?` | `repo` in `owner/repo` form. |
| `url` | object | `url`, `ref?`, `sha?` | Full git URL (`https://` or `git@`); `.git` suffix optional. |
| `git-subdir` | object | `url`, `path`, `ref?`, `sha?` | Subdirectory of a git repo; sparse clone for monorepos. `url` also accepts `owner/repo` or SSH. |
| `npm` | object | `package`, `version?`, `registry?` | Installed via `npm install`; supports scoped packages and private registries. |

Examples:

```json
{ "name": "gh",  "source": { "source": "github", "repo": "owner/plugin-repo", "ref": "v2.0.0", "sha": "a1b2c3..." } }
{ "name": "git", "source": { "source": "url", "url": "https://gitlab.com/team/plugin.git", "ref": "main" } }
{ "name": "sub", "source": { "source": "git-subdir", "url": "https://github.com/acme/monorepo.git", "path": "tools/claude-plugin" } }
{ "name": "npm", "source": { "source": "npm", "package": "@acme/claude-plugin", "version": "^2.0.0", "registry": "https://npm.example.com" } }
```

When both `ref` and `sha` are set, `sha` is the effective pin. **Marketplace source vs plugin source** are different: the marketplace source (set via `/plugin marketplace add`) locates the `marketplace.json` catalog and supports `ref` but not `sha`; a plugin source locates one plugin and supports both.

**Relative paths need a git or local marketplace.** If a marketplace is added via a direct URL to `marketplace.json`, only that file is downloaded, so relative-path plugins fail — use `github`/`npm`/`url` sources for URL-distributed marketplaces.

## Strict mode

`strict` (default `true`) controls whether `plugin.json` is the authority for component definitions:

- **`true`** — `plugin.json` is authoritative; the marketplace entry may supplement it, and both merge.
- **`false`** — the marketplace entry is the entire definition. The plugin repo can be raw files with no `plugin.json`; if it does declare components, that is a conflict and the plugin fails to load. Use when the marketplace operator wants to curate/restructure a plugin's components.

## Hosting

- **GitHub (recommended)**: create a repo, add `.claude-plugin/marketplace.json`, share as `/plugin marketplace add owner/repo`.
- **Other git hosts**: `/plugin marketplace add https://gitlab.com/company/plugins.git`.
- **Local (testing)**: `/plugin marketplace add ./my-marketplace`.

## Private repositories

Manual install/update uses your existing git credential helpers (`gh auth login`, keychain, `git-credential-store`); SSH works if the host is in `known_hosts` and the key is in `ssh-agent`. Background auto-updates run without credential helpers, so set a token in the environment:

| Provider | Env vars |
| :--- | :--- |
| GitHub | `GITHUB_TOKEN` or `GH_TOKEN` |
| GitLab | `GITLAB_TOKEN` or `GL_TOKEN` |
| Bitbucket | `BITBUCKET_TOKEN` |

## Requiring a marketplace for a team

Add it to the project's `.claude/settings.json` so collaborators are prompted on trust, and optionally enable specific plugins by default:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": { "source": { "source": "github", "repo": "your-org/claude-plugins" } }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "deployment-tools@company-tools": true
  }
}
```

Marketplace state is stored once per user in `~/.claude/plugins/known_marketplaces.json`, not per project; worktrees share the main checkout's marketplace location.

## Versioning and release channels

Version is the cache key for update detection. Resolved from the first set: (1) `version` in `plugin.json`, (2) `version` in the marketplace entry, (3) the git commit SHA of the source, (4) `unknown` (npm sources / non-git local dirs).

| Approach | How | Update behavior | Best for |
| :--- | :--- | :--- | :--- |
| Explicit version | `"version": "2.1.0"` in `plugin.json` | Users update only when you bump it; commits without a bump do nothing | Published plugins with release cycles |
| Commit-SHA | Omit `version` everywhere | Every new commit is an update | Internal / actively developed plugins |

Avoid setting `version` in both `plugin.json` and the marketplace entry — `plugin.json` silently wins.

**Release channels**: point two marketplaces at different `ref`s/SHAs of the same repo (e.g. `stable` and `latest`) and assign each to a user group via managed settings' `extraKnownMarketplaces`. Each channel must resolve to a *different* version, or updates are skipped.

**Dependency version pinning**: a plugin can constrain its `dependencies` to a semver range using the `{plugin-name}--v{version}` git-tag convention. Create tags with `claude plugin tag`.

## Renaming or removing a plugin

`name` is the stable identifier used in `enabledPlugins`, `pluginConfigs`, and installs — changing it breaks installs. To change only the UI label, set `displayName` and keep `name`. To actually rename or remove, add a top-level `renames` map (v2.1.193+) so existing users migrate instead of hitting `plugin-not-found`:

```json
{
  "name": "acme-tools",
  "owner": { "name": "Acme" },
  "plugins": [ { "name": "code-formatter", "source": "./plugins/code-formatter" } ],
  "renames": { "formatter": "code-formatter", "legacy-linter": null }
}
```

Map an old name to the new name, or to `null` if removed. Treat `renames` as append-only history (Claude Code follows chains). Remote-source renames report `plugin-cache-miss` and need one `/plugin install`. Run `claude plugin validate .` — it rejects cycles or chains that don't terminate.

## Container seeding

For CI/images, pre-populate `~/.claude/plugins` at build time and point `CLAUDE_CODE_PLUGIN_SEED_DIR` at it so Claude Code starts with marketplaces/plugins ready without cloning. Structure mirrors `~/.claude/plugins` (`known_marketplaces.json`, `marketplaces/<name>/…`, `cache/<marketplace>/<plugin>/<version>/…`). Build it by installing once with `CLAUDE_CODE_PLUGIN_CACHE_DIR=/opt/claude-seed` set, then setting `CLAUDE_CODE_PLUGIN_SEED_DIR=/opt/claude-seed` at runtime. Seeds are read-only, take precedence over user config, resolve by probing the mount path (not stored JSON paths), and block `/plugin marketplace remove|update`.

## Managed restrictions

Admins can restrict which marketplaces users may add via `strictKnownMarketplaces` in managed settings: undefined = no restriction, `[]` = full lockdown, or an allowlist of source matchers. Supports `github` (`repo` + optional `ref`/`path`), `url` (exact match), `hostPattern` (regex on host — recommended for self-hosted git), and `pathPattern` (regex on filesystem path). Pair with `extraKnownMarketplaces` to auto-register allowed ones, and `disableSideloadFlags` to reject `--plugin-dir`/sideload flags. Enforced before any network/filesystem operation, on add and on install/update/refresh.

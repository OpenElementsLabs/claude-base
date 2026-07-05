# Auto-provisioning plugins for your team + how versioning/updates work

You want two things:

1. **Zero-friction adoption** — a teammate clones the repo, trusts it, and the right plugins are just *there*.
2. **A sane update story** for a team that pushes often.

Both are solved by combining a **marketplace** (the catalog of your plugins) with a couple of entries in the project's `.claude/settings.json`, plus picking the right **versioning strategy**. Here's the whole picture.

---

## 1. Set up the marketplace

A marketplace is just a catalog file — `.claude-plugin/marketplace.json` — that lists your plugins and where to fetch each one. You host it (typically a GitHub repo), users add it once, and then install/enable individual plugins from it.

You have two common layouts:

### Option A — plugins live in the same repo as the marketplace (simplest for one team)

```
your-org/claude-plugins            (a git repo)
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    ├── code-formatter/
    │   ├── .claude-plugin/plugin.json
    │   └── skills/format/SKILL.md
    └── deploy-tools/
        ├── .claude-plugin/plugin.json
        └── skills/deploy/SKILL.md
```

`marketplace.json`:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "company-tools",
  "owner": { "name": "Platform Team", "email": "platform@your-org.com" },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "./plugins/code-formatter",
      "description": "Automatic code formatting and lint fixes"
    },
    {
      "name": "deploy-tools",
      "source": "./plugins/deploy-tools",
      "description": "Deployment automation for our services"
    }
  ]
}
```

The relative `source` paths (`"./plugins/..."`, must start with `./`) resolve against the marketplace repo root. Relative-path sources only work when the marketplace is added as a git repo or local path — which is exactly your case.

### Option B — plugins live in other repos

Point each entry at its own repo instead of a local path:

```json
{
  "name": "company-tools",
  "owner": { "name": "Platform Team", "email": "platform@your-org.com" },
  "plugins": [
    { "name": "deploy-tools",
      "source": { "source": "github", "repo": "your-org/deploy-plugin" } },
    { "name": "monorepo-helpers",
      "source": { "source": "git-subdir",
                  "url": "https://github.com/your-org/monorepo.git",
                  "path": "tools/claude-plugin" } }
  ]
}
```

Supported source types: relative path, `github` (`{ "repo": "owner/repo", "ref"?, "sha"? }`), `url` (any git URL), `git-subdir` (a folder inside a monorepo), and `npm`.

**Manual add/install** (what a person types the first time, for reference):

```
/plugin marketplace add your-org/claude-plugins
/plugin install code-formatter@company-tools
```

But the whole point of your question is to *not* make people do that manually — that's the next step.

---

## 2. Make the team get the plugins automatically on repo open

This is the key mechanism. In the **project's** `.claude/settings.json` (checked into the repo you want them to open), declare the marketplace and which plugins should be enabled by default:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": { "source": "github", "repo": "your-org/claude-plugins" }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "deploy-tools@company-tools": true
  }
}
```

What happens for a teammate:

- They clone/open the repo. On the **trust prompt**, Claude Code registers the `company-tools` marketplace for them (`extraKnownMarketplaces`) — no manual `/plugin marketplace add`.
- The plugins keyed in `enabledPlugins` are installed and enabled automatically. No manual `/plugin install`.
- The plugin keys are `"<plugin-name>@<marketplace-name>"`.

Notes that matter:

- Marketplace registration is stored **once per user** (`~/.claude/plugins/known_marketplaces.json`), not per project. Worktrees share the main checkout's marketplace.
- A user's own explicit `enabledPlugins` choice takes precedence and persists — so you're setting a default, not forcibly overriding someone who opted out.
- If some plugins are optional/costly (e.g. connect to an external service), leave them out of `enabledPlugins` and set `"defaultEnabled": false` in that plugin's manifest so it installs disabled until someone opts in.

### Optional: lock down which marketplaces are allowed (org admins)

If you want to *require* this marketplace and forbid others, use **managed settings** (admin-controlled, not the per-project file):

```json
{
  "extraKnownMarketplaces": {
    "company-tools": { "source": { "source": "github", "repo": "your-org/claude-plugins" } }
  },
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "your-org/claude-plugins" }
  ],
  "disableSideloadFlags": true
}
```

`strictKnownMarketplaces: []` is full lockdown; an allowlist permits only listed sources; leaving it undefined means no restriction. `disableSideloadFlags` rejects `--plugin-dir` sideloading. This is optional — the `.claude/settings.json` approach above already gives you auto-adoption without it.

---

## 3. How versioning and updates actually work

**Version is the cache key Claude Code uses to decide "is there an update?"** It's resolved from the first of these that's set:

1. `version` in the plugin's `plugin.json`
2. `version` in the marketplace entry
3. the **git commit SHA** of the source
4. `unknown` (npm sources / non-git local dirs)

Do **not** set `version` in both `plugin.json` and the marketplace entry — `plugin.json` silently wins and the marketplace value is ignored.

There are two strategies, and the right one depends on your "we push often" situation:

| Strategy | How | Update behavior | Best for |
| :--- | :--- | :--- | :--- |
| **Commit-SHA (recommended for you)** | Omit `version` everywhere | Every new commit is a new version | Internal, actively developed plugins |
| **Explicit semver** | `"version": "2.1.0"` in `plugin.json` | Users update **only when you bump the field** — pushing commits without bumping does *nothing* | Published plugins with release cycles |

### Because you push often: omit `version`

For a team that ships changes frequently, the explicit-version model is a footgun — every change would require a manual `MAJOR.MINOR.PATCH` bump, and forgetting the bump means teammates silently never get the update. So:

- **Leave `version` out** of `plugin.json` (and out of the marketplace entry). The commit SHA becomes the version, so **every push is automatically a new version** with nothing to remember.
- Teammates pick up changes when they run `/plugin marketplace update`. That re-reads the catalog and pulls new plugin versions; then a session restart (or `/reload-plugins` mid-session for skills/agents/hooks/MCP/LSP) applies them.

`plugin.json` for the SHA-based approach — note no `version`:

```json
{
  "name": "code-formatter",
  "description": "Automatic code formatting and lint fixes",
  "author": { "name": "Platform Team", "email": "platform@your-org.com" }
}
```

### If you later want controlled releases

Switch to explicit semver, follow `MAJOR.MINOR.PATCH`, keep a `CHANGELOG.md`, and **bump the field on every release** — otherwise the update is not delivered.

### Pinning a specific version (optional stability)

You can pin what the team receives regardless of how often you push, by setting a `ref`/`sha` on the source, or a `version` in the marketplace entry:

```json
{ "name": "deploy-tools",
  "source": { "source": "github", "repo": "your-org/deploy-plugin", "ref": "v2.0.0" } }
```

When both `ref` and `sha` are given on a source, `sha` wins.

### Stable vs. latest channels (best of both)

If part of the team wants bleeding-edge and part wants stability, use **release channels**: create two marketplaces pointing at different `ref`s/SHAs of the same repo (e.g. `stable` → a tag, `latest` → `main`) and assign each group its marketplace via managed-settings `extraKnownMarketplaces`. Each channel must resolve to a *different* version or the update is skipped.

---

## 4. Update lifecycle summary

1. You commit and push a plugin change to `your-org/claude-plugins`.
2. With `version` omitted, that commit is automatically a new version (its SHA).
3. A teammate runs `/plugin marketplace update` (pulls the new catalog + plugin versions). You can make this a habit or a periodic reminder for the team.
4. Changes take effect on the next session; mid-session, `/reload-plugins` picks up skills, agents, hooks, and plugin MCP/LSP servers without a restart (monitors need a restart).
5. New teammates: nothing to do beyond opening the repo and trusting it — `extraKnownMarketplaces` + `enabledPlugins` provision everything.

---

## 5. Gotchas worth knowing up front

- **Only `plugin.json` goes inside `.claude-plugin/`.** `skills/`, `agents/`, `hooks/`, `.mcp.json`, etc. live at the plugin **root**, not inside `.claude-plugin/`. This is the single most common reason a plugin "loads but nothing works."
- **Reference bundled files with `${CLAUDE_PLUGIN_ROOT}`** in hook/MCP/LSP/monitor commands. Plugins are copied to a cache on install and the root path **changes on every update**, so hard-coded paths break.
- **Persist state in `${CLAUDE_PLUGIN_DATA}`, never `${CLAUDE_PLUGIN_ROOT}`** — the data dir survives updates; the root does not. (Great for `node_modules`/venvs installed once and reused.)
- **Renaming a plugin breaks installs.** `name` is the stable key used in `enabledPlugins` and installs. To change only the label use `displayName`; to truly rename/remove, add a top-level `renames` map in `marketplace.json` (`{ "old-name": "new-name", "removed-name": null }`) so existing users migrate instead of hitting `plugin-not-found`.
- **Private repos + background auto-updates:** manual updates use your git credential helpers, but background auto-updates run without them — set a token in the environment (`GITHUB_TOKEN`/`GH_TOKEN`, `GITLAB_TOKEN`/`GL_TOKEN`, or `BITBUCKET_TOKEN`).
- **Validate before you push**, especially in CI: `claude plugin validate ./plugins/code-formatter --strict` (treats unknown-field warnings as errors; also rejects rename cycles).

---

## TL;DR

- **Auto-adoption:** host a `marketplace.json`, then in the repo's `.claude/settings.json` set `extraKnownMarketplaces` (registers the marketplace on trust) + `enabledPlugins` (installs/enables the plugins). Teammates get everything just by opening and trusting the repo.
- **Versioning for a fast-moving team:** **omit `version`** so every commit/push is automatically a new version — no manual bumps to forget. Teammates pull changes with `/plugin marketplace update`; `/reload-plugins` applies most changes without a restart.
- Move to explicit semver only when you want deliberate release cycles (and remember: no bump = no update).

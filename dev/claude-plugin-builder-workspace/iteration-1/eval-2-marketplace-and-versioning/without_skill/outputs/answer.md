# Auto-installing team plugins from a repo marketplace, and how versioning/updates work

You want two things:

1. **When a teammate opens the repo, Claude Code automatically has your plugins available** (no manual install steps).
2. **A clear story for versioning and updates**, given you push changes often.

Both are solved by combining a **plugin marketplace** with **project-level (repo-committed) configuration**. Here is the full setup.

---

## 1. The core idea

Claude Code has three building blocks:

- **Plugin** — a bundle of slash commands, agents, hooks, MCP servers, and/or skills, described by a `plugin.json` manifest.
- **Marketplace** — a catalog file (`marketplace.json`, sometimes referred to via `.claude-plugin/marketplace.json`) that lists one or more plugins and where to find them.
- **Repo-level settings** (`.claude/settings.json` committed to the repo) — this is what lets you *auto-enable* a marketplace and its plugins for anyone who opens the project, without each person running install commands.

The "team automatically gets the plugins" behavior comes from committing the marketplace reference **and** the enabled-plugins list into the repository's `.claude/settings.json`. When a teammate opens the repo, Claude Code reads that file, trusts the configured marketplace, and makes the listed plugins available.

---

## 2. Directory layout

You can host the marketplace and plugins in a **dedicated plugins repo** (recommended when many projects share them) or **inside the project repo itself** (simplest for a single team/project). Both work; the difference is only the `source` you point at.

### Option A — plugins live in the same repo (simplest)

```
your-project/
├── .claude/
│   └── settings.json              # commits the marketplace + enabled plugins
├── .claude-plugin/
│   └── marketplace.json           # the catalog
├── plugins/
│   ├── team-workflow/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json         # plugin manifest
│   │   ├── commands/
│   │   │   └── deploy.md
│   │   ├── agents/
│   │   ├── hooks/
│   │   │   └── hooks.json
│   │   └── skills/
│   └── code-standards/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
└── src/ ...
```

### Option B — dedicated marketplace repo (best for sharing across many projects)

```
company-claude-plugins/            # a separate git repo
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    ├── team-workflow/
    │   └── .claude-plugin/plugin.json
    └── code-standards/
        └── .claude-plugin/plugin.json
```

Then each consuming project just points its `.claude/settings.json` at that repo.

---

## 3. The marketplace catalog (`marketplace.json`)

This lists the plugins and their sources.

```json
{
  "name": "company-plugins",
  "owner": {
    "name": "Open Elements",
    "email": "team@open-elements.com"
  },
  "metadata": {
    "description": "Shared Claude Code plugins for our team",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "team-workflow",
      "source": "./plugins/team-workflow",
      "description": "Deploy, release, and PR helper commands",
      "version": "1.4.0"
    },
    {
      "name": "code-standards",
      "source": "./plugins/code-standards",
      "description": "Our Java/TS conventions as skills",
      "version": "2.0.1"
    }
  ]
}
```

Notes:
- `source` can be a **relative path** (`"./plugins/team-workflow"`) when the plugin lives in the same repo as the marketplace, or a **git reference** for plugins hosted elsewhere (see versioning section below).
- The `name` of each plugin must match the `name` in that plugin's `plugin.json`.

---

## 4. The plugin manifest (`plugin.json`)

Each plugin folder has `.claude-plugin/plugin.json`:

```json
{
  "name": "team-workflow",
  "version": "1.4.0",
  "description": "Deploy, release, and PR helper commands",
  "author": {
    "name": "Open Elements"
  }
}
```

Everything else (commands, agents, hooks, skills) is discovered by convention from the standard subfolders (`commands/`, `agents/`, `hooks/`, `skills/`). You only need to declare paths explicitly if you deviate from the defaults.

---

## 5. The part that makes it automatic: repo-committed `.claude/settings.json`

This is the key to "teammates get it just by opening the repo." Commit this file at `your-project/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "company-plugins": {
      "source": {
        "source": "github",
        "repo": "OpenElementsLabs/company-claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "team-workflow@company-plugins": true,
    "code-standards@company-plugins": true
  }
}
```

What each field does:

- **`extraKnownMarketplaces`** — registers the marketplace so Claude Code knows where the catalog lives. Because it is in the repo's `.claude/settings.json`, it applies to everyone who opens the project. The `source` can be a `github` repo, a generic `git` URL, or a local relative path.
- **`enabledPlugins`** — turns specific plugins **on** for this project. The key format is `<plugin-name>@<marketplace-name>`. This is what removes the manual "install the plugin" step.

If the marketplace lives **inside the same repo** (Option A), use a local source instead:

```json
{
  "extraKnownMarketplaces": {
    "company-plugins": {
      "source": {
        "source": "local",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "team-workflow@company-plugins": true,
    "code-standards@company-plugins": true
  }
}
```

### Trust prompt
The first time a teammate opens the repo, Claude Code will ask them to **trust** the project (and the plugins/marketplace it configures), since plugins can run hooks and MCP servers. This is a one-time confirmation per user, not a per-plugin manual install. It is a security feature — do not try to bypass it.

---

## 6. How versioning works

Versioning happens at two levels, and it matters which "source" style you use.

### a) Semantic version fields
Both `plugin.json` and each entry in `marketplace.json` carry a `version` (use semver: `MAJOR.MINOR.PATCH`). These are primarily **informational / for display and dependency reasoning** — they help humans and tooling know what's current. The version string by itself does **not** pin what code a teammate receives; what they receive is determined by the **source**.

### b) What actually pins the code: the git source

- **Relative/local path source** (`"./plugins/..."` or `"local"`): teammates get whatever is on the branch/commit they have checked out. Since the plugin is *in the same repo*, a `git pull` updates the plugin along with the code. This is the tightest coupling and the simplest mental model — **the plugin version is the repo version.**

- **`github` / `git` source in a separate repo**: by default this tracks the default branch (`main`). You can pin it explicitly:

```json
{
  "extraKnownMarketplaces": {
    "company-plugins": {
      "source": {
        "source": "github",
        "repo": "OpenElementsLabs/company-claude-plugins",
        "ref": "v1.4.0"
      }
    }
  }
}
```

`ref` can be a **branch**, **tag**, or **commit SHA**:
- Point at `main` (or omit `ref`) → teammates always get the latest pushed version.
- Point at a **tag** like `v1.4.0` → teammates are pinned to a known-good release, and only move when you bump the `ref`.

---

## 7. How updates work — and the recommendation for "we push often"

### The mechanics of updating

- **Marketplace refresh**: Claude Code caches the marketplace catalog. New/changed plugins are picked up when the marketplace is refreshed — via `/plugin` (the interactive plugin manager) using its update/refresh action, or by restarting Claude Code. There is a marketplace update command in the `/plugin` menu that re-pulls the catalog and any git-sourced plugins.
- **Same-repo plugins (Option A)**: updates arrive with a normal `git pull`. When someone pulls new commits, the plugin content updates automatically because it is just files in the repo. This is the lowest-friction path.
- **Separate marketplace repo tracking a branch**: a refresh pulls the latest commit of that branch.
- **Separate marketplace repo pinned to a tag/SHA**: teammates only move when you change the `ref` in the committed `.claude/settings.json` (and they pull that change).

### Recommendation given frequent pushes

Because you push changes often, pick based on how much stability you want:

- **Fastest iteration (recommended for a single active project):** Use **Option A** — plugins in the same repo, `local` source. Every `git pull` updates commands/skills/hooks along with code. No tag management, no separate refresh step for the content itself. Just bump the `version` fields when you make a notable change so humans can track it.

- **Shared across many repos, want everyone on latest:** Separate marketplace repo, `source: github` **without** a `ref` (tracks `main`). Push to the plugins repo; teammates get updates on the next marketplace refresh/restart. Simple, but a bad push affects everyone immediately.

- **Shared across many repos, want stability/controlled rollout:** Separate marketplace repo pinned by **tag** (`"ref": "v1.4.0"`). Your frequent pushes land on `main` safely; you cut a tag when a release is ready, bump the `ref` in each project's committed `.claude/settings.json`, and teammates adopt it when they pull. This gives you review/rollback and prevents an in-progress change from breaking everyone.

For a team that pushes often but wants to avoid breaking colleagues mid-day, the **tag-pinned separate repo** is usually the sweet spot; for a single project where the plugin *is* part of the project, **same-repo/local** is simplest.

---

## 8. Bumping a version — the routine

1. Make your changes in the plugin folder (`commands/`, `skills/`, etc.).
2. Bump `version` in that plugin's `.claude-plugin/plugin.json` (semver: patch for fixes, minor for new commands/skills, major for breaking changes to command names or behavior).
3. Bump the matching `version` in `marketplace.json` (and optionally the marketplace `metadata.version`).
4. Commit and push.
5. If you pin by tag: create/move the tag (e.g. `git tag v1.5.0 && git push --tags`) and update the `"ref"` in the consuming projects' `.claude/settings.json`.
6. Teammates `git pull` (same-repo) or refresh the marketplace via `/plugin` / restart (separate repo).

---

## 9. Verifying the setup

- Run `/plugin` in Claude Code to open the plugin manager — confirm the marketplace is listed and the expected plugins show as enabled.
- Confirm `/help` (or typing `/`) lists the slash commands your plugin provides.
- Ask a teammate to clone fresh and open the repo: they should get the trust prompt once, accept it, and immediately have the plugins available with no manual install.

---

## 10. Quick checklist

- [ ] Each plugin has `.claude-plugin/plugin.json` with `name` + `version`.
- [ ] `marketplace.json` lists every plugin with matching `name`, a `source`, and a `version`.
- [ ] Repo's `.claude/settings.json` sets `extraKnownMarketplaces` (pointing at the marketplace) and `enabledPlugins` (the `<plugin>@<marketplace>` keys). Commit this file.
- [ ] Choose a source strategy: **local/same-repo** for fastest updates, **github tracking `main`** for always-latest shared, **github pinned to a tag** for controlled rollout.
- [ ] Document the one-time trust prompt for teammates.
- [ ] On every change: bump `version` in both `plugin.json` and `marketplace.json`, commit, push, (tag if pinning), and have teammates pull/refresh.

> Note: exact JSON field names for the marketplace source (e.g. `source`/`repo`/`ref`) and the settings keys (`extraKnownMarketplaces`, `enabledPlugins`) should be confirmed against the current Claude Code documentation, as the plugin system is evolving. The overall model — marketplace catalog + committed repo settings to auto-enable + git source (branch vs. tag) to control versioning/updates — is the stable pattern.

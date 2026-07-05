# Turning your `.claude/` commands + agent into a shareable plugin

Good news: your slash commands and code-review agent map almost one-to-one onto a
Claude Code plugin. A plugin is just a self-contained directory with a manifest and
your components at the root. Hosting it on your GitHub org means adding a small
**marketplace** catalog so teammates can install it with two commands.

I've called the plugin `team-toolkit` below — rename it to whatever you like (use
kebab-case, no spaces). Everything is copied straight from your `.claude/` folder,
one level up.

---

## Recommended GitHub repo layout

Put both the plugin and the marketplace catalog in one repo on your org
(e.g. `github.com/your-org/claude-plugins`). The marketplace lives at the repo root;
the plugin is a subfolder it points at.

```
your-org/claude-plugins            <- the GitHub repo
├── .claude-plugin/
│   └── marketplace.json           <- the catalog teammates add (repo root)
└── team-toolkit/                  <- the plugin itself
    ├── .claude-plugin/
    │   └── plugin.json            <- ONLY the manifest lives in here
    ├── commands/                  <- your slash commands, one .md per command
    │   ├── review.md
    │   ├── commit.md
    │   └── test.md
    └── agents/                    <- your subagents, one .md per agent
        └── code-reviewer.md
```

The single most common mistake: **only `plugin.json` goes inside `.claude-plugin/`.**
Your `commands/` and `agents/` folders live at the *plugin root* (`team-toolkit/`),
never inside `.claude-plugin/`. This is exactly the layout you already have under
`.claude/` — you're just moving it up a level into a named plugin folder.

> Your commands become **namespaced**: `/review` becomes `/team-toolkit:review`, and
> the agent is mentioned as `@team-toolkit:code-reviewer`. That's the trade for
> sharing — it prevents collisions when several plugins ship a command of the same
> name. This is why I kept the plugin name short.

---

## The manifest — `team-toolkit/.claude-plugin/plugin.json`

`name` is the only required field. I've included the metadata worth having for a
shared plugin. Because I set an explicit `version`, teammates only get updates when
you **bump this field** — pushing commits alone does nothing until you bump it. (If
you'd rather have every commit auto-update while you iterate, delete the `version`
line and the git commit SHA becomes the version instead.)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "team-toolkit",
  "displayName": "Team Toolkit",
  "description": "Shared slash commands and a code-review subagent for our team.",
  "version": "1.0.0",
  "author": {
    "name": "Your Team",
    "email": "dev@your-org.example"
  },
  "homepage": "https://github.com/your-org/claude-plugins",
  "repository": "https://github.com/your-org/claude-plugins",
  "license": "MIT",
  "keywords": ["code-review", "commands", "team", "workflow"]
}
```

You don't need to list `commands` or `agents` paths in the manifest — Claude Code
auto-discovers `commands/` and `agents/` at the plugin root. Only add those fields
if you keep them somewhere non-standard.

---

## The catalog — `.claude-plugin/marketplace.json` (repo root)

This is what teammates "add." It names your marketplace and lists the plugin(s) in
the repo. The relative `source` points at the plugin subfolder.

```json
{
  "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
  "name": "your-org",
  "owner": {
    "name": "Your Org",
    "email": "dev@your-org.example"
  },
  "plugins": [
    {
      "name": "team-toolkit",
      "source": "./team-toolkit",
      "description": "Shared slash commands and a code-review subagent for our team."
    }
  ]
}
```

A relative-path `source` like `./team-toolkit` works because the marketplace is
hosted in a git repo, so the whole repo is cloned. (If you ever distribute a
marketplace as a bare `marketplace.json` URL, switch to a `github` source instead,
since only that one file gets downloaded.)

---

## How your teammates install it

Once the repo is pushed to `github.com/your-org/claude-plugins`, each teammate runs,
inside Claude Code:

```bash
# 1. Register the marketplace (once). Uses the "name" from marketplace.json: "your-org"
/plugin marketplace add your-org/claude-plugins

# 2. Install the plugin
/plugin install team-toolkit@your-org
```

That's it — `/team-toolkit:review`, `/team-toolkit:commit`, `/team-toolkit:test`, and
the `@team-toolkit:code-reviewer` agent are now available in every project.

To get later updates after you bump `version` and push:

```bash
/plugin marketplace update your-org
/plugin update team-toolkit
```

### Optional: make it automatic for the whole team

Add this to your project's `.claude/settings.json` and commit it. Teammates are
prompted to trust the marketplace on first open and get the plugin enabled without
running anything:

```json
{
  "extraKnownMarketplaces": {
    "your-org": { "source": { "source": "github", "repo": "your-org/claude-plugins" } }
  },
  "enabledPlugins": {
    "team-toolkit@your-org": true
  }
}
```

---

## Before you push: test and validate locally

```bash
# Load the plugin directly, no install, to try it out:
claude --plugin-dir ./team-toolkit
#   then run /team-toolkit:review and check the agent in /context (Custom Agents)
#   use /reload-plugins to pick up edits without restarting

# Validate the manifest, command/agent frontmatter, and structure:
claude plugin validate ./team-toolkit
claude plugin validate ./team-toolkit --strict   # use this in CI

# Validate the marketplace catalog too:
claude plugin validate .
```

Once it validates and works via `--plugin-dir`, remove the originals from your
project's `.claude/commands/` and `.claude/agents/` so you don't have duplicates —
a project `.claude/agents/code-reviewer.md` would otherwise override the plugin's.

---

## Notes on what I generated

- I recreated **three example slash commands** (`review`, `commit`, `test`) and the
  `code-reviewer` agent as concrete, working files so you can see the exact format.
  Swap in your real command bodies — the structure (a `commands/*.md` file per
  command, an `agents/*.md` file per agent, each with YAML frontmatter) is what
  matters, and it's identical to your existing `.claude/` files.
- `commands/` is the right home for existing slash commands. For *new* shared
  capabilities, Claude Code now prefers **skills** (`skills/<name>/SKILL.md`) over
  flat commands, since skills can be model-invoked automatically. Worth considering
  as the toolkit grows, but there's no need to convert what you already have.
- Agent frontmatter supports `model`, `effort`, `maxTurns`, `tools`,
  `disallowedTools`, etc. For security, plugin agents may **not** declare `hooks`,
  `mcpServers`, or `permissionMode` — if your `.claude/` agent used any of those,
  drop them during the move.

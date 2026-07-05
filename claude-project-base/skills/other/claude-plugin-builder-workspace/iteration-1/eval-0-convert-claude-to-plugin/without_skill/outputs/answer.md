# Turning your `.claude/` commands and agent into a shareable plugin

Good news: a Claude Code plugin is basically the same files you already have in `.claude/`, just moved into a plugin folder with a small manifest (`plugin.json`) added. Your slash commands stay as `.md` files under `commands/`, and your code-review agent stays as a `.md` file under `agents/`. Nothing about the command/agent file format changes.

To let your teammates install it with one command, you host it as a **marketplace** on your GitHub org. A marketplace is just a git repo containing one `marketplace.json` that lists one or more plugins.

## 1. Directory layout

Here's the layout I recommend. You can keep the plugin and the marketplace manifest in the **same repo** (simplest for a single team plugin):

```
my-plugin/                         # this is your plugin repo (github.com/your-org/my-plugin)
├── .claude-plugin/
│   └── plugin.json                # the plugin manifest (REQUIRED, must be in this exact folder)
├── commands/                      # each .md file = one slash command
│   ├── review.md                  # becomes /review  (or /my-plugin:review)
│   └── test.md                    # becomes /test
├── agents/                        # each .md file = one subagent
│   └── code-reviewer.md           # your code-review agent
├── marketplace.json               # lists this plugin so `/plugin marketplace add` works
└── README.md                      # optional, for humans on GitHub
```

Key rules:

- `plugin.json` **must** live inside a folder literally named `.claude-plugin/` at the plugin root. This is the one file whose location matters.
- `commands/` and `agents/` sit at the plugin root (NOT inside `.claude-plugin/`). Claude Code auto-discovers them by convention, so you don't have to list individual files in `plugin.json`.
- File names drive the invocation names: `commands/review.md` → `/review`. If two plugins define the same command name, users disambiguate with `/my-plugin:review`.
- The `marketplace.json` `name` field is the **marketplace** name your team types once when adding the source; the plugin `name` is what they install.

> Note on splitting: for many plugins you'd put `marketplace.json` in a separate dedicated "marketplace" repo and point each plugin `source` at its own repo. For a single team plugin, keeping both in one repo (as above) is perfectly fine and less to maintain.

## 2. The `plugin.json`

Path: `my-plugin/.claude-plugin/plugin.json`

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Shared slash commands and a code-review agent for our team.",
  "author": {
    "name": "Your Team",
    "email": "team@your-org.example",
    "url": "https://github.com/your-org"
  },
  "homepage": "https://github.com/your-org/my-plugin",
  "repository": "https://github.com/your-org/my-plugin",
  "license": "MIT",
  "keywords": ["code-review", "commands", "team"]
}
```

Only `name` is strictly required, but `version` and `description` are strongly recommended so teammates see what they're installing and you can bump versions. Because your commands and agents follow the default `commands/` and `agents/` layout, you do **not** need to declare them in `plugin.json` — they're picked up automatically. (If you ever want custom paths, there are optional `commands` / `agents` fields, but you don't need them here.)

## 3. The command and agent files

These are just your existing files, moved. Example of what they look like:

`commands/review.md`
```markdown
---
description: Review the current changes for bugs, style, and clarity.
argument-hint: [optional path or scope]
---

Review the current git diff (or the path in `$ARGUMENTS` if provided).
...
```

`agents/code-reviewer.md`
```markdown
---
name: code-reviewer
description: Expert code review agent. Use proactively after writing or changing code.
tools: Read, Grep, Glob, Bash
---

You are a senior code reviewer. When invoked:
1. Run `git diff` to see recent changes.
2. Review for correctness, security, error handling, readability, and test coverage.
...
```

If your originals reference files with paths, use the `${CLAUDE_PLUGIN_ROOT}` variable to point at bundled files so paths resolve no matter where the plugin is installed.

## 4. The `marketplace.json`

Path: `my-plugin/marketplace.json` (at the repo root)

```json
{
  "name": "your-org",
  "owner": {
    "name": "Your Org",
    "url": "https://github.com/your-org"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./my-plugin",
      "description": "Shared slash commands and a code-review agent for our team."
    }
  ]
}
```

If `marketplace.json` lives in the same repo as the plugin, `"source": "./my-plugin"` means "the plugin folder is this same repo." If you instead keep a separate marketplace repo, set `source` to the plugin's own repo, e.g. `"source": "your-org/my-plugin"` (a `github` shorthand) or a full git URL.

## 5. Publish it

```bash
cd my-plugin
git init
git add .
git commit -m "Add my-plugin: shared commands and code-review agent"
git remote add origin https://github.com/your-org/my-plugin.git
git push -u origin main
```

Make sure the repo is accessible to your teammates (private org repo is fine as long as they have access; they'll authenticate via their normal git/GitHub credentials).

## 6. How your teammates install it

From inside Claude Code, each teammate runs two commands:

```
# 1. Add your org's marketplace (only needed once, uses the repo that holds marketplace.json)
/plugin marketplace add your-org/my-plugin

# 2. Install the plugin from that marketplace
/plugin install my-plugin@your-org
```

`your-org/my-plugin` is the GitHub `owner/repo` shorthand; you can also pass a full `https://github.com/...` or SSH URL. After install, they can restart Claude Code (or it prompts to reload), and then:

- `/review` and `/test` show up as slash commands.
- The `code-reviewer` agent is available to Claude and can be invoked automatically or explicitly.

They can also browse and toggle everything interactively by just running `/plugin` and picking from the menu.

### Rolling out updates

When you change a command or the agent, bump `version` in `plugin.json`, commit, and push. Teammates get updates with:

```
/plugin marketplace update your-org
/plugin update my-plugin@your-org
```

### Optional: auto-install for everyone in a repo

If you want the plugin enabled automatically for anyone working in a specific project, commit this to that project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "your-org": {
      "source": { "source": "github", "repo": "your-org/my-plugin" }
    }
  },
  "enabledPlugins": ["my-plugin@your-org"]
}
```

Then teammates just get prompted to trust/enable it when they open the project — no manual `/plugin` commands needed.

---

That's the whole thing: add `.claude-plugin/plugin.json`, keep your commands in `commands/` and your agent in `agents/`, add a `marketplace.json`, push to GitHub, and share the two `/plugin` commands.

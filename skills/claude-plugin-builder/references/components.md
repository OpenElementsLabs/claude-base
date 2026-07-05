# Plugin Components Reference

How each component type is declared and discovered. Every component lives in a default directory at the **plugin root** (never inside `.claude-plugin/`) and is discovered automatically when the plugin is enabled. Custom paths are set in the manifest (see `plugin-manifest.md`).

**Contents**
- [File locations at a glance](#file-locations-at-a-glance)
- [Skills](#skills)
- [Slash commands](#slash-commands)
- [Subagents](#subagents)
- [Hooks](#hooks)
- [MCP servers](#mcp-servers)
- [LSP servers](#lsp-servers)
- [Monitors](#monitors)
- [Themes](#themes)
- [Executables (`bin/`)](#executables-bin)
- [Default settings](#default-settings)

## File locations at a glance

| Component | Default location |
| :--- | :--- |
| Manifest | `.claude-plugin/plugin.json` |
| Skills | `skills/<name>/SKILL.md` |
| Commands | `commands/*.md` |
| Agents | `agents/*.md` |
| Output styles | `output-styles/` |
| Themes | `themes/*.json` |
| Hooks | `hooks/hooks.json` |
| MCP servers | `.mcp.json` |
| LSP servers | `.lsp.json` |
| Monitors | `monitors/monitors.json` |
| Executables | `bin/` |
| Default settings | `settings.json` |

A plugin-root `CLAUDE.md` is **not** loaded as context — ship instructions as a skill.

## Skills

Model-invoked capabilities that also create `/plugin-name:skill-name` shortcuts. Each is a directory with a `SKILL.md` plus optional supporting files:

```
skills/
├── code-reviewer/
│   └── SKILL.md
└── pdf-processor/
    ├── SKILL.md
    ├── reference.md      (optional)
    └── scripts/          (optional)
```

`SKILL.md` is YAML frontmatter + Markdown instructions. Include a `description` so Claude knows when to invoke it:

```yaml
---
description: Reviews code for best practices and potential issues. Use when reviewing code, checking PRs, or analyzing code quality.
---

When reviewing code, check for:
1. Code organization and structure
2. Error handling
3. Security concerns
4. Test coverage
```

`$ARGUMENTS` in the body captures text the user types after the skill name. Add `disable-model-invocation: true` in frontmatter to make a skill user-only (not auto-invoked). Run `/reload-plugins` after adding skills. For full skill-authoring guidance (progressive disclosure, tool restrictions, description tuning), use the **skill-creator** skill.

## Slash commands

Legacy flat-file commands: simple Markdown files in `commands/`, one command per file. Prefer the `skills/` layout for new plugins — commands exist for backward compatibility. Both are discovered automatically and shown under the plugin namespace.

## Subagents

Specialized agents Claude can delegate to. Markdown files in `agents/`:

```markdown
---
name: agent-name
description: What this agent specializes in and when Claude should invoke it
model: sonnet
effort: medium
maxTurns: 20
disallowedTools: Write, Edit
---

Detailed system prompt describing the agent's role, expertise, and behavior.
```

Supported frontmatter: `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation` (only valid value: `"worktree"`). **Not supported for plugin agents** (for security): `hooks`, `mcpServers`, `permissionMode`.

Agents appear in the `@`-mention typeahead as `my-plugin:agent-name`, can be invoked automatically or manually, and work alongside built-in agents. Note: project/user `.claude/agents/` definitions override same-named plugin agents.

## Hooks

Event handlers that respond to Claude Code lifecycle events. Config in `hooks/hooks.json` (or inline in `plugin.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook types**: `command` (run a shell command/script), `http` (POST the event JSON to a URL), `mcp_tool` (call a tool on a configured MCP server), `prompt` (evaluate a prompt with an LLM, using `$ARGUMENTS` for context), `agent` (run an agentic verifier with tools).

**Lifecycle events** (same set as user-defined hooks):

| Event | When it fires |
| :--- | :--- |
| `SessionStart` | A session begins or resumes |
| `Setup` | `--init-only`, or `--init`/`--maintenance` in `-p` mode — one-time CI/script prep |
| `UserPromptSubmit` | A prompt is submitted, before processing |
| `UserPromptExpansion` | A typed command expands into a prompt, before it reaches Claude. Can block |
| `PreToolUse` | Before a tool call. Can block |
| `PermissionRequest` | A permission dialog appears |
| `PermissionDenied` | A call is denied by the auto-mode classifier. Return `{retry: true}` to allow a retry |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `PostToolBatch` | After a batch of parallel tool calls resolves, before the next model call |
| `Notification` | Claude Code sends a notification |
| `MessageDisplay` | While assistant message text is displayed |
| `SubagentStart` / `SubagentStop` | A subagent is spawned / finishes |
| `TaskCreated` / `TaskCompleted` | A task is created / marked completed |
| `Stop` | Claude finishes responding |
| `StopFailure` | The turn ends due to an API error (output/exit code ignored) |
| `TeammateIdle` | An agent-team teammate is about to go idle |
| `InstructionsLoaded` | A CLAUDE.md or `.claude/rules/*.md` file loads into context |
| `ConfigChange` | A configuration file changes during a session |
| `CwdChanged` | The working directory changes (e.g. a `cd`) |
| `FileChanged` | A watched file changes; `matcher` specifies filenames to watch |
| `WorktreeCreate` / `WorktreeRemove` | A worktree is created / removed (replaces default git behavior) |
| `PreCompact` / `PostCompact` | Before / after context compaction |
| `Elicitation` / `ElicitationResult` | An MCP server requests user input / a user responds |
| `SessionEnd` | A session terminates |

Event names are **case-sensitive** (`PostToolUse`, not `postToolUse`). Command scripts must be executable (`chmod +x`). Copying hooks from `.claude/settings.json` works verbatim — the `hooks` object format is identical.

## MCP servers

Bundle Model Context Protocol servers to connect external tools. Config in `.mcp.json` (or inline in `plugin.json`); standard MCP server format:

```json
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data" }
    },
    "plugin-api-client": {
      "command": "npx",
      "args": ["@company/mcp-server", "--plugin-mode"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

Plugin MCP servers start automatically when the plugin is enabled and appear as standard MCP tools. Always reference bundled paths with `${CLAUDE_PLUGIN_ROOT}`.

## LSP servers

Give Claude real-time code intelligence (diagnostics, go-to-definition, hover). Config in `.lsp.json` (or `lspServers` inline in `plugin.json`):

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

Required: `command` (binary, must be in `PATH`), `extensionToLanguage`. Optional: `args`, `transport` (`stdio` default | `socket`), `env`, `initializationOptions`, `settings`, `workspaceFolder`, `startupTimeout`, `maxRestarts`, `diagnostics` (default `true`; set `false` to keep navigation but suppress auto-injected diagnostics).

The plugin configures the connection but **does not include the language-server binary** — users must install it themselves. For common languages, prefer the official LSP plugins (`pyright-lsp`, `typescript-lsp`, `rust-analyzer-lsp`) from the marketplace; build custom LSP plugins only for uncovered languages.

## Monitors

Background watchers that run a shell command for the session's lifetime and deliver each stdout line to Claude as a notification — for reacting to logs, status changes, or polled events without being asked to start the watch. Config in `monitors/monitors.json` (array), or inline via `experimental.monitors`:

```json
[
  {
    "name": "deploy-status",
    "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/poll-deploy.sh ${user_config.api_endpoint}",
    "description": "Deployment status changes"
  },
  {
    "name": "error-log",
    "command": "tail -F ./logs/error.log",
    "description": "Application error log",
    "when": "on-skill-invoke:debug"
  }
]
```

Required: `name` (unique within the plugin), `command`, `description`. Optional: `when` — `"always"` (default; starts at session start and on reload) or `"on-skill-invoke:<skill-name>"` (starts the first time that skill is dispatched). Supports the same variable substitutions as MCP/LSP. Monitors run only in interactive CLI sessions, unsandboxed at the same trust level as hooks, and require v2.1.105+. Disabling a plugin mid-session does not stop already-running monitors; they stop at session end.

## Themes

Color themes that appear in `/theme`. A JSON file in `themes/` with a `base` preset and a sparse `overrides` map (experimental component):

```json
{
  "name": "Dracula",
  "base": "dark",
  "overrides": { "claude": "#bd93f9", "error": "#ff5555", "success": "#50fa7b" }
}
```

Plugin themes are read-only; `Ctrl+E` in `/theme` copies one into `~/.claude/themes/` for editing. Selecting one persists `custom:<plugin-name>:<slug>`.

## Executables (`bin/`)

Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled, so they are invokable as bare commands in any Bash call.

## Default settings

A `settings.json` at the plugin root applies default configuration when the plugin is enabled. Only `agent` and `subagentStatusLine` keys are currently supported; unknown keys are silently ignored.

```json
{ "agent": "security-reviewer" }
```

Setting `agent` activates one of the plugin's own agents as the main thread (its system prompt, tool restrictions, and model), letting a plugin change default behavior when enabled. `settings.json` takes priority over a `settings` block declared in `plugin.json`.

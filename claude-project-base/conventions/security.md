# Security Configuration for Claude Code

This document defines security rules and configurations for using Claude Code in Open Elements projects. The goal is to ensure Claude Code operates safely within the project boundary and never accesses or modifies sensitive data without explicit developer consent.

## Core Principles

- **Project boundary is sacred** — Claude Code must never modify files outside the project directory without explicit user confirmation.
- **No silent reads outside the project** — Files outside the project directory must not be read unless the developer explicitly asks for it or grants access.
- **Deny by default for sensitive paths** — Access to credentials, keys, and personal configuration is blocked by deny rules.
- **Layered defense** — Combine permission rules, sandbox mode, and hooks for defense in depth.

## Permission Configuration

Add these rules to `.claude/settings.json` (shared, committed to the repository) or `.claude/settings.local.json` (personal, gitignored).

### Recommended Deny Rules

Block access to credentials and sensitive configuration. These rules apply to all developers on the project:

```json
{
  "permissions": {
    "deny": [
      "Read(~/.ssh/**)",
      "Read(~/.gnupg/**)",
      "Read(~/.aws/**)",
      "Read(~/.azure/**)",
      "Read(~/.kube/**)",
      "Read(~/.docker/config.json)",
      "Read(~/.npmrc)",
      "Read(~/.pypirc)",
      "Read(~/.gem/credentials)",
      "Read(~/.git-credentials)",
      "Read(~/.config/gh/**)",
      "Read(~/.bashrc)",
      "Read(~/.zshrc)",
      "Read(~/.bash_profile)",
      "Read(~/.zprofile)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Edit(~/.ssh/**)",
      "Edit(~/.gnupg/**)",
      "Edit(~/.aws/**)",
      "Edit(~/.azure/**)",
      "Edit(~/.kube/**)",
      "Edit(~/.docker/config.json)",
      "Edit(~/.npmrc)",
      "Edit(~/.bashrc)",
      "Edit(~/.zshrc)",
      "Edit(~/.bash_profile)",
      "Edit(~/.zprofile)",
      "Edit(./.env)",
      "Edit(./.env.*)",
      "Bash(rm -rf *)"
    ]
  }
}
```

What this blocks:
- **SSH/GPG keys** — `~/.ssh`, `~/.gnupg`
- **Cloud credentials** — `~/.aws`, `~/.azure`, `~/.kube`, `~/.docker/config.json`
- **Package registry tokens** — `~/.npmrc`, `~/.pypirc`, `~/.gem/credentials`
- **Git credentials** — `~/.git-credentials`, `~/.config/gh`
- **Shell configuration** — Prevents backdoor injection into `.bashrc`, `.zshrc`, etc.
- **Environment files** — `.env` and `.env.*` which may contain secrets
- **Destructive commands** — `rm -rf` requires manual alternatives

### What is NOT blocked

- Reading project files within the working directory — this is normal operation
- Reading files the developer explicitly asks Claude to look at (e.g., "read my ~/.gitconfig")
- Git operations within the project

## Sandbox Mode

For additional OS-level isolation, enable sandbox mode. This restricts file system access and network at the operating system level, not just at the tool level.

Add to `.claude/settings.json`:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "denyRead": [
        "~/.aws/credentials",
        "~/.ssh/**"
      ],
      "denyWrite": [
        "//etc",
        "//usr/local/bin"
      ]
    }
  }
}
```

Sandbox uses Seatbelt on macOS and bubblewrap on Linux for enforcement at the OS level. This catches cases where Bash commands might bypass tool-level permission rules.

## Hooks for Safety

Hooks can block dangerous operations before they execute and log actions for audit trails.

### Block destructive git operations

Prevent accidental force-pushes to main:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$TOOL_INPUT\" | grep -qE 'git\\s+push.*--force|git\\s+push.*-f|git\\s+reset\\s+--hard'; then echo 'Blocked: destructive git operation. Use the Git CLI directly if intended.' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
```

### Activity logging

Log every tool call Claude Code makes to `claude.log` in the project root. This provides a full audit trail of all actions during a session:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo \"$(date -u '+%Y-%m-%dT%H:%M:%SZ') [$TOOL_NAME] $TOOL_INPUT\" >> claude.log"
          }
        ]
      }
    ]
  }
}
```

This logs all tool calls (Bash, Read, Edit, Write, Glob, Grep, etc.) with timestamp and input. The log is temporary and must be added to `.gitignore`.

## Setup Checklist

When adding `claude-project-base` to a new project:

- [ ] Copy the deny rules into `.claude/settings.json`
- [ ] Add `.claude/settings.local.json` and `claude.log` to `.gitignore`
- [ ] Consider enabling sandbox mode for stricter isolation
- [ ] Review whether additional project-specific paths need to be denied (e.g., `./secrets/`, `./certs/`)

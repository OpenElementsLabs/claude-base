# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.12.0] - 2026-07-05

### Removed

- **Hiero/Hedera content** moved to its own plugin,
  [`agentic-support-hiero`](https://github.com/OpenElementsLabs/agentic-support-hiero).
  This removes the `hedera-info`, `hiero-info`, and `hiero-solo` skills and the
  `hedera-docs` MCP server from `.mcp.json`. Projects that need Hiero/Hedera support
  should install that plugin alongside `claude-base`:

  ```
  /plugin marketplace add OpenElementsLabs/agentic-support-hiero
  /plugin install agentic-support-hiero@open-elements-hiero
  ```

## [0.11.0] - 2026-07-05

### Changed

- **Distribution model:** `claude-base` is now a Claude Code **plugin** distributed
  through a marketplace instead of a `setup.sh` file-copy script. Install with
  `/plugin marketplace add OpenElementsLabs/claude-base` and
  `/plugin install claude-base@open-elements`.
- **Repository layout:** the `claude-project-base/` wrapper directory was removed.
  Skills now live flat under `skills/`, convention documents under `conventions/`,
  and the shared MCP configuration in `.mcp.json` at the repository root (which is
  also the plugin root).
- Skills reference convention documents via `${CLAUDE_PLUGIN_ROOT}/conventions/…`
  instead of the previous `../../../conventions/` relative paths.
- All skills are now namespaced under the plugin (e.g. `/claude-base:spec-create`).
- `setup.sh` no longer copies files; it prints the plugin installation instructions.

### Removed

- The base `CLAUDE.md` merge, `.gitignore` augmentation, and `settings.local.json`
  provisioning that the old `setup.sh` performed. These are not expressible in the
  plugin model. The former base template is preserved under `dev/legacy/` for
  reference.

### Added

- `.claude-plugin/plugin.json` — plugin manifest.
- `.claude-plugin/marketplace.json` — marketplace catalog (this repo is its own marketplace).
- `CHANGELOG.md`.

### Maintained

- `update-skills.sh` (vendoring upstream skills into this repo) is unchanged; it is
  a maintainer tool and unrelated to distribution.

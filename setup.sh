#!/usr/bin/env bash
set -euo pipefail

# Open Elements Claude Base — Setup Notice
#
# claude-base is now distributed as a Claude Code PLUGIN via a marketplace,
# not by copying files into a project's .claude/ directory. This script no
# longer copies anything; it only points you to the new installation flow.
#
# (Kept so existing `curl ... | bash` bookmarks fail soft and guide users.)

cat <<'EOF'

  Open Elements Claude Base is now a Claude Code plugin.

  Install it from inside Claude Code:

    /plugin marketplace add OpenElementsLabs/claude-base
    /plugin install claude-base@open-elements

  Then restart Claude Code (or run /reload-plugins). All skills are namespaced,
  e.g. /claude-base:spec-create, /claude-base:quality-review.

  Update to a newer release later with:

    /plugin marketplace update open-elements

  Details: https://github.com/OpenElementsLabs/claude-base#readme

EOF

#!/usr/bin/env bash
set -euo pipefail

# Open Elements Claude Base — Setup Script
# Copies claude-project-base into the current project's .claude/ directory
# and merges CLAUDE.md using Claude Code.
#
# Usage (run from your project root):
#   curl -sSL https://raw.githubusercontent.com/OpenElementsLabs/claude-base/main/setup.sh | bash

REPO_URL="https://github.com/OpenElementsLabs/claude-base.git"
BRANCH="main"
TMPDIR_BASE="${TMPDIR:-/tmp}"
WORK_DIR="$TMPDIR_BASE/claude-base-setup-$$"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "==> Cloning claude-base into temporary directory..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$WORK_DIR" 2>/dev/null

SRC="$WORK_DIR/claude-project-base"

# --- Sync conventions, skills, hooks into .claude/ ---
# Base items are overwritten to stay up to date.
# Exception: conventions/project-specific/ is never overwritten (project-owned content).
echo "==> Syncing conventions, skills, and hooks into .claude/..."
for dir in conventions skills hooks; do
  src_dir="$SRC/$dir"
  dest_dir=".claude/$dir"
  [ -d "$src_dir" ] || continue
  mkdir -p "$dest_dir"

  for item in "$src_dir"/*; do
    name="$(basename "$item")"
    dest="$dest_dir/$name"

    # Never overwrite project-specific conventions
    if [ "$dir" = "conventions" ] && [ "$name" = "project-specific" ]; then
      if [ -e "$dest" ]; then
        echo "    KEPT: .claude/$dir/$name (project-specific, not overwritten)"
      else
        cp -R "$item" "$dest"
        echo "    Copied $dir/$name"
      fi
      continue
    fi

    if [ -e "$dest" ]; then
      rm -rf "$dest"
      echo "    Updated $dir/$name"
    else
      echo "    Copied $dir/$name"
    fi
    cp -R "$item" "$dest"
  done
done

# --- Copy settings.local.json into .claude/ ---
if [ -f "$SRC/settings.local.json" ]; then
  if [ -f .claude/settings.local.json ]; then
    echo "    .claude/settings.local.json already exists — skipping (will not overwrite)"
  else
    cp "$SRC/settings.local.json" .claude/
    echo "    Copied settings.local.json into .claude/"
  fi
fi

# --- Copy .mcp.json into project root ---
if [ -f "$SRC/.mcp.json" ]; then
  if [ -f .mcp.json ]; then
    echo "    .mcp.json already exists — skipping (will not overwrite)"
  else
    cp "$SRC/.mcp.json" .mcp.json
    echo "    Copied .mcp.json into project root"
  fi
fi

# --- Append gitignore additions ---
if [ -f "$SRC/PROJECT_GITIGNORE_ADDITITIONS" ]; then
  echo "==> Updating .gitignore..."
  touch .gitignore
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$line" ] && ! grep -qxF "$line" .gitignore; then
      echo "$line" >> .gitignore
      echo "    Added '$line' to .gitignore"
    fi
  done < "$SRC/PROJECT_GITIGNORE_ADDITITIONS"
fi

# --- Merge CLAUDE.md using Claude Code ---
if [ -f "$SRC/PROJECT_CLAUDE.md" ]; then
  echo "==> Merging CLAUDE.md..."
  if [ -f CLAUDE.md ]; then
    # Project already has a CLAUDE.md — use Claude to merge
    echo "    Existing CLAUDE.md found — merging with base (this may take a moment)..."
    cp "$SRC/PROJECT_CLAUDE.md" .claude/_base_claude.md
    MERGED="$(claude --print --model sonnet -p "$(cat <<'PROMPT'
Read the files .claude/_base_claude.md and CLAUDE.md.
Merge them into a single Markdown document. Rules:
- Base content (.claude/_base_claude.md) comes first, then project-specific content.
- Do not duplicate rules that appear in both files.
- Keep all project-specific rules, paths, and configurations from CLAUDE.md.
- Keep all base rules from _base_claude.md.
- If rules conflict, the project-specific version wins.
- Output ONLY the merged Markdown content, no explanations or code fences.
PROMPT
)")"
    if [ -n "$MERGED" ]; then
      echo "$MERGED" > CLAUDE.md
      echo "    Merged CLAUDE.md (base + project-specific)"
    else
      echo "    WARNING: Claude returned empty result — keeping existing CLAUDE.md unchanged"
      echo "    You can merge manually: base is at .claude/_base_claude.md"
    fi
    rm -f .claude/_base_claude.md
  else
    # No existing CLAUDE.md — just copy the base
    cp "$SRC/PROJECT_CLAUDE.md" CLAUDE.md
    echo "    Created CLAUDE.md from base template"
  fi
fi

echo ""
echo "==> Done! Claude base configuration has been applied."
echo ""
echo "Next steps:"
echo "  1. Review CLAUDE.md and remove convention references not needed for your project"
echo "  2. Fill in API keys in .claude/settings.local.json"
echo "  3. Review .mcp.json and remove MCP servers you don't need"
echo "  4. Run 'claude' to start using the configuration"

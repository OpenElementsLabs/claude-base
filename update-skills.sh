#!/usr/bin/env bash
#
# update-skills.sh — Update vendored skills from their upstream repositories.
#
# Skills that originate from an external repository declare their provenance in
# the `metadata` block of their SKILL.md frontmatter:
#
#   metadata:
#     source: https://github.com/anthropics/skills   # upstream repository
#     author: Anthropic
#     modifications: None                             # human-readable note
#     update: overwrite                               # update policy (see below)
#     upstream_path: skills/pdf                        # optional; path within the repo
#
# Update policies (the `update:` field):
#   overwrite  Replace the whole skill folder with the upstream version, keeping
#              only the local `metadata:` frontmatter block. Use for skills that
#              are NOT locally modified (modifications: None).
#   subfiles   Sync every upstream file EXCEPT SKILL.md into the local folder
#              (non-destructive: local-only files are kept). SKILL.md is left
#              untouched. Use for skills whose adaptations live in SKILL.md.
#   manual     Never write. Only show a diff between upstream and the local
#              SKILL.md so a human can reconcile. Use for heavily adapted skills
#              or skills derived from a single upstream document.
#
# If `update:` is absent, the skill is treated as `manual` (safest default).
# If `upstream_path:` is absent, it defaults to `skills/<skill-name>`.
#
# Skills whose source is this repository (open-elements/claude-base) are original
# content and are skipped.
#
# Usage:
#   ./update-skills.sh [options] [skill-name ...]
#
# Options:
#   -n, --dry-run   Show what would change; write nothing.
#   -h, --help      Show this help.
#
# Positional arguments limit the run to the named skills (by their `name:` field).
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIRS=("$REPO_ROOT/claude-project-base/skills" "$REPO_ROOT/.claude/skills")
OWN_REPO_MARKER="open-elements/claude-base"

DRY_RUN=0
FILTER_NAMES=()

# Colors (disabled when not a TTY)
if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; DIM=""; RESET=""
fi

# Counters
count_overwrite=0; count_subfiles=0; count_manual=0; count_skipped=0; count_error=0

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
usage() { sed -n '2,45p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) FILTER_NAMES+=("$1"); shift ;;
  esac
done

# ---------------------------------------------------------------------------
# Frontmatter helpers
# ---------------------------------------------------------------------------

# fm_get <file> <key> — print the value of <key> from the first frontmatter
# block (matches top-level or indented keys). Empty if not present.
fm_get() {
  awk -v key="$2" '
    d<2 && /^---[[:space:]]*$/ { d++; next }
    d==1 {
      line=$0; sub(/\r$/,"",line); sub(/^[[:space:]]+/,"",line)
      if (line ~ "^" key ":") {
        sub("^" key ":[[:space:]]*","",line); sub(/[[:space:]]+$/,"",line)
        print line; exit
      }
    }
  ' "$1"
}

# extract_metadata <file> — print the `metadata:` block (the metadata: line and
# its indented children) from the first frontmatter block.
extract_metadata() {
  awk '
    d<2 && /^---[[:space:]]*$/ { d++; next }
    d==1 && /^metadata:[[:space:]]*$/ { cap=1; print; next }
    d==1 && cap==1 && /^[[:space:]]/ { print; next }
    d==1 && cap==1 { cap=0 }
  ' "$1"
}

# inject_metadata <upstream_skill_md> <metadata_block_file> — print the upstream
# SKILL.md with any existing metadata: block replaced by the saved block
# (inserted just before the closing frontmatter delimiter).
inject_metadata() {
  awk -v metafile="$2" '
    BEGIN { while ((getline l < metafile) > 0) meta = meta l "\n" }
    d<2 && /^---[[:space:]]*$/ {
      d++
      if (d==2) { printf "%s", meta; print; next }
      print; next
    }
    d==1 && /^metadata:[[:space:]]*$/ { skip=1; next }
    d==1 && skip==1 && /^[[:space:]]/ { next }
    d==1 && skip==1 { skip=0 }
    { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Upstream checkout (one shallow clone per unique repository, cached)
# ---------------------------------------------------------------------------
CLONE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/update-skills.XXXXXX")"
cleanup() { rm -rf "$CLONE_ROOT"; }
trap cleanup EXIT

clone_repo() {
  local url="$1" slug dir
  slug="$(printf '%s' "$url" | sed 's|[^a-zA-Z0-9]|_|g')"
  dir="$CLONE_ROOT/$slug"
  if [ ! -d "$dir" ]; then
    echo "${DIM}  cloning $url ...${RESET}" >&2
    git clone --depth 1 --quiet "$url" "$dir"
  fi
  printf '%s' "$dir"
}

# ---------------------------------------------------------------------------
# Per-skill processing
# ---------------------------------------------------------------------------
process_skill() {
  local skill_md="$1"
  local local_dir name source update upstream_path
  local_dir="$(dirname "$skill_md")"

  name="$(fm_get "$skill_md" name)"
  source="$(fm_get "$skill_md" source)"
  update="$(fm_get "$skill_md" update)"
  upstream_path="$(fm_get "$skill_md" upstream_path)"
  [ -n "$name" ] || name="$(basename "$local_dir")"

  # Apply name filter, if any.
  if [ "${#FILTER_NAMES[@]}" -gt 0 ]; then
    local match=0 f
    for f in "${FILTER_NAMES[@]}"; do [ "$f" = "$name" ] && match=1; done
    [ "$match" -eq 1 ] || return 0
  fi

  # Skip original / non-external skills.
  if [ -z "$source" ] || printf '%s' "$source" | grep -q "$OWN_REPO_MARKER"; then
    count_skipped=$((count_skipped + 1)); return 0
  fi

  [ -n "$update" ] || update="manual"
  [ -n "$upstream_path" ] || upstream_path="skills/$name"

  echo ""
  echo "${BOLD}$name${RESET} ${DIM}($update)${RESET}"
  echo "  source: $source"

  local clone up
  if ! clone="$(clone_repo "$source")"; then
    echo "  ${RED}error: could not clone $source${RESET}"; count_error=$((count_error + 1)); return 0
  fi
  up="$clone/$upstream_path"

  if [ ! -e "$up" ]; then
    echo "  ${RED}error: upstream path not found: $upstream_path${RESET}"
    count_error=$((count_error + 1)); return 0
  fi

  case "$update" in
    overwrite) do_overwrite "$local_dir" "$up" ;;
    subfiles)  do_subfiles "$local_dir" "$up" ;;
    manual)    do_manual "$local_dir" "$up" ;;
    *) echo "  ${RED}error: unknown update policy '$update'${RESET}"; count_error=$((count_error + 1)) ;;
  esac
}

do_overwrite() {
  local local_dir="$1" up="$2"
  if [ ! -f "$up/SKILL.md" ]; then
    echo "  ${RED}error: upstream has no SKILL.md; cannot overwrite${RESET}"; count_error=$((count_error + 1)); return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  ${YELLOW}would overwrite folder from upstream (keeping local metadata block)${RESET}"
    diff -qr "$local_dir" "$up" 2>/dev/null | grep -v 'SKILL.md' || true
    count_overwrite=$((count_overwrite + 1)); return 0
  fi
  local meta_tmp skill_tmp
  meta_tmp="$(mktemp)"; skill_tmp="$(mktemp)"
  extract_metadata "$local_dir/SKILL.md" > "$meta_tmp"
  rm -rf "$local_dir"
  cp -R "$up" "$local_dir"
  if [ -s "$meta_tmp" ]; then
    inject_metadata "$local_dir/SKILL.md" "$meta_tmp" > "$skill_tmp"
    mv "$skill_tmp" "$local_dir/SKILL.md"
  else
    rm -f "$skill_tmp"
  fi
  rm -f "$meta_tmp"
  echo "  ${GREEN}overwritten from upstream (metadata block preserved)${RESET}"
  count_overwrite=$((count_overwrite + 1))
}

do_subfiles() {
  local local_dir="$1" up="$2"
  if [ ! -d "$up" ]; then
    echo "  ${RED}error: upstream path is not a directory; 'subfiles' needs a folder${RESET}"; count_error=$((count_error + 1)); return 0
  fi
  local changed=0 rel
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    if [ ! -f "$local_dir/$rel" ] || ! cmp -s "$up/$rel" "$local_dir/$rel"; then
      changed=$((changed + 1))
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "  ${YELLOW}would sync${RESET} $rel"
      else
        mkdir -p "$local_dir/$(dirname "$rel")"
        cp "$up/$rel" "$local_dir/$rel"
        echo "  ${GREEN}synced${RESET} $rel"
      fi
    fi
  done < <(cd "$up" && find . -type f ! -name SKILL.md -print0)

  [ "$changed" -eq 0 ] && echo "  ${DIM}sub-files already up to date${RESET}"

  # Informational: has the upstream SKILL.md diverged from the (protected) local one?
  if [ -f "$up/SKILL.md" ] && ! cmp -s "$up/SKILL.md" "$local_dir/SKILL.md"; then
    echo "  ${BLUE}note: upstream SKILL.md differs from local (protected — review manually):${RESET}"
    diff -u "$local_dir/SKILL.md" "$up/SKILL.md" | sed 's/^/    /' || true
  fi
  count_subfiles=$((count_subfiles + 1))
}

do_manual() {
  local local_dir="$1" up="$2" up_skill
  if [ -d "$up" ]; then
    up_skill="$up/SKILL.md"
  else
    up_skill="$up"   # upstream is a single file (e.g. a steering document)
  fi
  if [ ! -f "$up_skill" ]; then
    echo "  ${RED}error: upstream document not found${RESET}"; count_error=$((count_error + 1)); return 0
  fi
  if cmp -s "$up_skill" "$local_dir/SKILL.md"; then
    echo "  ${DIM}identical to upstream — nothing to review${RESET}"
  else
    echo "  ${YELLOW}manual policy — diff only (no changes written):${RESET}"
    diff -u "$local_dir/SKILL.md" "$up_skill" | sed 's/^/    /' || true
  fi
  count_manual=$((count_manual + 1))
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "${BOLD}Updating vendored skills${RESET}${DRY_RUN:+}"
[ "$DRY_RUN" -eq 1 ] && echo "${YELLOW}(dry run — no files will be written)${RESET}"

while IFS= read -r skill_md; do
  process_skill "$skill_md"
done < <(
  for d in "${SKILL_DIRS[@]}"; do
    [ -d "$d" ] && find "$d" -name SKILL.md -type f
  done | sort
)

echo ""
echo "${BOLD}Summary${RESET}"
echo "  overwrite : $count_overwrite"
echo "  subfiles  : $count_subfiles"
echo "  manual    : $count_manual  ${DIM}(review diffs above)${RESET}"
echo "  skipped   : $count_skipped  ${DIM}(original / non-external)${RESET}"
[ "$count_error" -gt 0 ] && echo "  ${RED}errors    : $count_error${RESET}"
echo ""
echo "${DIM}Review changes with 'git diff' before committing.${RESET}"
[ "$count_error" -eq 0 ]

#!/bin/bash
# install_mas_agiledev.sh
# code:tool-install-mas-001:create-symlink
#
# Usage:
#   bash /path/to/mas/install_mas_agiledev.sh [TARGET_DIR]
#   (TARGET_DIR defaults to current directory)

set -euo pipefail

MAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# code:tool-install-mas-001:resolve-target
# mkdir -p so cd never fails on a non-existent TARGET_DIR
TARGET_DIR="${1:-$(pwd)}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "MAS: $MAS_DIR"
echo "Target: $TARGET_DIR"

[ "$TARGET_DIR" = "$MAS_DIR" ] && echo "Same dir — nothing to do." && exit 0

# Step 1: .claude/ must be a real dir (not a symlink)
# We cannot symlink the whole .claude/ dir because we need to mix global MAS
# agents with local TARGET-specific skills.
CLAUDE="$TARGET_DIR/.claude"
[ -L "$CLAUDE" ] && rm "$CLAUDE"
mkdir -p "$CLAUDE"

# Step 2: symlink MAS components into .claude/
# rm -f before ln -s: ln -sf on an existing *directory* appends inside
# it instead of replacing it, causing nested symlinks.
rm -f "$CLAUDE/agents" "$CLAUDE/settings.json" "$CLAUDE/log-session.sh"
ln -s "$MAS_DIR/.claude/agents"         "$CLAUDE/agents"
ln -s "$MAS_DIR/.claude/settings.json"  "$CLAUDE/settings.json"
ln -s "$MAS_DIR/.claude/log-session.sh" "$CLAUDE/log-session.sh"
echo "Linked: agents/, settings.json, log-session.sh"

# Step 3: TARGET_DIR/.agents/skills/* → TARGET_DIR/.claude/skills/
# code:tool-install-mas-001:link-skills
# (Skills are local to the target project, NOT global to the MAS dir)
if [ ! -d "$TARGET_DIR/.agents/skills" ]; then
  echo "⚠️  No .agents/skills dir found in target ($TARGET_DIR) — skipping skills step."
else
  mkdir -p "$CLAUDE/skills"

  # === 3A. MAS Global Skills ===
  # Link global skills (like spawn-team) from MAS_DIR/.claude/skills/
  if [ -d "$MAS_DIR/.claude/skills" ]; then
    for SRC in "$MAS_DIR/.claude/skills"/*/; do
      # If no subdirs exist, glob might return the raw string with *; guard against it
      [ -e "$SRC" ] || continue
      SRC="${SRC%/}"
      NAME="$(basename "$SRC")"
      rm -rf "$CLAUDE/skills/$NAME"
      ln -s "$SRC" "$CLAUDE/skills/$NAME"
      echo "  global skill: $NAME"
    done
  fi

  # === 3B. Target Local Skills ===
  # Link target-specific skills from TARGET_DIR/.agents/skills/
  # Glob-based loop (never word-splits on spaces/special chars)
  for SRC in "$TARGET_DIR/.agents/skills"/*/; do
    [ -e "$SRC" ] || continue
    SRC="${SRC%/}"
    NAME="$(basename "$SRC")"

    # Prefer create symlink: if target already exists, delete it first
    rm -rf "$CLAUDE/skills/$NAME"

    if [ -L "$SRC" ]; then
      # Validate readlink — skip dangling symlinks
      LINK_TARGET="$(readlink "$SRC")"
      if [ -z "$LINK_TARGET" ]; then
        echo "  ⚠️  skip dangling symlink: $NAME"
        continue
      fi
      ln -s "$LINK_TARGET" "$CLAUDE/skills/$NAME"   # copy symlink as-is
    else
      ln -s "$SRC" "$CLAUDE/skills/$NAME"            # real dir → symlink
    fi
    echo "  skill: $NAME"
  done
fi

echo "Done."
ls -la "$CLAUDE/"

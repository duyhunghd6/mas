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
# Bug fix: mkdir -p so cd never fails on a non-existent TARGET_DIR
TARGET_DIR="${1:-$(pwd)}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "MAS: $MAS_DIR"
echo "Target: $TARGET_DIR"

[ "$TARGET_DIR" = "$MAS_DIR" ] && echo "Same dir — nothing to do." && exit 0

# Step 1: .claude/ must be a real dir (not a symlink)
CLAUDE="$TARGET_DIR/.claude"
[ -L "$CLAUDE" ] && rm "$CLAUDE"
mkdir -p "$CLAUDE"

# Step 2: symlink MAS components into .claude/
# Use rm -f first: ln -sf on an existing *directory* appends inside it
# instead of replacing it (causing e.g. .claude/agents/agents).
rm -f "$CLAUDE/agents" "$CLAUDE/settings.json" "$CLAUDE/log-session.sh"
ln -s "$MAS_DIR/.claude/agents"         "$CLAUDE/agents"
ln -s "$MAS_DIR/.claude/settings.json"  "$CLAUDE/settings.json"
ln -s "$MAS_DIR/.claude/log-session.sh" "$CLAUDE/log-session.sh"
echo "Linked: agents/, settings.json, log-session.sh"

# Step 3: .agents/skills/* → .claude/skills/
# code:tool-install-mas-001:link-skills
if [ ! -d "$MAS_DIR/.agents/skills" ]; then
  echo "⚠️  No .agents/skills dir found — skipping skills step."
else
  mkdir -p "$CLAUDE/skills"

  # Bug fix: use glob instead of $(ls -1 ...) to handle names with spaces safely
  for SRC in "$MAS_DIR/.agents/skills"/*/; do
    # glob yields trailing slash; strip it and get the basename
    SRC="${SRC%/}"
    NAME="$(basename "$SRC")"

    rm -rf "$CLAUDE/skills/$NAME"

    if [ -L "$SRC" ]; then
      # Bug fix: validate readlink result before using it (handles dangling symlinks)
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

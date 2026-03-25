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

CLAUDE="$TARGET_DIR/.claude"

# code:tool-install-mas-001:link-strategy
# Preferred path: .claude/ does not exist or is already a symlink.
# → Symlink the entire .claude/ dir in one atomic step.
#   This avoids any risk of nested symlinks (e.g. .claude/agents/agents).
#
# Fallback path: .claude/ exists as a real directory (project already has its own).
# → Link individual MAS components inside it, preserving the project's own files.

if [ ! -e "$CLAUDE" ] || [ -L "$CLAUDE" ]; then
  # ── PREFERRED: single symlink for the whole .claude/ ─────────────────────
  rm -f "$CLAUDE"
  ln -s "$MAS_DIR/.claude" "$CLAUDE"
  echo "Linked: .claude/ → $MAS_DIR/.claude (preferred)"

else
  # ── FALLBACK: .claude/ is a real dir — link components individually ───────
  echo "Note: .claude/ exists as a real dir — linking MAS components inside it"

  # rm -f before ln -s: ln -sf on an existing *directory* appends inside
  # it instead of replacing it, causing nested symlinks.
  rm -f "$CLAUDE/agents" "$CLAUDE/settings.json" "$CLAUDE/log-session.sh"
  ln -s "$MAS_DIR/.claude/agents"         "$CLAUDE/agents"
  ln -s "$MAS_DIR/.claude/settings.json"  "$CLAUDE/settings.json"
  ln -s "$MAS_DIR/.claude/log-session.sh" "$CLAUDE/log-session.sh"
  echo "Linked: agents/, settings.json, log-session.sh"

  # code:tool-install-mas-001:link-skills
  if [ ! -d "$MAS_DIR/.agents/skills" ]; then
    echo "⚠️  No .agents/skills dir found — skipping skills step."
  else
    mkdir -p "$CLAUDE/skills"

    # Glob-based loop (never word-splits on spaces/special chars)
    for SRC in "$MAS_DIR/.agents/skills"/*/; do
      SRC="${SRC%/}"
      NAME="$(basename "$SRC")"
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
fi

echo "Done."
ls -la "$CLAUDE/"

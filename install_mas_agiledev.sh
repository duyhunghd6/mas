#!/bin/bash
# install_mas_agiledev.sh
# code:tool-install-mas-001:create-symlink
#
# MAS Agile Dev — Install Script
# Creates a symlink from the TARGET project's .claude/ directory
# to this MAS repository's .claude/ directory.
#
# Usage:
#   cd /path/to/your-project
#   bash /path/to/mas/install_mas_agiledev.sh
#
#   OR from anywhere:
#   bash /path/to/mas/install_mas_agiledev.sh /path/to/your-project
#
# What it does:
#   <TARGET_DIR>/.claude  →  <MAS_DIR>/.claude  (symlink)
#
# This gives the target project access to:
#   - .claude/settings.json  (Stop hook → log-session.sh)
#   - .claude/log-session.sh (full raw JSONL transcript capture)
#   - .claude/agents/        (SM, ARCH, Dev1-3, QA1, QA2, etc.)

set -euo pipefail

# code:tool-install-mas-001:resolve-paths
# Resolve absolute path to this MAS repository
MAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAS_CLAUDE_DIR="${MAS_DIR}/.claude"

# Target project: arg $1 or current working directory
TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"
TARGET_CLAUDE_LINK="${TARGET_DIR}/.claude"

echo "MAS Agile Dev — Install"
echo "========================"
echo "MAS source : ${MAS_DIR}"
echo "Target dir : ${TARGET_DIR}"
echo ""

# code:tool-install-mas-001:guard-same-dir
if [ "${TARGET_DIR}" = "${MAS_DIR}" ]; then
  echo "⚠  Target is the MAS directory itself — nothing to do."
  exit 0
fi

# code:tool-install-mas-001:guard-existing
if [ -e "${TARGET_CLAUDE_LINK}" ] || [ -L "${TARGET_CLAUDE_LINK}" ]; then
  if [ -L "${TARGET_CLAUDE_LINK}" ]; then
    EXISTING_TARGET="$(readlink "${TARGET_CLAUDE_LINK}")"
    if [ "${EXISTING_TARGET}" = "${MAS_CLAUDE_DIR}" ]; then
      echo "✓ Symlink already correct: ${TARGET_CLAUDE_LINK} → ${MAS_CLAUDE_DIR}"
      exit 0
    fi
    echo "⚠  Existing symlink points elsewhere: ${TARGET_CLAUDE_LINK} → ${EXISTING_TARGET}"
    echo "   Removing and re-linking..."
    rm "${TARGET_CLAUDE_LINK}"
  else
    echo "❌ ${TARGET_CLAUDE_LINK} already exists and is not a symlink."
    echo "   Please remove or rename it manually, then re-run this script."
    exit 1
  fi
fi

# code:tool-install-mas-001:create-symlink
ln -s "${MAS_CLAUDE_DIR}" "${TARGET_CLAUDE_LINK}"

echo "✓ Symlink created:"
echo "  ${TARGET_CLAUDE_LINK}"
echo "  → ${MAS_CLAUDE_DIR}"
echo ""

# code:tool-install-mas-001:verify
echo "Contents available in target project:"
ls -la "${TARGET_CLAUDE_LINK}/"
echo ""
echo "Done. Claude Code in '${TARGET_DIR}' will now use MAS agents and Stop hook logging."

#!/bin/bash
# install_mas_agiledev.sh
# code:tool-install-mas-001:create-symlink
#
# MAS Agile Dev — Install Script
#
# Usage:
#   cd /path/to/your-project && bash /path/to/mas/install_mas_agiledev.sh
#   OR: bash /path/to/mas/install_mas_agiledev.sh /path/to/your-project
#
# What it does:
#   1. <TARGET>/.claude              → <MAS>/.claude           (symlink)
#   2. <TARGET>/.claude/skills/<SUB> → <MAS>/.agents/skills/<SUB>  (per-skill symlinks)
#      Force-recreates each skill symlink (removes existing first).
#
# This gives the target project access to:
#   - .claude/settings.json      (Stop hook → log-session.sh)
#   - .claude/log-session.sh     (full raw JSONL transcript capture)
#   - .claude/agents/            (SM, ARCH, Dev1-3, QA1, QA2, …)
#   - .claude/skills/<SUBDIR>/   (one symlink per .agents/skills/ subdirectory)

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────
# code:tool-install-mas-001:resolve-paths
MAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAS_CLAUDE_DIR="${MAS_DIR}/.claude"
MAS_SKILLS_SRC="${MAS_DIR}/.agents/skills"

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"
TARGET_CLAUDE_LINK="${TARGET_DIR}/.claude"

echo "MAS Agile Dev — Install"
echo "========================"
echo "MAS source : ${MAS_DIR}"
echo "Target dir : ${TARGET_DIR}"
echo ""

# ── Guard: same dir ───────────────────────────────────────────────────────────
# code:tool-install-mas-001:guard-same-dir
if [ "${TARGET_DIR}" = "${MAS_DIR}" ]; then
  echo "⚠  Target is the MAS directory itself — nothing to do."
  exit 0
fi

# ── Step 1: .claude symlink ───────────────────────────────────────────────────
# code:tool-install-mas-001:guard-existing
echo "── Step 1: .claude/ symlink"
if [ -e "${TARGET_CLAUDE_LINK}" ] || [ -L "${TARGET_CLAUDE_LINK}" ]; then
  if [ -L "${TARGET_CLAUDE_LINK}" ]; then
    EXISTING_TARGET="$(readlink "${TARGET_CLAUDE_LINK}")"
    if [ "${EXISTING_TARGET}" = "${MAS_CLAUDE_DIR}" ]; then
      echo "  ✓ Already correct: ${TARGET_CLAUDE_LINK} → ${MAS_CLAUDE_DIR}"
    else
      echo "  ⚠  Stale symlink detected (→ ${EXISTING_TARGET}), re-linking..."
      rm "${TARGET_CLAUDE_LINK}"
      ln -s "${MAS_CLAUDE_DIR}" "${TARGET_CLAUDE_LINK}"
      echo "  ✓ Symlink updated: ${TARGET_CLAUDE_LINK} → ${MAS_CLAUDE_DIR}"
    fi
  else
    echo "  ❌ ${TARGET_CLAUDE_LINK} exists and is not a symlink."
    echo "     Please remove or rename it manually, then re-run this script."
    exit 1
  fi
else
  # code:tool-install-mas-001:create-symlink
  ln -s "${MAS_CLAUDE_DIR}" "${TARGET_CLAUDE_LINK}"
  echo "  ✓ Created: ${TARGET_CLAUDE_LINK} → ${MAS_CLAUDE_DIR}"
fi
echo ""

# ── Step 2: per-skill symlinks inside .claude/skills/ ─────────────────────────
# code:tool-install-mas-002:link-skills
echo "── Step 2: .claude/skills/<SUBDIR> → .agents/skills/<SUBDIR>"

if [ ! -d "${MAS_SKILLS_SRC}" ]; then
  echo "  ⚠  No .agents/skills/ directory found in MAS — skipping skill links."
else
  SKILLS_DEST="${TARGET_CLAUDE_LINK}/skills"
  mkdir -p "${SKILLS_DEST}"

  SKILL_COUNT=0
  for SKILL_PATH in "${MAS_SKILLS_SRC}"/*/; do
    [ -e "${SKILL_PATH}" ] || continue          # glob miss
    SUBDIR="$(basename "${SKILL_PATH}")"
    DEST_LINK="${SKILLS_DEST}/${SUBDIR}"

    # Force-remove existing (symlink, dir, or file)
    if [ -L "${DEST_LINK}" ]; then
      rm "${DEST_LINK}"
    elif [ -e "${DEST_LINK}" ]; then
      rm -rf "${DEST_LINK}"
    fi

    # Resolve real path — follow if the skill source is itself a symlink
    REAL_SKILL="$(cd "${SKILL_PATH}" && pwd -P)"
    ln -s "${REAL_SKILL}" "${DEST_LINK}"
    echo "  ✓ ${SUBDIR} → ${REAL_SKILL}"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  done

  if [ "${SKILL_COUNT}" -eq 0 ]; then
    echo "  (no skill subdirectories found in ${MAS_SKILLS_SRC})"
  else
    echo "  ${SKILL_COUNT} skill(s) linked."
  fi
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "Contents of ${TARGET_CLAUDE_LINK}/:"
ls -la "${TARGET_CLAUDE_LINK}/"
echo ""
echo "Done. Claude Code in '${TARGET_DIR}' will now use MAS agents, hooks, and skills."

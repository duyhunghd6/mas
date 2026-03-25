#!/bin/bash
# tests/test_install_mas_agiledev.sh
# code:test-plan:install-mas:test-suite
#
# Unit tests for install_mas_agiledev.sh
# Run: bash tests/test_install_mas_agiledev.sh
#
# Universal IDs:
#   test-plan:install-mas:t1-nonexistent-target
#   test-plan:install-mas:t2-core-symlinks
#   test-plan:install-mas:t3-target-skill-linked
#   test-plan:install-mas:t4-idempotent
#   test-plan:install-mas:t5-no-double-nesting
#   test-plan:install-mas:t6-same-dir-noop

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install_mas_agiledev.sh"
PASS=0
FAIL=0

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL+1)); }

assert_symlink() { [ -L "$1" ] && pass "$2" || fail "$2 — expected symlink at $1"; }
assert_not_exist() { [ ! -e "$1" ] && pass "$2" || fail "$2 — expected $1 to NOT exist"; }

TARGET="/tmp/mas_install_test_$$"
trap 'rm -rf "$TARGET"' EXIT

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T1: target dir does not exist yet (mkdir-p guard)"
# test-plan:install-mas:t1-nonexistent-target
rm -rf "$TARGET"
# Set up a mock skill in the TARGET dir before running install
mkdir -p "$TARGET/.agents/skills/mock-target-skill"

bash "$INSTALL_SCRIPT" "$TARGET" > /tmp/mas_t1.log 2>&1
STATUS=$?
[ "$STATUS" -eq 0 ] && pass "exit 0 on non-existent target" || fail "script crashed with status $STATUS (see /tmp/mas_t1.log)"
[ -d "$TARGET/.claude" ] && pass ".claude/ dir created" || fail ".claude/ dir not created"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T2: core symlinks created from MAS"
# test-plan:install-mas:t2-core-symlinks
assert_symlink "$TARGET/.claude/agents"         ".claude/agents is a symlink"
assert_symlink "$TARGET/.claude/settings.json"  ".claude/settings.json is a symlink"
assert_symlink "$TARGET/.claude/log-session.sh" ".claude/log-session.sh is a symlink"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T3: skill from TARGET dir linked correctly"
# test-plan:install-mas:t3-target-skill-linked
assert_symlink "$TARGET/.claude/skills/mock-target-skill" "target skill is symlink"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T4: idempotent — second run also exits 0"
# test-plan:install-mas:t4-idempotent
bash "$INSTALL_SCRIPT" "$TARGET" > /tmp/mas_t4.log 2>&1
STATUS=$?
[ "$STATUS" -eq 0 ] && pass "second run exits 0" || fail "second run crashed with status $STATUS (see /tmp/mas_t4.log)"
assert_symlink "$TARGET/.claude/settings.json" "settings.json still a symlink after second run"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T5: no double-nesting (.claude/agents/agents must NOT exist)"
# test-plan:install-mas:t5-no-double-nesting
assert_not_exist "$TARGET/.claude/agents/agents" "no .claude/agents/agents nesting"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "T6: same-dir no-op"
# test-plan:install-mas:t6-same-dir-noop
OUTPUT="$(bash "$INSTALL_SCRIPT" "$SCRIPT_DIR" 2>&1)"
echo "$OUTPUT" | grep -q "Same dir — nothing to do." && pass "same-dir no-op message printed" || fail "no-op message not found"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL=$((PASS+FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo "  🎉 All $TOTAL tests passed."
else
  echo "  ⚠️  $FAIL/$TOTAL tests FAILED."
  exit 1
fi

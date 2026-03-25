#!/bin/bash
# tests/test_install_mas_agiledev.sh
# code:test-plan:install-mas:test-suite
#
# Unit tests for install_mas_agiledev.sh
# Run: bash tests/test_install_mas_agiledev.sh
#
# Universal IDs:
#   test-plan:install-mas:t1-preferred-symlink
#   test-plan:install-mas:t2-preferred-resolves
#   test-plan:install-mas:t3-no-double-nesting
#   test-plan:install-mas:t4-idempotent-preferred
#   test-plan:install-mas:t5-fallback-real-dir
#   test-plan:install-mas:t6-fallback-components
#   test-plan:install-mas:t7-fallback-no-nesting
#   test-plan:install-mas:t8-same-dir-noop

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

# ═══════════════════════════ PREFERRED PATH TESTS ════════════════════════════

echo ""
echo "── PREFERRED PATH: .claude/ does not exist yet ──────────────────────────"

echo ""
echo "T1: .claude/ is created as a symlink (preferred)"
# test-plan:install-mas:t1-preferred-symlink
rm -rf "$TARGET"
bash "$INSTALL_SCRIPT" "$TARGET" > /tmp/mas_t1.log 2>&1
STATUS=$?
[ "$STATUS" -eq 0 ] && pass "exit 0" || fail "crashed — see /tmp/mas_t1.log"
assert_symlink "$TARGET/.claude" ".claude/ itself is a symlink"

echo ""
echo "T2: symlink resolves to MAS .claude/"
# test-plan:install-mas:t2-preferred-resolves
DEST="$(readlink "$TARGET/.claude")"
[ "$DEST" = "$SCRIPT_DIR/.claude" ] && pass ".claude/ → correct MAS .claude/" || fail ".claude/ points to '$DEST', expected '$SCRIPT_DIR/.claude'"

echo ""
echo "T3: no double-nesting (.claude/agents/agents must NOT exist)"
# test-plan:install-mas:t3-no-double-nesting
assert_not_exist "$TARGET/.claude/agents/agents" "no .claude/agents/agents nesting"

echo ""
echo "T4: idempotent — second run keeps .claude/ as a symlink"
# test-plan:install-mas:t4-idempotent-preferred
bash "$INSTALL_SCRIPT" "$TARGET" > /tmp/mas_t4.log 2>&1
STATUS=$?
[ "$STATUS" -eq 0 ] && pass "second run exits 0" || fail "second run crashed — see /tmp/mas_t4.log"
assert_symlink "$TARGET/.claude" ".claude/ still a symlink after second run"

# ════════════════════════════ FALLBACK PATH TESTS ════════════════════════════

echo ""
echo "── FALLBACK PATH: .claude/ exists as a real directory ───────────────────"

echo ""
echo "T5: individual components linked when .claude/ is a real dir"
# test-plan:install-mas:t5-fallback-real-dir
FALLBACK="/tmp/mas_fallback_test_$$"
trap 'rm -rf "$TARGET" "$FALLBACK"' EXIT
mkdir -p "$FALLBACK/.claude"   # real dir — triggers fallback
bash "$INSTALL_SCRIPT" "$FALLBACK" > /tmp/mas_t5.log 2>&1
STATUS=$?
[ "$STATUS" -eq 0 ] && pass "fallback exits 0" || fail "fallback crashed — see /tmp/mas_t5.log"

echo ""
echo "T6: fallback core symlinks created inside real .claude/"
# test-plan:install-mas:t6-fallback-components
assert_symlink "$FALLBACK/.claude/agents"         ".claude/agents is a symlink"
assert_symlink "$FALLBACK/.claude/settings.json"  ".claude/settings.json is a symlink"
assert_symlink "$FALLBACK/.claude/log-session.sh" ".claude/log-session.sh is a symlink"

echo ""
echo "T7: fallback — no double-nesting"
# test-plan:install-mas:t7-fallback-no-nesting
assert_not_exist "$FALLBACK/.claude/agents/agents" "no .claude/agents/agents in fallback"

# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "T8: same-dir no-op"
# test-plan:install-mas:t8-same-dir-noop
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

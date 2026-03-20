#!/bin/bash
# code:tool-log-session-001:capture-trace
#
# Log Session Script
# Called by Claude Code Stop hook OR manually by /chat skill.
# Captures session metadata from stdin (JSON) and appends to session log.
#
# Usage:
#   echo '{"session_id":"...","cwd":"..."}' | ./scripts/log-session.sh
#   OR: called automatically by Claude Code Stop hook

set -euo pipefail

LOGS_DIR="$(cd "$(dirname "$0")/.." && pwd)/logs/iteration"
RUN_ID=$(date +"%Y%m%d-%H%M%S")
SESSION_DIR="${LOGS_DIR}/${RUN_ID}"

# Create session directory
mkdir -p "${SESSION_DIR}"

# Read hook input from stdin (if available)
if [ -t 0 ]; then
  # No stdin (manual call) — log basic info
  INPUT="{}"
else
  INPUT=$(cat)
fi

# Extract session_id if present
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")

# Write session metadata
cat > "${SESSION_DIR}/metadata.json" << EOF
{
  "run_id": "${RUN_ID}",
  "session_id": "${SESSION_ID}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hook_input": ${INPUT}
}
EOF

# Print path for Claude to use
echo "Session logged to: ${SESSION_DIR}"
echo "Run ID: ${RUN_ID}"

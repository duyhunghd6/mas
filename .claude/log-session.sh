#!/bin/bash
# code:tool-log-session-001:capture-trace
#
# Log Session Script — Full Raw Transcript Capture
# Called by Claude Code Stop hook automatically at end of each session.
# Copies the raw JSONL transcript directly from Claude Code's transcript_path.
#
# Stop hook payload (stdin):
#   {
#     "session_id": "<uuid>",
#     "transcript_path": "~/.claude/projects/.../<uuid>.jsonl",
#     "cwd": "/path/to/project",
#     "hook_event_name": "Stop",
#     "last_assistant_message": "..."
#   }
#
# Usage (manual test):
#   TRANSCRIPT=$(ls -t ~/.claude/projects/-Users-steve-duyhunghd6-mas/*.jsonl | head -1)
#   echo "{\"session_id\":\"test\",\"transcript_path\":\"$TRANSCRIPT\",\"cwd\":\"$PWD\",\"hook_event_name\":\"Stop\",\"last_assistant_message\":\"test\"}" \
#     | ./scripts/log-session.sh

set -euo pipefail

LOGS_DIR="$(cd "$(dirname "$0")/.." && pwd)/logs/iteration"
# NOTE: .claude/ is one level below project root, so ../ reaches project root correctly.
RUN_ID=$(date +"%Y%m%d-%H%M%S")
SESSION_DIR="${LOGS_DIR}/${RUN_ID}"

# Create session directory
mkdir -p "${SESSION_DIR}"

# code:tool-log-session-001:read-stdin
# Read hook input from stdin (if available)
if [ -t 0 ]; then
  # No stdin (manual call) — log basic info only
  INPUT="{}"
else
  INPUT=$(cat)
fi

# code:tool-log-session-001:extract-fields
# Extract fields from hook payload
SESSION_ID=$(echo "$INPUT"  | jq -r '.session_id          // "unknown"' 2>/dev/null || echo "unknown")
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""'        2>/dev/null || echo "")
LAST_MSG=$(echo "$INPUT"    | jq -r '.last_assistant_message // ""'      2>/dev/null || echo "")
CWD=$(echo "$INPUT"         | jq -r '.cwd // ""'                         2>/dev/null || echo "")

# Expand ~ in transcript_path if present
TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

# code:tool-log-session-001:write-metadata
# Write session metadata
cat > "${SESSION_DIR}/metadata.json" << EOF
{
  "run_id": "${RUN_ID}",
  "session_id": "${SESSION_ID}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "cwd": "${CWD}",
  "transcript_source": "${TRANSCRIPT_PATH}",
  "hook_input": ${INPUT}
}
EOF

# code:tool-log-session-001:copy-raw-transcript
# Copy the full raw JSONL transcript directly — no LLM analysis, byte-perfect copy
if [ -n "${TRANSCRIPT_PATH}" ] && [ -f "${TRANSCRIPT_PATH}" ]; then
  cp "${TRANSCRIPT_PATH}" "${SESSION_DIR}/transcript.jsonl"
  echo "✓ Raw transcript copied: $(wc -l < "${SESSION_DIR}/transcript.jsonl") lines"

  # code:tool-log-session-001:copy-subagent-transcripts
  # Copy subagent transcripts if they exist (sibling subagents/ dir)
  SUBAGENTS_DIR="$(dirname "${TRANSCRIPT_PATH}")/${SESSION_ID}/subagents"
  if [ -d "${SUBAGENTS_DIR}" ]; then
    mkdir -p "${SESSION_DIR}/subagents"
    cp "${SUBAGENTS_DIR}"/*.jsonl "${SESSION_DIR}/subagents/" 2>/dev/null || true
    SUBAGENT_COUNT=$(ls "${SESSION_DIR}/subagents/"*.jsonl 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ Subagent transcripts copied: ${SUBAGENT_COUNT} file(s)"
  fi

  # code:tool-log-session-001:generate-conversation-txt
  # Generate human-readable conversation.txt by extracting role+content from JSONL
  # Each JSONL line is a message event; extract role and text content only
  python3 - "${SESSION_DIR}/transcript.jsonl" "${SESSION_DIR}/conversation.txt" << 'PYEOF'
import sys, json

src  = sys.argv[1]
dest = sys.argv[2]

out = []
with open(src, "r", encoding="utf-8") as f:
    for raw in f:
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            continue

        # Skip non-message events (file-history-snapshot, etc.)
        if obj.get("type") not in ("user", "assistant"):
            continue

        msg  = obj.get("message", {})
        role = msg.get("role", obj.get("type", "unknown"))
        ts   = obj.get("timestamp", "")
        content = msg.get("content", "")

        # content can be a string or a list of content blocks
        if isinstance(content, list):
            parts = []
            for block in content:
                if isinstance(block, dict):
                    btype = block.get("type", "")
                    if btype == "text":
                        parts.append(block.get("text", ""))
                    elif btype == "tool_use":
                        parts.append(f"[tool_use: {block.get('name','')} input={json.dumps(block.get('input',''), ensure_ascii=False)[:200]}]")
                    elif btype == "tool_result":
                        result_content = block.get("content", "")
                        if isinstance(result_content, list):
                            result_content = " ".join(b.get("text","") for b in result_content if isinstance(b,dict))
                        parts.append(f"[tool_result: {str(result_content)[:300]}]")
                    elif btype == "thinking":
                        pass  # skip internal thinking blocks
                    else:
                        pass
                elif isinstance(block, str):
                    parts.append(block)
            text = "\n".join(p for p in parts if p)
        else:
            text = str(content)

        if text.strip():
            out.append(f"[{ts}] {role.upper()}\n{text}\n")
            out.append("-" * 80 + "\n")

with open(dest, "w", encoding="utf-8") as f:
    f.writelines(out)

print(f"✓ conversation.txt written: {len(out)//2} messages")
PYEOF

else
  echo "⚠ No transcript_path in hook payload — skipping raw log copy"
  echo "  (transcript_path was: '${TRANSCRIPT_PATH}')"
fi

# code:tool-log-session-001:summary
# Print summary
echo ""
echo "Session logged to: ${SESSION_DIR}"
echo "Run ID:            ${RUN_ID}"
echo "Session ID:        ${SESSION_ID}"
if [ -n "${LAST_MSG}" ]; then
  echo "Last message:      ${LAST_MSG:0:120}..."
fi
ls -lh "${SESSION_DIR}/"


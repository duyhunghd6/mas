---
trigger: always_on
glob: "*"
description: Git Commit Rules and Claude Code Subagent Workflows
---

# Git Commit Rules and Agent Team Guidelines

1. **Agent Rules Commit**: Whenever modifying Agent Rules or System prompts, ensure the commit message clearly indicates that it is an Agent Rules commit.
2. **Claude Code Subagents**: When writing any Claude Code subagents or Agent Teams, you MUST use the agent skill: `build-with-claudecode`.
3. **Verification**: When finished writing subagents, you MUST call the workflow: `/verify-claudecode-extension`.

---
description: Verify Claude Code Extension including SubAgents and Workflows
---

# Verify Claude Code Extension

When tracking specific iterations or agents during verification, utilize the variables `{run-iteration-id}` and `{subagents}`:

1. Validate that the Claude Code extension properly contains the designated SubAgents and Workflows.
2. You MUST use the Agent Skill `build-with-claudecode` to perform this verification.
3. Ensure that all inputs, outputs, and memory states for the targeted `{subagents}` align with the master orchestrator's design. Verify the subagent memory at `memory/agents/{subagents}.md`.
4. Cross-reference the agent outputs with the execution logs found in `logs/iteration/{run-iteration-id}/` to ensure consistent execution traces.

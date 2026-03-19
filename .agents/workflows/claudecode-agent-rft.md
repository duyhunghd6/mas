---
description: Claude Code Agent Reinforcement Fine-Tuning (RFT) Workflow
---

# Agent Reinforcement Fine-Tuning (RFT)

When executing this workflow, you must use the variables `{run-iteration-id}` and `{subagents}` to locate the correct context:

1. **Log Analysis**: Read the session logs for the specific iteration located at `logs/iteration/{run-iteration-id}/` to capture all requests and responses for the targeted `{subagents}`.
2. **Alignment Check**: Review the subagent's memory file at `memory/agents/{subagents}.md` and analyze the actual behaviors observed in logs against the intended design documents and PRDs.
3. **Self-Improvement**: Define actionable instructions or updates to the SubAgent prompts and the system architecture to make self-improvements based on the observed gaps.

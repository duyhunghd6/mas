---
id: research:spike:build-agent-rft
description: Step-by-step guidance for applying Reinforcement Fine-Tuning (RFT) in a production-grade MAS running fully in GeminiCLI / Claude Code.
---

# Native CLI Agent Reinforcement Fine-Tuning (RFT)

Building a production-grade Multi-Agent System (MAS) that mimics a real, self-improving human organization requires continuous learning. In a native CLI environment (GeminiCLI / Claude Code), where you do not alter underlying model weights, Reinforcement Fine-Tuning (RFT) and Multi-Agent Reinforcement Learning (MARL) are achieved structurally via prompt engineering, workflow iteration, and memory state management.

Here is a comprehensive methodology and step-by-step guidance for building, testing, and fine-tuning a self-improving enterprise MAS running fully in native CLIs.

> **Claude Code Implementation Note:** Throughout this document, all agent definitions reference Claude Code's SubAgent file format (YAML frontmatter + markdown body in `.claude/agents/`). See the [SubAgents reference](https://code.claude.com/docs/en/sub-agents) for the canonical specification.

## Phase 1: Treating MAS as Traditional Software (QA & Observability)

To prevent the "static swarm" problem, a MAS should be developed with the same rigorous Quality Assurance (QA) principles applied to traditional software engineering.

*   **Test Planning**: Treat requirements in `docs/PRD/` as absolute ground truth. Before any execution subagents are spawned, QA subagents must review the designated PRDs and structurally outline test plans in `docs/tests/{test-plan-id}.md`.
*   **Test Case Generation & Execution**: For every Acceptance Criteria linked to a Universal ID (`{type}:{section}:{component-name}`), there must be a mapped test case. Because MAS output is probabilistic and dynamically varied, do not rely on exact string matching. Instead, utilize an "LLM-as-a-Judge" (a Critic subagent) running code-first evaluation workflows (like `/verify-claudecode-extension`) to strictly grade artifacts on factual correctness, layout conformity, and state progression.
*   **QA Sign-Off and Release Gates**: No agent configuration update or RFT rule should be finalized without a formal QA sign-off. The Critic or QA subagent must produce a formal `docs/tests/{run-iteration-id}-signoff.md` report verifying that all test scenarios and human-in-the-loop (HITL) checkpoints passed successfully.
    *   **Claude Code Implementation**: Use **Hooks** to enforce QA gates natively. A `TaskCompleted` hook (type: `agent`) can spawn a QA SubAgent to verify all acceptance criteria before a task is marked done. A `Stop` hook (type: `prompt`) can check if all required sign-off files exist:
    ```json
    {
      "hooks": {
        "TaskCompleted": [{
          "hooks": [{
            "type": "agent",
            "prompt": "Verify all acceptance criteria in docs/tests/ are marked PASS before allowing task completion.",
            "timeout": 120
          }]
        }]
      }
    }
    ```
*   **Deep Observability & Iteration Logs**: Multi-agent debugging is impossible without structured logging. Manually or structurally log all execution paths into `logs/iteration/{run-iteration-id}/` to trace inputs, terminal commands, and subagent tool calls if a test case fails.
    *   **Claude Code Implementation**: Use **Background SubAgents** (`background: true` in YAML frontmatter) to run long QA validation suites without blocking the Orchestrator. Use **HTTP Hooks** (`type: http`) to stream telemetry to external observability systems:
    ```json
    {
      "hooks": {
        "PostToolUse": [{
          "hooks": [{
            "type": "http",
            "url": "http://localhost:8080/telemetry/tool-use"
          }]
        }]
      }
    }
    ```
*   **Systematic Regression Testing**: Codify previously failed agent exchanges and run them as automated test cases on every commit within `.agents/workflows/`.

## Phase 2: Reinforcement Fine-Tuning (RFT) for Individual Agents

Before teaching the entire organization to collaborate, individual subagents must be structurally optimized for their specific roles using the `/claudecode-agent-rft` workflow.

1.  **Log Analysis**: Read the session logs for a specific iteration located at `logs/iteration/{run-iteration-id}/` to trace the exact context window and actions of the targeted `{subagents}`.
2.  **Alignment Check**: Review the subagent's memory file (`memory/agents/{subagents}.md`) and analyze the actual behaviors against the intended system design documents or PRDs. 
3.  **Self-Improvement via Rule Updates**: Define actionable instructions to update the SubAgent's definition file. In Claude Code, each SubAgent is defined as a `.md` file in `.claude/agents/` using YAML frontmatter:
    ```yaml
    ---
    name: qa-lead
    description: QA specialist responsible for test plans, validation, and release gates.
    tools: Read, Grep, Glob, Bash
    model: sonnet
    maxTurns: 25
    ---
    
    You are the QA Lead. When invoked, review test plans against PRD acceptance criteria.
    Always cite the Universal ID when referencing a requirement.
    Never modify production files — you have read-only access plus Bash for test execution.
    ```
    The RFT workflow updates the SubAgent's **YAML frontmatter** (tool access, model, maxTurns) and **markdown body** (behavioral instructions). This structurally prevents repeating errors without altering underlying model weights.
4.  **Eliminate Domain Shift**: Ensure your structural "training" datasets (iteration logs) exactly mirror your production traffic. 
5.  **Design Continuous Reward Functions**: Give "partial credit" via validation rubrics rather than strict pass/fail to slowly refine instructions (e.g., updating the workflow to prioritize fetching specific files rather than broad directory searches).

## Phase 3: Multi-Agent Reinforcement Learning (MARL) for Organizational Flow

Scaling RFT to multiple agents working together introduces structural problems. In CLI environments, you must manage how agents collaborate via the file system Blackboard Model — and leverage Claude Code's native multi-agent features.

### 3.1 Centralized Orchestration via Agent Teams

Claude Code provides **Agent Teams** — an experimental feature that enables multiple Claude Code instances working together with shared tasks and inter-agent messaging. Enable with:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

The **Lead** agent acts as the Orchestrator and spawns **Teammate** agents for parallel execution. Each teammate has its own context window and consumes tokens independently. Key capabilities:
- **Shared task list**: All agents can see task status (`~/.claude/tasks/{team-name}/`)
- **Inter-agent messaging**: `message` (to one teammate) or `broadcast` (to all)
- **Quality gates via Hooks**: `TeammateIdle` and `TaskCompleted` hooks enforce QA checks

### 3.2 Distributed Execution via SubAgents

For sequential delegation (not parallel), use SubAgents. The Orchestrator spawns isolated SubAgents via the `Agent()` tool:
- **Foreground**: Blocks the Orchestrator until completion; permission prompts pass through
- **Background** (`background: true`): Runs concurrently; pre-approves permissions

SubAgents can be chained: "Use the code-reviewer subagent to find issues, then use the optimizer subagent to fix them."

### 3.3 Reward Attribution

*   **Sequential vs. Dynamic Reward Attribution**: If a bug appears in the final CLI output, the Critic subagent traces the Universal IDs back through the sequential pipeline to find which specific subagent (e.g., Coder vs. Reviewer) caused the failure, rather than blindly punishing the Orchestrator. The RFT workflow then updates only that specific subagent's `.claude/agents/{name}.md` file.
*   **Context Engineering**: Treat context as a scarce resource. Claude Code's `maxTurns` field in SubAgent YAML limits conversation depth. The `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` environment variable (default: 50%) controls when auto-compaction triggers. Never pass the entire CLI chat history to a subagent — extract only the required context into a temporary file or specific prompt.

## Phase 4: Preventing Organizational Failure Modes

As your CLI multi-agent system evolves structurally, it is vulnerable to silent organizational failures:

*   **Lazy Agent Collapse**: One highly capable Orchestrator starts fully executing the Domain Agents' work because it was easier than correctly spawning a CLI sub-command. The system slowly devolves back into a monolithic "God Agent".
    *   **The Fix**: Enforce strict tool and boundary roles via SubAgent YAML. The Orchestrator's SubAgent file should restrict tools to state management only:
    ```yaml
    ---
    name: orchestrator
    description: Master Orchestrator — manages state and spawns subagents. NEVER writes code directly.
    tools: Read, Grep, Glob, Agent(lead-dev, qa-lead, cto)
    disallowedTools: Write, Edit, Bash
    model: opus
    ---
    ```
    Update `.agents/rules/` to rigidly prevent the Orchestrator from bypassing its subagents.
*   **Coordination Lock-in**: Agents develop a highly optimized but brittle file-passing protocol that fails catastrophically on unexpected edge cases.
    *   **The Fix**: Introduce "Dynamic Boomerang Architectures." Continuously define specialized tasks where subagents must pause execution, evaluate mid-flight findings, and return control to the Orchestrator for reassessment before continuing blindly.

## Phase 5: Organizational DNA & Culture

> **Cross-Reference**: The full organizational DNA framework — SOUL.md, Agent Lifecycle, Department Formation, Cross-Department Protocols, and Knowledge Management — is documented in detail in [spike-step-by-step-on-creating-mas.md](spike-step-by-step-on-creating-mas.md) (Phases 4.5 and 5). This section provides the RFT-specific perspective on culture.

### 5.1 The Founding Charter (SOUL.md)

The `SOUL.md` is a **rule file** stored at `.agents/rules/SOUL.md`. It is automatically injected into every agent's context via `CLAUDE.md` or `.claude/settings.json`. It codifies:

*   **Mission Statement**: The single sentence that defines what this MAS exists to accomplish.
*   **Core Values**: 3-5 non-negotiable behavioral principles (e.g., "Never modify production files without QA sign-off", "Always cite the Universal ID when referring to a requirement").
*   **Communication Style**: How agents address each other's outputs — constructive critique vs. binary pass/fail, formal artifact handovers vs. inline annotations.
*   **Decision-Making Authority Hierarchy**: Which agents have final say over which domains. The CEO/Orchestrator owns strategic decisions; the CTO/Architect owns technical decisions; the QA Lead owns release gates.

### 5.2 Agent Performance Reviews via RFT

Just as human organizations conduct quarterly reviews, a MAS must periodically audit each agent's effectiveness using the RFT workflow:

1.  **Collect Evidence**: Gather all iteration logs involving the target agent from `logs/iteration/{run-iteration-id}/`.
2.  **Evaluate Against Rubric**: Score on dimensions: (a) Task Completion Rate, (b) Error Introduction Rate, (c) Context Efficiency (tokens consumed vs. useful output), (d) Adherence to SOUL.md values.
3.  **Generate Review Document**: The Critic agent produces `docs/report/agent-review-{agent-name}-{date}.md` with quantified scores and specific improvement recommendations.
4.  **Action Items**: The review feeds back into the RFT workflow (Phase 2) to structurally update the agent's SubAgent definition at `.claude/agents/{agent-name}.md`.

### 5.3 Promotion & Demotion (Agent Lifecycle)

Agents evolve through capability tiers based on demonstrated performance. Each tier maps to concrete Claude Code SubAgent YAML configuration:

| Tier | Role | SubAgent YAML `tools` | SubAgent `model` | Trigger |
|:-----|:-----|:----------------------|:-----------------|:--------|
| **Intern** | Narrow single-task executor | `Read, Grep` (minimal) | `haiku` | New agent, first 3 iterations |
| **Junior** | Competent domain worker | `Read, Grep, Glob, Bash` | `sonnet` | 3+ clean iterations, <5% error rate |
| **Senior** | Trusted domain expert | Full department toolset + cross-dept read | `sonnet` | 10+ iterations, <2% error rate |
| **Lead** | Department head, can spawn sub-agents | Full toolset + `Agent(*)` | `opus` | Consistently outperforms peers, nominated by Orchestrator |

*   **Demotion**: If an agent's error rate exceeds its tier threshold for 2 consecutive iterations, it is demoted one tier — its SubAgent YAML `tools` field is restricted and `model` is downgraded accordingly.
*   **Retirement ("Firing")**: If an agent is demoted to Intern and still fails, it is archived (its `.claude/agents/{agent}.md` is moved to `.claude/agents/retired/`) and replaced with a redesigned agent built from the post-mortem analysis.

## Phase 6: Emergent Behavior Monitoring & Governance

> **Cross-Reference**: Organizational health metrics and retrospectives are covered in [spike-step-by-step-on-creating-mas.md](spike-step-by-step-on-creating-mas.md) (Phase 5.4). This section focuses on emergent behavior detection.

### 6.1 Tracking Emergent Norms

*   **Coordination Pattern Mining**: Periodically analyze `logs/iteration/` to detect recurring agent-to-agent file-passing sequences that were not part of the original workflow design. Document these in `memory/org/emergent-patterns.md`.
*   **Implicit Protocol Detection**: If agents consistently structure their output artifacts in a specific format (beyond what their rules require), this emergent "house style" should be evaluated — codified if beneficial, or corrected if it introduces ambiguity.

### 6.2 Automated Monitoring via Hooks

Use Claude Code's native hook system to automate emergent behavior detection:

*   **SubagentStop hooks**: Log every subagent's completion summary for pattern analysis:
    ```json
    {
      "hooks": {
        "SubagentStop": [{
          "hooks": [{
            "type": "command",
            "command": "./scripts/log-subagent-completion.sh"
          }]
        }]
      }
    }
    ```
*   **PostToolUse hooks**: Track file mutation patterns to detect implicit protocols
*   **Context Utilization**: Monitor via `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` — agents that compact frequently may need better context engineering

### 6.3 Org-Level Retrospectives

The Orchestrator runs periodic "all-hands" retrospective sessions:

1.  **Aggregate**: Collect recent iteration logs from all departments.
2.  **Analyze**: Identify systemic patterns — recurring blockers, bottlenecks, and wins.
3.  **Decide**: Update `SOUL.md` values, create new org-wide rules, or restructure departments as needed.
4.  **Document**: Write `memory/org/retrospective-{date}.md` capturing decisions and action items.
5.  **Distribute**: Notify all department-head agents of changes via updated memory files.

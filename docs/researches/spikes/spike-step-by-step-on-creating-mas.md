---
id: plan:step-by-step:creating-mas
description: Step by step guide to creating a production-grade Multi-Agent System natively in GeminiCLI and Claude Code.
---

# Phase 1: Getting Started (Native CLI Level)

## 1.1 Determine the Need for a Native MAS
Before building, confirm that a single agent with a well-crafted prompt cannot solve the problem. Single agents are ideal for linear tasks that fit within a single context window. Native CLI Multi-agent systems introduce coordination overhead and should only be used when a problem can be decomposed into parallel subtasks, requires distinct specialized expertise, or involves highly complex workflows that exceed single-agent capabilities.

## 1.2 Understand Core CLI Agent Capabilities
Every agent in your system operates within a terminal session (Claude Code or Gemini CLI) relying on:
- **Perception:** Interpreting strictly scoped markdown prompts and file inputs.
- **Reasoning:** ReAct loops (Reason + Act) generating internal thoughts.
- **Action:** Executing terminal commands and Model Context Protocol (MCP) tools.
- **Memory:** Reading and writing to isolated markdown files (e.g., `memory/agents/{subagents}.md`).

### Claude Code Built-In SubAgents

Before creating custom agents, check if one of the 3 built-in subagents suffices:

| Built-In | Model | Tools | Best For |
|:---------|:------|:------|:---------|
| **Explore** | Haiku (fast, low-latency) | Read-only | File discovery, codebase exploration |
| **Plan** | Inherits from main | Read-only | Codebase research for planning |
| **General-purpose** | Inherits from main | All tools | Complex research, multi-step operations, code modifications |

Use `/statusline` to see active subagents. Use `/agents` to view, create, edit, and delete custom subagents interactively.

## 1.3 Select the Orchestration Framework
Instead of relying on heavy external SDKs (like LangGraph or CrewAI), the system relies purely on native CLI capabilities, file-based handovers, and executable workflows (e.g., `.agents/workflows/`). In Claude Code, this translates to:
- **SubAgents** (`.claude/agents/`): Isolated agent definitions with YAML frontmatter
- **Skills** (`.claude/skills/`): Reusable workflows and domain knowledge
- **Hooks** (`.claude/settings.json`): Lifecycle event handlers for automation
- **Agent Teams**: Experimental parallel execution (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- **Headless Mode** (`claude -p`): Programmatic pipeline execution

# Phase 2: Designing the Architecture (Intermediate Level)

## 2.1 Task Decomposition and Directory Structure
Break the high-level goal into specialized, manageable subtasks. Enforce a rigorous directory structure to manage the system state:
- `docs/PRD/`: Product Requirement Documents (with Universal IDs).
- `docs/tests/`: Test plans and QA verification documents.
- `memory/agents/{subagents}.md`: Context and state memory for individual subagents.
- `memory/{task,progress,plan}.md`: Centralized Master Orchestrator state.
- `.agents/rules/`: Agent Rules like Git formatting, identities, Universal IDs, and SOUL.md.
- `.agents/workflows/`: Executable AI workflows like Agent RFT and Verification tests.
- `.claude/agents/`: Claude Code SubAgent **definitions** (YAML frontmatter + prompt body).
- `.claude/skills/`: Claude Code Skill definitions (SKILL.md format).

> **Important Distinction**: Agent **definitions** (who the agent *is*) go in `.claude/agents/{name}.md`. Agent **state/memory** (what the agent *remembers*) goes in `memory/agents/{name}.md`. These are separate concerns.

## 2.2 Choose a CLI-Native Orchestration Pattern
Select the core flow for your CLI agents:
- **Sequential Pipeline:** CLI passes output from SubAgent A (`temp_step1.md`) as input to SubAgent B. In Claude Code, chain via **Headless Mode**:
  ```bash
  claude -p "Produce a technical design from the PRD" \
    --allowedTools "Read,Grep,Glob,Write" --output-format json > /tmp/design.json
  
  jq -r '.result' /tmp/design.json | \
    claude -p "Implement from this design: $(cat)" \
    --allowedTools "Read,Write,Edit,Bash"
  ```
- **Supervisor (Queen-Worker-Drone):** The main CLI session plans and sequentially spawns isolated worker SubAgents via the `Agent()` tool.
- **Recursive & Dynamic (Boomerang):** Subagents are spawned for specific tasks and return a final artifact to the Orchestrator via a strict Handover Protocol.
- **Agent Teams (Native Parallel):** Multiple Claude Code processes with shared task lists, inter-agent messaging, and Lead/Teammate coordination. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Best for parallelizable work like simultaneous code review, multi-module development, or competing hypothesis investigation.

## 2.3 Establish Universal ID Communication
All elements in the system MUST use Universal IDs (`{type}:{section}:{component-name}`) to maintain loose-coupled linking from PRDs down to code and test-plans. The state is shared via the file system (the "Blackboard" model).

# Phase 3: Managing Complexity and Context (Advanced Level)

## 3.1 Context Engineering
Multi-agent systems fail due to token sprawl. Never pass the entire CLI chat history to a subagent. Claude Code SubAgents automatically get isolated context windows. Additional measures:
- Set `maxTurns` in SubAgent YAML to prevent infinite loops
- Use `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (default: 50%) to control auto-compaction behavior
- Use `model: haiku` for cost-sensitive narrow tasks

## 3.2 Integrate External Tools (MCP)
Equip agents with tools to interact with external databases and APIs natively. Scope MCP servers to specific SubAgents via the `mcpServers` frontmatter field:

```yaml
---
name: browser-tester
description: Tests features in a real browser using Playwright.
tools: Bash, Read
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  - github
---
```

## 3.3 Implement Robust Memory
Rely on the structured directory `memory/` for long-term semantic memory. The Orchestrator maintains the global state in `memory/task.md` while isolated `.md` files track individual sub-agent memory.

Additionally, Claude Code provides **native SubAgent memory** via the `memory` frontmatter field:

| Scope | Path | Use Case |
|:------|:-----|:---------|
| `user` | `~/.claude/agent-memory/{name}/` | Personal preferences, cross-project knowledge |
| `project` | `.claude/agent-memory/{name}/` | Project-specific patterns, accumulated decisions |
| `local` | `.claude/agent-memory-local/{name}/` | Machine-specific configuration |

The subagent's system prompt automatically includes instructions for managing a `MEMORY.md` file within its memory scope.

# Phase 4: Making It Production-Grade (Expert Level)

## 4.1 Enforce Multi-Agent Validation
Use an Executor → Validator → Critic chain composed of entirely separate CLI invocations. One CLI agent executes code; an autonomous QA agent runs testing workflows (like `/verify-claudecode-extension`) against PRDs; a Critic subagent decides on approval.

**Claude Code Implementation**: Expand the `/verify-claudecode-extension` workflow to include structural validation — verify SubAgent YAML frontmatter fields, tool lists, model specifications, and cross-reference against org-chart definitions.

## 4.2 Add Human-in-the-Loop (HITL) Checkpoints
Insert workflows that pause and explicitly request human approval before transitioning between major pipeline stages.

**Claude Code Implementation**: Use **Hooks** to implement HITL gates natively:

- **Stop hooks** (type: `prompt`): Check completeness before the agent finishes:
  ```json
  {
    "hooks": {
      "Stop": [{
        "hooks": [{
          "type": "prompt",
          "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains\"}."
        }]
      }]
    }
  }
  ```

- **TaskCompleted hooks** (for Agent Teams): Gate task completion on QA checks:
  ```json
  {
    "hooks": {
      "TaskCompleted": [{
        "hooks": [{
          "type": "agent",
          "prompt": "Run the test suite and verify all acceptance criteria pass before allowing completion.",
          "timeout": 120
        }]
      }]
    }
  }
  ```

## 4.3 Log Telemetry and Observability
Log all execution paths manually or structurally into `logs/iteration/{run-iteration-id}/`. This captures exact inputs, outputs, and subagent tool calls.

**Claude Code Implementation**: Use **HTTP Hooks** to stream telemetry to external systems:
```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "http",
        "url": "http://localhost:8080/telemetry/tool-use"
      }]
    }],
    "SubagentStop": [{
      "hooks": [{
        "type": "command",
        "command": "./scripts/log-subagent-completion.sh"
      }]
    }]
  }
}
```

## 4.4 Agent Reinforcement Fine-Tuning (RFT)
Apply continuous improvement mechanisms natively. Use workflows like `/claudecode-agent-rft` to analyze iteration logs, detect behavioral drift, and autonomously update the SubAgent's definition at `.claude/agents/{name}.md` — modifying YAML frontmatter (tool access, model, maxTurns) and prompt body (behavioral instructions) to structurally prevent repeating errors without altering underlying model weights.

> **Cross-Reference**: See [spike-build-agent-rft.md](spike-build-agent-rft.md) for the comprehensive RFT methodology including MARL, failure mode prevention, and emergent behavior governance.

## 4.5 Organizational DNA Bootstrap

Before scaling, every MAS needs its founding DNA — the cultural and structural primitives that make it behave like a coherent organization, not a random collection of CLI processes.

### Step 1: Write the Founding Charter (SOUL.md)

Create `.agents/rules/SOUL.md` as a **rule file** (automatically injected into every agent's context) containing:

*   **Mission**: One sentence defining the MAS's purpose.
*   **Core Values**: 3-5 non-negotiable principles (e.g., "Never modify production files without QA sign-off", "Always cite Universal IDs").
*   **Communication Norms**: Structured artifact handovers only — no free-text summaries between agents.
*   **Decision Authority Matrix**: Who has final say over which domains (CEO→strategic, CTO→technical, QA Lead→quality, Product Owner→requirements).

### Step 2: Hire the Founding Team

Define your 3-5 core agents. Each agent needs TWO files:
1. **SubAgent definition** in `.claude/agents/{name}.md` — Identity, tools, model, constraints
2. **State/memory file** in `memory/agents/{name}.md` — Accumulated context and decisions

| Role | SubAgent Definition | Memory File | Responsibility | Tool Access |
|:-----|:-------------------|:------------|:---------------|:------------|
| **CEO / Orchestrator** | `.claude/agents/orchestrator.md` | `memory/agents/ceo.md` | Mission decomposition, sprint planning, retrospectives | `Agent(cto, product-owner)` — NO write tools |
| **CTO / Architect** | `.claude/agents/cto.md` | `memory/agents/cto.md` | Technical decisions, pattern selection, architecture review | `Read, Grep, Glob, Write, Agent(lead-dev, qa-lead)` |
| **Lead Dev** | `.claude/agents/lead-dev.md` | `memory/agents/lead-dev.md` | Code implementation, developer sub-agent management | Full dev toolset + `Agent(junior-dev)` |
| **QA Lead** | `.claude/agents/qa-lead.md` | `memory/agents/qa-lead.md` | Test planning, validation, release gates | `Read, Grep, Glob, Bash` — NO write tools |
| **Product Owner** | `.claude/agents/product-owner.md` | `memory/agents/product-owner.md` | PRD authorship, acceptance criteria, stakeholder proxy | `Read, Write` — PRD writes only |

**Example SubAgent Definition** (`.claude/agents/qa-lead.md`):
```yaml
---
name: qa-lead
description: QA Lead responsible for test plans, validation workflows, and release gates.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: sonnet
maxTurns: 25
skills:
  - verify-claudecode-extension
memory: project
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: "Did you produce a formal sign-off document in docs/tests/? Answer {ok: true/false}."
---

You are the QA Lead. When invoked:
1. Read the test plan referenced by Universal ID.
2. Execute all test cases via Bash.
3. Produce a formal sign-off document in docs/tests/{run-iteration-id}-signoff.md.
4. NEVER modify production code — flag issues for Engineering.
```

### Step 3: Establish Communication Protocols

Define the handoff contracts between founding team members:

1.  **Product Owner → CTO**: PRD with Universal IDs + acceptance criteria.
2.  **CTO → Lead Dev**: Technical design document referencing the PRD.
3.  **Lead Dev → QA Lead**: Working code artifact + build confirmation.
4.  **QA Lead → Product Owner**: Test report with pass/fail per acceptance criterion.
5.  **Any → CEO**: Escalation when handoff is rejected twice.

All handoffs are mediated through the file system (`docs/`, `memory/`). No agent directly "talks" to another — they communicate exclusively through structured artifacts.

**Claude Code Implementation**: Use `SubagentStop` hooks to validate handoff artifacts exist when each agent completes.

### Step 4: Run the First Sprint

Execute a small, end-to-end task to validate the entire pipeline:

1.  CEO reads the first task from `memory/task.md`.
2.  CEO creates a plan in `memory/plan.md` and assigns subtasks.
3.  Product Owner produces a micro-PRD in `docs/PRD/`.
4.  CTO reviews and approves the technical approach.
5.  Lead Dev implements the feature.
6.  QA Lead runs the `/verify-claudecode-extension` workflow.
7.  CEO reviews QA results and writes `memory/progress.md`.

The goal of the first sprint is **not output quality** — it is **pipeline validation**. Verify that every handoff works, every artifact lands in the correct directory, and no agent bypasses its role boundaries.

**Automated Pipeline Execution**: Use **Headless Mode** to script the first sprint:
```bash
#!/bin/bash
# first-sprint.sh — Automated pipeline validation
ITERATION="sprint-01"

# Step 1: CEO creates plan
claude -p "Read memory/task.md and create a plan in memory/plan.md" \
  --allowedTools "Read,Write" --output-format json > logs/iteration/$ITERATION/ceo.json

# Step 2: Product Owner writes micro-PRD
claude -p "Based on memory/plan.md, produce a micro-PRD in docs/PRD/" \
  --allowedTools "Read,Write" --output-format json > logs/iteration/$ITERATION/po.json

# Step 3-5: CTO reviews, Lead Dev implements
claude -p "Review the PRD and spawn lead-dev to implement" \
  --allowedTools "Read,Grep,Glob,Agent(lead-dev)" \
  --output-format json > logs/iteration/$ITERATION/cto.json

# Step 6: QA Lead validates
claude -p "Run /verify-claudecode-extension and produce sign-off" \
  --allowedTools "Read,Grep,Glob,Bash" \
  --output-format json > logs/iteration/$ITERATION/qa.json
```

### Step 5: Retrospective & Culture Calibration

After the first sprint, the CEO/Orchestrator runs a retrospective:

1.  **Collect**: Aggregate all logs from `logs/iteration/{first-run-id}/`.
2.  **Analyze**: Identify which handoffs were clean, which were messy, and which agents overstepped their boundaries.
3.  **Calibrate**: Update `SOUL.md` with lessons learned. Update individual SubAgent definitions in `.claude/agents/` to address observed drift.
4.  **Document**: Write `memory/org/retrospective-sprint-01.md`.

# Phase 5: Scaling the Organization (Enterprise Level)

Once the founding team proves the pipeline works, the MAS can scale — carefully and structurally.

## 5.1 Department Formation

Transform flat teams into departments when complexity demands it:

**Trigger Rules:**
*   A single Lead agent consistently spawns >3 sub-agents for the same domain.
*   Error rates in a specific area exceed 5% for 2+ consecutive iterations.
*   A new PRD introduces a domain that none of the existing founding team covers.

**Department Structure:**
```
Department: Engineering
├── Department Head: Engineering Lead (reports to CTO)
│   SubAgent: .claude/agents/lead-dev.md
├── Senior Dev agents (2-3)
│   SubAgents: .claude/agents/senior-dev-{n}.md
├── Junior Dev agents (as needed)
│   SubAgents: .claude/agents/junior-dev-{n}.md
└── Shared Memory: memory/org/dept-engineering.md
```

Each department gets:
*   A **Department Head** agent (must be Lead-tier or above).
*   A **shared memory file** (`memory/org/dept-{name}.md`) for department-level decisions.
*   **Input/Output contracts** defining what artifacts flow in and out.

**For parallel department work**, use **Agent Teams** or **Git Worktree Isolation** (`isolation: worktree` in SubAgent YAML) to prevent file conflicts between departments working simultaneously.

## 5.2 Hiring New Agents (Onboarding Template)

When the organization needs a new agent:

1.  **Role Definition**: Create TWO files:
    - SubAgent definition: `.claude/agents/{new-agent}.md` with YAML frontmatter specifying name, description, tools, model, and prompt body with constraints referencing `SOUL.md`.
    - State/memory: `memory/agents/{new-agent}.md` for accumulated context.
2.  **Probation Period**: The new agent starts at **Intern tier** — `tools: Read, Grep` | `model: haiku` — all outputs are reviewed by its Department Head for the first 3 iterations.
3.  **Promotion Review**: After 3 clean iterations (<5% error rate), the agent is promoted to Junior — `tools: Read, Grep, Glob, Bash` | `model: sonnet`. The Department Head documents the promotion in `docs/report/agent-review-{name}.md`.
4.  **Retirement Protocol**: If the agent fails probation, it is retired — its SubAgent definition is moved to `.claude/agents/retired/{name}.md` with a post-mortem explaining the failure and recommendations for its replacement.

Use the `/agents` command or `claude agents` CLI to manage SubAgent lifecycle interactively.

## 5.3 Knowledge Management

As the organization grows, institutional knowledge becomes the most valuable asset:

*   **Playbooks** (`memory/org/playbooks/`): Step-by-step procedures for recurring workflows, written after a process is successfully executed 3+ times.
*   **Post-Mortems** (`memory/org/post-mortems/`): Root cause analysis of every failure that required HITL intervention.
*   **Best Practices** (`memory/org/best-practices.md`): Curated lessons from Senior and Lead agents, reviewed during retrospectives.
*   **Org Glossary** (`memory/org/glossary.md`): Shared vocabulary to prevent semantic ambiguity (e.g., "deployment" means X in Engineering, Y in QA — resolve it here).

**Claude Code Implementation**: Use **Skills preloading** (`skills:` in SubAgent YAML) to inject relevant playbooks and best practices into agents at spawn time.

**Rule**: Before creating a new workflow or solving a novel problem, every agent must first search `memory/org/playbooks/` and `memory/org/post-mortems/`. This enforces organizational learning.

## 5.4 Organizational Health Dashboard

Track these metrics across every iteration cycle and log to `docs/report/org-health-{date}.md`:

| Metric | What It Measures | Healthy Target |
|:-------|:-----------------|:---------------|
| **Iteration Velocity** | Time from task assignment to QA sign-off | Improving (decreasing) trend |
| **Error Rate per Dept** | Errors attributed to each department | <5% per department |
| **Context Efficiency** | Useful tokens / total tokens consumed | >60% |
| **HITL Frequency** | How often humans must intervene | Decreasing trend |
| **Handoff Success Rate** | First-attempt acceptance rate between departments | >90% |
| **Agent Promotion Rate** | Agents advancing through tiers | Steady positive flow |
| **Knowledge Reuse** | Playbook lookups before new workflow creation | >80% of new tasks |

When metrics drift outside healthy ranges, the CEO/Orchestrator triggers an org-level retrospective to diagnose root causes and update `SOUL.md`, department structures, or individual SubAgent definitions in `.claude/agents/` as needed.

---
id: research:spike:skill-guidance-for-mas
description: Architecture research, orchestration models, and skill guidance for building a CLI-native Multi-Agent System in Claude Code / GeminiCLI.
---

# Spike: Multi-Agent System (MAS) Architecture and Skill Guidance

## 1. Research: AI Agent Architecture Models

Based on recent Agentic Software Engineering patterns (2026), AI agent architectures have rapidly evolved from early conversational swarms to highly structured, stateful orchestrations.

### 1.1 Core Orchestration Models

1. **Hierarchical (Queen-Worker-Drone / QWD):**
   - **Queen (Orchestrator):** Acts as the high-level planner and gatekeeper. Decomposes the user's intent and reviews intermediate outputs.
   - **Worker (Specialist):** Domain-specific agents (e.g., Architect, Dev, QA) with restricted context windows optimized for their specific tasks.
   - **Drone (Utility):** Short-lived agents for single-task execution like web searching or running terminal commands.
2. **Recursive & Dynamic (Boomerang / Sub-Agent Spawning):**
   - The Orchestrator functions as a Project Manager ("The Conductor"). It observes requirements, plans, decomposes into discrete tasks, and dynamically spawns specialized sub-agents via tools like `new_task` or `spawn_agent`.
   - Workflows rely on a strict **Handover Protocol**: Brief -> Specialized Action -> Summary/Artifact -> Orchestrator Review & Integration Check.
3. **Graph-Based & Stateful (e.g., ClaudeFlow):**
   - Workflows are defined as Directed Acyclic Graphs (DAGs), enabling branching and loops.
   - Combines stateful orchestration with persistent memory (e.g., Hive/Beads) allowing agents to pause and resume work over multiple days without context loss.
4. **Standard Operating Procedure (SOP) Driven (e.g., MetaGPT, ChatDev):**
   - Simulates a traditional software company using sequential chains (Design -> Code -> Test).
   - Mandates **Structured Outputs** (PRD, System Design) at checkpoints to significantly reduce LLM hallucinations by anchoring thoughts in documents.
5. **Conversational Swarm (e.g., AutoGen):**
   - A flexible framework where agents (LLMs, tools, or humans) debate solutions iteratively. Best suited for non-linear, open-ended problem solving.

### 1.2 Scaling and Enterprise Reliability (1M+ Files)

Successfully scaling these systems for massive codebases requires specific architectural pillars:
- **Model Context Protocol (MCP):** Connects agents to datasets and tools without loading the entire codebase into context. Acts as the "USB-C for AI".
- **Stateful Orchestration & Hive Memory:** Centralized storage of project state (e.g., CASS, Beads) to ensure agents retain context and architectural decisions across long-running iterations.
- **Self-Healing QA:** Autonomous generation of spec-to-test suites, with built-in mechanics to monitor and automatically refactor test code or infrastructure when deviations (e.g., UI shifts) occur.

### 1.3 Mapping Models to Claude Code Primitives

Each orchestration model maps to specific Claude Code extension features:

| Architecture Model | Claude Code Primitive | Implementation |
|:-------------------|:---------------------|:---------------|
| QWD / Hierarchical | **SubAgents** (`.claude/agents/`) | Queen = Lead agent, Workers = SubAgents with restricted `tools`, Drones = `model: haiku` subagents |
| Boomerang / Dynamic | **SubAgents** with `Agent()` tool | Orchestrator spawns via `Agent(worker-name)`, receives summary on completion |
| Parallel Execution | **Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) | Lead coordinates Teammates with shared task list |
| SOP-Driven Pipeline | **Skills** (`.claude/skills/`) + **Headless** (`claude -p`) | Each SOP step is a Skill or headless invocation chained via bash |
| Blackboard / Shared State | **File system** + **SubAgent memory** (`memory: project`) | Agents read/write to shared `memory/` directory |

## 2. Skill Definition: Native CLI MAS Architect

The following is an executable skill definition designed to implement the above concepts natively in Claude Code. It uses Claude Code's official extension model — SubAgents, Skills, Hooks, and Agent Teams — instead of external SDKs (LangGraph, Google ADK, CrewAI).

> **Note:** This skill should be extracted into `.claude/skills/mas-architect/SKILL.md` when moving from research to implementation.

### STEP 1: Assessment & CLI Constraint Check

Before scaffolding any multi-agent workflow, evaluate if the task genuinely requires splitting into sub-agents.

- **Tool Density Ceiling**: A single agent's reasoning degrades when managing more than 10-15 tools. If the CLI workflow requires extensive specialized tool usage (e.g., database querying, web searching, plus deep code refactoring), split the task.
- **Sequential vs. Parallel Penalty**: Multi-agent architectures can boost performance on parallelizable tasks by up to 80.9%. However, on strict sequential reasoning tasks, context fragmentation can actually degrade performance by 39% to 70%. Ensure the workflow is appropriately decoupled before distributing it across sub-agents.
- **Claude Code Built-In SubAgents**: Before creating custom agents, check if one of the 3 built-in subagents suffices:

  | Built-In | Model | Tools | Best For |
  |:---------|:------|:------|:---------|
  | **Explore** | Haiku (fast) | Read-only | File discovery, codebase exploration |
  | **Plan** | Inherits | Read-only | Research for planning |
  | **General-purpose** | Inherits | All tools | Complex research, multi-step operations |

### STEP 2: Select a Claude Code Orchestration Pattern

Instead of using external frameworks, construct your workflow using Claude Code's native extension model:

- **Sequential Pipeline via Headless Mode**: Chain SubAgent invocations programmatically using `claude -p`:
  ```bash
  # Step 1: Architect produces design
  claude -p "Read the PRD and produce a technical design" \
    --allowedTools "Read,Grep,Glob,Write" \
    --output-format json > /tmp/step1-design.json
  
  # Step 2: Developer implements from design
  cat /tmp/step1-design.json | jq -r '.result' | \
    claude -p "Implement the feature based on this design: $(cat)" \
    --allowedTools "Read,Write,Edit,Bash"
  ```

- **Supervisor (Orchestrator-Worker)**: Define a Lead SubAgent that spawns Workers:
  ```yaml
  ---
  name: orchestrator
  description: Master Orchestrator that decomposes tasks and spawns specialized agents.
  tools: Read, Grep, Glob, Agent(architect, lead-dev, qa-lead)
  disallowedTools: Write, Edit, Bash
  model: opus
  ---
  
  You are the Master Orchestrator. You NEVER write code directly.
  Your role is to decompose tasks, spawn the appropriate SubAgent, and review results.
  ```

- **Recursive & Dynamic (Boomerang)**: SubAgents are spawned for specific tasks and return a final artifact to the Orchestrator. Use `Agent(worker_name)` in the Orchestrator's `tools` list to restrict which agents it can spawn.

- **Agent Teams (Native Parallel)**: Multiple Claude Code processes with shared task lists and inter-agent messaging:
  ```
  Create an agent team with 3 teammates:
  - One architect teammate to design the API layer
  - One developer teammate to implement the data models
  - One QA teammate to write test plans
  Use Sonnet for each teammate.
  ```

- **Blackboard (Shared File State)**: SubAgents communicate via the `memory/` directory. Use `memory: project` in SubAgent YAML for native persistent memory.

### STEP 3: Scaffold Claude Code SubAgent Definitions

Define SubAgents as `.md` files in `.claude/agents/` with YAML frontmatter:

```yaml
---
name: lead-dev
description: Lead Developer responsible for code implementation and developer sub-agent management.
tools: Read, Write, Edit, Bash, Grep, Glob, Agent(junior-dev)
model: sonnet
maxTurns: 30
permissionMode: acceptEdits
skills:
  - api-conventions
  - error-handling-patterns
memory: project
---

You are the Lead Developer. When assigned a task:
1. Read the technical design document referenced by Universal ID.
2. Plan the implementation — create a brief plan before writing any code.
3. Implement the feature following the project's existing patterns.
4. Run tests via Bash to verify your implementation.
5. Produce a summary artifact for the QA Lead.

## Constraints
- Always cite Universal IDs when referencing requirements.
- Never modify files outside your assigned scope.
- Escalate to the CTO if the implementation requires architectural changes.
```

Key frontmatter fields to leverage:

| Field | Purpose | Example |
|:------|:--------|:--------|
| `tools` | Whitelist allowed tools | `Read, Grep, Glob, Bash` |
| `disallowedTools` | Blacklist specific tools | `Write, Edit` |
| `model` | Cost/capability control | `haiku`, `sonnet`, `opus` |
| `maxTurns` | Prevent infinite loops | `25` |
| `permissionMode` | Automation level | `acceptEdits`, `dontAsk`, `plan` |
| `skills` | Preload domain knowledge | `api-conventions` |
| `memory` | Persistent memory scope | `user`, `project`, `local` |
| `mcpServers` | External tool access | Playwright, GitHub, databases |
| `background` | Non-blocking execution | `true` |
| `isolation` | Git worktree isolation | `worktree` |
| `hooks` | Per-agent lifecycle hooks | See STEP 5 |

### STEP 4: Engineer the Cognitive Loop & Tool Access (MCP)

Every SubAgent must execute a robust internal reasoning loop using available local resources:

- **ReAct (Reason + Act):** Prompt the CLI agents to generate verbal reasoning traces (Thoughts) before executing terminal commands or MCP tool calls (Actions), followed by reading the terminal output (Observations).
- **Tooling via MCP**: Scope MCP servers to specific SubAgents via the `mcpServers` frontmatter field:
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
  ---
  ```

### STEP 5: Implement Multi-Agent Validation & Conflict Resolution via Hooks

Use Claude Code's **Hooks** system to build explicit checkpoints:

- **Executor → Validator → Critic Chain**: Use `PostToolUse` hooks on write operations to trigger validation:
  ```json
  {
    "hooks": {
      "PostToolUse": [{
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "./scripts/run-linter.sh"
        }]
      }],
      "Stop": [{
        "hooks": [{
          "type": "agent",
          "prompt": "Verify all acceptance criteria pass. Run the test suite.",
          "timeout": 120
        }]
      }]
    }
  }
  ```

- **Conflict Resolution (OVADARE Principles)**: Use `PreToolUse` hooks to detect resource competition before writes:
  ```json
  {
    "hooks": {
      "PreToolUse": [{
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "./scripts/check-file-lock.sh"
        }]
      }]
    }
  }
  ```

- **Git Worktree Isolation**: For Agent Teams working in parallel, use `isolation: worktree` in SubAgent YAML to prevent file conflicts entirely.

### STEP 6: Optimize Token Economics & Memory Management

Multi-agent systems can easily consume 15x more tokens than single-agent chats. Manage with Claude Code's native features:

- **Context Isolation**: Never pass the entire CLI chat history to a sub-agent. SubAgents automatically get isolated context windows.
- **Model Selection**: Use `model: haiku` for cost-sensitive, narrow tasks (Drone/Intern tier). Use `model: sonnet` for standard work. Reserve `model: opus` for complex reasoning (Lead/Orchestrator tier).
- **Max Turns**: Set `maxTurns` in SubAgent YAML to hardcode fallback limits. If a ReAct loop iterates beyond this threshold, the subagent gracefully exits.
- **Auto-Compaction**: Claude Code automatically compacts context when it grows too large. Configure with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` (default: 50%).

### STEP 7: MAS Evaluation & RFT

> **Cross-Reference**: The full RFT methodology is documented in [spike-build-agent-rft.md](spike-build-agent-rft.md). Key steps:

1. **Log Analysis**: Capture all execution logs into `logs/iteration/{run-iteration-id}/`.
2. **Alignment Check**: Review `memory/agents/{subagents}.md` against PRDs.
3. **Update SubAgent Definitions**: Modify `.claude/agents/{name}.md` YAML and prompt body.
4. **Use the RFT workflow**: Invoke `/claudecode-agent-rft` to execute the structured improvement process.

---

## 3. Living Organization Architecture

The patterns above describe *how* agents work. This section describes *how agents live together* — the organizational structures that transform a collection of CLI agents into a coherent, self-improving entity that mirrors a real human organization.

### 3.1 Organizational Chart (Org Chart)

Map the MAS to a real company hierarchy. Each agent receives a formal role definition stored in `memory/org/org-chart.md` AND a corresponding SubAgent definition in `.claude/agents/{name}.md`:

```markdown
# Organizational Chart

## C-Suite (Strategic Layer)
- **CEO / Master Orchestrator** — Owns mission, decomposes high-level goals, runs retrospectives
  - Reports to: Human (HITL)
  - Manages: CTO, Product Owner
  - SubAgent: `.claude/agents/orchestrator.md`

## VP Layer (Tactical Layer)
- **CTO / Architect** — Owns technical decisions, selects patterns, reviews architecture
  - Reports to: CEO
  - Manages: Engineering Lead, QA Lead
  - SubAgent: `.claude/agents/cto.md`
- **Product Owner** — Owns PRDs, acceptance criteria, and stakeholder communication
  - Reports to: CEO
  - Manages: BA (Business Analyst) agents
  - SubAgent: `.claude/agents/product-owner.md`

## Director Layer (Operational Layer)
- **Engineering Lead** — Owns code output, spawns developer sub-agents
  - Reports to: CTO
  - Manages: Dev agents (Junior, Senior)
  - SubAgent: `.claude/agents/lead-dev.md`
- **QA Lead** — Owns test plans, validation workflows, release gates
  - Reports to: CTO
  - Manages: QA agents, Critic agents
  - SubAgent: `.claude/agents/qa-lead.md`
```

**Concrete SubAgent YAML examples** for key roles:

**CEO / Orchestrator:**
```yaml
---
name: orchestrator
description: Master Orchestrator. Decomposes goals, manages state, runs retrospectives. NEVER writes code.
tools: Read, Grep, Glob, Agent(cto, product-owner)
disallowedTools: Write, Edit, Bash
model: opus
maxTurns: 40
memory: project
---
```

**QA Lead:**
```yaml
---
name: qa-lead
description: QA Lead. Owns test plans, runs validation workflows, controls release gates.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: sonnet
maxTurns: 25
skills:
  - verify-claudecode-extension
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: "Did you produce a formal sign-off document in docs/tests/? Answer {ok: true/false}."
---
```

The key insight: **authority flows down, artifacts flow up**. A Junior Dev agent cannot override a QA Lead's rejection. The CTO cannot bypass the Product Owner's PRD. This mirrors real organizational governance.

### 3.2 Department Formation

Group agents into functional departments. Each department has:

*   **A Department Head agent** that synthesizes outputs from its members before escalating to the C-Suite.
*   **A shared department memory file** (`memory/org/dept-{name}.md`) tracking active work and decisions.
*   **Clear intake and output contracts** — what artifacts a department accepts as input and produces as output.

**When to form a new department** (trigger rules):
1.  A single agent consistently spawns >3 sub-agents for the same domain across multiple iterations.
2.  Error rates in a specific domain exceed the organizational threshold (>5%), indicating the need for dedicated oversight.
3.  A new PRD introduces a domain that doesn't map to any existing department.

### 3.3 Cross-Department Protocols

Inter-department communication is the #1 source of failure in both human organizations and MAS. Codify strict handoff rules:

| Handoff | Required Artifact | Validation |
|:--------|:-----------------|:-----------|
| Product → Engineering | PRD with Universal IDs, acceptance criteria | CTO reviews for technical feasibility |
| Engineering → QA | Working code + build confirmation | QA Lead verifies testability |
| QA → Engineering | Test report with Universal ID-linked failures | Engineering Lead triages and assigns |
| Engineering → Product | Completed feature artifact | Product Owner validates against PRD |

**Claude Code Implementation**: Use **Hooks** to enforce handoff validation:

*   **SubagentStop hooks**: When a SubAgent completes, validate that the expected output artifact exists:
    ```json
    {
      "hooks": {
        "SubagentStop": [{
          "matcher": "lead-dev",
          "hooks": [{
            "type": "command",
            "command": "./scripts/validate-engineering-handoff.sh"
          }]
        }]
      }
    }
    ```

*   **Escalation Protocol**: If a handoff is rejected twice, the issue escalates to the C-Suite (CEO/Orchestrator) for mediation. The rejection reasons are logged in `memory/org/escalations.md`.
*   **OVADARE Conflict Resolution**: When two departments attempt to modify the same shared file, use `PreToolUse` hooks to detect the conflict. For Agent Teams, use `isolation: worktree` to give each teammate its own git worktree.

### 3.4 Agent Specialization Lifecycle

Agents don't emerge fully formed. They evolve through a structured lifecycle:

```
  [Intern] ──3 clean iterations──→ [Junior] ──7 clean iterations──→ [Senior] ──nomination──→ [Lead]
     ↑                                ↑                                ↑
     └── demotion (2x threshold) ─────┘── demotion (2x threshold) ────┘
```

Each tier maps to concrete SubAgent YAML changes:

*   **Intern**: `tools: Read, Grep` | `model: haiku` | `permissionMode: plan` — output always reviewed by Department Head.
*   **Junior**: `tools: Read, Grep, Glob, Bash` | `model: sonnet` — QA spot-checks 50% of outputs. Begins contributing to `memory/org/best-practices.md`.
*   **Senior**: Full department toolset + cross-dept read | `model: sonnet` — Reviews Intern and Junior outputs. Trusted to self-validate routine tasks.
*   **Lead**: Full toolset + `Agent(*)` | `model: opus` — Can spawn sub-agents, define workflows, and propose updates to `SOUL.md`. Periodic audits only.

### 3.5 Shared Knowledge Base

Beyond individual `memory/agents/{name}.md` files, the organization maintains shared institutional knowledge:

| Resource | Path | Purpose |
|:---------|:-----|:--------|
| **Playbooks** | `memory/org/playbooks/` | Step-by-step procedures for common workflows |
| **Post-Mortems** | `memory/org/post-mortems/` | Root cause analysis of past failures |
| **Best Practices** | `memory/org/best-practices.md` | Accumulated wisdom from successful iterations |
| **Emergent Patterns** | `memory/org/emergent-patterns.md` | Detected coordination patterns not explicitly designed |
| **Glossary** | `memory/org/glossary.md` | Shared vocabulary to prevent semantic ambiguity between agents |

**Claude Code Implementation**: Use SubAgent **Skills preloading** (`skills:` in YAML) to inject relevant playbooks and best practices into agents at spawn time. Create a skill like `.claude/skills/org-knowledge/SKILL.md` that references these shared docs.

The Orchestrator enforces a rule: **before creating a new workflow, every agent must first search the Playbooks directory**. This prevents reinventing solutions and ensures organizational learning accumulates.

### 3.6 Culture Document (SOUL.md)

The `SOUL.md` is a living **rule file** stored at `.agents/rules/SOUL.md`. As a rule (not a SubAgent or Skill), it is automatically injected into every agent's context. It defines the organization's identity:

```markdown
# SOUL.md — Organizational Identity

## Mission
[One sentence: what this MAS exists to accomplish]

## Core Values
1. **Quality Over Speed** — Never ship without QA sign-off.
2. **Traceability** — Every output links back to a Universal ID.
3. **Transparency** — Log all decisions; never silently skip a step.
4. **Ownership** — Each artifact has exactly one responsible agent.
5. **Continuous Improvement** — Every iteration must produce at least one RFT insight.

## Communication Norms
- Handoffs use structured artifacts, never free-text summaries.
- Rejections include specific, actionable reasons with Universal ID references.
- Escalations are not failures — they are governance working correctly.

## Decision Authority
- Strategic: CEO/Orchestrator
- Technical: CTO/Architect
- Quality: QA Lead
- Requirements: Product Owner
```

The `SOUL.md` is updated only during org-level retrospectives (see [spike-build-agent-rft.md](spike-build-agent-rft.md) Phase 6) and requires CEO/Orchestrator approval, mirroring how real organizations treat their founding principles.

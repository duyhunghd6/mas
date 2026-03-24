---
description: Spawn a 7-agent Agile Dev Team (SM, ARCH, QA1, Dev1, Dev2, Dev3, QA2) to run a sprint on an existing codebase. Generates a single copyable Claude Code Agent Team prompt.
---

# /spawn-team — Agile Dev Agent Team

Spawns the 7-agent Scrum team defined in `AGILEDEV-TUTORIAL.md`.
Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

---

## Prerequisites

Before running this workflow, verify:
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set in `.claude/settings.json` `env` block
- Sprint PRD exists at `docs/PRD/sprint-{N}/sprint-backlog.md`
- Definition of Done exists at `docs/PRD/sprint-{N}/dod.md`

---

## Step 1 — Gather Inputs

Ask the user (or extract from context) the following:

| Input | Where to find it |
|:------|:-----------------|
| Sprint PRD path | e.g. `docs/PRD/sprint-1/sprint-backlog.md` |
| Sprint scope (one sentence) | User describes the feature/fix goal |
| Task list (T1, T2, T3) | From `sprint-backlog.md` |
| Dependency graph | From `sprint-backlog.md` (which tasks block which) |
| Model name | User specifies (e.g. `sonnet`, `opus`, `claude-sonnet-4-5`) |

---

## Step 2 — Read Project Context

Read these files before generating the prompt:

// turbo
1. `docs/PRD/sprint-{N}/sprint-backlog.md` — task list, story points, owners
2. `docs/PRD/sprint-{N}/dod.md` — Definition of Done per task
3. `docs/report/architecture-decisions.md` — if it exists (brownfield context)

Extract:
- **T1**: task ID + description + files likely touched + DoD criteria
- **T2**: same
- **T3**: same
- **Dependency order**: e.g. T1 → T2, T3 independent

---

## Step 3 — Generate the Agent Team Prompt

Output **one single fenced code block** (the user copies and pastes this into Claude Code).

Follow the format from `.agents/skills/build-with-claude-code/agile-agent-team/agile-dev-brown-field.md` Step 5.

Fill in all `[PLACEHOLDERS]` with real values extracted in Steps 1–2.

```
Create an agent team with 7 teammates using model [MODEL] to run Sprint [N]: [SPRINT SCOPE].

Prerequisites:
- CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 must be set in .claude/settings.json
- model: [MODEL]

Sprint context (read before spawning):
- docs/PRD/sprint-[N]/sprint-backlog.md — task list and story points
- docs/PRD/sprint-[N]/dod.md — Definition of Done per task
- docs/report/ — existing architecture decisions (if any)

Task dependency order: [T1 → T2, T3 independent / etc.]

Spawn the following 7 teammates:

TEAMMATE SM — Scrum Master:
You are the Scrum Master. Your subagent identity is defined in .agents/agents/sm.md.
Read docs/PRD/sprint-[N]/sprint-backlog.md first.
Assign tasks: T1 → Dev1, T2 → Dev2, T3 → Dev3.
Spawn all 6 teammates immediately with the prompts below.
When QA1 posts test-plan.md, reply "Test plan APPROVED ✅" immediately and broadcast to Dev1/Dev2/Dev3: "Test plan approved. Begin implementation."
Run the bug-fix loop per sm.md rules. Never write code. Max 3 rounds before ARCH escalation.

TEAMMATE ARCH — Software Architect:
You are the Software Architect. Your subagent identity is defined in .agents/agents/arch.md.
Read docs/PRD/sprint-[N]/ and these source files: [list key files for T1, T2, T3].
Produce docs/report/architecture-decisions.md covering: file ownership map, integration points, design constraints.
Do not write production code. Message SM: "ARCH done. architecture-decisions.md ready."

TEAMMATE QA1 — Planning QA:
You are QA1. Your subagent identity is defined in .agents/agents/qa1.md.
Wait for docs/report/architecture-decisions.md to exist.
Read ARCH output + docs/PRD/sprint-[N]/dod.md.
Write docs/tests/test-plan.md: one test case per DoD criterion, exact commands, binary pass/fail.
Do not run tests. Message SM: "QA1 done. test-plan.md ready."

TEAMMATE Dev1:
You are Developer 1. Your subagent identity is defined in .agents/agents/dev1.md.
Wait for SM broadcast: "Test plan approved. Begin implementation."
Own tasks: [T1 — description]. Own files: [file list from ARCH].
Read docs/report/architecture-decisions.md first.
Write unit tests. Message SM: "Dev1 done [T1]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the reported failure, re-run unit tests, message SM.

TEAMMATE Dev2:
You are Developer 2. Your subagent identity is defined in .agents/agents/dev2.md.
Wait for SM broadcast: "Test plan approved. Begin implementation."
Own tasks: [T2 — description]. Own files: [file list from ARCH].
Read docs/report/architecture-decisions.md first.
Write unit tests. Message SM: "Dev2 done [T2]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the reported failure, re-run unit tests, message SM.

TEAMMATE Dev3:
You are Developer 3. Your subagent identity is defined in .agents/agents/dev3.md.
Wait for SM broadcast: "Test plan approved. Begin implementation."
Own tasks: [T3 — description]. Own files: [file list from ARCH].
Read docs/report/architecture-decisions.md first.
Write unit tests. Message SM: "Dev3 done [T3]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the reported failure, re-run unit tests, message SM.

TEAMMATE QA2 — Test Execution:
You are QA2. Your subagent identity is defined in .agents/agents/qa2.md.
On first spawn: run ALL cases from docs/tests/test-plan.md.
Write docs/report/qa-report.md: PASS/FAIL per case, exact error output, repro steps.
Never fix code. Message SM: "QA2 done. [N passed / M failed]. See qa-report.md."
On re-spawn: run ONLY the cases listed in your re-spawn prompt, append results to qa-report.md.
```

---

## Step 4 — Deliver to User

Present the generated prompt block and say:

> **Paste this into Claude Code** (with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` active).
> The SM will spawn all 6 teammates and drive the sprint to completion.

---

## Self-Check Before Delivering

Verify every placeholder is filled — no `[BRACKETS]` remain in the output:

| Check | Must be YES |
|:------|:------------|
| Model name is specified (not `[MODEL]`) | YES |
| Sprint N is filled | YES |
| T1/T2/T3 descriptions are real tasks from the PRD | YES |
| File lists for each Dev come from the PRD/source | YES |
| Dependency order is stated | YES |
| Zero `[PLACEHOLDER]` brackets remain | YES |

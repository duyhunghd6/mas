---
name: spawn-team
description: >
  Spawn a 7-agent Agile Dev Team (SM, ARCH, QA1, Dev1, Dev2, Dev3, QA2) to run
  a sprint on an existing codebase. Generates a single copyable Claude Code Agent
  Team prompt. Use when the user says "spawn team", "/spawn-team", or wants to
  start a sprint with the Agile Dev Agent Team.
argument-hint: "[sprint PRD path] [model]"
disable-model-invocation: true
---

# /spawn-team — Agile Dev Agent Team Sprint

Generates a single, ready-to-paste Claude Code Agent Team prompt for the 7-agent Scrum team.

> **Requires:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.json`

## Reference

- Agent role definitions: `.claude/agents/` (sm, arch, qa1, dev1, dev2, dev3, qa2)
- Brownfield directive: `.agents/skills/build-with-claude-code/agile-agent-team/agile-dev-brown-field.md`

---

## Step 1 — Gather Inputs

Arguments: `$ARGUMENTS` (e.g. `docs/PRD/sprint-1/sprint-backlog.md sonnet`)

Parse:
- **PRD path** — `$ARGUMENTS[0]` or ask the user
- **Model** — `$ARGUMENTS[1]` (default: `sonnet`)

---

## Step 2 — Read Project Context

Read these files (do not skip):

1. The sprint PRD: `[PRD path]/sprint-backlog.md`
2. Definition of Done: `[PRD path]/dod.md`
3. Existing architecture (if any): `docs/report/architecture-decisions.md`

Extract:
- **T1, T2, T3**: task IDs + descriptions + files likely touched + DoD criteria
- **Dependency order**: e.g. `T1 → T2, T3 independent`

---

## Step 3 — Self-Check Before Generating

| # | Check | Must be YES |
|---|---|---|
| 1 | Every teammate reads project docs before acting | YES |
| 2 | SM auto-approves QA1 plan without human input | YES |
| 3 | SM re-spawns (not messages) Dev and QA2 on failure | YES |
| 4 | Zero file ownership conflicts between Dev1/Dev2/Dev3 | YES |
| 5 | Every teammate has a clear "message SM when done" | YES |
| 6 | Output is a single copyable prompt block | YES |
| 7 | Model name is specified (no `[MODEL]` placeholder left) | YES |
| 8 | ARCH outputs to a file all Devs can read | YES |
| 9 | QA2 re-spawn includes exact list of failing test cases | YES |
| 10 | Zero `[PLACEHOLDER]` brackets remain | YES |

---

## Step 4 — Generate the Prompt

Output a **single fenced code block** that the user pastes into Claude Code.

Fill every `[PLACEHOLDER]` with real values from the PRD:

```
Create an agent team with 7 teammates using model [MODEL] to run Sprint [N]: [SPRINT SCOPE].

Requires: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

Sprint context:
- [PRD path]/sprint-backlog.md — task list and story points
- [PRD path]/dod.md — Definition of Done per task
- docs/report/ — existing architecture decisions (if any)

Task dependency order: [T1 → T2, T3 independent / etc.]

Spawn these 7 teammates:

TEAMMATE SM — Scrum Master:
Identity: .claude/agents/sm.md
Read [PRD path]/sprint-backlog.md first.
Assign: T1 → Dev1, T2 → Dev2, T3 → Dev3.
Spawn all 6 teammates immediately.
When QA1 posts test-plan.md: reply "Test plan APPROVED ✅" and broadcast to Dev1/Dev2/Dev3: "Begin implementation."
Bug-fix loop (max 3 rounds): re-spawn failing Dev with exact QA2 failure → re-spawn QA2 with failing cases. After round 3 FAIL → escalate to ARCH.
Never write code.

TEAMMATE ARCH — Software Architect:
Identity: .claude/agents/arch.md
Read [PRD path]/, docs/report/, and source files: [T1 files], [T2 files], [T3 files].
Produce docs/report/architecture-decisions.md: file ownership map, integration points, design constraints.
No production code. Message SM: "ARCH done. architecture-decisions.md ready."

TEAMMATE QA1 — Planning QA:
Identity: .claude/agents/qa1.md
Wait for docs/report/architecture-decisions.md.
Read ARCH output + [PRD path]/dod.md.
Write docs/tests/test-plan.md: one test case per DoD criterion, exact CLI commands, binary pass/fail.
No tests. Message SM: "QA1 done. test-plan.md ready."

TEAMMATE Dev1:
Identity: .claude/agents/dev1.md
Wait for SM: "Begin implementation."
Tasks: [T1 — description]. Files: [T1 file list].
Read docs/report/architecture-decisions.md first. Write unit tests.
Message SM: "Dev1 done [T1]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the listed failure, re-run tests, message SM.

TEAMMATE Dev2:
Identity: .claude/agents/dev2.md
Wait for SM: "Begin implementation."
Tasks: [T2 — description]. Files: [T2 file list].
Read docs/report/architecture-decisions.md first. Write unit tests.
Message SM: "Dev2 done [T2]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the listed failure, re-run tests, message SM.

TEAMMATE Dev3:
Identity: .claude/agents/dev3.md
Wait for SM: "Begin implementation."
Tasks: [T3 — description]. Files: [T3 file list].
Read docs/report/architecture-decisions.md first. Write unit tests.
Message SM: "Dev3 done [T3]. Unit tests pass."
Bug-fix: read qa-report.md, fix only the listed failure, re-run tests, message SM.

TEAMMATE QA2 — Test Execution:
Identity: .claude/agents/qa2.md
First spawn: run ALL cases from docs/tests/test-plan.md.
Write docs/report/qa-report.md: PASS/FAIL per case, exact errors, repro steps.
Never fix code. Message SM: "QA2 done. [N passed / M failed]. See qa-report.md."
Re-spawn: run ONLY listed failing cases, append results to qa-report.md.
```

---

## Step 5 — Deliver

Present the prompt and say:

> Paste this into Claude Code (with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` active).  
> SM will spawn all 6 teammates and drive the sprint to DONE ✅.

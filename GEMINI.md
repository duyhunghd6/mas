# Project Purpose

This project provides a Basic Multi-Agent System (MAS) Architecture. It is designed to act as a step-by-step guidance repository for the online seminar of GSCfin.

## Directory Structure

To guide AI Agents seamlessly and consistently working on this project, the following directory structure is enforced:

- `docs/PRD/`: Stores Product Requirement Documents.
- `docs/report/`: Stores analysis and status reports.
- `docs/tests/`: Stores all test plans and QA verification documents.
- `logs/iteration/{run-iteration-id}/`: Stores execution and communication logs per iteration run.
- `memory/agents/{subagents}.md`: Stores context and states for individual `{subagents}`.
- `memory/{task,progress,plan}.md`: Stores the centralized Master Orchestrator state.
- `.agents/rules/`: Stores required Agent Rules like Git formatting, Agent identities, and Universal IDs.
- `.agents/workflows/`: Stores executable AI workflows like Agent RFT and Verification tests.

## Objectives
- Demonstrate a simple and general Multi-Agent System orchestration.
- Provide a clear directory structure for documentation (PRDs, reports, tests), logs, and agent memory.
- Act as the reference implementation built by Antigravity to be run with Claude Code.

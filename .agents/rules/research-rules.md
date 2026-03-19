---
trigger: glob
glob: docs/researches/spikes/**
description: Research rules following SAFe 6.0 Continuous Exploration — Spike-based research, 4-activity CE cycle. Activates only when editing files under docs/researches/spikes/.
---

# 📋 Research Rules — SAFe 6.0 Continuous Exploration

## Core Principle

> **Research = Spikes.** Every research session (whether 1 or 100) produces exactly 1 Spike Report.
> Spikes accumulate knowledge → synthesized into PRDs in Activity D (Synthesize).
> Spikes do NOT require individual Human approval — approval is only needed after Synthesize is complete.

---

## 1. Spike Report — Per Research Session

Each time you conduct **a research session** (Activity B: Collaborate & Research), create a file at:

```
./docs/researches/spikes/spike-{topic}.md
```

The filename should briefly describe the research topic (kebab-case).

### Spike Report Structure

```markdown
# Spike: [Topic]

**Beads ID:** bd-xxx (spike task)
**Author:** [Agent role / Human]
**Phase:** Continuous Exploration — Activity B (Collaborate & Research)

## Hypothesis

- The hypothesis to validate through this spike

## Research Sessions

### Session 1 (YYYY-MM-DD)

**Findings:**

- Results from session 1

**Open Items:**

- Questions to continue investigating → Session 2

### Session 2 (YYYY-MM-DD)

**Findings:**

- Additional findings from session 2

**Open Items:**

- (If remaining → Session 3, if resolved → move to Recommendation)

## Recommendation

- Specific recommendations based on synthesis of all sessions

## Decision (if agreed with Human)

- Decision + Rationale (record as ADR if it is an architectural decision)

## Open Items → Next Spikes

- Unresolved questions → create new spike: `bd create "Spike: ..." --type=spike`
```

### Spike Workflow

```bash
# 1. Create a Spike task in Beads (once per research session)
bd create "Spike: Evaluate FrankenSQLite vs DoltDB" --type=spike

# 2. Research → write the spike report
# → docs/researches/spikes/spike-frankensqlite-vs-doltdb.md

# 3. Close the spike when done
bd close <spike-id>
```

> 💡 **Hundreds of spikes is normal.** If you need 100 research sessions before writing a PRD →
> create 100 spike reports. Each spike is lightweight, requires no individual approval, and accumulates gradually.

---

## 2. Read Existing Spikes Before Starting a New One

**BEFORE** beginning any new spike, the agent **MUST**:

1. **Read all previous Spike Reports** (at minimum the Findings/Recommendation sections)
2. **Synthesize context** from prior spikes to avoid duplicating work
3. **Check Open Items** from previous spikes → convert them into hypotheses for the new spike

```bash
# List existing spike reports
ls ./docs/researches/spikes/

# Read findings from most recent spikes
cat ./docs/researches/spikes/spike-*.md
```

> ⚠️ **WARNING:** Skipping the spike-reading step → agent will repeat prior research, wasting tokens and time. This is a process violation.

---

## 3. Clear Phase Separation — NO code implementation during CE

Per SAFe 6.0, Continuous Exploration consists of 4 activities:

| Activity                      | SAFe Name           | Who Executes    | Output                                          |
| ----------------------------- | ------------------- | --------------- | ----------------------------------------------- |
| **A. Hypothesize**            | Value Hypothesis    | Human + PMO     | Epic Hypothesis Statement (Beads Epic)          |
| **B. Collaborate & Research** | Market Research     | PMO             | `docs/researches/spikes/*.md`                   |
| **C. Architect**              | Architecture Runway | Architect       | `Architecture.md`, ADRs                         |
| **D. Synthesize**             | Feature Definition  | PMO + Architect | `Vision.md`, PRDs, ART Backlog (Beads Features) |

> 🔴 **RULE:** During the Continuous Exploration phase, the agent **MUST NOT** write implementation code. Only the following are permitted:
>
> - Writing Spike Reports (research)
> - Writing PRD / Vision / Architecture docs
> - Creating Beads epics/tasks/spikes for the backlog
> - Analyzing reference code (read-only, no modifications)
> - Creating diagrams, mockups, ADRs

---

## 4. CE Definition of Done

The CE Phase is complete when **ALL** of the following criteria are met:

- [ ] Vision.md written and Human reviewed
- [ ] At least 1 PRD written
- [ ] Architecture.md draft exists (if applicable)
- [ ] ART Backlog has ≥ 1 Epic with Features decomposed
- [ ] Spike reports for research are closed (`bd close`)
- [ ] Human has **approved** the transition to PI Planning Phase

> 💡 **Principle:** "Agents propose, Humans approve." — Phase transition = Level 3 Human Decision Required.
> Human approval is only needed **once** at the end of CE (after Synthesize), NOT after each spike.

---

## 5. Naming Convention

| Artifact           | Path                                        | Example                            |
| ------------------ | ------------------------------------------- | ---------------------------------- |
| Spike Report       | `./docs/researches/spikes/spike-{topic}.md` | `spike-frankensqlite-vs-doltdb.md` |
| Research Reference | `./docs/researches/*.md`                    | `FastCode-Integration-Research.md` |
| PRD                | `./docs/PRDs/PRD-XX-*.md`                   | `PRD-01-Overview.md`               |
| Architecture       | `./docs/architecture/Architecture.md`       | —                                  |
| ADR                | `./docs/architecture/adr/ADR-XXX-*.md`      | `ADR-001-storage-choice.md`        |
| Vision             | `./docs/requirements/Vision.md`             | —                                  |

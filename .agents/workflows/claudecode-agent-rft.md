---
description: Claude Code Agent Reinforcement Fine-Tuning (RFT) Workflow
---

# Agent Reinforcement Fine-Tuning (RFT)

<!-- workflow:rft:agent-finetuning-cycle -->

This workflow implements a 4-phase RFT cycle to continuously improve agent quality. Execute this after accumulating session logs from `/chat` runs.

When executing this workflow, use `{run-iteration-id}` to identify which session(s) to analyze. If not specified, analyze **all** sessions in `logs/iteration/`.

---

## Phase 1: Collect — Gather Session Traces

<!-- workflow:rft:phase-1-collect -->

1. List all available session logs:
   ```bash
   ls -la logs/iteration/
   ```

2. For a specific run, read the full session trace:
   ```bash
   cat logs/iteration/{run-iteration-id}/session.md
   ```

3. If analyzing multiple sessions, read all of them to identify patterns:
   ```bash
   for d in logs/iteration/*/; do echo "=== $d ==="; cat "$d/session.md" 2>/dev/null; done
   ```

4. Collect the set of (question, intent, answer, validation, final_result) tuples from each session.

---

## Phase 2: Score — Rate Agent Quality

<!-- workflow:rft:phase-2-score -->

For **each session trace**, score every agent on these criteria:

### Analyzer Scoring

| Criterion | Score (1-5) | Check |
|:----------|:-----------|:------|
| Intent accuracy | _ | Does the intent correctly capture what the user asked? |
| Keyword relevance | _ | Are the keywords useful for searching the knowledge base? |
| Completeness | _ | Did the Analyzer miss any aspect of the question? |

### Librarian Scoring

| Criterion | Score (1-5) | Check |
|:----------|:-----------|:------|
| Search coverage | _ | Did the Librarian search all relevant files in `docs/knowledge/`? |
| Answer accuracy | _ | Is the answer factually correct per the knowledge base? |
| No fabrication | _ | Does the answer contain ONLY information from the knowledge base? |
| Proper NOT_FOUND | _ | If info was missing, did the Librarian correctly report NOT_FOUND? |

### Validator Scoring

| Criterion | Score (1-5) | Check |
|:----------|:-----------|:------|
| Verification thoroughness | _ | Did the Validator check every claim against the knowledge base? |
| Correct verdict | _ | Is the PASS/REJECT decision correct? |
| False positive catch | _ | If the answer had fabricated info, did the Validator REJECT? |

Write the score card to `logs/iteration/{run-iteration-id}/scorecard.md`:

```markdown
# Score Card: {run-iteration-id}

## Analyzer: [total]/15
- Intent accuracy: [1-5]
- Keyword relevance: [1-5]  
- Completeness: [1-5]

## Librarian: [total]/20
- Search coverage: [1-5]
- Answer accuracy: [1-5]
- No fabrication: [1-5]
- Proper NOT_FOUND: [1-5]

## Validator: [total]/15
- Verification thoroughness: [1-5]
- Correct verdict: [1-5]
- False positive catch: [1-5]

## Overall: [total]/50
## Issues Found:
- [list specific issues]
```

---

## Phase 3: Improve — Update Subagent Prompts

<!-- workflow:rft:phase-3-improve -->

Based on the score card, update the subagent prompts to fix identified gaps:

1. Read current subagent definitions:
   ```bash
   cat .claude/agents/analyzer.md
   cat .claude/agents/librarian.md
   cat .claude/agents/validator.md
   ```

2. For each issue found in Phase 2, determine which subagent needs improvement:

   | Issue Type | Target Agent | Fix Strategy |
   |:-----------|:-------------|:-------------|
   | Poor intent extraction | Analyzer | Add examples, clarify intent categories |
   | Missed knowledge base content | Librarian | Add search strategy instructions |
   | Fabricated information | Librarian | Strengthen "no fabrication" constraints |
   | False PASS (fabrication not caught) | Validator | Add stricter verification checklist |
   | False REJECT (correct answer rejected) | Validator | Add guidance for edge cases |

3. Edit the appropriate `.claude/agents/{agent}.md` file with the improvements.

4. Document changes in `logs/iteration/{run-iteration-id}/improvements.md`:
   ```markdown
   # Improvements: {run-iteration-id}

   ## Changes Made
   - [agent]: [what was changed and why]

   ## Expected Impact
   - [what should improve in the next run]
   ```

---

## Phase 4: Verify — Re-run and Compare

<!-- workflow:rft:phase-4-verify -->

1. Extract the original questions from the analyzed sessions:
   ```bash
   grep "## Question" logs/iteration/{run-iteration-id}/session.md -A 2
   ```

2. Re-run each question through `/chat`:
   ```
   /chat [original question from session]
   ```

3. Compare the new session trace against the previous one:
   - Did the issues from Phase 2 get resolved?
   - Did any new issues appear (regression)?

4. If scores improved → commit the changes. If not → return to Phase 3.

5. Write the verification result to `logs/iteration/{run-iteration-id}/verification.md`:
   ```markdown
   # Verification: {run-iteration-id}

   ## Re-run Results
   | Question | Before Score | After Score | Status |
   |:---------|:------------|:-----------|:-------|
   | [question] | [old]/50 | [new]/50 | ✅ Improved / ❌ Regressed |

   ## Decision
   - [ ] Commit improvements
   - [ ] Return to Phase 3
   ```

---

## Quick Reference

```
/claudecode-agent-rft {run-iteration-id}

Phase 1: Collect  → Read logs/iteration/{run-iteration-id}/session.md
Phase 2: Score    → Write logs/iteration/{run-iteration-id}/scorecard.md
Phase 3: Improve  → Edit .claude/agents/{agent}.md
Phase 4: Verify   → Re-run questions, write verification.md
```

---
trigger: always_on
glob: "**/*.md"
description: Universal ID Rules for Document Linking
---

# Universal ID System

All PRD documents, test plans, and architectural Markdown documents MUST utilize Universal IDs to facilitate loose-coupled linking and step-by-step matching.

## ID Format
The required format is:
`{type}:{section}:{component-name}`

- **type**: The kind of document (e.g., `prd`, `plan`, `workflow`, `test-plan`).
- **section**: The specific section or step in the entity (e.g., `init-step`, `subagent-ba`).
- **component-name**: The smallest logical unit or ticket/task/commit ID (e.g., `create-prj-dir`, `read-doc-step01`).

*Example*: `test-plan:subagent-ba:read-doc-step01`

## Implementation
- Each section inside a PRD or equivalent document must specify its Universal ID clearly.
- For `*.md` files, the smallest entity ID should be placed in the YAML metadata (frontmatter) and must correspond precisely to a ticketID, taskID, or commitID within the system.
- State the ID clearly so it is appropriately sized (not too macro-level, not excessively micro-level) to maintain traceability.
- Use these Universal IDs across the project to maintain loose-coupling from requirements through execution and testing.

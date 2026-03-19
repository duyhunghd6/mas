---
name: build-with-claude-code
description: >
  Expert skill for building with Claude Code. Use when the user asks to create
  subagents, agent teams, plugins, skills, hooks, output styles, scheduled tasks,
  headless/programmatic usage, MCP integrations, or troubleshoot Claude Code issues.
  Also use when the user asks "how do I extend Claude Code?" or wants to understand
  Claude Code's architecture, best practices, and extension patterns.
---

# Build with Claude Code

You are an expert at building with Claude Code. This skill covers the full Claude Code extension and automation ecosystem.

## Reference Documentation

The `reference/` directory contains comprehensive documentation for all major Claude Code features. **Always consult the relevant reference file before answering questions or implementing solutions.**

| Feature | Reference File | When to Use |
|:--------|:---------------|:------------|
| **Subagents** | [sub-agents.md](reference/sub-agents.md) | Creating specialized AI agents within a session |
| **Agent Teams** | [agent-teams.md](reference/agent-teams.md) | Orchestrating multiple Claude Code instances in parallel |
| **Plugins** | [plugins.md](reference/plugins.md) | Creating distributable extension packages |
| **Discover Plugins** | [discover-plugins.md](reference/discover-plugins.md) | Finding, installing, and managing plugins from marketplaces |
| **Skills** | [skills.md](reference/skills.md) | Creating reusable slash commands and workflows |
| **Scheduled Tasks** | [scheduled-tasks.md](reference/scheduled-tasks.md) | Running prompts on a schedule or setting reminders |
| **Output Styles** | [output-styles.md](reference/output-styles.md) | Customizing Claude Code's communication style |
| **Hooks** | [hooks-guide.md](reference/hooks-guide.md) | Automating workflows with lifecycle event handlers |
| **Headless / API** | [headless.md](reference/headless.md) | Running Claude Code programmatically (CLI, Python, TypeScript) |
| **MCP** | [mcp.md](reference/mcp.md) | Connecting to external tools via Model Context Protocol |
| **Troubleshooting** | [troubleshooting.md](reference/troubleshooting.md) | Solving installation, auth, performance, and IDE issues |

## Decision Matrix: Choosing the Right Extension Type

| Goal | Recommended Approach |
|:-----|:---------------------|
| Add a reusable workflow or command | **Skill** (`.claude/skills/`) |
| Create a focused helper agent | **Subagent** (`.claude/agents/`) |
| Run multiple agents in parallel | **Agent Team** |
| Share extensions across projects | **Plugin** (`.claude-plugin/`) |
| Auto-format, validate, or notify | **Hook** (`settings.json`) |
| Run commands on a timer | **Scheduled Task** (`/loop`) |
| Change how Claude communicates | **Output Style** |
| Connect to external APIs/tools | **MCP Server** |
| Run Claude in CI/CD pipelines | **Headless Mode** (`-p`) |

## Workflow

1. **Identify** the right extension type using the decision matrix
2. **Read** the relevant reference file for detailed instructions
3. **Implement** following the documented patterns and examples
4. **Test** using the verification methods described in each reference
5. **Share** via plugins or version control as appropriate

## Critical Rules

1. **Always read the reference file** before implementing — don't guess at file formats or configurations
2. **Skills use SKILL.md with YAML frontmatter** — this is the required format
3. **Subagents run in isolated contexts** — they don't share the main conversation's history
4. **Hooks communicate via stdout/stderr/exit codes** — exit 0 to proceed, exit 2 to block
5. **Plugins are namespaced** — `plugin-name:skill-name` to avoid conflicts
6. **Agent teams are experimental** — requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
7. **Headless mode uses `-p` flag** — combine with `--allowedTools` for automation
8. **MCP servers have scopes** — local, project, or user level

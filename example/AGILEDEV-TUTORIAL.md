---
id: tutorial:mas:agile-dev-agent-team
description: Hướng dẫn xây dựng Agile Dev Agent Team bằng Claude Code — đội 7 agent chạy sprint để phát triển hệ thống MAS Chat Bot hỏi đáp.
---

# TUTORIAL: Agile Dev Agent Team — Xây Hệ Thống MAS Chat Bot

> **MAS = Phần mềm (Agile Dev) + Mô phỏng Nghiệp vụ (Org Simulation)**
>
> Tutorial này dạy mặt **Agile Dev** của MAS — cách tổ chức đội 7 agent
> Claude Code để phát triển hệ thống chat bot hỏi đáp theo sprint, tuân
> thủ ground-truth từ `GEMINI.md` và cấu trúc `docs/` của dự án.

---

## 1. Bài Toán

Xây một **hệ thống MAS Chat Bot hỏi đáp** với các điều kiện tiên quyết:

- Chat bot chỉ trả lời từ kho tài liệu được cung cấp — **tuyệt đối không bịa thông tin**.
- Nếu không tìm thấy → phản hồi: **"KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"**.
- Hệ thống gồm **3 agent nghiệp vụ** chạy lúc production:

```
┌──────────────────────────────────────────────────────────────┐
│             HỆ THỐNG CẦN XÂY (3 AGENT NGHIỆP VỤ)            │
│                                                              │
│   /chat "Câu hỏi?"                                           │
│        │                                                     │
│        ├─ ANALYZER  → phân tích câu hỏi, lấy intent         │
│        │              Tools: Read, Grep, Glob                │
│        │                                                     │
│        ├─ LIBRARIAN → tìm kho local + web (CDP port 9222)   │
│        │              Tools: Read, Grep, Glob, Bash          │
│        │                                                     │
│        └─ VALIDATOR → kiểm tra chéo, PASS hoặc REJECT       │
│                       Tools: Read, Grep, Glob, Bash          │
│                                                              │
│   QUY TẮC VÀNG:                                              │
│   Không tìm thấy = "KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"     │
│   Tuyệt đối KHÔNG bịa thông tin                              │
│   Validator REJECT = không bao giờ gửi cho khách             │
└──────────────────────────────────────────────────────────────┘
```

**Sprint goal:** Giao toàn bộ codebase trên mà không cần code thủ công.

```
DELIVERABLES SAU SPRINT:
  .claude/agents/analyzer.md      ← Subagent phân tích câu hỏi
  .claude/agents/librarian.md     ← Subagent tìm kho tài liệu
  .claude/agents/validator.md     ← Subagent kiểm tra chéo
  .claude/skills/chat/SKILL.md    ← /chat pipeline orchestrator
  tools/browse_knowledge.py       ← CDP browser tool (argparse CLI)
  .claude/settings.json           ← Hooks config (Stop → log-session)
  scripts/log-session.sh          ← Hook script → logs/iteration/{id}/
  docs/tests/test-plan.md         ← Bộ test cases (do QA1 viết)
  docs/report/architecture-decisions.md  ← ARCH output
  docs/report/qa-report.md        ← QA2 output
```

---

## 2. MAS = Phần Mềm + Mô Phỏng Nghiệp Vụ

```
┌──────────────────────────────────────────────────────────────────┐
│                 AGILE DEV AGENT TEAM — MAS BUILDER               │
│                                                                  │
│  ┌─────────────────────────┐     ┌────────────────────────────┐  │
│  │  PHẦN MỀM (Agile Dev)   │     │  MÔ PHỎNG NGHIỆP VỤ        │  │
│  │                         │  +  │  (Org Simulation)          │  │
│  │  Đội 7 agent xây code   │     │  3 agent chạy production   │  │
│  │  Sprint workflow        │     │  Analyzer→Librarian→Valid. │  │
│  │  GEMINI.md là SSOT      │     │  Return-value chaining     │  │
│  └─────────────────────────┘     └────────────────────────────┘  │
│                                                                  │
│  Công cụ: Claude Code + CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Đội Hình: 7 Agent

```
┌──────────────────────────────────────────────────────────────────┐
│                        ĐỘI HÌNH 7 AGENT                          │
│                                                                  │
│         ┌──────────┐                                             │
│         │    SM    │  ← Scrum Master, điều phối, KHÔNG code      │
│         └────┬─────┘                                             │
│              │ spawn tất cả                                       │
│   ┌──────────┼────────────┐                                      │
│   ▼          ▼            ▼                                      │
│ ┌──────┐  ┌──────┐  ┌──────────────────────────┐                │
│ │ ARCH │  │ QA1  │  │  Dev1 │  Dev2  │  Dev3   │                │
│ │      │  │      │  │ agent │  tools │  cfg &  │                │
│ │ thiết│  │ test │  │ files │  skill │  hooks  │                │
│ │  kế  │  │ plan │  └──┬───┴───┬────┴────┬────┘                │
│ └──────┘  └──────┘     │       │         │                      │
│                         └───────┴─────────┘                     │
│                                 │ "DevN done"                    │
│                              ┌──▼───┐                           │
│                              │ QA2  │  ← chạy tests, KHÔNG code  │
│                              └──────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

### Chi Tiết Từng Agent

| Agent | Vai trò | Code? | Output chính |
|:------|:--------|:-----:|:-------------|
| **SM** | Điều phối sprint, không code | ❌ | Broadcast, task assignment |
| **ARCH** | Đọc GEMINI.md + docs/, thiết kế file ownership | ❌ | `docs/report/architecture-decisions.md` |
| **QA1** | Đọc ARCH output + PRD/DoD, viết test plan | ❌ | `docs/tests/test-plan.md` |
| **Dev1** | Viết 3 agent files (analyzer, librarian, validator) | ✅ | `.claude/agents/*.md` |
| **Dev2** | Viết CDP tool + /chat skill | ✅ | `tools/browse_knowledge.py`, `.claude/skills/chat/SKILL.md` |
| **Dev3** | Viết hooks config + log script | ✅ | `.claude/settings.json`, `scripts/log-session.sh` |
| **QA2** | Chạy test plan, viết qa-report | ❌ | `docs/report/qa-report.md` |

---

## 4. Sprint Pipeline

```
  START: Paste prompt vào Claude Code → SM khai mạc sprint
         │
         ▼
  ┌──────────────────────────────────────────────────────────┐
  │  SM                                                      │
  │  Đọc GEMINI.md → spawn 6 teammates → giao task          │
  │  T1 → Dev1  │  T2 → Dev2  │  T3 → Dev3                 │
  └──────┬───────────────────────────────────────────────────┘
         │ spawn all
         ▼
  ┌──────────────────────────────────────────────────────────┐
  │  ARCH                                                    │
  │  Đọc GEMINI.md, docs/, .claude/ hiện tại               │
  │  → docs/report/architecture-decisions.md                 │
  │    (file ownership, integration points, design rules)    │
  │  Nhắn SM: "ARCH done"                                   │
  └──────┬───────────────────────────────────────────────────┘
         ▼
  ┌──────────────────────────────────────────────────────────┐
  │  QA1                                                     │
  │  Đọc ARCH output + GEMINI.md + docs/PRD/                 │
  │  → docs/tests/test-plan.md                               │
  │    (test case/DoD criterion, command cụ thể, pass/fail)  │
  │  Nhắn SM: "QA1 done"                                    │
  └──────┬───────────────────────────────────────────────────┘
         │ SM: "APPROVED ✅" → broadcast "Begin implementation"
         ▼
  ┌───────────────────────────────────────────────────────┐
  │  Dev1 (song song)    Dev2 (song song)   Dev3 (song song)│
  │  .claude/agents/     tools/ + skills/   settings + hook│
  │  analyzer.md         browse_knowledge   settings.json  │
  │  librarian.md        .py (CDP CLI)      log-session.sh │
  │  validator.md        chat/SKILL.md      logs/iteration/ │
  │  → unit test         → python -c import → bash syntax  │
  │  → nhắn SM          → nhắn SM          → nhắn SM      │
  └─────────────────────────────┬─────────────────────────┘
                                 │ "DevN done"
                                 ▼
  ┌──────────────────────────────────────────────────────────┐
  │  QA2                                                     │
  │  Chạy test-plan.md                                       │
  │  → docs/report/qa-report.md (PASS/FAIL + repro steps)   │
  │  Nhắn SM: "N passed / M failed"                         │
  └──────┬───────────────────────────────────────────────────┘
         │
    ┌────┴──────────────────────────────────────────────┐
    ▼                                                   ▼
 PASS 100%                                          FAIL
 Sprint DONE ✅                    SM re-spawn Dev bị lỗi
                                   Dev fix → nhắn SM
                                   SM re-spawn QA2 (case lỗi)
                                   Lặp đến zero failures
```

---

## 5. Giao Tiếp Giữa Các Agent

```
┌───────────────────────────────────────────────────────────────┐
│                AGENT TEAM COMMUNICATION MODEL                  │
│                                                               │
│  SM ──broadcast──→ Dev1/Dev2/Dev3:                            │
│     "Test plan approved. Begin implementation."               │
│                                                               │
│  Dev1 ──message──→ SM: "Dev1 done [T1]. Agent files ready."  │
│  Dev2 ──message──→ SM: "Dev2 done [T2]. Tool and skill ready."│
│  Dev3 ──message──→ SM: "Dev3 done [T3]. Config and hook ready"│
│                                                               │
│  SM ──spawn──→ QA2: "Run all cases from test-plan.md."       │
│  QA2 ──message──→ SM: "3 passed / 1 failed. See qa-report." │
│                                                               │
│  [Bug-fix]                                                    │
│  SM ──re-spawn──→ Dev2: "Fix: browse_knowledge.py import err"│
│  Dev2 ──message──→ SM: "Fixed. Syntax check passes."         │
│  SM ──re-spawn──→ QA2: "Re-run case TC-02 only."             │
│                                                               │
│  File là kênh giao tiếp bền vững:                             │
│  architecture-decisions.md → tất cả Devs đọc                 │
│  test-plan.md → QA2 chạy                                      │
│  qa-report.md → SM điều phối bug-fix                          │
└───────────────────────────────────────────────────────────────┘
```

---

## 6. Ready-to-Paste Prompt

Kích hoạt trước:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Paste toàn bộ block sau vào Claude Code:

```
Create an agent team with 7 teammates using model sonnet to build
the MAS QA Chatbot system — a 3-agent pipeline (Analyzer, Librarian,
Validator) that answers questions strictly from a knowledge base, with
zero hallucination tolerance.

Prerequisites:
- CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 must be set
- model: sonnet

Ground truth — every teammate reads these FIRST, before any action:
- GEMINI.md (or CLAUDE.md) — project directory rules, agent identity,
  universal ID format, git commit format, tool-writing rules
- docs/PRD/ — Product Requirement Documents and Definition of Done
- docs/researches/spikes/ — technical spikes (verify against source)

Task breakdown:
- T1 (Dev1): .claude/agents/analyzer.md, librarian.md, validator.md
    → 3 subagent files with correct YAML frontmatter
    → Analyzer: tools: Read, Grep, Glob — extracts intent + keywords
    → Librarian: tools: Read, Grep, Glob, Bash — searches local docs
      AND web via tools/browse_knowledge.py (CDP port 9222)
    → Validator: tools: Read, Grep, Glob, Bash — cross-checks answer
      against source; emits PASS or REJECT
- T2 (Dev2): tools/browse_knowledge.py + .claude/skills/chat/SKILL.md
    → browse_knowledge.py: argparse CLI, connects CDP on port 9222,
      fetches web knowledge when called by Librarian/Validator via Bash
    → chat/SKILL.md: /chat skill — orchestrates the pipeline using
      return-value chaining: Analyzer → Librarian → Validator;
      only sends answer when Validator emits PASS;
      sends "KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN" on REJECT or miss
- T3 (Dev3): .claude/settings.json + scripts/log-session.sh
    → settings.json: Stop hook pointing to scripts/log-session.sh
    → log-session.sh: appends session metadata to
      logs/iteration/{run-id}/session.md (creates dir if needed)

Dependency order:
- ARCH and QA1 run immediately after spawn (parallel, no code deps)
- Dev1, Dev2, Dev3 run in parallel after SM broadcasts approval
- T2 (browse_knowledge.py) must be committed before Dev1 writes
  librarian.md (ARCH documents this constraint)
- QA2 runs after all Devs report done

Spawn the following 7 teammates:

TEAMMATE SM — Scrum Master:
You are the Scrum Master. Read GEMINI.md first. Never write code.
Spawn these 6 teammates immediately with the prompts below.
Assign: Dev1 → T1, Dev2 → T2, Dev3 → T3.
When QA1 posts docs/tests/test-plan.md, immediately reply
"Test plan APPROVED ✅" and broadcast to Dev1/Dev2/Dev3:
"Test plan approved. Begin implementation."
Bug-fix loop: on QA2 failure report → re-spawn the failing Dev
with the exact test case failure text → after Dev confirms fix,
re-spawn QA2 with only that failing case → repeat until zero
failures → mark sprint DONE.

TEAMMATE ARCH — Software Architect:
Read GEMINI.md, docs/PRD/, docs/researches/, .claude/ (current state).
Produce docs/report/architecture-decisions.md covering:
  - File ownership: Dev1 owns .claude/agents/; Dev2 owns tools/ and
    .claude/skills/; Dev3 owns .claude/settings.json and scripts/
  - Integration: /chat SKILL.md calls Analyzer subagent first,
    passes returned intent to Librarian subagent, passes returned
    answer to Validator subagent; each call is return-value, stateless
  - Constraint: browse_knowledge.py MUST exist before librarian.md
    references it — Dev2 commits tool before Dev1 writes the Bash call
  - Golden rules (from PRD): no hallucination, Validator REJECT
    means the answer is never sent to the user
  - Tool-writing rules from GEMINI.md apply to browse_knowledge.py
    (argparse, universal ID tags, FrankenSQLite if state needed)
Do not write production code. Message SM: "ARCH done."

TEAMMATE QA1 — Planning QA:
Wait for ARCH to post docs/report/architecture-decisions.md.
Read GEMINI.md + ARCH output + docs/PRD/.
Write docs/tests/test-plan.md with at minimum:
  TC-01: All 3 agent files exist with valid YAML frontmatter
         command: cat .claude/agents/analyzer.md | grep 'tools:'
         pass: line contains "Read"
  TC-02: browse_knowledge.py is a valid Python CLI
         command: python -c "import ast; ast.parse(open('tools/browse_knowledge.py').read())"
         pass: no exception
  TC-03: /chat SKILL.md exists and references all 3 agents
         command: grep -c "Analyzer\|Librarian\|Validator" .claude/skills/chat/SKILL.md
         pass: count >= 3
  TC-04: Settings hook points to log-session.sh
         command: cat .claude/settings.json | python -c "import sys,json; d=json.load(sys.stdin); print(d['hooks']['Stop'][0]['hooks'][0]['command'])"
         pass: contains "log-session.sh"
  TC-05: log-session.sh is executable and creates log directory
         command: bash -n scripts/log-session.sh
         pass: no syntax error
Do not run tests. Message SM: "QA1 done. test-plan.md ready."

TEAMMATE Dev1 — Agent Files:
Read GEMINI.md, docs/report/architecture-decisions.md first.
Wait for SM broadcast "Begin implementation."
Own T1 — files: .claude/agents/analyzer.md, librarian.md, validator.md
Write each as a Claude Code subagent file (YAML frontmatter + markdown):
  analyzer.md: tools: Read, Grep, Glob; description explains intent extraction
  librarian.md: tools: Read, Grep, Glob, Bash; references tools/browse_knowledge.py
    for web lookup; returns answer text or literal "KHÔNG TÌM THẤY"
  validator.md: tools: Read, Grep, Glob, Bash; cross-checks answer against
    source; returns PASS or REJECT with reason
Tag each file with a universal ID comment per GEMINI.md rules.
Smoke test: grep 'tools:' .claude/agents/*.md (all 3 must respond).
Message SM: "Dev1 done [T1]. Agent files ready."
On re-spawn: apply exact QA2 failure fix only, re-run smoke test, message SM.

TEAMMATE Dev2 — Tools & Skill:
Read GEMINI.md, docs/report/architecture-decisions.md first.
Wait for SM broadcast "Begin implementation."
Own T2 — files: tools/browse_knowledge.py, .claude/skills/chat/SKILL.md
Write tools/browse_knowledge.py:
  - argparse CLI: --url, --query flags
  - Connects to Chrome DevTools Protocol on port 9222
  - Returns page text relevant to query
  - Tag with universal ID per GEMINI.md tool-writing rules
Write .claude/skills/chat/SKILL.md:
  - Triggered by /chat command
  - Step 1: spawn Analyzer subagent → receive intent + keywords
  - Step 2: spawn Librarian subagent with intent → receive answer
  - Step 3: spawn Validator subagent with answer → receive PASS/REJECT
  - On PASS: output answer to user
  - On REJECT or "KHÔNG TÌM THẤY": output "KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"
  - Each step uses return-value chaining (stateless, no shared files)
Syntax check: python -c "import ast; ast.parse(open('tools/browse_knowledge.py').read())"
Message SM: "Dev2 done [T2]. Tool and skill ready."
On re-spawn: apply exact QA2 failure fix only, re-run check, message SM.

TEAMMATE Dev3 — Config & Hooks:
Read GEMINI.md, docs/report/architecture-decisions.md first.
Wait for SM broadcast "Begin implementation."
Own T3 — files: .claude/settings.json, scripts/log-session.sh
Write .claude/settings.json:
  Stop hook → command: "scripts/log-session.sh"
  Append any existing hooks (do not overwrite unrelated config).
Write scripts/log-session.sh:
  - Reads CLAUDE_SESSION_ID (or generates timestamp-based run-id)
  - Creates logs/iteration/{run-id}/ directory if not exists
  - Appends session start time, model, and turn count to session.md
  - Make executable (chmod +x)
Syntax check: bash -n scripts/log-session.sh
Message SM: "Dev3 done [T3]. Config and hook ready."
On re-spawn: apply exact QA2 failure fix only, re-run check, message SM.

TEAMMATE QA2 — Test Execution:
Run the test cases from docs/tests/test-plan.md as listed by SM.
Write docs/report/qa-report.md: PASS/FAIL per case, exact repro steps
for any failure (copy the actual command output).
Never fix code. Message SM: "QA2 done. [N passed / M failed].
See docs/report/qa-report.md."
On re-spawn: run only the cases SM listed, report delta only.
```

---

## 7. Cấu Trúc Thư Mục

```bash
mas/                              # Repo gốc
│
├── GEMINI.md                     # ← Ground truth: rules + dir layout
├── CLAUDE.md → GEMINI.md         # ← Symlink cho Claude Code
│
├── docs/
│   ├── PRD/                      # Product Requirement Documents
│   ├── report/
│   │   ├── architecture-decisions.md  # [ARCH viết]
│   │   └── qa-report.md               # [QA2 viết]
│   ├── tests/
│   │   └── test-plan.md          # [QA1 viết, QA2 chạy]
│   └── researches/spikes/        # Technical research
│
├── tools/
│   └── browse_knowledge.py       # [Dev2] CDP browser CLI
│
├── scripts/
│   └── log-session.sh            # [Dev3] Stop hook → session log
│
├── logs/
│   └── iteration/{run-id}/
│       └── session.md            # Session traces cho RFT
│
├── memory/
│   ├── agents/{subagent}.md      # Agent context & state
│   ├── task.md / progress.md / plan.md
│
├── .claude/
│   ├── settings.json             # [Dev3] Hooks config
│   ├── agents/
│   │   ├── analyzer.md           # [Dev1] Subagent: intent extraction
│   │   ├── librarian.md          # [Dev1] Subagent: doc search
│   │   └── validator.md          # [Dev1] Subagent: cross-check
│   └── skills/chat/
│       └── SKILL.md              # [Dev2] /chat pipeline orchestrator
│
└── .agents/
    ├── rules/                    # Agent identity, git, universal ID
    └── workflows/                # RFT, verify workflows
```

---

## 8. Tổng Kết

```
┌──────────────────────────────────────────────────────────────────┐
│                    TỔNG KẾT AGILE DEV AGENT TEAM                 │
│                                                                  │
│  export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1                   │
│  → Paste prompt → Claude Code                                    │
│                                                                  │
│  SM đọc GEMINI.md → spawn 6 teammates                           │
│                                                                  │
│  ARCH → architecture-decisions.md (file ownership + rules)       │
│  QA1  → test-plan.md         SM: "APPROVED ✅"                   │
│                                                                  │
│  Dev1          Dev2              Dev3          (song song)        │
│  agents/*.md   tool + skill      settings.json                   │
│  3 subagents   browse_knowledge  log-session.sh                  │
│                chat/SKILL.md                                     │
│                                                                  │
│  QA2 → qa-report.md (PASS/FAIL)                                  │
│                                                                  │
│  Bug-fix loop: SM ↔ DevN ↔ QA2 → zero failures                  │
│                                                                  │
│  Sprint DONE ✅                                                   │
│                                                                  │
│  KẾT QUẢ: Hệ thống 3-agent chạy production                      │
│    /chat → Analyzer → Librarian → Validator                      │
│    → PASS: gửi câu trả lời                                       │
│    → REJECT / miss: "KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"        │
└──────────────────────────────────────────────────────────────────┘
```

---

> **Tham khảo kỹ thuật:**
> - Ground truth: [GEMINI.md](../GEMINI.md)
> - Agent Teams: `.agents/skills/build-with-claude-code/reference/agent-teams.md`
> - Agile Dev Brownfield: `.agents/skills/build-with-claude-code/agile-agent-team/agile-dev-brown-field.md`
> - Agent RFT: `.agents/workflows/claudecode-agent-rft.md`

---

_Tạo cho GSCfin MAS Seminar — Phiên bản Agile Dev Agent Team_

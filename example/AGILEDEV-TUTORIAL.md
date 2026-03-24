---
id: tutorial:mas:agile-dev-agent-team
description: Hướng dẫn xây dựng Agile Dev Agent Team bằng Claude Code — đội 7 agent thực hiện sprint để xây bộ MAS Chat Bot.
---

# TUTORIAL: Agile Dev Agent Team — Xây MAS Chat Bot theo Sprint

> **MAS = Phần mềm (Agile Dev) + Mô phỏng Nghiệp vụ (Org Simulation)**
>
> Tutorial này là mặt **Agile Dev** của MAS — dạy cách *xây phần mềm* bằng một đội
> agent 7 người, thay vì code thủ công.
>
> 📄 Xem mặt nghiệp vụ tại: [CHATBOT-TUTORIAL.md](./CHATBOT-TUTORIAL.md)

---

## 1. Bài Toán

Ta cần **xây bộ code MAS Chat Bot** (đã thiết kế ở CHATBOT-TUTORIAL):

```
KẾT QUẢ CẦN GIAO:
  - .claude/agents/analyzer.md      ← Agent phân tích câu hỏi
  - .claude/agents/librarian.md     ← Agent tìm kho tài liệu
  - .claude/agents/validator.md     ← Agent kiểm tra chéo
  - .claude/skills/chat/SKILL.md    ← /chat pipeline orchestrator
  - tools/browse_knowledge.py       ← CDP browser tool
  - docs/knowledge/                 ← Kho tài liệu mẫu (faq, policy)
  - .claude/settings.json           ← Hooks config (session logging)
  - scripts/log-session.sh          ← Hook script
  - docs/tests/test-plan.md         ← Bộ test cases
```

Yêu cầu: **Không một người nào tự code thủ công.** Toàn bộ do Agent Team thực hiện.

---

## 2. MAS = Phần Mềm + Mô Phỏng Nghiệp Vụ

```
┌──────────────────────────────────────────────────────────────────┐
│                 AGILE DEV AGENT TEAM — MAS BUILDER               │
│                                                                  │
│  ┌─────────────────────┐       ┌──────────────────────────────┐  │
│  │   PHẦN MỀM          │       │  MÔ PHỎNG NGHIỆP VỤ          │  │
│  │   (Agile Dev)       │  +   │  (Org Simulation)            │  │
│  │                     │       │                              │  │
│  │ - Agent code files  │       │ - 7 vai trò Agile            │  │
│  │ - Sprint workflow   │       │ - SM điều phối               │  │
│  │ - Test plan & QA    │       │ - Bug-fix loop tự động       │  │
│  └─────────────────────┘       └──────────────────────────────┘  │
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
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                          │
│  │   SM    │  │  ARCH   │  │   QA1   │                          │
│  │         │  │         │  │         │                          │
│  │ Scrum   │  │ Phân    │  │ Viết    │                          │
│  │ Master  │  │ tích KT │  │ test    │                          │
│  │ Điều   │  │ Thiết   │  │ plan    │                          │
│  │ phối   │  │ kế file │  │ (không  │                          │
│  │ sprint  │  │ ownership│  │ chạy)   │                          │
│  └────┬────┘  └─────────┘  └─────────┘                          │
│       │                                                          │
│       │  Spawn & điều phối                                        │
│       │                                                          │
│  ┌────┴───────────────────────────────────────┐                  │
│  │                                            │                  │
│  ▼            ▼             ▼                 ▼                  │
│ ┌──────┐  ┌──────┐  ┌──────┐            ┌──────┐                │
│ │ Dev1 │  │ Dev2 │  │ Dev3 │            │ QA2  │                │
│ │      │  │      │  │      │            │      │                │
│ │Agent │  │Tools │  │Docs  │            │ Chạy │                │
│ │files │  │& Sk- │  │& Se- │            │ test,│                │
│ │      │  │ills  │  │ttings│            │ báo  │                │
│ └──────┘  └──────┘  └──────┘            └──────┘                │
└──────────────────────────────────────────────────────────────────┘
```

### Chi Tiết Từng Agent

| Agent | Vai trò | Viết code? | Output |
|:------|:--------|:----------:|:-------|
| **SM** | Scrum Master, điều phối sprint, không code | ❌ | Sprint board, tin nhắn điều phối |
| **ARCH** | Thiết kế file ownership, integration points | ❌ | `docs/planning/architecture-decisions.md` |
| **QA1** | Viết test plan từ DoD | ❌ | `docs/tests/test-plan.md` |
| **Dev1** | Agent files (analyzer, librarian, validator) | ✅ | `.claude/agents/*.md` |
| **Dev2** | Tools & skills (browse_knowledge, /chat skill) | ✅ | `tools/`, `.claude/skills/` |
| **Dev3** | Docs, settings, hooks | ✅ | `docs/knowledge/`, `.claude/settings.json`, `scripts/` |
| **QA2** | Chạy test plan, báo PASS/FAIL | ❌ | `docs/planning/qa-report.md` |

---

## 4. Sprint Pipeline

```
  START: User paste prompt vào Claude Code
         │
         ▼
  ┌─────────────┐
  │     SM      │  Bước 0: Đọc GEMINI.md + task source
  │             │  Spawn 6 teammates cùng lúc
  │  "Khai      │  Giao task theo dependency graph
  │   mạc       │
  │   sprint"   │
  └──────┬──────┘
         │ spawn all
         ▼
  ┌─────────────┐
  │    ARCH     │  Bước 1: Đọc codebase + thiết kế
  │             │  → Ai touch file nào?
  │  "Phân      │  → Integration points
  │   tích      │  Output: architecture-decisions.md
  │   KT"       │
  └──────┬──────┘
         │ "ARCH done"
         ▼
  ┌─────────────┐
  │    QA1      │  Bước 2: Đọc ARCH output + DoD
  │             │  Viết test case cho mỗi tiêu chí
  │  "Viết      │  Output: test-plan.md
  │   test      │  Nhắn SM: "QA1 done"
  │   plan"     │
  └──────┬──────┘
         │ SM phê duyệt tức thì "APPROVED ✅"
         ▼
  ┌──────────────────────────────────┐
  │   Dev1  │  Dev2  │  Dev3        │  Bước 3: Song song
  │  agents │  tools │  docs+cfg    │  Mỗi Dev: đọc arch-decisions
  │  files  │  skill │  settings    │  → code → unit test → done
  └────┬────┴────┬───┴────┬─────────┘
       │         │        │
       └────┬────┴────────┘
            │ "DevN done"
            ▼
  ┌─────────────┐
  │    QA2      │  Bước 4: Chạy test plan
  │             │  Output: qa-report.md
  │  "Chạy      │  Nhắn SM: "N passed / M failed"
  │   tests"    │
  └──────┬──────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌──────────┐
│ PASS  │ │  FAIL    │  Bước 5: Bug-fix loop
│ 100%  │ │          │  SM re-spawn Dev bị lỗi
└───┬───┘ │ SM       │  Dev fix → SM re-spawn QA2
    │     │ re-spawn │  Lặp đến khi zero failures
    │     │ Dev+QA2  │
    ▼     └──────────┘
 Sprint DONE ✅
```

---

## 5. Giao Tiếp Giữa Các Agent

### Model: Agent Team Messaging (Claude Code Native)

```
┌────────────────────────────────────────────────────────────────┐
│              AGENT TEAM COMMUNICATION MODEL                     │
│                                                                │
│  SM ──broadcast──→ Dev1, Dev2, Dev3: "Begin implementation"    │
│                                                                │
│  Dev1 ──message──→ SM: "Dev1 done [T1, T3]."                  │
│  Dev2 ──message──→ SM: "Dev2 done [T2]."                      │
│  Dev3 ──message──→ SM: "Dev3 done [T4]."                      │
│                                                                │
│  SM ──spawn──→ QA2: "Run test-plan.md cases [list]."          │
│  QA2 ──message──→ SM: "3 passed / 1 failed. See qa-report."   │
│                                                                │
│  SM ──re-spawn──→ Dev1: "Fix bug: [exact failure]."           │
│  Dev1 ──message──→ SM: "Fixed. Unit tests pass."              │
│  SM ──re-spawn──→ QA2: "Re-run failing case [X]."             │
│                                                                │
│  ✅ Mỗi teammate là process riêng biệt                          │
│  ✅ File là kênh giao tiếp bền vững (arch-decisions, qa-report) │
│  ✅ Message là tín hiệu điều phối nội bộ                        │
└────────────────────────────────────────────────────────────────┘
```

### So Sánh: Subagent vs. Agent Team

| Tiêu chí | Subagent (CHATBOT-TUTORIAL) | Agent Team (AGILEDEV-TUTORIAL) |
|:---------|:--------------------------|:-------------------------------|
| Dùng khi | Delegate subtask, giữ context | Parallel independent work |
| Process | Cùng process với main | Process riêng biệt |
| Giao tiếp | Return value → Orchestrator | message / broadcast |
| Concurrent | Tuần tự (chaining) | Song song thực sự |
| Chi phí token | Thấp (chung context) | Cao hơn (mỗi agent = context riêng) |
| Phù hợp | Runtime Q&A pipeline | Sprint-level software development |

---

## 6. Ready-to-Paste Prompt

Khi đã có `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` trong môi trường,
copy toàn bộ block dưới đây và paste vào Claude Code:

```
Create an agent team with 7 teammates to build the MAS QA Chatbot codebase.

Prerequisites:
- CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 must be set
- model: sonnet (set in .claude/settings.json or --model flag)

Read before spawning — ground truth for this project:
- GEMINI.md (or CLAUDE.md) — project rules and conventions
- README.md — system overview and directory layout
- example/CHATBOT-TUTORIAL.md — the chatbot design spec (source of truth for what to build)

Task breakdown:
- T1: .claude/agents/analyzer.md, librarian.md, validator.md (Agent subagent files)
- T2: tools/browse_knowledge.py (CDP browser tool), .claude/skills/chat/SKILL.md (/chat skill)
- T3: docs/knowledge/ (faq.md, product-info.md, policy.md), .claude/settings.json, scripts/log-session.sh
- T4: docs/tests/test-plan.md (derived from DoD in CHATBOT-TUTORIAL.md)

Dependency order: T4 (QA1, parallel with T1-T3) → T1, T2, T3 (parallel Devs after ARCH) → QA2

Spawn the following 7 teammates:

TEAMMATE SM — Scrum Master:
You are the Scrum Master orchestrating this sprint. Read GEMINI.md and example/CHATBOT-TUTORIAL.md first.
Spawn these 6 teammates immediately with the prompts below.
Task assignment: Dev1 → T1, Dev2 → T2, Dev3 → T3.
When QA1 posts docs/tests/test-plan.md, reply "Test plan APPROVED ✅" immediately and broadcast to Dev1/Dev2/Dev3: "Test plan approved. Begin implementation."
Run the bug-fix loop: wait for QA2 report → re-spawn failing Dev with exact failure description → after Dev confirms fix, re-spawn QA2 with only the previously failing cases → repeat until zero failures → mark sprint DONE.
Never write code yourself.

TEAMMATE ARCH — Software Architect:
Read GEMINI.md, README.md, example/CHATBOT-TUTORIAL.md, and the existing .claude/ and docs/ structure.
Produce docs/planning/architecture-decisions.md covering:
  - File ownership map: Dev1 owns .claude/agents/, Dev2 owns tools/ and .claude/skills/, Dev3 owns docs/knowledge/ and .claude/settings.json and scripts/
  - Integration points: how /chat SKILL.md calls the 3 agents; how log-session.sh is triggered by hooks
  - Design constraints from CHATBOT-TUTORIAL.md (golden rules, no hallucination)
Do not write production code. Message SM when done: "ARCH done. architecture-decisions.md ready."

TEAMMATE QA1 — Planning QA:
Wait for ARCH to post docs/planning/architecture-decisions.md.
Read GEMINI.md + ARCH output + the Definition of Done from example/CHATBOT-TUTORIAL.md sections 3-8.
Write docs/tests/test-plan.md with:
  - One test case per DoD criterion (agent files exist and have correct YAML frontmatter, /chat skill invokes all 3 agents, Validator rejects hallucinated answers, session log is created after each chat)
  - Exact commands/assertions (e.g., cat .claude/agents/analyzer.md | grep 'tools:', claude /chat "test question")
  - Pass/Fail criteria
Do not run tests. Message SM: "QA1 done. test-plan.md ready for approval."

TEAMMATE Dev1 — Agent Files:
Read GEMINI.md, README.md, docs/planning/architecture-decisions.md, and example/CHATBOT-TUTORIAL.md sections 3 and 7 first.
Wait for SM to say "Begin implementation."
Own tasks: T1. Files you own: .claude/agents/analyzer.md, .claude/agents/librarian.md, .claude/agents/validator.md
Write each agent file with correct YAML frontmatter (name, description, tools, model fields).
Follow all conventions in GEMINI.md. Write a simple smoke test (e.g., cat each file | grep 'tools:') to verify.
Message SM when done: "Dev1 done [T1]. Agent files ready."
When re-spawned for a bug fix, read the exact QA2 failure, fix only that, re-run your smoke test, message SM.

TEAMMATE Dev2 — Tools & Skills:
Read GEMINI.md, README.md, docs/planning/architecture-decisions.md, and example/CHATBOT-TUTORIAL.md sections 4 and 7 first.
Wait for SM to say "Begin implementation."
Own tasks: T2. Files you own: tools/browse_knowledge.py, .claude/skills/chat/SKILL.md
Write tools/browse_knowledge.py as a CLI tool (argparse, connects to CDP on port 9222 if available).
Write .claude/skills/chat/SKILL.md as the /chat pipeline orchestrator (invokes Analyzer → Librarian → Validator via subagent return-value chaining).
Follow tool-writing rules in GEMINI.md. Write a simple import/syntax check: python -c "import tools.browse_knowledge".
Message SM when done: "Dev2 done [T2]. Tools and skill ready."
When re-spawned for a bug fix, read the exact QA2 failure, fix only that, re-run your check, message SM.

TEAMMATE Dev3 — Docs, Config & Hooks:
Read GEMINI.md, README.md, docs/planning/architecture-decisions.md, and example/CHATBOT-TUTORIAL.md sections 7-8 first.
Wait for SM to say "Begin implementation."
Own tasks: T3. Files you own: docs/knowledge/faq.md, docs/knowledge/product-info.md, docs/knowledge/policy.md, .claude/settings.json, scripts/log-session.sh
Create sample knowledge docs (faq, product-info, policy) for GSCfin MAS use case.
Write .claude/settings.json with the Stop hook pointing to scripts/log-session.sh.
Write scripts/log-session.sh to append session metadata to logs/iteration/{run-id}/session.md.
Message SM when done: "Dev3 done [T3]. Docs, settings, and scripts ready."
When re-spawned for a bug fix, read the exact QA2 failure, fix only that, message SM.

TEAMMATE QA2 — Test Execution:
Run these test cases from docs/tests/test-plan.md: [all cases on first spawn / only previously failing cases on re-spawn].
Write docs/planning/qa-report.md: PASS/FAIL per test case, exact repro steps for any failures.
Never fix code yourself — only report.
Message SM: "QA2 done. [N passed / M failed]. See docs/planning/qa-report.md."
On re-spawn, run only the cases listed by SM, report only those results as a delta.
```

---

## 7. Cấu Trúc Thư Mục

```bash
mas-qa-chatbot/              # Repo gốc
├── example/
│   ├── CHATBOT-TUTORIAL.md  # Thiết kế nghiệp vụ (ground truth)
│   └── AGILEDEV-TUTORIAL.md # File này — hướng dẫn Agile Dev
│
├── docs/
│   ├── knowledge/           # [Dev3] Kho tài liệu mẫu
│   │   ├── faq.md
│   │   ├── product-info.md
│   │   └── policy.md
│   ├── tests/
│   │   └── test-plan.md     # [QA1] Bộ test cases
│   └── planning/
│       ├── architecture-decisions.md  # [ARCH]
│       └── qa-report.md               # [QA2]
│
├── tools/
│   └── browse_knowledge.py  # [Dev2] CDP browser tool
│
├── scripts/
│   └── log-session.sh       # [Dev3] Hook script — log session
│
├── logs/
│   └── iteration/           # Session traces cho RFT
│       └── {run-id}/session.md
│
├── .claude/
│   ├── settings.json        # [Dev3] Hooks config (Stop → log-session)
│   ├── agents/
│   │   ├── analyzer.md      # [Dev1] Agent Analyzer
│   │   ├── librarian.md     # [Dev1] Agent Librarian
│   │   └── validator.md     # [Dev1] Agent Validator
│   └── skills/
│       └── chat/
│           └── SKILL.md     # [Dev2] /chat — Pipeline orchestrator
│
└── .agents/
    └── rules/
        └── SOUL.md          # Quy tắc văn hoá MAS
```

---

## 8. Tổng Kết

```
┌────────────────────────────────────────────────────────────────────┐
│                   TỔNG KẾT AGILE DEV AGENT TEAM                    │
│                                                                    │
│  Paste prompt → Claude Code (EXPERIMENTAL_AGENT_TEAMS=1)           │
│                   │                                                │
│            SM spawns 6 teammates                                   │
│                   │                                                │
│       ARCH ──→ architecture-decisions.md                           │
│       QA1  ──→ test-plan.md (SM auto-APPROVED ✅)                  │
│                   │                                                │
│  Dev1 ──→ agents  │  Dev2 ──→ tools+skill  │  Dev3 ──→ docs+cfg   │
│  (song song)       (song song)               (song song)          │
│                   │                                                │
│              QA2 ──→ qa-report.md                                  │
│                   │                                                │
│          Bug-fix loop (SM ↔ Dev ↔ QA2)                            │
│                   │                                                │
│            Sprint DONE ✅                                          │
│                                                                    │
│  QUAN HỆ VỚI CHATBOT-TUTORIAL:                                     │
│  - CHATBOT = Org Simulation (3 agent nghiệp vụ chạy production)    │
│  - AGILEDEV = Phần mềm (7 agent xây code để có 3 agent trên)       │
│  - Hai tutorial cùng nhau = Một MAS hoàn chỉnh                     │
│                                                                    │
│  MÔ HÌNH NHÂN SỰ:                                                  │
│  SM → không code  │  ARCH → không code  │  QA1 → không code       │
│  Dev1,2,3 → code  │  QA2 → không code                             │
│                                                                    │
│  KÍCH HOẠT: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1                 │
└────────────────────────────────────────────────────────────────────┘
```

---

> **Liên kết:**
> - Thiết kế nghiệp vụ: [CHATBOT-TUTORIAL.md](./CHATBOT-TUTORIAL.md)
> - Agent RFT Workflow: `.agents/workflows/claudecode-agent-rft.md`
> - Skill tham khảo: `.agents/skills/build-with-claude-code/SKILL.md`

---

_Tạo cho GSCfin MAS Seminar — Phiên bản Agile Dev Agent Team_

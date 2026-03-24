---
id: tutorial:mas:agile-dev-agent-team
description: Hướng dẫn xây dựng Agile Dev Agent Team bằng Claude Code — đội 7 agent chạy sprint để phát triển một dự án MAS bất kỳ.
---

# TUTORIAL: Agile Dev Agent Team — Phát Triển Dự Án MAS

> **MAS = Phần mềm (Agile Dev) + Mô phỏng Nghiệp vụ (Org Simulation)**
>
> Tutorial này dạy mặt **Agile Dev** của MAS — cách tổ chức đội 7 agent
> Claude Code để phát triển phần mềm theo sprint, tuân thủ ground-truth
> từ `GEMINI.md` và cấu trúc `docs/` của dự án.
>
> 🔗 Xem ví dụ nghiệp vụ tại: [CHATBOT-TUTORIAL.md](./CHATBOT-TUTORIAL.md)
> _(CHATBOT-TUTORIAL là một Org Simulation — pipeline chạy lúc production,
> không phải quy trình xây phần mềm.)_

---

## 1. Bài Toán

Ta cần **phát triển một dự án MAS** (Multi-Agent System) bằng Claude Code,
với yêu cầu:

- Toàn bộ quá trình phát triển đều do Agent Team thực hiện.
- Agents **PHẢI** đọc `GEMINI.md` (hoặc `CLAUDE.md`) trước khi làm bất cứ điều gì.
- Cấu trúc `docs/` và tech stack trong đó là **ground-truth** — không được tự đặt ra quy tắc riêng.
- Tất cả tài liệu, test plan, PRD đều nằm trong `docs/` theo đúng chuẩn dự án.

```
GROUND-TRUTH HIERARCHY (bắt buộc đọc trước khi sprint bắt đầu):

  GEMINI.md (hoặc CLAUDE.md)
    └─ docs/PRD/         ← Product Requirement Documents
    └─ docs/report/      ← Analysis & status reports
    └─ docs/tests/       ← Test plans & QA verification docs
    └─ docs/researches/  ← Spikes và technical research
    └─ logs/iteration/   ← Execution logs per iteration run
    └─ memory/           ← Agent state & orchestrator memory
    └─ .agents/rules/    ← Agent identity, git, universal ID rules
    └─ .agents/workflows/← Executable AI workflows (RFT, verify)
```

---

## 2. MAS = Phần Mềm + Mô Phỏng Nghiệp Vụ

```
┌──────────────────────────────────────────────────────────────────┐
│                 AGILE DEV AGENT TEAM — MAS BUILDER               │
│                                                                  │
│  ┌─────────────────────┐       ┌──────────────────────────────┐  │
│  │   PHẦN MỀM          │       │  MÔ PHỎNG NGHIỆP VỤ          │  │
│  │   (Agile Dev)       │  +    │  (Org Simulation)            │  │
│  │                     │       │                              │  │
│  │ - Đội 7 agent       │       │ - Vai trò Agile cụ thể       │  │
│  │ - Sprint workflow   │       │ - SM không code              │  │
│  │ - docs/ là SSOT     │       │ - Bug-fix loop tự động       │  │
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
│        ┌─────────┐                                               │
│        │   SM    │  ← Scrum Master, điều phối, KHÔNG code        │
│        └────┬────┘                                               │
│             │ spawn tất cả                                        │
│    ┌────────┼────────┐                                           │
│    ▼        ▼        ▼                                           │
│ ┌──────┐ ┌──────┐ ┌──────┐                                       │
│ │ ARCH │ │ QA1  │ │ Dev* │  ← ARCH + QA1: không code            │
│ │      │ │      │ │      │  ← Dev1-3: code + unit test          │
│ └──────┘ └──────┘ └──┬───┘                                       │
│                       │ sau khi code xong                        │
│                    ┌──▼───┐                                      │
│                    │ QA2  │  ← Chạy tests, báo cáo, KHÔNG code  │
│                    └──────┘                                      │
└──────────────────────────────────────────────────────────────────┘
```

### Chi Tiết Từng Agent

| Agent | Vai trò | Viết code? | Output |
|:------|:--------|:----------:|:-------|
| **SM** | Scrum Master, điều phối sprint, phê duyệt test plan | ❌ | Sprint board, tin nhắn broadcast |
| **ARCH** | Đọc GEMINI.md + docs/, thiết kế file ownership & integration | ❌ | `docs/report/architecture-decisions.md` |
| **QA1** | Đọc ARCH output + PRD/DoD, viết test plan | ❌ | `docs/tests/test-plan.md` |
| **Dev1** | Implement feature/module được SM giao (T1) | ✅ | Source files T1 |
| **Dev2** | Implement feature/module được SM giao (T2) | ✅ | Source files T2 |
| **Dev3** | Implement feature/module được SM giao (T3) | ✅ | Source files T3 |
| **QA2** | Chạy test plan, viết qa-report, KHÔNG fix | ❌ | `docs/report/qa-report.md` |

> **Quy tắc phân chia Dev:** Không hai Dev nào cùng sở hữu một file
> tại cùng một thời điểm (tránh conflict). ARCH quyết định file ownership.

---

## 4. Sprint Pipeline

```
  START: Paste prompt vào Claude Code
         │
         ▼
  ┌──────────────┐
  │     SM       │  Bước 0: Đọc GEMINI.md + docs/PRD/ + task source
  │              │  Spawn 6 teammates cùng lúc
  │  "Khai mạc   │  Giao task T1/T2/T3 theo dependency graph
  │   sprint"    │
  └──────┬───────┘
         │ spawn all
         ▼
  ┌──────────────┐
  │    ARCH      │  Bước 1: Đọc GEMINI.md, docs/, source files
  │              │  Thiết kế: ai touch file nào, integration points
  │  "Phân tích  │  Output → docs/report/architecture-decisions.md
  │   & thiết kế"│  Nhắn SM: "ARCH done"
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │    QA1       │  Bước 2: Đọc GEMINI.md + ARCH output + PRD DoD
  │              │  Viết test case cụ thể (command, assertion, pass/fail)
  │  "Viết test  │  Output → docs/tests/test-plan.md
  │   plan"      │  Nhắn SM: "QA1 done"
  └──────┬───────┘
         │ SM reply "APPROVED ✅" tức thì
         ▼
  ┌────────────────────────────────┐
  │  Dev1   │   Dev2   │   Dev3   │  Bước 3: Song song
  │  [T1]   │   [T2]   │   [T3]   │  Đọc GEMINI.md + arch-decisions.md
  │  file   │   file   │   file   │  Code → unit test → nhắn SM
  │  set 1  │   set 2  │   set 3  │
  └────┬────┴────┬──────┴────┬────┘
       └─────────┴───────────┘
                 │ "DevN done"
                 ▼
  ┌──────────────┐
  │    QA2       │  Bước 4: Chạy test-plan.md
  │              │  Output → docs/report/qa-report.md
  │  "Chạy       │  Nhắn SM: "N passed / M failed"
  │   tests"     │
  └──────┬───────┘
         │
    ┌────┴─────┐
    ▼          ▼
┌───────┐  ┌──────────────────────────────────┐
│ PASS  │  │  FAIL                            │
│ 100%  │  │  SM re-spawn Dev bị lỗi          │
└───┬───┘  │  Dev fix → nhắn SM               │
    │       │  SM re-spawn QA2 với case lỗi    │
    │       │  Lặp đến khi zero failures       │
    ▼       └──────────────────────────────────┘
 Sprint DONE ✅
```

---

## 5. Giao Tiếp Giữa Các Agent

```
┌────────────────────────────────────────────────────────────────┐
│              AGENT TEAM COMMUNICATION MODEL                     │
│                                                                │
│  SM ─broadcast─→ Dev1, Dev2, Dev3: "Test plan approved.        │
│                                     Begin implementation."     │
│                                                                │
│  DevN ─message─→ SM: "DevN done [task IDs]."                  │
│                                                                │
│  SM ─spawn─→ QA2: "Run test-plan.md cases: [list]."           │
│  QA2 ─message─→ SM: "3 passed / 1 failed. See qa-report."    │
│                                                                │
│  [Bug-fix loop]                                                │
│  SM ─re-spawn─→ DevN: "Fix bug: [exact QA2 failure]."         │
│  DevN ─message─→ SM: "Fixed. Unit tests pass."                │
│  SM ─re-spawn─→ QA2: "Re-run failing case [X] only."          │
│                                                                │
│  ✅ File là kênh giao tiếp bền vững:                            │
│     docs/report/architecture-decisions.md → Devs đọc          │
│     docs/tests/test-plan.md → QA2 chạy                        │
│     docs/report/qa-report.md → SM đọc để điều phối            │
└────────────────────────────────────────────────────────────────┘
```

> **Lưu ý:** Agent Team là các process Claude Code **riêng biệt**, khác với
> Subagent (cùng process, return-value chaining như trong CHATBOT-TUTORIAL).
> Dùng Agent Team khi cần song song thực sự; dùng Subagent khi cần delegate
> subtask trong cùng pipeline.

---

## 6. Ready-to-Paste Prompt

Kích hoạt feature flag trước:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Sau đó copy block dưới đây và paste vào Claude Code. **Điền vào `[...]`
các giá trị thực tế của sprint:**

```
Create an agent team with 7 teammates to implement [SPRINT GOAL / feature description].

Prerequisites:
- CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 must be set
- model: sonnet

Ground truth — every teammate must read these first, before any action:
- GEMINI.md (or CLAUDE.md) — project rules, directory conventions, agent identity rules
- docs/PRD/ — Product Requirement Documents and Definition of Done
- docs/researches/spikes/ — technical spikes and research (verify against source)
- [path to task source document] — sprint task list, dependency graph, DoD per task

Task breakdown for this sprint:
- T1: [description] — files: [list of files Dev1 will own]
- T2: [description] — files: [list of files Dev2 will own]
- T3: [description] — files: [list of files Dev3 will own]

Dependency order: [e.g. T1 → T2, T3 independent]

Spawn the following 7 teammates:

TEAMMATE SM — Scrum Master:
You are the Scrum Master. Read GEMINI.md and [task source] first. Never write code.
Spawn these 6 teammates immediately with the prompts below.
Assign: Dev1 → T1, Dev2 → T2, Dev3 → T3. Enforce the file ownership from ARCH.
When QA1 posts docs/tests/test-plan.md, reply "Test plan APPROVED ✅" immediately
and broadcast to Dev1/Dev2/Dev3: "Test plan approved. Begin implementation."
Bug-fix loop: wait for QA2 report → re-spawn failing Dev with exact failure text →
after Dev confirms fix, re-spawn QA2 with only the failing cases → repeat until zero failures → mark DONE.

TEAMMATE ARCH — Software Architect:
Read GEMINI.md, docs/PRD/, docs/researches/, and the relevant source files for this sprint.
Produce docs/report/architecture-decisions.md covering:
  - File ownership map (Dev1 owns [files], Dev2 owns [files], Dev3 owns [files])
  - Integration points between tasks
  - Design constraints and conventions from GEMINI.md that Devs must follow
  - Tech stack references from docs/ that apply to this sprint
Do not write production code. Message SM: "ARCH done. architecture-decisions.md ready."

TEAMMATE QA1 — Planning QA:
Wait until ARCH posts docs/report/architecture-decisions.md.
Read GEMINI.md + ARCH output + DoD from docs/PRD/.
Write docs/tests/test-plan.md with:
  - One test case per DoD criterion
  - Exact commands/assertions (CLI, file existence checks, unit test commands)
  - Pass/Fail criteria
Do not run tests. Message SM: "QA1 done. test-plan.md ready for approval."

TEAMMATE Dev1:
Read GEMINI.md, docs/PRD/, docs/report/architecture-decisions.md first. Never start before ARCH posts.
Wait for SM to broadcast "Begin implementation."
Own tasks: T1. Files you own: [list]. Do not touch Dev2 or Dev3 files.
Follow all conventions in GEMINI.md (universal IDs, commit format, tool-writing rules, etc.).
Write unit tests for your code. Message SM: "Dev1 done [T1]."
On re-spawn: read the exact QA2 failure, fix only that, re-run unit tests, message SM.

TEAMMATE Dev2:
[Same structure as Dev1 — tasks: T2, files: [list]]

TEAMMATE Dev3:
[Same structure as Dev1 — tasks: T3, files: [list]]

TEAMMATE QA2 — Test Execution:
Run the test cases listed by SM from docs/tests/test-plan.md.
Write docs/report/qa-report.md: PASS/FAIL per case, exact repro steps for failures.
Never fix code. Message SM: "QA2 done. [N passed / M failed]. See docs/report/qa-report.md."
On re-spawn: run only the previously failing cases; report delta only.
```

---

## 7. Cấu Trúc Thư Mục (Theo GEMINI.md)

```bash
mas/                              # Repo gốc
│
├── GEMINI.md                     # ← Ground truth: rules + dir structure
├── CLAUDE.md → GEMINI.md         # ← Symlink cho Claude Code
│
├── docs/
│   ├── PRD/                      # Product Requirement Documents
│   │   └── [feature].md          # [ARCH + QA1 đọc]
│   ├── report/                   # Analysis & status reports
│   │   ├── architecture-decisions.md  # [ARCH viết]
│   │   └── qa-report.md               # [QA2 viết]
│   ├── tests/                    # Test plans & QA docs
│   │   └── test-plan.md          # [QA1 viết, QA2 chạy]
│   └── researches/
│       └── spikes/               # Technical research
│
├── logs/
│   └── iteration/{run-id}/       # Execution logs per sprint
│       └── session.md
│
├── memory/
│   ├── agents/{subagent}.md      # Agent context & state
│   ├── task.md                   # Master Orchestrator task list
│   ├── progress.md               # Sprint progress
│   └── plan.md                   # Current plan
│
├── .agents/
│   ├── rules/                    # Agent identity, git rules, Universal IDs
│   └── workflows/                # claudecode-agent-rft, verify workflows
│
└── example/
    ├── CHATBOT-TUTORIAL.md       # Org Simulation example (nghiệp vụ)
    └── AGILEDEV-TUTORIAL.md      # File này — Agile Dev how-to
```

> **Không có `docs/knowledge/`** — đó là thư mục thuộc về Org Simulation
> (chatbot kho tài liệu), không thuộc Agile Dev workflow.

---

## 8. Tổng Kết

```
┌────────────────────────────────────────────────────────────────────┐
│                   TỔNG KẾT AGILE DEV AGENT TEAM                    │
│                                                                    │
│  1. Paste prompt vào Claude Code                                   │
│     (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)                       │
│                                                                    │
│  2. SM đọc GEMINI.md → spawn 6 teammates                           │
│                                                                    │
│  3. ARCH đọc docs/ → architecture-decisions.md                     │
│     QA1 đọc PRD + ARCH → test-plan.md (SM: APPROVED ✅)            │
│                                                                    │
│  4. Dev1 │ Dev2 │ Dev3 — song song, không conflict file            │
│     └─── mỗi Dev đọc GEMINI.md + arch-decisions trước             │
│                                                                    │
│  5. QA2 chạy test-plan → qa-report                                 │
│                                                                    │
│  6. Bug-fix loop: SM ↔ Dev ↔ QA2 cho đến zero failures            │
│                                                                    │
│  Sprint DONE ✅                                                     │
│                                                                    │
│  PHÂN BIỆT HAI TUTORIAL:                                           │
│  CHATBOT-TUTORIAL  = Org Simulation (pipeline nghiệp vụ lúc run)   │
│  AGILEDEV-TUTORIAL = Phần mềm (quy trình xây dự án bằng agents)    │
│  → Kết hợp cả hai = MAS hoàn chỉnh                                 │
└────────────────────────────────────────────────────────────────────┘
```

---

> **Tham khảo:**
> - Ground truth: [GEMINI.md](../GEMINI.md)
> - Agent Teams: `.agents/skills/build-with-claude-code/reference/agent-teams.md`
> - Agile Dev (brownfield): `.agents/skills/build-with-claude-code/agile-agent-team/agile-dev-brown-field.md`
> - Agent RFT: `.agents/workflows/claudecode-agent-rft.md`

---

_Tạo cho GSCfin MAS Seminar — Phiên bản Agile Dev Agent Team_

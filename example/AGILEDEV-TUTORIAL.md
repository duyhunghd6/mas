---
id: tutorial:mas:agile-dev-agent-team
description: Hướng dẫn tổ chức Agile Dev Agent Team bằng Claude Code — đội 7 agent chạy sprint phát triển phần mềm theo mô hình MAS.
---

# TUTORIAL: Agile Dev Agent Team

> **MAS = Phần mềm (Agile Dev) + Mô phỏng Nghiệp vụ (Org Simulation)**
>
> Bài toán: Tổ chức một **đội phát triển phần mềm** gồm 7 agent AI,
> hoạt động theo quy trình Agile, tuân thủ ground-truth từ `GEMINI.md`.

---

## 1. Bài Toán

Xây phần mềm bằng đội AI — không phải một người tự code tất cả.

- Mỗi agent có **một vai trò cụ thể**, không làm lẫn sang vai trò khác.
- Agents **PHẢI** đọc `GEMINI.md` (hoặc `CLAUDE.md`) trước khi làm bất cứ điều gì.
- `docs/` là nơi chứa tài liệu ground-truth dự án: PRD, test plan, báo cáo.
- **Tuyệt đối không agent nào tự ý đặt ra quy tắc riêng** ngoài những gì GEMINI.md quy định.

```
┌──────────────────────────────────────────────────────────┐
│                   BÀI TOÁN AGILE DEV                     │
│                                                          │
│  Input:  Danh sách task từ docs/PRD/ + dependency graph  │
│  Output: Code đã test, tài liệu đã cập nhật, zero bugs   │
│                                                          │
│  QUY TẮC VÀNG:                                           │
│  SM không bao giờ viết code                              │
│  ARCH + QA1 + QA2 không bao giờ viết production code     │
│  Dev chỉ chạm vào file được ARCH giao — không thêm       │
│  QA2 chỉ báo lỗi — không tự sửa                         │
└──────────────────────────────────────────────────────────┘
```

---

## 2. MAS = Phần Mềm + Mô Phỏng Nghiệp Vụ

```
┌──────────────────────────────────────────────────────────────────┐
│                      AGILE DEV AGENT TEAM                        │
│                                                                  │
│  ┌──────────────────────────┐    ┌─────────────────────────────┐ │
│  │  PHẦN MỀM (Agile Dev)    │    │  MÔ PHỎNG NGHIỆP VỤ         │ │
│  │                          │ +  │  (Org Simulation)           │ │
│  │  - 7 agent có vai trò    │    │  - SM = Scrum Master        │ │
│  │  - Sprint workflow       │    │  - ARCH = Kiến trúc sư      │ │
│  │  - GEMINI.md là SSOT     │    │  - QA1, QA2 = Kiểm thử      │ │
│  │  - docs/ là ground truth │    │  - Dev1-3 = Lập trình viên  │ │
│  └──────────────────────────┘    └─────────────────────────────┘ │
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
│         │    SM    │  Scrum Master — spawn & điều phối           │
│         └────┬─────┘  KHÔNG code                                 │
│              │                                                   │
│    ┌─────────┼──────────┐                                        │
│    ▼         ▼          ▼                                        │
│ ┌──────┐  ┌──────┐  ┌──────────────────────────────────┐        │
│ │ ARCH │  │ QA1  │  │    Dev1    │   Dev2   │   Dev3   │        │
│ │      │  │      │  │  [Task T1] │  [T2]    │  [T3]    │        │
│ │ Thiết│  │ Test │  └──────┬─────┴────┬─────┴────┬─────┘        │
│ │  kế  │  │ plan │         │          │          │              │
│ └──────┘  └──────┘         └──────────┴──────────┘              │
│ Không code Không code           Có code | unit test             │
│                                         │                        │
│                                      ┌──▼───┐                   │
│                                      │ QA2  │  Chạy tests       │
│                                      └──────┘  KHÔNG code        │
└──────────────────────────────────────────────────────────────────┘
```

### Chi Tiết Từng Agent

| Agent | Nhiệm vụ | Input | Output |
|:------|:---------|:------|:-------|
| **SM** | Điều phối sprint, giao task, chạy bug-fix loop | GEMINI.md + PRD | Spawn + broadcast |
| **ARCH** | Thiết kế file ownership, integration points | GEMINI.md + docs/ + source | `docs/report/architecture-decisions.md` |
| **QA1** | Viết test plan từ DoD | ARCH output + PRD | `docs/tests/test-plan.md` |
| **Dev1** | Implement task T1 | GEMINI.md + arch-decisions | Code files cho T1 |
| **Dev2** | Implement task T2 | GEMINI.md + arch-decisions | Code files cho T2 |
| **Dev3** | Implement task T3 | GEMINI.md + arch-decisions | Code files cho T3 |
| **QA2** | Chạy test plan, báo PASS/FAIL | test-plan.md | `docs/report/qa-report.md` |

---

## 4. Quy Trình Xử Lý (Pipeline)

```
  Nhận task từ docs/PRD/ + dependency graph
         │
         ▼
  ┌──────────────┐
  │      SM      │  Bước 0: Đọc GEMINI.md + PRD
  │              │  Spawn 6 teammates cùng lúc
  │  "Khai mạc   │  Phân công T1→Dev1, T2→Dev2, T3→Dev3
  │   sprint"    │
  └──────┬───────┘
         │ spawn all
         ▼
  ┌──────────────┐
  │    ARCH      │  Bước 1: Phân tích codebase + docs/
  │              │  → Ai chạm file nào (ownership map)
  │  "Ai làm gì  │  → Integration points giữa các task
  │   ở đâu?"    │  Output: docs/report/architecture-decisions.md
  └──────┬───────┘  Nhắn SM: "ARCH done"
         │
         ▼
  ┌──────────────┐
  │    QA1       │  Bước 2: Đọc ARCH output + PRD + GEMINI.md
  │              │  Viết test case cho mỗi DoD criterion
  │  "Test case  │  Lệnh cụ thể, pass/fail rõ ràng
  │   là gì?"    │  Output: docs/tests/test-plan.md
  └──────┬───────┘  Nhắn SM: "QA1 done"
         │
         │  SM reply "APPROVED ✅" tức thì
         │  SM broadcast → Dev1, Dev2, Dev3: "Begin implementation"
         ▼
  ┌─────────────────────────────────────┐
  │  Dev1   │     Dev2     │    Dev3    │  Bước 3: Song song
  │  [T1]   │     [T2]     │    [T3]   │  Mỗi Dev: đọc GEMINI.md
  │         │              │           │  + arch-decisions.md trước
  │ code T1 │   code T2    │  code T3  │  → code → unit test riêng
  │         │              │           │  → nhắn SM khi done
  └────┬────┴──────┬───────┴─────┬─────┘
       └───────────┴─────────────┘
                   │ "DevN done [task IDs]"
                   ▼
  ┌──────────────┐
  │    QA2       │  Bước 4: Chạy test-plan.md
  │              │  Output: docs/report/qa-report.md
  │  "PASS hay   │  Nhắn SM: "N passed / M failed"
  │   FAIL?"     │
  └──────┬───────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐  ┌──────────────────────────────────────┐
│ PASS  │  │  FAIL                                │
│ 100%  │  │  SM re-spawn DevN bị lỗi             │
└───┬───┘  │  → DevN fix → nhắn SM               │
    │       │  → SM re-spawn QA2 (chỉ case lỗi)   │
    ▼       │  → Lặp đến zero failures            │
 Sprint     └──────────────────────────────────────┘
 DONE ✅
```

---

## 5. Giao Tiếp Giữa Các Agent

### Model: Agent Team Messaging (Claude Code Native)

Mỗi agent là một **process Claude Code riêng biệt**, giao tiếp qua
messaging — không phải return-value trong cùng session.

```
┌────────────────────────────────────────────────────────────────┐
│                   AGENT TEAM MESSAGING                          │
│                                                                │
│  SM ──broadcast──→ Dev1, Dev2, Dev3:                           │
│     "Test plan approved. Begin implementation."                │
│                                                                │
│  Dev1 ──message──→ SM: "Dev1 done [T1]."                      │
│  Dev2 ──message──→ SM: "Dev2 done [T2]."                      │
│  Dev3 ──message──→ SM: "Dev3 done [T3]."                      │
│                                                                │
│  SM ──spawn──→ QA2: "Run all cases from test-plan.md."        │
│  QA2 ──message──→ SM: "3 passed / 1 failed. See qa-report."  │
│                                                                │
│  [Bug-fix loop]                                                │
│  SM ──re-spawn──→ Dev2: "Fix: [exact failure text from QA2]"  │
│  Dev2 ──message──→ SM: "Fixed. Unit tests pass."              │
│  SM ──re-spawn──→ QA2: "Re-run failing case [TC-X] only."    │
│                                                                │
│  File là kênh giao tiếp bền vững:                              │
│  ✅ docs/report/architecture-decisions.md → Devs đọc          │
│  ✅ docs/tests/test-plan.md → QA2 chạy                        │
│  ✅ docs/report/qa-report.md → SM điều phối bug-fix           │
└────────────────────────────────────────────────────────────────┘
```

### So Sánh Hai Mô Hình

| Tiêu chí | Return-Value (Subagent) | Agent Team Messaging |
|:---------|:-----------------------|:---------------------|
| Dùng khi | Delegate subtask, cùng pipeline | Parallel independent work |
| Process | Cùng Claude Code session | Process riêng biệt |
| Token cost | Thấp hơn | Cao hơn (mỗi agent = context riêng) |
| Concurrent | Tuần tự theo chain | Song song thực sự |
| Phù hợp | Org Simulation runtime | Sprint-level software dev |

---

## 6. Quyết Định Và Quy Tắc

```
┌────────────────────────────────────────────────────────────┐
│                    QUY TẮC QUYẾT ĐỊNH                       │
│                                                            │
│  1. SM KHÔNG bao giờ viết code                             │
│     → Nếu cần code: spawn Dev                              │
│                                                            │
│  2. Dev KHÔNG chạm file của Dev khác                       │
│     → Vi phạm ownership = conflict, revert                 │
│                                                            │
│  3. QA2 KHÔNG tự sửa lỗi                                  │
│     → Tìm thấy bug = báo SM, SM re-spawn Dev               │
│                                                            │
│  4. Mọi agent đọc GEMINI.md TRƯỚC KHI làm bất cứ điều gì  │
│     → GEMINI.md là nguồn sự thật duy nhất                  │
│                                                            │
│  5. Sprint chỉ DONE khi QA2 báo zero failures             │
│     → FAIL = không bao giờ ship                            │
└────────────────────────────────────────────────────────────┘
```

---

## 7. Cấu Trúc Thư Mục

```bash
mas/
│
├── GEMINI.md                     # ← Ground truth cho tất cả agents
├── CLAUDE.md → GEMINI.md         # ← Symlink cho Claude Code
│
├── docs/
│   ├── PRD/                      # Input của sprint — task + DoD
│   ├── report/
│   │   ├── architecture-decisions.md  # ARCH viết → Devs đọc
│   │   └── qa-report.md               # QA2 viết → SM điều phối
│   ├── tests/
│   │   └── test-plan.md          # QA1 viết → QA2 chạy
│   └── researches/spikes/        # Technical research
│
├── logs/
│   └── iteration/{run-id}/       # Execution logs per sprint
│
├── memory/
│   ├── agents/{subagent}.md      # Agent context (per .agents/rules/)
│   ├── task.md                   # Master Orchestrator task list
│   ├── progress.md               # Sprint progress
│   └── plan.md                   # Current plan
│
└── .agents/
    ├── rules/                    # Luật: Agent identity, git, UID
    └── workflows/                # claudecode-agent-rft, verify
```

---

## 8. Tổng Kết

```
┌────────────────────────────────────────────────────────────────┐
│                   TỔNG KẾT AGILE DEV AGENT TEAM                │
│                                                                │
│  Đọc GEMINI.md + docs/PRD/ → xác định task list               │
│                   │                                            │
│  Paste prompt vào Claude Code (AGENT_TEAMS=1)                  │
│                   │                                            │
│  SM spawn 6 teammates                                          │
│    ARCH → architecture-decisions.md                            │
│    QA1  → test-plan.md        ← SM: "APPROVED ✅"              │
│                   │                                            │
│  Dev1 │ Dev2 │ Dev3 (song song, không conflict file)           │
│    Mỗi Dev đọc GEMINI.md + arch-decisions trước khi code      │
│                   │                                            │
│  QA2 → qa-report.md                                           │
│                   │                                            │
│  Bug-fix loop: SM ↔ Dev ↔ QA2 → zero failures                 │
│                                                                │
│  Sprint DONE ✅                                                 │
│                                                                │
│  QUY TẮC VÀNG:                                                 │
│  SM không code │ ARCH/QA1/QA2 không code production           │
│  Dev chỉ touch file được giao │ QA2 chỉ báo lỗi, không fix   │
│  Mọi agent đọc GEMINI.md trước tiên — always                  │
└────────────────────────────────────────────────────────────────┘
```

---

> **Tham khảo kỹ thuật:**
> - Ground truth: [GEMINI.md](../GEMINI.md)
> - Agent Teams: `.agents/skills/build-with-claude-code/reference/agent-teams.md`
> - Agile Dev Brownfield directive: `.agents/skills/build-with-claude-code/agile-agent-team/agile-dev-brown-field.md`
> - Agent RFT: `.agents/workflows/claudecode-agent-rft.md`

---

_Tạo cho GSCfin MAS Seminar — Phiên bản Agile Dev Agent Team_

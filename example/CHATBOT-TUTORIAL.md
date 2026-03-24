---
id: tutorial:mas:qa-chatbot-basic
description: Hướng dẫn xây dựng một small MAS - Chat bot hỏi đáp bám sát kho tài liệu.
---

# TUTORIAL: Xây Dựng MAS Chat Bot Hỏi Đáp

> **MAS = Phần mềm (Agile Dev) + Mô phỏng Nghiệp vụ (Org Simulation)**
>
> Bài toán: Chat bot hỏi đáp **bám sát kho tài liệu**, tuyệt đối KHÔNG bịa thông tin.

---

## 1. Bài Toán

Xây một chat bot hỏi đáp với điều kiện tiên quyết:

- Câu trả lời **PHẢI** lấy từ kho tài liệu được cung cấp.
- Nếu không tìm thấy → phản hồi: **"KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"**.
- **Tuyệt đối KHÔNG được bịa thông tin** để trả lời.

---

## 2. MAS = Phần Mềm + Mô Phỏng Nghiệp Vụ

```
┌──────────────────────────────────────────────────────────────┐
│                     MAS CHAT BOT HỎI ĐÁP                     │
│                                                              │
│  ┌────────────────────┐        ┌────────────────────────┐    │
│  │   PHẦN MỀM         │        │  MÔ PHỎNG NGHIỆP VỤ    │    │
│  │   (Agile Dev)      │   +    │  (Org Simulation)      │    │
│  │                    │        │                        │    │
│  │ - Agent code       │        │ - 3 nhân viên          │    │
│  │ - Kho tài liệu     │        │ - Quy trình xử lý      │    │
│  │ - File giao tiếp   │        │ - Kiểm tra chéo        │    │
│  └────────────────────┘        └────────────────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Đội Hình: 3 Agent

```
┌──────────────────────────────────────────────────────────┐
│                    ĐỘI HÌNH 3 AGENT                      │
│                                                          │
│  ┌────────────────┐ ┌────────────────┐ ┌──────────────┐  │
│  │   ANALYZER     │ │   LIBRARIAN    │ │  VALIDATOR   │  │
│  │                │ │                │ │              │  │
│  │ Phân tích      │ │ Tìm kiếm       │ │ Kiểm tra     │  │
│  │ câu hỏi        │ │ kho tài liệu   │ │ câu trả lời  │  │
│  │ → Xác định     │ │ → Lập phản     │ │ → Đối chiếu  │  │
│  │   intent       │ │   hồi          │ │   với kho    │  │
│  └────────────────┘ └────────────────┘ └──────────────┘  │
│                                                          │
│  QUY TẮC VÀNG:                                           │
│  Không tìm thấy = Trả lời "KHÔNG TÌM THẤY".              │
│  Tuyệt đối KHÔNG bịa thông tin.                          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Chi tiết từng Agent

| Agent | Nhiệm vụ | Input | Output |
|:------|:---------|:------|:-------|
| **Analyzer** | Phân tích câu hỏi, xác định intent khoa học và có hệ thống | Câu hỏi của khách hàng | Intent + từ khoá chính |
| **Librarian** | Tìm kiếm kho tài liệu (local + web via CDP browser) theo intent, lập phản hồi | Intent từ Analyzer | Câu trả lời (hoặc "KHÔNG TÌM THẤY") |
| **Validator** | Kiểm tra câu trả lời có đúng nằm trong kho tài liệu không | Câu trả lời từ Librarian | PASS hoặc REJECT |

---

## 4. Quy Trình Xử Lý (Pipeline)

```
  Khách hàng gửi câu hỏi
         │
         ▼
  ┌──────────────┐
  │   ANALYZER   │  Bước 1: Phân tích câu hỏi
  │              │  - Tách ý chính
  │  "Câu hỏi   │  - Xác định intent
  │   này hỏi   │  - Xác định từ khoá
  │   về gì?"    │
  └──────┬───────┘
         │ intent + từ khoá
         ▼
  ┌──────────────┐
  │  LIBRARIAN   │  Bước 2: Tìm kiếm kho tài liệu
  │              │  - [A] Đọc docs/knowledge/ (local)
  │  "Kho tài   │  - [B] Duyệt web via CDP browser
  │   liệu có   │  - So khớp với intent
  │   gì không?" │  - Tìm thấy → Lập câu trả lời
  │              │  - Không thấy → "KHÔNG TÌM THẤY"
  └──────┬───────┘
         │ câu trả lời (hoặc "KHÔNG TÌM THẤY")
         ▼
  ┌──────────────┐
  │  VALIDATOR   │  Bước 3: Kiểm tra chéo
  │              │  - Đối chiếu câu trả lời với kho
  │  "Thông tin  │  - Xác nhận có trong kho → PASS
  │   này có    │  - Không tìm thấy → REJECT
  │   thật sự    │
  │   trong kho?"│
  └──────┬───────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌────────┐
│ PASS  │ │ REJECT│
└───┬───┘ └───┬────┘
    │         │
    ▼         ▼
 Gửi câu   Gửi: "KHÔNG TÌM
 trả lời   THẤY THÔNG TIN
 cho        LIÊN QUAN"
 khách
```

---

## 5. Giao Tiếp Giữa Các Agent

### Model A: Return-Value Chaining (Production — Scalable)

Mỗi agent **trả kết quả về cho Orchestrator**. Orchestrator giữ kết quả
trong context và truyền cho agent tiếp theo. **Không có file chia sẻ.**

```
┌────────────────────────────────────────────────────────────┐
│            RETURN-VALUE CHAINING (STATELESS)                │
│                                                            │
│  /chat "Câu hỏi?"                                         │
│     │                                                      │
│     ├─ Analyzer(question)  ──→ return intent   ──┐         │
│     │                                            │         │
│     │  Orchestrator giữ intent trong context     │         │
│     │                                            ▼         │
│     ├─ Librarian(intent)   ──→ return answer   ──┐         │
│     │                                            │         │
│     │  Orchestrator giữ answer trong context     │         │
│     │                                            ▼         │
│     └─ Validator(answer)   ──→ return PASS/REJECT          │
│                                                            │
│  ✅ Mỗi session hoàn toàn độc lập                           │
│  ✅ 10M users đồng thời = 10M pipeline riêng biệt           │
│  ✅ Không race condition, không shared state                 │
└────────────────────────────────────────────────────────────┘
```

**Tại sao scalable?** Mỗi lần gọi `/chat` tạo ra một session riêng.
Dữ liệu chỉ tồn tại trong context của session đó, giống như mỗi
cuộc gọi hàm có stack frame riêng — không bao giờ xung đột.

### Model B: Blackboard via File (Educational Only — ⚠️ Single-User)

```
┌────────────────────────────────────────────────────────────┐
│               BLACKBOARD MODEL (⚠️ SINGLETON)               │
│                                                            │
│  User A ghi intent.md ──┐                                  │
│                          ├── ❌ RACE CONDITION              │
│  User B ghi intent.md ──┘                                  │
│                                                            │
│  Analyzer ──→ memory/intent.md ──→ Librarian               │
│  Librarian ──→ memory/answer.md ──→ Validator              │
│                                                            │
│  ⚠️ Chỉ phục vụ được 1 user tại 1 thời điểm                │
│  ⚠️ File bị ghi đè khi nhiều user dùng đồng thời           │
└────────────────────────────────────────────────────────────┘
```

> **Lưu ý:** Model B chỉ dùng để hiểu concept. Production phải dùng Model A.

### So sánh hai Model

| Tiêu chí | Model A (Return-Value) | Model B (Blackboard) |
|:---------|:----------------------|:--------------------|
| Concurrent users | ✅ Không giới hạn | ❌ 1 user |
| Race condition | ✅ Không có | ❌ Có |
| Debug/Audit trail | Có thể log ra file | Tự động có file |
| Độ phức tạp | Thấp | Thấp |

### Debug Logs (Tuỳ chọn)

Thư mục `memory/` giữ lại như **audit logs** để debug, không phải kênh giao tiếp:

| File | Mục đích |
|:-----|:---------|
| `memory/intent.md` | Log kết quả phân tích gần nhất |
| `memory/answer.md` | Log câu trả lời gần nhất |
| `memory/validation.md` | Log kết quả kiểm tra gần nhất |
| `docs/knowledge/` | Kho tài liệu gốc (chỉ đọc) |

---

## 6. Quyết Định Và Quy Tắc

```
┌─────────────────────────────────────────────────────┐
│               QUY TẮC QUYẾT ĐỊNH                    │
│                                                     │
│  1. Librarian KHÔNG được bịa thông tin              │
│     Tìm thấy trong kho → Trả lời                    │
│     Không tìm thấy    → "KHÔNG TÌM THẤY"            │
│                                                     │
│  2. Validator PHẢI đối chiếu lại với kho            │
│     Thông tin đúng  → PASS                          │
│     Thông tin sai   → REJECT → trả về Librarian     │
│                                                     │
│  3. Chỉ gửi câu trả lời khi Validator PASS          │
│     REJECT = không bao giờ gửi cho khách            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 7. Cấu Trúc Thư Mục

```bash
mas-qa-chatbot/
├── docs/
│   └── knowledge/            # Kho tài liệu gốc (chỉ đọc)
│       ├── faq.md
│       ├── product-info.md
│       └── policy.md
├── tools/
│   └── browse_knowledge.py   # CDP browser tool (port 9222)
├── scripts/
│   └── log-session.sh        # Hook script — log session metadata
├── logs/
│   └── iteration/            # Session traces cho RFT
│       └── {run-id}/session.md
├── memory/                   # ⚠️ Debug logs only
│   ├── intent.md
│   ├── answer.md
│   └── validation.md
├── .agents/
│   ├── rules/
│   │   └── SOUL.md           # Quy tắc văn hoá MAS
│   └── workflows/
│       └── claudecode-agent-rft.md  # Agent RFT workflow
└── .claude/
    ├── settings.json          # Hooks config (Stop → log-session)
    ├── agents/
    │   ├── analyzer.md        # Agent Analyzer (Read, Grep, Glob)
    │   ├── librarian.md       # Agent Librarian (+ Bash → CDP tool)
    │   └── validator.md       # Agent Validator (+ Bash → CDP tool)
    └── skills/
        └── chat/
            └── SKILL.md       # /chat — Pipeline orchestrator
```

---

## 8. Tổng Kết

```
┌─────────────────────────────────────────────────────────────┐
│                   TỔNG KẾT MAS CHAT BOT                     │
│                                                             │
│  /chat "Câu hỏi"                                           │
│     │                                                       │
│     ├─ ANALYZER ─→ intent (return-value chaining)           │
│     ├─ LIBRARIAN ─→ answer (local + web CDP tool)           │
│     └─ VALIDATOR ─→ PASS/REJECT (cross-check cả 2 nguồn)   │
│                                                             │
│  KHO TÀI LIỆU:                                             │
│  - Local: docs/knowledge/ (faq, product-info, policy)       │
│  - Web: RBXInsightBot via tools/browse_knowledge.py (CDP)   │
│                                                             │
│  SESSION LOGGING → logs/iteration/{run-id}/session.md       │
│  AGENT RFT → /claudecode-agent-rft (Collect→Score→Improve) │
│                                                             │
│  QUY TẮC:                                                   │
│  - Không tìm thấy = "KHÔNG TÌM THẤY THÔNG TIN LIÊN QUAN"   │
│  - Không bịa thông tin                                      │
│  - Validator REJECT = không gửi cho khách                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

> **Tiếp theo:** Đọc [spike-step-by-step-on-creating-mas.md](docs/researches/spikes/spike-step-by-step-on-creating-mas.md) để hiểu cách implement chi tiết với Claude Code.

---

_Tạo cho GSCfin MAS Seminar — Phiên bản cơ bản_

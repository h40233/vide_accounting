# Design: Multi-Account & Group Accounting System

## Architecture Overview
系統核心設計考量：Google 唯一授權、多向帳戶、群組數據隔離與權限、以及排程化後台任務。

- **Auth**: Google OAuth2 (Google Sign-In)
- **Task Worker**: 透過 Redis 佇列，處理 `Recurring Payment` 與 `Daily Check`。

## Database Schema (PostgreSQL)

### Table: `users`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `google_sub` | VARCHAR(255)| Unique, NOT NULL (Google ID) |
| `email` | VARCHAR(255) | Unique, NOT NULL |
| `display_name` | VARCHAR(255) | |
| `avatar_url` | TEXT | | (Google 帳戶大頭貼網址) |

### Table: `accounts`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `user_id` | UUID | Foreign Key (users.id) |
| `name` | VARCHAR(100) | e.g. "Cash", "Bank" |
| `balance` | DECIMAL(15, 2)| NOT NULL |
| `type` | VARCHAR(50) | 'liquid', 'savings', 'credit' |

### Table: `groups`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `name` | VARCHAR(100) | |
| `creator_id` | UUID | Foreign Key (users.id) |

### Table: `group_memberships`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `user_id` | UUID | PK, FK (users.id) |
| `group_id` | UUID | PK, FK (groups.id) |
| `role` | VARCHAR(50) | 'owner', 'member' |
| `show_balance` | BOOLEAN | Default: FALSE |

### Table: `transactions`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `user_id` | UUID | Foreign Key (users.id) |
| `account_id` | UUID | Foreign Key (accounts.id) |
| `amount` | DECIMAL(15, 2)| |
| `type` | VARCHAR(50) | 'income', 'expense' |
| `category` | VARCHAR(100) | |
| `note` | TEXT | |
| `date` | TIMESTAMP | |

### Table: `schedules` (自動記帳排程)
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `user_id` | UUID | Foreign Key (users.id) |
| `account_id` | UUID | Foreign Key (accounts.id) |
| `amount` | DECIMAL(15, 2)| |
| `category` | VARCHAR(100) | |
| `note` | TEXT | |
| `interval_days` | INTEGER | 每隔幾天執行 |
| `next_run` | TIMESTAMP | 下次執行時間 |

### Table: `notifications` (系統內通知)
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `user_id` | UUID | Foreign Key (users.id) |
| `content` | TEXT | |
| `type` | VARCHAR(50) | 'reminder', 'auto_log', 'failed' |
| `is_read` | BOOLEAN | Default: FALSE |

## API Definition
- `POST /auth/google`: 透過 Google Token 進行登入/換取 JWT。
- `GET/POST /accounts`: 帳戶管理。
- `GET /groups`: 查詢所屬群組。
- `GET /groups/{id}/report`: 前往群組收支分析與報告（統計各人流水）。
- `PATCH /groups/{id}/membership`: 更新個人權限（如 `show_balance`）。

## Docker Configuration
- **Backend (FastAPI)**: 主 API 伺服器且暴露 `8000`。
- **Worker (FastAPI/Celery)**: 訂閱 Redis 排程任務。
- **Redis**: 暫存排程資料。

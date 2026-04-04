# Tasks: Advanced Accounting App Implementation List

## Phase 1: Infrastructure & Database (Initial)
- [ ] 撰寫 `docker-compose.yml` (backend, db, redis, worker)。
- [ ] 撰寫 `init.sql` 以建立 `users`, `accounts`, `groups`, `transactions`, `schedules`, `notifications` 表。
- [ ] 驗證資料庫容器連線與資料表結構。

## Phase 2: Google Auth & Account Management
- [ ] 實作 `POST /auth/google` (與 Google OAuth2 API 驗證)。
- [ ] 實作 JWT Token 生成與中介軟體 (Middleware) 驗證。
- [ ] 實作 `GET/POST /accounts` 端點（預設建立系統帳戶）。
- [ ] 撰寫帳戶餘額更新的資料庫觸發器或後端邏輯。

## Phase 3: Transaction CRUD & Reporting
- [ ] 實作 `GET/POST/PUT/DELETE /transactions`。
- [ ] 實作 `/transactions/report` (依類別、時間統計收支)。
- [ ] 實作 `/transactions/export` (可選報表導出)。

## Phase 4: Family Groups & Visibility
- [ ] 實作 `POST /groups` (建立群組)。
- [ ] 實作 `POST /groups/invite` (邀請成員與驗證)。
- [ ] 實作 `GET /groups/{id}/transactions` (查看所有人流水)。
- [ ] 實作 `GET /groups/{id}/balances` (依權限 `show_balance` 顯示)。

## Phase 5: Worker & Automation Tasks
- [ ] 實作背景 Worker (Celery/FastAPI) 處理定時任務。
- [ ] 實作「固定支出自動記帳」邏輯（每日午夜）。
- [ ] 實作「每日記帳提醒」邏輯（每日晚間 9:00）。
- [ ] 實作 `GET /notifications` 與未讀標記。

## Phase 6: Flutter Web Development (Front-End)
- [ ] 初始化 Flutter 專案，設定 Web 支援。
- [ ] 整合 `google_sign_in` 插件。
- [ ] 實作帳戶切換 Drawer。
- [ ] 實作群組管理與權解設定介面。
- [ ] 實作 Dashboard 統計圓餅圖與流水清單。

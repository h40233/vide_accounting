# Specs: Detailed Logic for Multi-Account & Grouping

## Authentication Flow (Google OAuth2)
- **Login**: 前端傳入 Google `idToken` 或 `accessToken`。
- **Verify**: 後端驗證 Token 合法性，並比對資料庫 `google_sub`。
- **Flow**:
    - 若 `google_sub` 不存在，自動建立 User & 一個預設的系統帳戶 (Cash)。
    - 若 `google_sub` 已存在，更新 `display_name` 與 `avatar_url` 並回傳 JWT。
- **JWT**: 用於後續所有 API 調用。

## Multi-Account Logic
- **Balance Integrity**:
    - 每一筆 Transaction 都必須關聯 `account_id`。
    - 交易建立後，系統應自動在 `accounts` 表更新該帳戶的 `balance`。
- **Account Transfer**: 提供轉帳功能 (由帳戶 A 轉至帳戶 B)，需產生兩筆 Transaction (Out/In)。

## Group Management & Permissions
### Visibility Control
- **Transactions**: 群組內所有成員皆可看見群組內其他人的「收支流水」（類別、金額、備註）。
- **Balances**: 只有當 `show_balance` 為 TRUE 時，群組內其他人才看得到該成員的「個人總資產/各帳戶餘額」。
- **Reports**: 提供「群組總收支」報告，統計群組全體成員的數據。

## Automated Tasks (The Worker)
### 1. Recurring Payments (固定支出)
- **Trigger**: 每天午夜執行一次。
- **Process**:
    - 遍歷所有 `next_run` 為今日或更早的 `schedules`。
    - 生成一筆 Transaction 並更新 `accounts.balance`。
    - 更新 `next_run = next_run + interval_days`。
- **Negative Balance**: 如果餘額不足變為負數，系統應發送 `auto_log` 類型通知，標題為「自動記帳成功 (餘額揭示負數)」，內容包含項目與當前餘額。

### 2. Daily Reminder (記帳提醒)
- **Trigger**: 每天晚上 9:00 (預設) 執行。
- **Process**:
    - 檢查每個 `user_id` 在本日 (00:00 - 現在) 是否有任何 Transaction 紀錄。
    - 若無，發送 `reminder` 類型通知。內容為：「您今天還沒記帳喔！快點進來記一筆吧！」

## System Notifications
- **In-App only (Initial Phase)**:
    - 前端 Dashboard 顯示未讀通知紅點。
    - `GET /notifications` 獲取通知列表。
    - `PATCH /notifications/{id}/read` 標記已讀。
- **Android/iOS Push (Phase 2)**:
    - 整合 Firebase Cloud Messaging (FCM) 進行外部通知發送。

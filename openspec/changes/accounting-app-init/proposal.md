# Proposal: Advanced Accounting App (Google Auth + Multi-Account + Groups)

## Goals
建立一個全方位的個人與家庭財務管理系統。支援 Google 唯一的身份驗證、多帳戶管理（現金/銀行）、家庭群組協作及高度自動化的記帳體驗。

### 原則
- **極簡登入**: 排除繁瑣註冊，僅使用 Google 登入。
- **透明協作**: 家庭成員可依權限共享支出流水與餘額資訊。
- **自動化優先**: 減少手動操作，透過每日提醒與定期自動記帳保持數據更新。
- **負數容忍**: 自動記帳允許餘額為負，並透過系統通知使用者後續處理。

## User Stories
- **身為使用者**，我希望直接用 Google 帳號登入，快速開始記帳。
- **身為使用者**，我希望將我的「現金」與「銀行」帳戶分開管理，清楚知道各別餘額。
- **身為群組發起人**，我希望邀請家人加入群組，共同管理家庭開支。
- **身為群組成員**，我希望設定「不公開我的帳戶總額」，但仍能與家人共享消費流水。
- **身為上班族**，我希望「定期訂閱服務」能自動每月記帳，省去手動紀錄的時間。
- **身為健忘的使用者**，我希望每晚收到系統提醒，如果我今天還沒記帳的話。

## Technical Selection
- **Frontend**: Flutter (Priority: Web > Android > iOS)
- **Backend**: Python FastAPI (Async API)
- **Database**: PostgreSQL (Structured data)
- **Background Tasks**: Redis + Celery/FastAPI Tasks (Recurring & Notifications)
- **Auth**: Google OAuth2 (No local passwords)

## Out of Scope
- 發票影像辨識 (OCR)（初期）。

## Acceptance Criteria
- [ ] 僅支援 Google 登入並成功導向個人頁面。
- [ ] 支援新增多個帳戶並計算總資產。
- [ ] 能建立群組並透過 Email/Invitation Code 邀請他人。
- [ ] 定期支出排程在背景成功運行且產生流水紀錄。
- [ ] 如果今日無記帳，系統於晚間準時發送系統內通知。

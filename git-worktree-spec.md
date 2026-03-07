# Feature Spec: Backend
# Feature Spec: Database

> 此文件由 Git Worktree Design Skill 自動產生，供 AI Agent 作為開發指引。

## 分支資訊

| 項目 | 值 |
|------|-----|
| 分支名稱 | `feature/backend` |
| 基於分支 | `main` |
| Worktree 路徑 | `d:\Vide Coding project\accounting-backend` |
| 分支名稱 | `feature/database` |
| 基於分支 | `main` |
| Worktree 路徑 | `d:\Vide Coding project\accounting-database` |
| 建立時間 | 2026-03-07 |

## 目標

使用 Java Spring Boot 建構後端服務

## 實作範圍

- [x] 初始化 Spring Boot 專案 (Spring Web, Spring Data JPA/JDBC)
- [x] 建立對應 Database Schema 的 Entities 
- [x] 實作基本的 API Controllers (視與 Supabase 的分工而定，處理複雜業務邏輯)
- [x] (可選) 串接 Supabase Auth / Connection Pooler
- [x] API 說明文件 (Swagger/OpenAPI) 生成

## 驗收標準

- Spring Boot 應用程式可成功啟動
- 開出的 API 接口可用 Postman/curl 成功呼叫並返回預期結果

## 技術約束

- 使用 Java Spring Boot 框架
- 遵循 RESTful API 設計風格
- 保持乾淨的架構 (Controller -> Service -> Repository)

## 跨分支備註

- **相依於 `feature/database`**，需等 Database Schema 確立後才能建立 Entities。
撰寫 Supabase 建表語法 (Users, Families, Transactions) 及 RLS 安全規則

## 實作範圍

- [x] 設計並撰寫 `Users` 表格 (id, email, name)
- [x] 設計並撰寫 `Families` 表格 (id, name, created_at)
- [x] 設計並撰寫 `Transactions` 表格 (id, family_id, user_id, amount, category, type, date, note)
- [x] 撰寫對應的 Foreign Key 約束
- [x] 設定 RLS (Row Level Security) 確保只有同一個 Family ID 的人能看到該筆資料

## 驗收標準

- SQL 腳本可在 Supabase SQL Editor 中成功執行無報錯
- RLS 行為符合預期 (家族成員只能存取所屬家族的交易紀錄)

## 技術約束

- 限定使用 Supabase 適用的 PostgreSQL 語法
- 預設啟用 RLS
- 將所有 SQL 語句整理在一個或多個清晰的 `.sql` 檔案中

## 跨分支備註

- **無相依，此為最優先執行步驟。** 後端與前端需等待此階段定義出明確的 Table Schema 才能順利開發。

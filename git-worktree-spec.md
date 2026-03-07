# Feature Spec: Backend

> 此文件由 Git Worktree Design Skill 自動產生，供 AI Agent 作為開發指引。

## 分支資訊

| 項目 | 值 |
|------|-----|
| 分支名稱 | `feature/backend` |
| 基於分支 | `main` |
| Worktree 路徑 | `d:\Vide Coding project\accounting-backend` |
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

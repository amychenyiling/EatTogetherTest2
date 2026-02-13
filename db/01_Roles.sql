/*
 * 檔案名稱：01_Roles.sql
 * 負責成員：A (怡伶)
 * 用途：建立餐廳的職位角色資料 (Phase 1)
 * 說明：定義系統中可用的身份，供 UserRoles 連結使用
 */

USE EatTogetherTest2;
GO

-- 開啟手動插入 ID 功能 (為了確保大家的 ID 一致)
SET IDENTITY_INSERT Roles ON;
GO

-- 清除舊資料 (開發階段用，避免重複 Insert 報錯)
-- 注意：若 Roles 已經被 UserRoles 引用，這行 DELETE 會失敗，請視情況使用
DELETE FROM Roles WHERE Id BETWEEN 1 AND 8;
GO

INSERT INTO Roles (Id, RoleName, Description, CreatedAt) VALUES
(1, N'系統管理員', N'擁有系統最高權限，負責維護 RBAC 與資料庫設定 (開發人員用)', GETDATE()),

(2, N'店長', N'餐廳最高負責人，擁有查看營收報表、人事管理與退款權限', GETDATE()),

(3, N'副店長', N'協助店長處理店務，擁有排班管理與訂位衝突處理權限', GETDATE()),

(4, N'行政主廚', N'內場負責人，擁有菜單管理(新增/下架餐點)、成本控管與食材叫貨權限', GETDATE()),

(5, N'二廚/廚助', N'內場執行人員，僅能查看訂單明細與切換餐點庫存狀態', GETDATE()),

(6, N'外場領班', N'外場負責人，擁有特殊折扣授權、處理客訴與座位調度權限', GETDATE()),

(7, N'正職服務生', N'外場執行人員，負責點餐、結帳、送餐與桌況更新', GETDATE()),

(8, N'計時人員', N'工讀生，僅擁有基礎點餐與送餐權限，無法操作結帳或折扣', GETDATE());
GO

-- 關閉手動插入 ID 功能
SET IDENTITY_INSERT Roles OFF;
GO

-- 驗證資料
SELECT * FROM Roles ORDER BY Id;
GO
/*
 * 腳本名稱：Reset_All.sql
 * 專案名稱：EatTogether (義起吃)
 * 用途：一鍵重置資料庫結構並匯入所有測試資料
 * 注意事項：
 * 1. 請務必在 SSMS 中開啟 [SQLCMD Mode] (查詢 -> SQLCMD 模式)
 * 2. 請確認所有 .sql 檔案都放在同一個目錄下(如下)，或是修改下方的 $(Path) 變數
		db
		├── CreateDatabase.sql       (負責建庫與建表)
		├── Reset_All.sql            (總指揮官：依序執行所有 db 資料夾中的 .sql 檔)
		├── 01_Roles.sql             (資料檔...)
		├── 02_Functions.sql         (資料檔...)
		...
		└── 99_Update_Payment_FK.sql (最後修復檔)
 */

-- =============================================
-- 1. 設定檔案路徑變數
-- =============================================
-- 預設為當前目錄 (.)，如果執行失敗，請將下行改成絕對路徑，例如 "C:\Users\User\Desktop\DB_Scripts"
:setvar Path "C:\Users\User\Desktop\資展全端班\EatTogetherTest\db"

-- =============================================
-- 2. 重建資料庫結構 (Schema)
-- =============================================
PRINT '>>> 正在重建資料庫結構 (Drop & Create Database)...';
:r $(Path)\CreateDatabase.sql
GO

USE EatTogetherTest2;
GO

PRINT '>>> 資料庫結構建立完成，開始匯入資料...';

-- =============================================
-- 3. Phase 1: 基礎獨立資料 (Level 1)
-- =============================================
PRINT '>>> [Phase 1] 匯入基礎資料...';

-- 權限
:r $(Path)\01_Roles.sql
--:r $(Path)\02_Functions.sql
--:r $(Path)\03_Users.sql

-- 會員
--:r $(Path)\04_Members.sql

-- 菜單
--:r $(Path)\05_Categories.sql
--:r $(Path)\06_SetMeals.sql

-- 行銷與桌位
--:r $(Path)\07_Tables.sql
--:r $(Path)\08_Coupons.sql
--:r $(Path)\09_Reservations.sql

-- 品牌與活動
--:r $(Path)\10_Events.sql
--:r $(Path)\11_ArticleCategories.sql
--:r $(Path)\12_EmailQueue.sql

-- =============================================
-- 4. Phase 2: 依賴型資料 (Level 2)
-- =============================================
PRINT '>>> [Phase 2] 匯入依賴型資料...';

-- 權限關聯
--:r $(Path)\13_UserRoles.sql
--:r $(Path)\14_RoleFunctions.sql

-- 菜單細項
--:r $(Path)\15_Dishes.sql

-- 文章與訂閱
--:r $(Path)\16_Articles.sql
--:r $(Path)\17_SubscriptionPreferences.sql

-- =============================================
-- 5. Phase 3: 複合與關聯資料 (Level 3)
-- =============================================
PRINT '>>> [Phase 3] 匯入複合關聯資料...';

-- 套餐內容
--:r $(Path)\18_SetMealItems.sql

-- 收藏
--:r $(Path)\19_MemberFavorites.sql

-- 領券
--:r $(Path)\20_MemberCoupons.sql

-- 通知
--:r $(Path)\21_UserNotifications.sql

-- =============================================
-- 6. Phase 4: 核心交易資料 (Transaction Data)
-- =============================================
PRINT '>>> [Phase 4] 匯入交易核心資料...';

-- 訂單與付款 - 循環參照處理
-- 步驟 1: 先建立 Payments (OrderId 此時為 NULL)
--:r $(Path)\22_Payments.sql

-- 步驟 2: 建立訂單 (FK 指向 Payments)
--:r $(Path)\23_PreOrders.sql
--:r $(Path)\24_Orders.sql

-- 步驟 3: 建立訂單明細
--:r $(Path)\25_PreOrderDetails.sql
--:r $(Path)\26_OrderDetails.sql

-- =============================================
-- 7. 收尾：修復循環參照 (Fix Circular Reference)
-- =============================================
PRINT '>>> [Phase 5] 更新付款單關聯 (Update Payments FK)...';

-- 執行最後的 UPDATE 語句，把 OrderId 填回 Payments 表
--:r $(Path)\99_Update_Payment_FK.sql

-- =============================================
-- 完成
-- =============================================
PRINT '>>> ==========================================';
PRINT '>>> 全部執行完畢！資料庫 EatTogetherDB 重置成功。';
PRINT '>>> ==========================================';
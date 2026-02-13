/*
 * 資料庫專題：EatTogether (義起吃)
 * 資料庫名稱：EatTogetherTest2
 * 伺服器版本：SQL Server 2025
 * 產生時間：2026-02-11
 */

USE master;
GO

-- 檢查資料庫是否存在(注意資料庫名稱是否正確)，若存在則刪除 (開發階段方便重置，正式環境請小心)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'EatTogetherTest2')
BEGIN
    ALTER DATABASE EatTogetherTest2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE EatTogetherTest2;
END
GO

CREATE DATABASE EatTogetherTest2;
GO

USE EatTogetherTest2;
GO

/* ==========================================================================
   權限與會員系統 (RBAC)
   ========================================================================== */

-- 1. Roles (角色表)
CREATE TABLE Roles (
    Id INT IDENTITY(1,1) NOT NULL,
    RoleName NVARCHAR(20) NOT NULL,
    Description NVARCHAR(100) NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_Roles PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX IX_Roles_RoleName ON Roles(RoleName);
GO

-- 2. Functions (功能權限表)
CREATE TABLE Functions (
    Id INT IDENTITY(1,1) NOT NULL,
    Category NVARCHAR(10) NOT NULL,
    FunctionName VARCHAR(50) NOT NULL,
    DisplayName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(200) NULL,
    CONSTRAINT PK_Functions PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX IX_Functions_FunctionName ON Functions(FunctionName);
GO

-- 3. RoleFunctions (角色權限對照表 - 多對多)
CREATE TABLE RoleFunctions (
    Id INT IDENTITY(1,1) NOT NULL,
    RoleId INT NOT NULL,
    FunctionId INT NOT NULL,
    CONSTRAINT PK_RoleFunctions PRIMARY KEY (Id),
    CONSTRAINT FK_RoleFunctions_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id),
    CONSTRAINT FK_RoleFunctions_Functions FOREIGN KEY (FunctionId) REFERENCES Functions(Id)
);
CREATE UNIQUE INDEX IX_RoleFunctions_Role_Func ON RoleFunctions(RoleId, FunctionId);
GO

-- 4. Users (員工帳號表)
CREATE TABLE Users (
    Id INT IDENTITY(1,1) NOT NULL,
    Account VARCHAR(50) NOT NULL,
    Password VARBINARY(128) NOT NULL,
    EmployeeNumber VARCHAR(20) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Phone VARCHAR(10) NOT NULL,
    HireDate DATE NOT NULL,
    TerminationDate DATE NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL, -- 0:請假, 1:啟用
    IsDeleted BIT DEFAULT 0 NOT NULL, -- 軟刪除 0:在職, 1:刪除
    DeletedAt DATETIME2(0) NULL,
    CONSTRAINT PK_Users PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX IX_Users_Account ON Users(Account);
CREATE UNIQUE INDEX IX_Users_EmployeeNumber ON Users(EmployeeNumber);
CREATE UNIQUE INDEX IX_Users_Email ON Users(Email);
GO

-- 5. UserRoles (員工角色對照表 - 多對多)
CREATE TABLE UserRoles (
    Id INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    CONSTRAINT PK_UserRoles PRIMARY KEY (Id),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);
CREATE UNIQUE INDEX IX_UserRoles_User_Role ON UserRoles(UserId, RoleId);
GO

/* ==========================================================================
   會員管理系統 (Member Management)
   ========================================================================== */

-- 6. Members (會員資料表)
CREATE TABLE Members (
    Id INT IDENTITY(1,1) NOT NULL,
    Account VARCHAR(100) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Password VARBINARY(128) NOT NULL,
    Phone VARCHAR(10) NOT NULL,
    BirthDate DATE NULL,
    IsBlacklisted BIT DEFAULT 0 NOT NULL, -- 0:正常, 1:停權
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    IsDeleted BIT DEFAULT 0 NOT NULL, -- 0:使用中, 1:已刪除
    DeletedAt DATETIME2(0) NULL,
    CONSTRAINT PK_Members PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX IX_Members_Account ON Members(Account);
CREATE UNIQUE INDEX IX_Members_Email ON Members(Email);
CREATE INDEX IX_Members_IsDeleted ON Members(IsDeleted);
GO

/* ==========================================================================
   菜單與食譜系統 (需先建立，因訂單與收藏需關聯此處)
   ========================================================================== */

-- 7. Categories (餐點分類表)
CREATE TABLE Categories (
    Id INT IDENTITY(1,1) NOT NULL,
    CategoryName NVARCHAR(50) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    ParentCategoryId INT NULL,
    DisplayOrder INT DEFAULT 0 NOT NULL,
    ImageUrl NVARCHAR(300) NULL,
    UpdatedAt DATETIME2(0) NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (Id),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryId) REFERENCES Categories(Id),
    CONSTRAINT CK_Categories_DisplayOrder CHECK (DisplayOrder >= 0)
);
GO

-- 8. Dishes (餐點表 / 規格書中的 Products)
CREATE TABLE Dishes (
    Id INT IDENTITY(1,1) NOT NULL,
    CategoryId INT NOT NULL,
    DishName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL, -- 1=上架
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    Description NVARCHAR(300) NULL,
    ImageUrl NVARCHAR(300) NULL,
    IsTakeOut BIT DEFAULT 1 NOT NULL,
    IsLimited BIT DEFAULT 0 NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    UpdatedAt DATETIME2(0) NULL,
    CONSTRAINT PK_Dishes PRIMARY KEY (Id),
    CONSTRAINT FK_Dishes_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(Id),
    CONSTRAINT CK_Dishes_Price CHECK (Price >= 0)
);
GO

-- 9. SetMeals (套餐表)
CREATE TABLE SetMeals (
    Id INT IDENTITY(1,1) NOT NULL,
    SetMealName NVARCHAR(100) NOT NULL,
    DiscountType NVARCHAR(20) NOT NULL, -- 'fixed' or 'percent'
    DiscountValue DECIMAL(10,2) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    SetPrice DECIMAL(10,2) NULL,
    Description NVARCHAR(300) NULL,
    ImageUrl NVARCHAR(300) NULL,
    UpdatedAt DATETIME2(0) NULL,
    CONSTRAINT PK_SetMeals PRIMARY KEY (Id),
    CONSTRAINT CK_SetMeals_DiscountValue CHECK (DiscountValue >= 0),
    CONSTRAINT CK_SetMeals_SetPrice CHECK (SetPrice >= 0),
    CONSTRAINT CK_SetMeals_DiscountType CHECK (DiscountType IN ('fixed', 'percent'))
);
GO

-- 10. SetMealItems (套餐內容表)
CREATE TABLE SetMealItems (
    Id INT IDENTITY(1,1) NOT NULL,
    SetMealId INT NOT NULL,
    DishId INT NOT NULL,
    Quantity INT DEFAULT 1 NOT NULL,
    IsOptional BIT DEFAULT 0 NOT NULL,
    OptionGroupNo INT NULL,
    PickLimit INT NULL,
    DisplayOrder INT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_SetMealItems PRIMARY KEY (Id),
    CONSTRAINT FK_SetMealItems_SetMeals FOREIGN KEY (SetMealId) REFERENCES SetMeals(Id),
    CONSTRAINT FK_SetMealItems_Dishes FOREIGN KEY (DishId) REFERENCES Dishes(Id),
    CONSTRAINT CK_SetMealItems_Quantity CHECK (Quantity >= 1),
    CONSTRAINT CK_SetMealItems_PickLimit CHECK (PickLimit >= 1),
    CONSTRAINT CK_SetMealItems_DisplayOrder CHECK (DisplayOrder >= 0)
);
GO

-- 11. MemberFavorites (會員收藏表) - 依賴 Members 和 Dishes
CREATE TABLE MemberFavorites (
    Id INT IDENTITY(1,1) NOT NULL,
    MemberId INT NOT NULL,
    ProductId INT NOT NULL, -- 對應 Dishes.Id
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_MemberFavorites PRIMARY KEY (Id),
    CONSTRAINT FK_MemberFavorites_Members FOREIGN KEY (MemberId) REFERENCES Members(Id),
    CONSTRAINT FK_MemberFavorites_Dishes FOREIGN KEY (ProductId) REFERENCES Dishes(Id)
);
CREATE UNIQUE INDEX IX_MemberFavorites_Mem_Prod ON MemberFavorites(MemberId, ProductId);
GO

/* ==========================================================================
   行銷與客服系統 (需先建立 Tables, Coupons 供訂單使用)
   ========================================================================== */

-- 12. Tables (桌位資料表)
CREATE TABLE Tables (
    Id INT IDENTITY(1,1) NOT NULL,
    TableName NVARCHAR(20) NOT NULL,
    SeatCount INT DEFAULT 2 NOT NULL,
    Status INT DEFAULT 0 NOT NULL, -- 0:空桌, 1:用餐中, 2:保留
    CONSTRAINT PK_Tables PRIMARY KEY (Id),
    CONSTRAINT CK_Tables_SeatCount CHECK (SeatCount > 0),
    CONSTRAINT CK_Tables_Status CHECK (Status BETWEEN 0 AND 2)
);
CREATE UNIQUE INDEX IX_Tables_TableName ON Tables(TableName);
GO

-- 13. Reservations (訂位紀錄表)
CREATE TABLE Reservations (
    Id INT IDENTITY(1,1) NOT NULL,
    BookingNumber VARCHAR(10) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    ReservationDate DATETIME2(0) NOT NULL,
    AdultsCount INT DEFAULT 1 NOT NULL,
    ChildrenCount INT DEFAULT 0 NOT NULL,
    Status INT DEFAULT 0 NOT NULL, -- 0:訂位中, 1:已報到, 2:已取消, 3:NoShow
    Remark NVARCHAR(200) NULL,
    ReservedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_Reservations PRIMARY KEY (Id),
    CONSTRAINT CK_Reservations_Adults CHECK (AdultsCount > 0),
    CONSTRAINT CK_Reservations_Children CHECK (ChildrenCount >= 0),
    CONSTRAINT CK_Reservations_Status CHECK (Status BETWEEN 0 AND 3)
);
CREATE UNIQUE INDEX IX_Reservations_BookingNumber ON Reservations(BookingNumber);
CREATE INDEX IX_Reservations_Date ON Reservations(ReservationDate);
GO

-- 14. Coupons (優惠券設定表)
CREATE TABLE Coupons (
    Id INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    Code VARCHAR(20) NOT NULL,
    DiscountType INT DEFAULT 0 NOT NULL, -- 0:扣金額($), 1:打折(%)
    DiscountValue INT DEFAULT 0 NOT NULL,
    MinSpend INT DEFAULT 0 NOT NULL,
    StartDate DATETIME2(0) NOT NULL,
    EndDate DATETIME2(0) NULL, -- Null代表永久
    LimitCount INT NULL, -- Null代表無限
    ReceivedCount INT NULL,
    CONSTRAINT PK_Coupons PRIMARY KEY (Id),
    CONSTRAINT CK_Coupons_DiscountValue CHECK (DiscountValue > 0),
    CONSTRAINT CK_Coupons_MinSpend CHECK (MinSpend >= 0),
    CONSTRAINT CK_Coupons_Type CHECK (DiscountType IN (0, 1))
);
CREATE UNIQUE INDEX IX_Coupons_Code ON Coupons(Code);
GO

-- 15. MemberCoupons (會員領券紀錄表)
CREATE TABLE MemberCoupons (
    Id INT IDENTITY(1,1) NOT NULL,
    MemberId INT NOT NULL,
    CouponId INT NOT NULL,
    IsUsed BIT DEFAULT 0 NOT NULL,
    UsedDate DATETIME2(0) NULL,
    CONSTRAINT PK_MemberCoupons PRIMARY KEY (Id),
    CONSTRAINT FK_MemberCoupons_Members FOREIGN KEY (MemberId) REFERENCES Members(Id),
    CONSTRAINT FK_MemberCoupons_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(Id)
);
GO

/* ==========================================================================
   訂單與交易系統 (相依性最高，最後建立)
   注意：Orders 和 Payments 互相關聯，這裡先建立 Table，最後再加 FK
   ========================================================================== */

-- 16. PreOrders (已建立的訂單 - 暫存)
CREATE TABLE PreOrders (
    Id INT IDENTITY(1,1) NOT NULL,
    OrderNumber NVARCHAR(200) NOT NULL,
    MemberId INT NULL,
    InOrOut BIT DEFAULT 0 NOT NULL, -- 0:內用, 1:外帶
    TableId INT NULL,
    UserId INT NULL, -- 結帳員工
    OrderAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CouponId INT NULL,
    OriginalAmount INT NOT NULL,
    DiscountAmount INT DEFAULT 0 NOT NULL,
    TotalAmount INT DEFAULT 0 NOT NULL,
    Note NVARCHAR(200) NULL,
    PaymentId INT NULL, -- 這裡先不設 FK，避免 Circular Dependency
    PayMethod NVARCHAR(50) NOT NULL,
    DoneOrCancel INT DEFAULT 0 NOT NULL, -- 0:未完成, 1:已完成, 2:已取消
    CONSTRAINT PK_PreOrders PRIMARY KEY (Id),
    CONSTRAINT FK_PreOrders_Members FOREIGN KEY (MemberId) REFERENCES Members(Id),
    CONSTRAINT FK_PreOrders_Tables FOREIGN KEY (TableId) REFERENCES Tables(Id),
    CONSTRAINT FK_PreOrders_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_PreOrders_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(Id),
    CONSTRAINT CK_PreOrders_TotalAmount CHECK (TotalAmount >= 0)
);
CREATE UNIQUE INDEX IX_PreOrders_OrderNumber ON PreOrders(OrderNumber);
CREATE INDEX IX_PreOrders_OrderAt ON PreOrders(OrderAt);
GO

-- 17. Orders (已完成訂單主檔)
CREATE TABLE Orders (
    Id INT IDENTITY(1,1) NOT NULL,
    PreOrderId INT NOT NULL,
    OrderNumber NVARCHAR(200) NOT NULL,
    MemberId INT NULL,
    InOrOut BIT DEFAULT 0 NOT NULL,
    TableId INT NULL,
    UserId INT NULL,
    OrderAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CouponId INT NULL,
    OriginalAmount INT NOT NULL,
    DiscountAmount INT DEFAULT 0 NOT NULL,
    TotalAmount INT DEFAULT 0 NOT NULL,
    Note NVARCHAR(200) NULL,
    PaymentId INT NOT NULL, -- 這裡先不設 FK
    PayMethod NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (Id),
    CONSTRAINT FK_Orders_PreOrders FOREIGN KEY (PreOrderId) REFERENCES PreOrders(Id),
    CONSTRAINT FK_Orders_Members FOREIGN KEY (MemberId) REFERENCES Members(Id),
    CONSTRAINT FK_Orders_Tables FOREIGN KEY (TableId) REFERENCES Tables(Id),
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Orders_Coupons FOREIGN KEY (CouponId) REFERENCES Coupons(Id),
    CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0)
);
CREATE UNIQUE INDEX IX_Orders_OrderNumber ON Orders(OrderNumber);
CREATE INDEX IX_Orders_OrderAt ON Orders(OrderAt);
GO

-- 18. Payments (付款紀錄)
CREATE TABLE Payments (
    Id INT IDENTITY(1,1) NOT NULL,
    OrderId INT NULL, -- 對應已完成訂單
    PreOrderId INT NOT NULL, -- 對應已建立訂單
    Method NVARCHAR(50) NOT NULL,
    PaidAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    DoneOrCancel INT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_Payments PRIMARY KEY (Id)
    -- OrderId FK 和 PreOrderId FK 在最後添加
);
GO

-- 19. PreOrderDetails (暫存訂單明細)
CREATE TABLE PreOrderDetails (
    Id INT IDENTITY(1,1) NOT NULL,
    PreOrderId INT NOT NULL,
    ProductId INT NOT NULL, -- 對應 Dishes
    ProductName NVARCHAR(50) NOT NULL,
    UnitPrice INT NOT NULL,
    Qty INT DEFAULT 1 NOT NULL,
    SubTotal INT DEFAULT 0 NOT NULL,
    DoneOrCancel INT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_PreOrderDetails PRIMARY KEY (Id),
    CONSTRAINT FK_PreOrderDetails_PreOrders FOREIGN KEY (PreOrderId) REFERENCES PreOrders(Id),
    CONSTRAINT FK_PreOrderDetails_Dishes FOREIGN KEY (ProductId) REFERENCES Dishes(Id),
    CONSTRAINT CK_PreOrderDetails_Qty CHECK (Qty > 0),
    CONSTRAINT CK_PreOrderDetails_UnitPrice CHECK (UnitPrice >= 0)
);
GO

-- 20. OrderDetails (正式訂單明細)
CREATE TABLE OrderDetails (
    Id INT IDENTITY(1,1) NOT NULL,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL, -- 對應 Dishes
    ProductName NVARCHAR(50) NOT NULL,
    UnitPrice INT NOT NULL,
    Qty INT DEFAULT 1 NOT NULL,
    SubTotal INT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (Id),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id),
    CONSTRAINT FK_OrderDetails_Dishes FOREIGN KEY (ProductId) REFERENCES Dishes(Id),
    CONSTRAINT CK_OrderDetails_Qty CHECK (Qty > 0),
    CONSTRAINT CK_OrderDetails_UnitPrice CHECK (UnitPrice >= 0)
);
GO

/* ==========================================================================
   補齊 Circular FK (Orders <-> Payments)
   ========================================================================== */
ALTER TABLE PreOrders ADD CONSTRAINT FK_PreOrders_Payments FOREIGN KEY (PaymentId) REFERENCES Payments(Id);
ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Payments FOREIGN KEY (PaymentId) REFERENCES Payments(Id);

ALTER TABLE Payments ADD CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id);
ALTER TABLE Payments ADD CONSTRAINT FK_Payments_PreOrders FOREIGN KEY (PreOrderId) REFERENCES PreOrders(Id);
GO

/* ==========================================================================
   品牌行銷與通知系統
   ========================================================================== */

-- 21. Events (活動管理表)
CREATE TABLE Events (
    Id INT IDENTITY(1,1) NOT NULL,
    Title NVARCHAR(100) NOT NULL,
    Summary NVARCHAR(50) NULL,
    MinSpend INT DEFAULT 0 NOT NULL,
    StartDate DATETIME2(0) NOT NULL,
    EndDate DATETIME2(0) NOT NULL,
    RewardItem NVARCHAR(100) NULL,
    DiscountType NVARCHAR(20) NULL, -- 'None', 'Percent', 'FixedAmount', 'Gift'
    DiscountValue DECIMAL(10,2) DEFAULT 0 NOT NULL,
    Status INT DEFAULT 0 NOT NULL, -- 0:草稿, 1:已發佈, 2:已結束
    CONSTRAINT PK_Events PRIMARY KEY (Id),
    CONSTRAINT CK_Events_Dates CHECK (EndDate > StartDate),
    CONSTRAINT CK_Events_MinSpend CHECK (MinSpend >= 0)
);
CREATE INDEX IX_Events_Status ON Events(Status);
CREATE INDEX IX_Events_StartDate ON Events(StartDate);
GO

-- 22. ArticleCategories (文章分類表)
CREATE TABLE ArticleCategories (
    Id INT IDENTITY(1,1) NOT NULL,
    Name NVARCHAR(50) NOT NULL,
    SortOrder INT DEFAULT 0 NOT NULL,
    IsEnabled BIT DEFAULT 1 NOT NULL,
    CONSTRAINT PK_ArticleCategories PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX IX_ArticleCategories_Name ON ArticleCategories(Name);
CREATE INDEX IX_ArticleCategories_Sort ON ArticleCategories(SortOrder);
GO

-- 23. Articles (文章/消息管理表)
CREATE TABLE Articles (
    Id INT IDENTITY(1,1) NOT NULL,
    CategoryId INT NOT NULL,
    EventId INT NULL,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    CoverImageUrl NVARCHAR(255) NULL,
    PublishDate DATETIME2(0) NOT NULL,
    ExpiryDate DATETIME2(0) NULL,
    IsPinned BIT DEFAULT 0 NOT NULL,
    Status INT DEFAULT 0 NOT NULL, -- 0:草稿, 1:發佈, 2:撤回
    CONSTRAINT PK_Articles PRIMARY KEY (Id),
    CONSTRAINT FK_Articles_Categories FOREIGN KEY (CategoryId) REFERENCES ArticleCategories(Id),
    CONSTRAINT FK_Articles_Events FOREIGN KEY (EventId) REFERENCES Events(Id)
);
CREATE INDEX IX_Articles_PublishDate ON Articles(PublishDate);
CREATE INDEX IX_Articles_Status ON Articles(Status);
GO

-- 24. UserNotifications (會員通知表)
CREATE TABLE UserNotifications (
    Id INT IDENTITY(1,1) NOT NULL,
    MemberId INT NOT NULL,
    ArticleId INT NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    IsRead BIT DEFAULT 0 NOT NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_UserNotifications PRIMARY KEY (Id),
    CONSTRAINT FK_UserNotifications_Members FOREIGN KEY (MemberId) REFERENCES Members(Id),
    CONSTRAINT FK_UserNotifications_Articles FOREIGN KEY (ArticleId) REFERENCES Articles(Id)
);
CREATE INDEX IX_UserNotifications_MemberId ON UserNotifications(MemberId);
CREATE INDEX IX_UserNotifications_IsRead ON UserNotifications(IsRead);
GO

-- 25. EmailQueue (郵件發送隊列)
CREATE TABLE EmailQueue (
    Id INT IDENTITY(1,1) NOT NULL,
    RecipientEmail NVARCHAR(100) NOT NULL,
    Subject NVARCHAR(200) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    Status INT DEFAULT 0 NOT NULL, -- 0:待處理, 1:成功, 2:失敗
    ProcessedAt DATETIME2(0) NULL,
    CreatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_EmailQueue PRIMARY KEY (Id)
);
CREATE INDEX IX_EmailQueue_Status ON EmailQueue(Status);
CREATE INDEX IX_EmailQueue_Recipient ON EmailQueue(RecipientEmail);
GO

-- 26. SubscriptionPreferences (會員訂閱偏好)
CREATE TABLE SubscriptionPreferences (
    Id INT IDENTITY(1,1) NOT NULL,
    MemberId INT NOT NULL,
    IsEmailSubscribed BIT DEFAULT 1 NOT NULL,
    IsPushSubscribed BIT DEFAULT 1 NOT NULL,
    UpdatedAt DATETIME2(0) DEFAULT GETDATE() NOT NULL,
    CONSTRAINT PK_SubscriptionPreferences PRIMARY KEY (Id),
    CONSTRAINT FK_SubscriptionPreferences_Members FOREIGN KEY (MemberId) REFERENCES Members(Id)
);
GO
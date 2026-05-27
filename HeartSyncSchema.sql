-- ==========================================
-- TẠO CƠ SỞ DỮ LIỆU 
-- ==========================================
CREATE DATABASE HeartSyncDB;
GO
USE HeartSyncDB;
GO

-- ==========================================
-- PHẦN 1: BẢNG DANH MỤC GỐC 
-- ==========================================

-- 1. Bảng Roles (Phân quyền)
CREATE TABLE Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Bảng Brands (Nhãn hàng tiếp thị)
CREATE TABLE Brands (
    BrandID INT IDENTITY(1,1) PRIMARY KEY,
    BrandName NVARCHAR(150) NOT NULL,
    LogoURL VARCHAR(500) NULL,
    ContactEmail VARCHAR(100) NULL,
    CommissionRate DECIMAL(5,2) NOT NULL DEFAULT 0.00
);

-- 3. Bảng Pets (Danh mục thú cưng)
CREATE TABLE Pets (
    PetID INT IDENTITY(1,1) PRIMARY KEY,
    PetName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NULL
);

-- 4. Bảng Challenges (Thử thách hệ thống)
CREATE TABLE Challenges (
    ChallengeID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    PointsReward INT NOT NULL DEFAULT 10
);

-- 5. Bảng OrderStatuses (Trạng thái đơn hàng)
CREATE TABLE OrderStatuses (
    OrderStatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(50) NOT NULL UNIQUE
);

-- ==========================================
-- PHẦN 2: BẢNG NGƯỜI DÙNG VÀ CẶP ĐÔI
-- ==========================================

-- 6. Bảng Users (Thông tin người dùng)
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Username VARCHAR(50) NULL UNIQUE,
    PasswordHash VARCHAR(255) NULL,
    GoogleID VARCHAR(255) NULL UNIQUE,
    RoleID INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
CREATE TABLE UserProfiles (
    UserID INT PRIMARY KEY, -- Quan hệ 1-1 với bảng Users
    FullName NVARCHAR(100) NOT NULL,
    PhoneNumber VARCHAR(15) NULL,
    Address NVARCHAR(255) NULL,
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
CREATE TABLE UserSubscriptions (
    UserID INT PRIMARY KEY, -- Quan hệ 1-1 với bảng Users
    AccountType VARCHAR(20) NOT NULL DEFAULT 'Standard',
    PremiumActivationDate DATETIME NULL, -- Bổ sung ngày kích hoạt
    PremiumExpiryDate DATETIME NULL,     -- Ngày hết hạn
    CONSTRAINT FK_UserSubscriptions_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- 7. Bảng Couples (Cặp đôi)
CREATE TABLE Couples (
    CoupleID INT IDENTITY(1,1) PRIMARY KEY,
    User1_ID INT NOT NULL,
    User2_ID INT NOT NULL,
    StartDate DATETIME NOT NULL DEFAULT GETDATE(),
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Couples_User1 FOREIGN KEY (User1_ID) REFERENCES Users(UserID),
    CONSTRAINT FK_Couples_User2 FOREIGN KEY (User2_ID) REFERENCES Users(UserID),
    CONSTRAINT CHK_Diff_Users CHECK (User1_ID <> User2_ID)
);

-- ==========================================
-- PHẦN 3: HỆ THỐNG THÚ CƯNG (TÁCH NHỎ)
-- ==========================================

-- 8. Bảng PetLevels (Cấu hình Level thú cưng)
CREATE TABLE PetLevels (
    PetLevelID INT IDENTITY(1,1) PRIMARY KEY,
    PetID INT NOT NULL,
    Level INT NOT NULL,
    RequiredXP INT NOT NULL DEFAULT 0,
    AnimationURL VARCHAR(500) NULL,
    CONSTRAINT FK_PetLevels_Pets FOREIGN KEY (PetID) REFERENCES Pets(PetID)
);

-- 9. Bảng CouplePets (Thú cưng thực tế của cặp đôi)
CREATE TABLE CouplePets (
    CouplePetID INT IDENTITY(1,1) PRIMARY KEY,
    CoupleID INT NOT NULL UNIQUE, 
    PetID INT NOT NULL,
    CurrentLevel INT NOT NULL DEFAULT 1,
    CurrentXP INT NOT NULL DEFAULT 0,
    CurrentAnimationURL VARCHAR(500) NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Frozen'
    LastInteractionDate DATETIME NOT NULL DEFAULT GETDATE(),

    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(), -- Ngày tạo/nhận nuôi pet
    FrozenAt DATETIME NULL, -- Ngày pet bị đóng băng (Cho phép NULL vì lúc mới nuôi chưa bị đóng băng)
    
    CONSTRAINT FK_CouplePets_Couples FOREIGN KEY (CoupleID) REFERENCES Couples(CoupleID),
    CONSTRAINT FK_CouplePets_Pets FOREIGN KEY (PetID) REFERENCES Pets(PetID)
);

-- ==========================================
-- PHẦN 4: TIẾP THỊ LIÊN KẾT, GIỎ HÀNG & ĐƠN HÀNG
-- ==========================================

-- 10. Bảng Products (Sản phẩm quà tặng)
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    BrandID INT NOT NULL,
    CategoryID INT NOT NULL, -- Khóa ngoại trỏ về bảng Categories
    ProductName NVARCHAR(255) NOT NULL,
    Price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    ProductImageURL VARCHAR(500) NULL,
    AffiliateLink VARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1, -- Trạng thái ẩn/hiện sản phẩm
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Products_Brands FOREIGN KEY (BrandID) REFERENCES Brands(BrandID),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);
CREATE TABLE ProductDetails (
    ProductID INT PRIMARY KEY, -- Dùng chính ProductID làm khóa chính kiêm khóa ngoại
    Description NVARCHAR(MAX) NULL, -- Bài viết mô tả chi tiết món quà
    Material NVARCHAR(100) NULL, -- Chất liệu (Ví dụ: Bạc 925, Vải cotton)
    Origin NVARCHAR(100) NULL, -- Xuất xứ
    WarrantyInfo NVARCHAR(255) NULL, -- Thông tin bảo hành
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ProductDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE
);

-- 11. Bảng Carts (Giỏ hàng tổng)
CREATE TABLE Carts (
    CartID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE, -- Mỗi user chỉ có 1 giỏ hàng
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Carts_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- 12. Bảng CartItems (Chi tiết giỏ hàng)
CREATE TABLE CartItems (
    CartItemID INT IDENTITY(1,1) PRIMARY KEY,
    CartID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CartItems_Carts FOREIGN KEY (CartID) REFERENCES Carts(CartID),
    CONSTRAINT FK_CartItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 13. Bảng Orders (Đơn hàng tổng)
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    OrderStatusID INT NOT NULL,
    TotalPrice DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    CommissionEarned DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    ShippingAddress NVARCHAR(255) NOT NULL,
    ShippingPhone VARCHAR(15) NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    CompletedDate DATETIME NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Orders_OrderStatuses FOREIGN KEY (OrderStatusID) REFERENCES OrderStatuses(OrderStatusID)
);

-- 14. Bảng OrderDetails (Chi tiết đơn hàng)
CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    PriceAtPurchase DECIMAL(18,2) NOT NULL, -- Giá chốt lúc mua
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
-- Bảng Payments (Lịch sử giao dịch thanh toán)
CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    PaymentStatusID INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TransactionReference VARCHAR(255) NULL, -- Nơi lưu mã giao dịch trả về từ cổng thanh toán (VD: Mã PayOS)
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_Payments_PaymentMethods FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID),
    CONSTRAINT FK_Payments_PaymentStatuses FOREIGN KEY (PaymentStatusID) REFERENCES PaymentStatuses(PaymentStatusID)
);
-- Bảng PaymentStatuses (Danh mục trạng thái thanh toán)
CREATE TABLE PaymentStatuses (
    PaymentStatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(50) NOT NULL UNIQUE 
    -- Các giá trị gợi ý: 'Pending', 'Success', 'Failed', 'Refunded'
);

-- Bảng PaymentMethods (Danh mục phương thức thanh toán)
CREATE TABLE PaymentMethods (
    PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,
    MethodName NVARCHAR(50) NOT NULL UNIQUE 
    -- Các giá trị gợi ý: 'PayOS', 'Bank Transfer', 'COD', 'Momo'
);

-- ==========================================
-- PHẦN 5: TÍNH NĂNG NHẬT KÝ, THỬ THÁCH & LOG LỊCH SỬ
-- ==========================================

-- 15. Bảng HeartSpaces (Nhật ký)
CREATE TABLE HeartSpaces (
    SpaceID INT IDENTITY(1,1) PRIMARY KEY,
    CoupleID INT NOT NULL,
    CreatedBy_UserID INT NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    ImageURL VARCHAR(500) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_HeartSpaces_Couples FOREIGN KEY (CoupleID) REFERENCES Couples(CoupleID),
    CONSTRAINT FK_HeartSpaces_Users FOREIGN KEY (CreatedBy_UserID) REFERENCES Users(UserID)
);

-- 16. Bảng Milestones (Cột mốc)
CREATE TABLE Milestones (
    MilestoneID INT IDENTITY(1,1) PRIMARY KEY,
    CoupleID INT NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    OccurredDate DATETIME NOT NULL,
    CONSTRAINT FK_Milestones_Couples FOREIGN KEY (CoupleID) REFERENCES Couples(CoupleID)
);

-- 17. Bảng CoupleChallenges (Lịch sử làm thử thách)
CREATE TABLE CoupleChallenges (
    CoupleChallengeID INT IDENTITY(1,1) PRIMARY KEY,
    CoupleID INT NOT NULL,
    ChallengeID INT NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CompletedAt DATETIME NULL,
    CONSTRAINT FK_CoupleChallenges_Couples FOREIGN KEY (CoupleID) REFERENCES Couples(CoupleID),
    CONSTRAINT FK_CoupleChallenges_Challenges FOREIGN KEY (ChallengeID) REFERENCES Challenges(ChallengeID)
);

-- 18. Bảng ActionLogs (Ghi vết hệ thống)
CREATE TABLE ActionLogs (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    ActionType VARCHAR(50) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    IPAddress VARCHAR(50) NULL,
    Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ActionLogs_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO


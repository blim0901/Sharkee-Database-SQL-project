CREATE SCHEMA SHARKEE;
USE SHARKEE;

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Shops')
	CREATE TABLE Shops (
		ShopName VARCHAR(50) PRIMARY KEY
	);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Users')
	CREATE TABLE Users(
		UserID INT PRIMARY KEY,
		UName VARCHAR(50) NOT NULL,
			CHECK (EName NOT LIKE '%[^a-Z]%')
	);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Employees')
	CREATE TABLE Employees(
		EmployeeID INT PRIMARY KEY,
		EName VARCHAR(50) NOT NULL,
			CHECK (EName NOT LIKE '%[^a-Z]%')
		Salary smallmoney NOT NULL
	);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Products')
CREATE TABLE Products(
	ProductName VARCHAR(50) PRIMARY KEY,
    Maker VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL
);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Orders')
CREATE TABLE Orders(
	OrderID INT PRIMARY KEY,
    ShippingAddress VARCHAR(50) NOT NULL,
    OrderDateTime DATETIME DEFAULT CURRENT_TIMESTAMP 
);
IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Complaints')
CREATE TABLE Complaints (
	ComplaintID INT PRIMARY KEY,
	ComplaintText VARCHAR(300) ,
    ComplaintStatus bit DEFAULT 0,
    FiledDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    HandledDateTime DATETIME,
    EmployeeID INT NOT NULL,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
	ON UPDATE CASCADE
	ON DELETE CASCADE, /*It specifies that the child data is deleted when the parent data is deleted.*/
    UserID INT NOT NULL,
	FOREIGN KEY (UserID) REFERENCES Users(UserID)
	ON UPDATE CASCADE
	ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='ShopComplaints')
CREATE TABLE  ShopComplaints (
	ComplaintID INT NOT NULL,
	FOREIGN KEY (ComplaintID) REFERENCES Complaints(ComplaintID)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	ShopName VARCHAR(50),
	FOREIGN KEY (ShopName) REFERENCES Shops(ShopName)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
    PRIMARY KEY(ComplaintID)
);
IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='OrderComplaints')
CREATE TABLE  OrderComplaints(
	ComplaintID INT NOT NULL,
	FOREIGN KEY (ComplaintID) REFERENCES Complaints(ComplaintID)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
    OrderID INT NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
    PRIMARY KEY(ComplaintID)
);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='ProductInShops')
CREATE TABLE  ProductInShops(
	Quantity INT NOT NULL DEFAULT 1,
      Price smallmoney NOT NULL,
        Check(Price > 0)
	ProductName VARCHAR(50) NOT NULL,
    FOREIGN KEY (ProductName) REFERENCES Products(ProductName)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
	ShopName VARCHAR(50),
	FOREIGN KEY (ShopName) REFERENCES Shops(ShopName)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	PRIMARY KEY(ProductName, ShopName)
);




IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='ProductInOrders')
CREATE TABLE  ProductInOrders(
	DeliverStatus VARCHAR(50) NOT NULL DEFAULT 'being processed',
    DeliveryDate DATETIME NOT NULL,
	Quantity INT NOT NULL DEFAULT 1,
    Price MONEY NOT NULL,/*-922,337,203,685,477.58 to 922,337,203,685,477.58*/
       Check(Price > 0)
    ProductName VARCHAR(50) NOT NULL,
    FOREIGN KEY (ProductName) REFERENCES Products(ProductName)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
	ShopName VARCHAR(50),
	FOREIGN KEY (ShopName) REFERENCES Shops(ShopName)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
    OrderID INT NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	PRIMARY KEY(ProductName, ShopName, OrderID)
);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='Feedback')
CREATE TABLE Feedback(
	Rating TINYINT NOT NULL DEFAULT 3 /*1 byte max value 255 unsigned*/
			CHECK (Rating >= 1 and Rating <= 5),
	FeedDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
	Comment VARCHAR(300),
	ProductName VARCHAR(50) NOT NULL,
    FOREIGN KEY (ProductName) REFERENCES Products(ProductName)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
	ShopName VARCHAR(50),
	FOREIGN KEY (ShopName) REFERENCES Shops(ShopName)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
    UserID INT NOT NULL,
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	PRIMARY KEY(ProductName, ShopName, UserID)
);

IF NOT EXISTS (SELECT * from sys.tables WHERE NAME='PriceHistory')
CREATE TABLE PriceHistory(
	StartDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	EndDate DATETIME NOT NULL,
	Price SMALLMONEY NOT NULL DEFAULT 1
		Check(Price > 0), 
	ProductName VARCHAR(50) NOT NULL,
    FOREIGN KEY (ProductName) REFERENCES Products(ProductName)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
	ShopName VARCHAR(50),
	FOREIGN KEY (ShopName) REFERENCES Shops(ShopName)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
	PRIMARY KEY(ProductName, ShopName, StartDate)
);

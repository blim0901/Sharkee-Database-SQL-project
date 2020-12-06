-- Complaint status changes from 'BeingHandled' to 'Pending' when the Employee in
-- charged is removed from Employee table
CREATE TRIGGER [dbo].[employee_deletion]
ON [dbo].[Employees]
AFTER DELETE
AS
	UPDATE	Complaints
	SET	ComplaintStatus='False'
	WHERE	ComplaintStatus='False' AND EmployeeID=NULL;


	 
-- When a user makes an order of a product, the stock of that product decreases by 1.
-- This is for stock count.
CREATE TRIGGER [dbo].[reduceStock]
ON [dbo].[ProductInOrders]
FOR INSERT
AS
	DECLARE @productName varchar(50);
	DECLARE @shopName varchar(50);
	DECLARE @Quantity INT

	SELECT @productName = ProductName FROM inserted i;
	SELECT @shopName =ShopName FROM inserted i;
	SELECT @Quantity = Quantity FROM inserted i;

	UPDATE	ProductInShops
	SET		Quantity = Quantity - @Quantity
	WHERE	productName = @productName AND ShopName = @shopName;*/


	
-- When user returns a product, the stock of the product increases by 1.
-- This is for stock count.
CREATE TRIGGER [dbo].[refundProduct]
ON [dbo].[ProductInOrders]
FOR UPDATE
AS
	DECLARE @productName varchar(50);
	DECLARE @shopName varchar(50);
	DECLARE @DeliverStatus varchar(50);
	DECLARE @Quantity INT;

	SELECT @productName = ProductName FROM inserted i;
	SELECT @shopName =ShopName FROM inserted i;
	SELECT @DeliverStatus = DeliverStatus FROM inserted i;
	SELECT @Quantity = Quantity FROM inserted i;

	UPDATE ProductInShops
	SET Quantity= Quantity + @Quantity
WHERE ProductName=@productName AND @shopName=@shopName AND @DeliverStatus='Returned';


-- Find the average price of “iPhone Xs” on Sharkee from 1 August 2020 to 31 August 2020.
SELECT AVG(PriceHistory.Price) AS "Average Price"
FROM PriceHistory
WHERE PriceHistory.ProductName = 'iPhone Xs' 
AND (PriceHistory.StartDate BETWEEN CONVERT(datetime,'2020-08-01') AND CONVERT(datetime,'2020-08-31')
OR PriceHistory.EndDate BETWEEN CONVERT(datetime,'2020-08-01') AND CONVERT(datetime,'2020-08-31'))


-- Find products that received at least 100 ratings of “5” in August 2020, and order them by their average ratings
WITH SubQuery AS
(SELECT ProductName, Rating FROM Feedback WHERE Rating = 5 AND DATEPART(month, FeedDateTime) = 8 AND DATEPART(year, FeedDateTime) = 2020 GROUP BY ProductName, Rating HAVING COUNT(Rating) >= 100)
SELECT f.ProductName, ROUND(AVG(CAST(f.Rating AS FLOAT)), 2) as 'Average Rating'
FROM Feedback f, SubQuery s
WHERE f.ProductName = s.ProductName AND DATEPART(month, FeedDateTime) = 8 AND DATEPART(year, FeedDateTime) = 2020
GROUP BY f.ProductName ORDER BY AVG(f.Rating) ASC


-- For all products purchased in June 2020 that have been delivered, find the average time from the ordering date to the delivery date.
SELECT ProductName, (CAST(SUM(DaysDiff) AS float)/COUNT(ProductName)) AS AverageDays
FROM (SELECT Orders.OrderID, Orders.OrderDateTime,ProductInOrders.ProductName, ProductInOrders.DeliveryDate, DATEDIFF(day,Orders.OrderDateTime,ProductInOrders.DeliveryDate)AS DaysDiff
FROM Orders,ProductInOrders 
WHERE Orders.OrderID = ProductInOrders.OrderID
AND DeliverStatus = 'Delivered' AND OrderDateTime BETWEEN CONVERT(datetime,'2020-06-01') AND CONVERT(datetime,'2020-06-30')) AS DerivedTable
GROUP BY ProductName;


-- Let us define the “latency” of an employee by the average that he/she takes to process a complaint. Find the employee with the smallest latency.
SELECT e.EmployeeID, e.EName
FROM Employees e
WHERE e.EmployeeID IN (
SELECT TOP 1 WITH TIES c.EmployeeID
	FROM Complaints c
	WHERE c.HandledDateTime IS NOT NULL
	GROUP BY c.EmployeeID
ORDER BY AVG(DATEDIFF(ss, c.FiledDateTime, c.HandledDateTime)) ASC)


-- Produce a list that contains (i) all products made by Samsung, and (ii) for each of them, the number of shops on Sharkee that sell the product.
SELECT p.ProductName, COUNT(pis.ShopName) as 'Number Of Shops' 
FROM ProductInShops pis 
RIGHT JOIN Products p ON pis.ProductName = p.ProductName 
WHERE p.Maker = 'Samsung' 
GROUP BY p.ProductName


-- Find shops that made the most revenue in August 2020.
SELECT TOP 1 WITH TIES SUM(pis.Price) as FinalPrice, pis.ShopName
FROM ProductInOrders pis
JOIN Orders o ON o.OrderID = pis.OrderID
WHERE DATEPART(month, o.OrderDateTime) = 8 AND DATEPART(YEAR, o.OrderDateTime) = 2020
AND pis.DeliverStatus <> 'Returned'
GROUP BY pis.ShopName
ORDER BY FinalPrice DESC


-- For users that made the most amount of complaints, find the most expensive products he/she has ever purchased.
SELECT P.ProductName, P.Price/P.Quantity AS 'Product Price', O.UserID
FROM ProductInOrders as P
JOIN Orders O ON P.OrderID = O.OrderID
JOIN (
    SELECT MAX(P.Price/P.Quantity) AS 'Price', o.UserID	 
    FROM Orders O
    LEFT JOIN ProductInOrders P ON O.OrderID = P.OrderID
    WHERE O.UserID IN (
   	 SELECT TOP 1 WITH TIES c2.UserID
   	 FROM Complaints c2
   	 GROUP BY c2.UserID
   	 ORDER BY Count(c2.ComplaintID) DESC)
   	 GROUP BY O.UserID
   	 ) AS MX ON MX.UserID = O.UserID AND (P.Price/P.Quantity) = MX.[Price]


-- Find products that have never been purchased by some users, but are the top 5 most purchased products by other users in August 2020.
SELECT TOP 5 SUM(pio.Quantity) AS NoOfPurchase, pio.ProductName
FROM ProductInOrders pio
JOIN Orders o ON o.OrderID = pio.OrderID
JOIN Users u ON o.UserID = u.UserID
WHERE DATEPART(month, o.OrderDateTime) = 8 AND DATEPART(year, o.OrderDateTime) = 2020
AND pio.ProductName IN (
	SELECT pio.ProductName
	FROM ProductInOrders pio
	JOIN Orders o ON o.OrderID = pio.OrderID
	JOIN Users u ON o.UserID = u.UserID
	GROUP BY pio.ProductName
	HAVING COUNT(DISTINCT u.UserID) < (SELECT COUNT(UserID) FROM Users))
GROUP BY pio.ProductName
ORDER BY NoOfPurchase DESC


-- Find products that are increasingly being purchased over at least 3 months. (static)
WITH SubQuery AS (
	SELECT pis.ProductName, SUM(pis.Quantity) as Quantity, YEAR(o.OrderDateTime)*12 + MONTH(o.OrderDateTime) as MonthNum
	FROM ProductInOrders pis
	JOIN Orders o ON o.OrderID = pis.OrderID
	GROUP BY pis.ProductName, pis.Quantity, MONTH(o.OrderDateTime), YEAR(o.OrderDateTime)
)
SELECT DISTINCT s3.ProductName
FROM SubQuery as s3
JOIN SubQuery s2 ON s3.ProductName = s2.ProductName
JOIN SubQuery s1 ON s2.ProductName = s1.ProductName
WHERE (s3.Quantity < s2.Quantity AND s2.Quantity < s1.Quantity) AND (s1.MonthNum - s2.MonthNum) = 1 AND (s2.MonthNum - s3.MonthNum) = 1


-- Find products that are increasingly being purchased over at least 3 months. (dynamic)
DECLARE @joinSql VARCHAR(2000), @whereSql VARCHAR(2000), @main VARCHAR(2000), @final VARCHAR(2000), @monthCounter INT
SET @joinSql = ' '
SET @whereSql = ' '
SET @main = 'WITH SubQuery AS (SELECT pis.ProductName, SUM(pis.Quantity) as Quantity, YEAR(o.OrderDateTime) * 12 + MONTH(o.OrderDateTime) as MonthNum FROM ProductInOrders pis JOIN Orders o ON o.OrderID = pis.OrderID GROUP BY pis.ProductName, pis.Quantity, MONTH(o.OrderDateTime), YEAR(o.OrderDateTime)) '
SET @monthCounter = 3 /*Change depending on months*/
BEGIN
	SET @main = @main + 'SELECT DISTINCT s'+CAST(@monthCounter as VARCHAR(50))+'.ProductName FROM SubQuery as s' + CAST(@monthCounter as VARCHAR(50))
	IF (@monthCounter > 1)
	BEGIN
		SET @whereSql = ' WHERE '
	END
	WHILE (@monthCounter > 1)
	BEGIN
		SET @joinSQL = @joinSQL + ' JOIN SubQuery s'+(CAST((@monthCounter-1) as VARCHAR(50)))+' ON s'+CAST(@monthCounter as VARCHAR(50))+'.ProductName = s'+(CAST((@monthCounter-1) as VARCHAR(50)))+'.ProductName '
		SET @whereSql = @whereSql + ' (s'+CAST(@monthCounter as VARCHAR(50))+'.Quantity < s'+(CAST((@monthCounter-1) as VARCHAR(50)))+'.Quantity AND s'+(CAST((@monthCounter-1) as VARCHAR(50)))+'.MonthNum - s'+CAST(@monthCounter as VARCHAR(50))+'.MonthNum = 1) '
		IF (@monthCounter - 1 > 1)
		BEGIN
			SET @whereSql = @whereSql + ' AND '
		END
		SET @monthCounter = @monthCounter - 1
	END
	SET @final = @main + @joinSql + @whereSql
	EXEC(@final)
END



USE EcommerceAnalystics;

SELECT * FROM Customers;

SELECT * FROM Products;

SELECT * FROM Orders;

SELECT * FROM OrderDetails;

-- Monthly Sales Treand
SELECT
 YEAR(o.OrderDate) AS Year,
 MONTH(o.OrderDate) AS Month,
 SUM(od.Quantity * p.SellingPrice) AS TotalSales
 FROM Orders o
 JOIN OrderDetails od
 ON o.OrderID = od.OrderID
 JOIN Products p
 ON od.ProductID = p.ProductID
 GROUP BY
 YEAR(o.OrderDate),
 MONTH(o.OrderDate)
 ORDER BY
 YEAR,MONTH;

 -- Top Selling Products Query
 SELECT
 p.ProductName,
 SUM(od.Quantity) AS TotalQuantitySold,
 SUM(od.Quantity * p.SellingPrice) AS TotalRevenue
 FROM Products p
 JOIN OrderDetails od
 ON p.ProductID = od.ProductID
 GROUP BY p.ProductName
 ORDER BY TotalRevenue DESC;

 -- Bonus
 SELECT *,
 RANK() OVER (ORDER BY TotalRevenue DESC) AS ProductRank
 FROM(
 SELECT 
 p.ProductName,
 SUM(od.Quantity * p.SellingPrice) AS TotalRevenue
 FROM Products p
 JOIN OrderDetails od
 ON p.ProductID = od.ProductID
 GROUP BY p.ProductName
)t;

-- Customer Purchase Summary
SELECT 
c.CustomerID,
c.CustomerName,
COUNT(DISTINCT o.OrderID) AS TotalOrders,
SUM(od.Quantity * p.SellingPrice) AS TotalSpent
FROM Customers c
JOIN Orders o
ON c.CustomerID = o.CustomerID
JOIN OrderDetails od 
ON o.OrderID = od.OrderID
JOIN Products p
ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC;

-- Profit Per Product
SELECT
p.ProductName,
SUM(od.Quantity) AS TotalQuantitySold,
SUM(od.Quantity * p.SellingPrice) AS TotalRevenue,
SUM(od.Quantity * (p.SellingPrice - p.CostPrice)) AS TotalProfit
FROM Products p
JOIN OrderDetails od
ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY TotalProfit DESC;

-- Customer Lifetime Value
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(od.Quantity * p.SellingPrice) AS LifetimeValue,
    AVG(od.Quantity * p.SellingPrice) AS AvgOrderValue
FROM Customers c
JOIN Orders o 
    ON c.CustomerID = o.CustomerID
JOIN OrderDetails od 
    ON o.OrderID = od.OrderID
JOIN Products p 
    ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY LifetimeValue DESC;

-- Top Customers Per City
WITH CustomerSales AS (
    SELECT 
        c.City,
        c.CustomerName,
        SUM(od.Quantity * p.SellingPrice) AS TotalSales
    FROM Customers c
    JOIN Orders o 
        ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od 
        ON o.OrderID = od.OrderID
    JOIN Products p 
        ON od.ProductID = p.ProductID
    GROUP BY c.City, c.CustomerName
)

SELECT *
FROM (
    SELECT *,
        RANK() OVER (PARTITION BY City ORDER BY TotalSales DESC) AS RankInCity
    FROM CustomerSales
) t
WHERE RankInCity <= 3;

-- Running Total Sales
SELECT 
    o.OrderDate,
    SUM(od.Quantity * p.SellingPrice) AS DailySales,
    SUM(SUM(od.Quantity * p.SellingPrice)) 
        OVER (ORDER BY o.OrderDate) AS RunningTotal
FROM Orders o
JOIN OrderDetails od 
    ON o.OrderID = od.OrderID
JOIN Products p 
    ON od.ProductID = p.ProductID
GROUP BY o.OrderDate
ORDER BY o.OrderDate;

-- Sales Growth %
WITH MonthlySales AS (
    SELECT 
        YEAR(o.OrderDate) AS Year,
        MONTH(o.OrderDate) AS Month,
        SUM(od.Quantity * p.SellingPrice) AS TotalSales
    FROM Orders o
    JOIN OrderDetails od 
        ON o.OrderID = od.OrderID
    JOIN Products p 
        ON od.ProductID = p.ProductID
    GROUP BY 
        YEAR(o.OrderDate),
        MONTH(o.OrderDate)
)
SELECT 
    Year,
    Month,
    TotalSales,
    ISNULL(
        LAG(TotalSales) OVER (ORDER BY Year, Month),
        0
    ) AS PreviousMonthSales,
    ISNULL(
        ((TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Month)) * 100.0
        / NULLIF(LAG(TotalSales) OVER (ORDER BY Year, Month), 0)),
        0
    ) AS GrowthPercent
FROM MonthlySales;
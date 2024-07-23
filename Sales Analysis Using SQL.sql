
-------SALES OVERVIEW
-- Check Duplicate in Database
--	Sales Table
SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*)
FROM AdventureWorksDW.dbo.FactInternetSales
GROUP BY SalesOrderNumber, SalesOrderLineNumber
HAVING COUNT(*) > 1

--
SELECT SalesOrderNumber, SalesOrderLineNumber, COUNT(*)
FROM AdventureWorksDW.dbo.FactResellerSales
GROUP BY SalesOrderNumber, SalesOrderLineNumber
HAVING COUNT(*) > 1

-- Product table
SELECT ProductKey,COUNT(*)
FROM AdventureWorksDW.dbo.DimProduct
GROUP BY ProductKey
HAVING COUNT(*) >1

-- Remove Duplicate Records
WITH SalesCTE AS (
SELECT 
	SalesOrderNumber,
	SalesOrderLineNumber, 
	ProductKey,
	OrderDateKey,
	SalesAmount,
	OrderQuantity,
	ROW_NUMBER() OVER(PARTITION BY SalesOrderNumber, SalesOrderLineNumber ORDER BY SalesOrderNumber) AS RowNum
FROM AdventureWorksDW.dbo.FactInternetSales	
)
DELETE FROM SalesCTE
Where RowNum >1

-- Check Records with Null or Invalid Foregin Keys
SELECT *
FROM AdventureWorksDW.dbo.FactInternetSales
WHERE ProductKey is null OR OrderDateKey is null

SELECT *
FROM AdventureWorksDW.dbo.DimProduct
WHERE ProductSubcategoryKey is null

SELECT *
FROM AdventureWorksDW.dbo.DimProduct
WHERE StandardCost is null

-- Delete Records wth Null or Invalid Foregin Keys
--	Delete dependent records in FactProductInventory
DELETE FROM AdventureWorksDW.dbo.FactProductInventory
WHERE ProductKey 
IN (SELECT ProductKey FROM AdventureWorksDW.dbo.DimProduct WHERE StandardCost is null);

--	Delete records in DimProduct
DELETE FROM AdventureWorksDW.dbo.DimProduct
WHERE StandardCost is null

-- Transform Data
UPDATE AdventureWorksDW.dbo.FactInternetSales
SET SalesAmount = ROUND(Salesamount,2),
	UnitPrice = ROUND(UnitPrice,2),
	TotalProductCost = ROUND(TotalProductCost,2)

-- Total Sales
SELECT 
    (SELECT SUM(SalesAmount) FROM AdventureWorksDW.dbo.FactResellerSales) AS TotalResellerSales,
    (SELECT SUM(SalesAmount) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalInternetSales,
    (SELECT SUM(SalesAmount) FROM AdventureWorksDW.dbo.FactResellerSales) + (SELECT SUM(SalesAmount) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalSales

-- Total Profit
SELECT 
    (SELECT SUM(SalesAmount-TotalProductCost) FROM AdventureWorksDW.dbo.FactResellerSales) AS TotalResellerProfit,
    (SELECT SUM(SalesAmount-TotalProductCost) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalInternetProfit,
    (SELECT SUM(SalesAmount-TotalProductCost) FROM AdventureWorksDW.dbo.FactResellerSales) + (SELECT SUM(SalesAmount-TotalProductCost) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalProfit

-- Total Orders
SELECT 
    (SELECT COUNT(DISTINCT SalesOrderNumber) FROM AdventureWorksDW.dbo.FactResellerSales) AS TotalResellerSales,
    (SELECT COUNT(DISTINCT SalesOrderNumber) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalInternetSales,
    (SELECT COUNT(DISTINCT SalesOrderNumber) FROM AdventureWorksDW.dbo.FactResellerSales) + (SELECT COUNT(DISTINCT SalesOrderNumber) FROM AdventureWorksDW.dbo.FactInternetSales) AS TotalSales

-- Return on Sales
SELECT 
    (SELECT (SUM(SalesAmount - TotalProductCost)/SUM(SalesAmount))*100 FROM AdventureWorksDW.dbo.FactResellerSales) AS ResellerROS,
    (SELECT (SUM(SalesAmount - TotalProductCost)/SUM(SalesAmount))*100 FROM AdventureWorksDW.dbo.FactInternetSales) AS InternetROS

-- Top-Selling Products
SELECT
	dp.EnglishProductName AS ProductName,
	SUM(SalesAmount) AS TotalSales,
	COUNT(dp.EnglishProductName)
FROM (
    SELECT ProductKey ,SalesAmount FROM AdventureWorksDW.dbo.FactResellerSales
    UNION ALL
    SELECT ProductKey, SalesAmount FROM AdventureWorksDW.dbo.FactInternetSales
) ts
JOIN AdventureWorksDW.dbo.DimProduct dp ON ts.ProductKey = dp.ProductKey
GROUP BY
	dp.EnglishProductName
ORDER BY
	TotalSales DESC

-- Sales by Category

SELECT 
	EnglishProductCategoryName,
	--EnglishProductSubcategoryName,
	--EnglishProductCategoryName
	SUM(SalesAmount) AS TotalSales,
	SUM(OrderQuantity) AS UnitSold
	--SUM(OrderQuantity) AS UnitSold
FROM (
    SELECT ProductKey ,SalesAmount, OrderQuantity FROM AdventureWorksDW.dbo.FactResellerSales
    UNION ALL
    SELECT ProductKey, SalesAmount, OrderQuantity FROM AdventureWorksDW.dbo.FactInternetSales
) ts
	JOIN AdventureWorksDW.dbo.DimProduct dp ON ts.ProductKey = dp.ProductKey
	JOIN AdventureWorksDW.dbo.DimProductSubcategory dps ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
	JOIN AdventureWorksDW.dbo.DimProductCategory ppc ON dps.ProductCategoryKey = ppc.ProductCategoryKey
GROUP BY EnglishProductCategoryName
ORDER BY 2 DESC

-- Top Sales by Territory
SELECT
	SalesTerritoryCountry,
	SUM(SalesAmount)
FROM (
    SELECT SalesTerritoryKey ,SalesAmount FROM AdventureWorksDW.dbo.FactResellerSales
    UNION ALL
    SELECT SalesTerritoryKey, SalesAmount FROM AdventureWorksDW.dbo.FactInternetSales
) ts
JOIN AdventureWorksDW.dbo.DimSalesTerritory st
ON ts.SalesTerritoryKey = st.SalesTerritoryKey
GROUP BY SalesTerritoryCountry
ORDER BY 2 DESC

--------CUSTOMER SEGMENT
-- Check Customer Data
SELECT CustomerKey, COUNT(*)
FROM AdventureWorksDW.dbo.DimCustomer
GROUP BY CustomerKey
HAVING CustomerKey > 1

-- Segment Customers Based on Gender
SELECT
	cus.Gender,
	SUM(fs.SalesAmount) AS TotalSales,
	COUNT(DISTINCT cus.CustomerKey) AS TotalCustomers
FROM 
	AdventureWorksDW.dbo.FactInternetSales fs
JOIN AdventureWorksDW.dbo.DimCustomer cus ON fs.CustomerKey = cus.CustomerKey
GROUP BY
	cus.Gender
ORDER BY 
	TotalSales DESC

-- Segment Customers Based on Education
SELECT
	cus.EnglishEducation,
	SUM(fs.SalesAmount) AS TotalSales,
	COUNT(DISTINCT cus.CustomerKey) AS TotalCustomers
FROM 
	AdventureWorksDW.dbo.FactInternetSales fs
JOIN AdventureWorksDW.dbo.DimCustomer cus ON fs.CustomerKey = cus.CustomerKey
GROUP BY
	cus.EnglishEducation
ORDER BY 
	TotalSales DESC

-- Define Income Levels
SELECT
	cus.CustomerKey,
	cus.YearlyIncome,
	CASE
		WHEN cus.YearlyIncome > 75000 THEN 'High'
		WHEN cus.YearlyIncome BETWEEN 35000 AND 75000 THEN 'Medium'
		ELSE 'Low'
	END AS IncomeLevel,
	SUM(fs.SalesAmount) AS TotalSales
FROM
	AdventureWorksDW.dbo.FactInternetSales fs
JOIN AdventureWorksDW.dbo.DimCustomer cus ON fs.CustomerKey = cus.CustomerKey
GROUP BY
		CASE
		WHEN cus.YearlyIncome > 75000 THEN 'High'
		WHEN cus.YearlyIncome BETWEEN 35000 AND 75000 THEN 'Medium'
		ELSE 'Low'
	END,
	cus.YearlyIncome,
	cus.CustomerKey
ORDER BY
	Totalsales DESC

-- Top Customers Contributing to the Sales
WITH CustomerSales AS (
	SELECT
		cus.CustomerKey,
		cus.FirstName,
		cus.LastName,
		SUM(fs.SalesAmount) AS TotalSales,
		COUNT(DISTINCT fs.SalesOrderNumber) AS TotalOrders
	FROM
		AdventureWorksDW.dbo.FactInternetSales fs
	JOIN AdventureWorksDW.dbo.DimCustomer cus ON fs.CustomerKey = cus.CustomerKey
	GROUP BY
		cus.CustomerKey,
		cus.FirstName,
		cus.LastName
)
SELECT *
FROM CustomerSales
ORDER BY 4 DESC

---------PRODUCT DETAIL
-- Determine the Profitability of Each Product
SELECT
	p.EnglishProductName,
	SUM(ts.SalesAmount) AS TotalSales,
	SUM(ts.TotalProductCost) AS TotalCost,
	SUM(ts.SalesAmount-ts.TotalProductCost) AS TotalProfit,
	(SUM(ts.SalesAmount - ts.TotalProductCost) / SUM(ts.SalesAmount)) * 100 AS ProfitMargin
FROM (
    SELECT ProductKey ,SalesAmount, OrderQuantity, TotalProductCost FROM AdventureWorksDW.dbo.FactResellerSales
    UNION ALL
    SELECT ProductKey, SalesAmount, OrderQuantity, TotalProductCost FROM AdventureWorksDW.dbo.FactInternetSales
) ts
JOIN AdventureWorksDW.dbo.DimProduct p 
	On ts.ProductKey = p.ProductKey
GROUP BY
	p.EnglishProductName
ORDER BY
	TotalProfit DESC

-- Conduct a Pricing Analysis
SELECT 
	p.EnglishProductName,
	AVG(ts.UnitPrice) AS AveragePrice,
	MIN(ts.UnitPrice) AS MinPrice,
	MAX(ts.UnitPrice) AS MaxPrice
FROM (
    SELECT ProductKey ,UnitPrice FROM AdventureWorksDW.dbo.FactResellerSales
    UNION ALL
    SELECT ProductKey, UnitPrice FROM AdventureWorksDW.dbo.FactInternetSales
) ts
JOIN AdventureWorksDW.dbo.DimProduct p 
	ON ts.ProductKey = p.ProductKey
GROUP BY
	p.EnglishProductName
ORDER BY
	AVG(ts.UnitPrice) DESC

-- INVENTORY QUANTITY
SELECT i.ProductKey, p.EnglishProductName,i.MovementDate AS Datetime, i.UnitsBalance AS CurrentQuantity, p.StandardCost
FROM AdventureWorksDW.dbo.FactProductInventory i
INNER JOIN (
	SELECT ProductKey, MAX(MovementDate) AS LatestMovementDate
	FROM AdventureWorksDW.dbo.FactProductInventory
	GROUP BY ProductKey
) latest
ON i.ProductKey = latest.ProductKey AND i.MovementDate = latest.LatestMovementDate
JOIN AdventureWorksDW.dbo.DimProduct p
ON p.ProductKey = i.ProductKey






-- 1.Top-Selling and Least-Selling Products Across Different Regions
-- 1.a Top 3 Selling Products by Quantity per Region
WITH RankedSales AS (
    SELECT
        s.Region,
        s.ProductID,
        p.ProductName,
        SUM(s.QuantitySold) AS TotalQuantitySold,
        ROW_NUMBER() OVER (PARTITION BY s.Region ORDER BY SUM(s.QuantitySold) DESC) as rn
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    GROUP BY 1, 2, 3
)
SELECT
    Region,
    ProductID,
    ProductName,
    TotalQuantitySold
FROM RankedSales
WHERE rn <= 3
ORDER BY Region, TotalQuantitySold DESC;

-- 1.b Least 3 Selling Products by Revenue per Region
WITH RegionalRevenue AS (
    SELECT
        s.Region,
        s.ProductID,
        p.ProductName,
        SUM(s.QuantitySold * s.SalePrice_INR) AS TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY s.Region ORDER BY SUM(s.QuantitySold * s.SalePrice_INR) ASC) as rn
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    GROUP BY 1, 2, 3
)
SELECT
    Region,
    ProductID,
    ProductName,
    TotalRevenue
FROM RegionalRevenue
WHERE rn <= 3
ORDER BY Region, TotalRevenue ASC;

-- 2: Top 5 Product Categories by Net Revenue and their Gross Margin %
SELECT
    P.Category,
    SUM(S.QuantitySold * S.SalePrice_INR * (1 - S.DiscountApplied)) AS Net_Revenue,
    SUM(S.QuantitySold * (S.SalePrice_INR * (1 - S.DiscountApplied) - (P.UnitPrice_INR * 0.8))) AS Gross_Margin,
    (SUM(S.QuantitySold * (S.SalePrice_INR * (1 - S.DiscountApplied) - (P.UnitPrice_INR * 0.8))) / SUM(S.QuantitySold * S.SalePrice_INR * (1 - S.DiscountApplied))) * 100 AS Gross_Margin_Percentage
FROM
    Sales S
INNER JOIN
    Products P ON S.ProductID = P.ProductID
GROUP BY
    P.Category
ORDER BY
    Net_Revenue DESC
LIMIT 5;

-- 3: Total Sales Quantity by Region and Product Category (Aggregation and Join)
SELECT
    S.Region,
    P.Category,
    SUM(S.QuantitySold) AS Total_Quantity_Sold
FROM
    Sales S
INNER JOIN
    Products P ON S.ProductID = P.ProductID
GROUP BY
    S.Region, P.Category
ORDER BY
    S.Region, Total_Quantity_Sold DESC;

-- 4: Low Stock Alert: Products whose StockLevel is less than or equal to their ReorderLevel (Join and Filter)

SELECT
    I.ProductID,
    P.ProductName,
    I.StockLevel,
    I.ReorderLevel,
    I.WarehouseLocation
FROM
    Inventory I
INNER JOIN
    Products P ON I.ProductID = P.ProductID
WHERE
    I.StockLevel <= I.ReorderLevel
ORDER BY
    I.StockLevel ASC;
    
-- 5. Discount Effect on Sales and Revenue

SELECT
    CASE
        WHEN DiscountApplied < 0.05 THEN '0% to 5%'
        WHEN DiscountApplied < 0.10 THEN '5% to 10%'
        WHEN DiscountApplied < 0.15 THEN '10% to 15%'
        ELSE '15%+'
    END AS DiscountBand,
    COUNT(SaleID) AS Total_count_of_Transactions,
    SUM(QuantitySold * SalePrice_INR) AS TotalRevenue_INR,
    -- Margin Calculation: (Selling Price - Unit Cost) * Quantity. UnitPrice_INR from products is assumed to be the unit cost.
    SUM(s.QuantitySold * (s.SalePrice_INR - p.UnitPrice_INR)) AS TotalMargin_INR,
    AVG(QuantitySold) AS AvgQuantitySold
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
GROUP BY 1
ORDER BY TotalRevenue_INR DESC;

-- 6: Average Discount per Region and its Effect on Average Revenue per Transaction

SELECT
    Region,
    ROUND(AVG(DiscountApplied) * 100, 2) AS AvgDiscountPercentage,
    COUNT(SaleID) AS TotalTransactions,
    ROUND(AVG(QuantitySold * SalePrice_INR), 2) AS AvgTransactionRevenue
FROM sales
GROUP BY Region
ORDER BY AvgTransactionRevenue DESC;

-- . Customer Segmentation: --

-- 7: Top 10 Most Valuable Customers (Revenue)

SELECT
    c.CustomerID,
    c.Name,
    c.Location,
    c.LoyaltyScore,
    SUM(s.QuantitySold * s.SalePrice_INR) AS TotalRevenueGenerated
FROM sales s
JOIN customers c ON s.CustomerID = c.CustomerID
GROUP BY 1, 2, 3, 4
ORDER BY TotalRevenueGenerated DESC
LIMIT 10;

-- . Marketing Campaign Performance: --

-- 8: Campaign Performance by Total Revenue Generated
SELECT
    m.CampaignID,
    p.ProductName,
    m.Budget_INR,
    m.ConversionRate,
    SUM(s.QuantitySold * s.SalePrice_INR) AS TotalRevenueGenerated
FROM marketing m
JOIN products p ON m.ProductID = p.ProductID
JOIN sales s ON m.ProductID = s.ProductID
GROUP BY 1, 2, 3, 4
ORDER BY TotalRevenueGenerated DESC;

-- 9: Campaign ROI (Revenue to Budget Ratio)
WITH CampaignRevenue AS (
    SELECT
        m.CampaignID,
        SUM(s.QuantitySold * s.SalePrice_INR) AS TotalRevenueGenerated
    FROM marketing m
    JOIN sales s ON m.ProductID = s.ProductID
    GROUP BY 1
)
SELECT
    m.CampaignID,
    m.Budget_INR,
    cr.TotalRevenueGenerated,
    -- Calculate ROI: (Revenue / Budget)
    ROUND(cr.TotalRevenueGenerated / m.Budget_INR, 2) AS RevenueToBudgetRatio
FROM marketing m
JOIN CampaignRevenue cr ON m.CampaignID = cr.CampaignID
ORDER BY RevenueToBudgetRatio DESC;

-- 10: Product Margin by Category

SELECT
    p.Category,
    COUNT(s.SaleID) AS TotalTransactions,
    SUM(s.QuantitySold * s.SalePrice_INR) AS TotalRevenue_INR,
    -- Total Margin Calculation
    SUM(s.QuantitySold * (s.SalePrice_INR - p.UnitPrice_INR)) AS TotalMargin_INR,
    -- Average Margin Percentage
    ROUND(
        (SUM(s.QuantitySold * (s.SalePrice_INR - p.UnitPrice_INR)) * 100.0) /
        SUM(s.QuantitySold * s.SalePrice_INR),
    2) AS AvgMarginPercentage
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY TotalMargin_INR DESC;

-- 11: Supplier Performance: Total Net Revenue for products supplied by each supplier (Join and Aggregation)
SELECT
    P.Supplier,
    SUM(S.QuantitySold * S.SalePrice_INR * (1 - S.DiscountApplied)) AS Total_Net_Revenue
FROM
    Sales S
INNER JOIN
    Products P ON S.ProductID = P.ProductID
GROUP BY
    P.Supplier
ORDER BY
    Total_Net_Revenue DESC;




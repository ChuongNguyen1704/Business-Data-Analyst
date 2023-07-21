
USE [E-commerce]



/*......................		 orders_dataset		...................... */
/*...................... Question 1: Total the number of orders by each year ...................... */

--  Convert Data functions
SELECT 
    YEAR(CONVERT(DATE, order_estimated_delivery_date)) AS yearView, -- Extract year column
    COUNT(order_id) AS Total_Order_Count
FROM dbo.[order]
GROUP BY YEAR(CONVERT(DATE, order_estimated_delivery_date)); -- Group by year (2016, 2017 & 2018)



/*......................		order_payments_dataset & orders_dataset		...................... */
/*...................... Question 2: Total the gross merchandise value by each year ...................... */
SELECT 
    YEAR(CONVERT(DATE, order_estimated_delivery_date)) AS yearView, -- Extract year column
    ROUND(SUM(op.payment_value), 2) AS Gross_Merchandise_Value -- Round the sum to 2 decimal places
FROM dbo.[order] AS o
JOIN dbo.[order_payments] AS op 
    ON o.order_id = op.order_id
GROUP BY YEAR(CONVERT(DATE, order_estimated_delivery_date)); -- Group by year (2016, 2017 & 2018)

SELECT 
    ROUND(SUM(op.payment_value), 2) AS Gross_Merchandise_Value -- Round the sum to 2 decimal places
FROM dbo.[order] AS o
JOIN dbo.[order_payments] AS op 
    ON o.order_id = op.order_id



/*......................		order_payments_dataset & orders_items & product		...................... */
/*...................... Question 3: The top 10 best-selling products and (Add payment values column). ...................... */

-- Join 2 conditional more
SELECT TOP 10
    oi.product_id,
	p.product_category_name,
	COUNT(oi.product_id) AS total_quantity_sold,
    SUM(op.payment_value) AS revenue
FROM
    dbo.[order_items] AS oi
LEFT JOIN 
	dbo.[products] AS p ON oi.product_id = p.product_id
LEFT JOIN 
	dbo.[order_payments] AS op ON oi.order_id = op.order_id
GROUP BY
    oi.product_id,
	product_category_name
ORDER BY
    total_quantity_sold DESC;


/*......................		order_payments_dataset		...................... */
/*...................... Question 4: All products have payment installments more than 5 times. ...................... */

-- Subquery and join
-- Scenario
SELECT
    (SELECT product_category_name
	 FROM dbo.products
	 WHERE product_id = oi.product_id) AS product_Name,
     op.payment_installments AS installments_Payment
FROM dbo.order_items AS oi
JOIN dbo.order_payments AS op ON oi.order_id = op.order_id
WHERE payment_installments IN (
    SELECT payment_installments
    FROM dbo.order_payments
	WHERE payment_installments > 5
)
ORDER BY op.payment_installments DESC;
-----------------------------------------------------
-- Scenario 2
SELECT
	product_category_name,
	payment_installments
FROM dbo.products AS p
JOIN dbo.order_items AS oi ON p.product_id = oi.product_id
JOIN dbo.order_payments AS op ON oi.order_id = op.order_id
WHERE payment_installments > 5
ORDER BY payment_installments DESC;

/*......................		order_reviews		...................... */
/*...................... Question 5: All orders are reviewed more than 4 star(Adding column with values 4-5: good and 1-3: bad). ...................... */

-- Case When - Subquery - Join 
 SELECT
        (SELECT product_category_name
         FROM dbo.products
         WHERE product_id = oi.product_id) AS product_Name,
        review_score,
        CASE
            WHEN oi.order_id IN (
                SELECT order_id
                FROM dbo.order_reviews
                WHERE review_score >= 4
            ) THEN 'Positive'
            ELSE 'Negative'
        END AS review_status
    FROM dbo.order_items AS oi
    JOIN dbo.order_reviews ON order_reviews.order_id = oi.order_id

/*...................... Question 6: The number of reviews by review category. ...................... */
-- View + CTEs + CASE WHEN + Independenly Nested Query
CREATE VIEW review_score_percentage AS
WITH total_review_score AS (
    SELECT
        (SELECT product_category_name
         FROM dbo.products
         WHERE product_id = oi.product_id) AS product_Name,
        review_score,
        CASE
            WHEN oi.order_id IN (
                SELECT order_id
                FROM dbo.order_reviews
                WHERE review_score >= 4
            ) THEN 'Positive'
            ELSE 'Negative'
        END AS review_status
    FROM dbo.order_items AS oi
    JOIN dbo.order_reviews ON order_reviews.order_id = oi.order_id
)
SELECT
    review_status,
    COUNT(*) AS category_count,
    CONCAT(FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM total_review_score), 'N2'), '%') AS category_percentage
FROM total_review_score
GROUP BY review_status;


/*...................... Question 7: The total number of the payment value of each payment type.   ...................... */

-- CTEs + CROSS JOIN
CREATE VIEW payment_type AS
WITH TotalSum AS (
    SELECT ROUND(SUM(payment_value), 2) AS total_sum
    FROM dbo.order_payments
)
SELECT
    op.payment_type,
	ROUND(SUM(op.payment_value), 2) AS total_value,
    CONCAT(FORMAT(SUM(op.payment_value) * 100.0 / ts.total_sum, 'N2'), '%') AS percentage
FROM dbo.order_payments AS op
CROSS JOIN TotalSum AS ts 
GROUP BY op.payment_type, ts.total_sum
HAVING ROUND(SUM(op.payment_value), 2) > 0;


/*......................		customers & order_payments & order		...................... */
/*...................... Question 8: GMV Distribution by States. ...................... */

-- Views + Window Function
CREATE VIEW dbo.state_percentage AS
SELECT 
    customerState,
    revenue,
    CONCAT(FORMAT(revenue * 100.0 / SUM(revenue) OVER (), 'N2'), '%') AS category_percentage
FROM (
    SELECT 
        c.customer_state AS customerState,
        SUM(op.payment_value) AS revenue
    FROM dbo.customers AS c
    JOIN dbo.[order] AS o ON o.customer_id = c.customer_id
    JOIN dbo.order_payments AS op ON op.order_id = o.order_id
    GROUP BY c.customer_state) AS subquery

SELECT * FROM dbo.state_percentage ORDER BY revenue DESC;


/*......................		Calendar & order		...................... */
/*...................... Question 9: The number of orders by days of week. ...................... */
SELECT 
    c.DayOfWeek,
    COUNT(o.[order_id]) AS NumberOfOrders,
    CONCAT(FORMAT(COUNT(o.[order_id]) * 100.0 / SUM(COUNT(o.[order_id])) OVER (), 'N2'), '%') AS Percentage
FROM 
    dbo.Calendar c
LEFT JOIN 
    dbo.[order] AS o
    ON DATEPART(weekday, o.[order_estimated_delivery_date]) = DATEPART(weekday, c.CalendarDate)
GROUP BY
    c.DayOfWeek
HAVING 
    COUNT(o.[order_id]) > 2
ORDER BY 
  Percentage DESC;


/*......................		Calendar & order & order_payments		...................... */
/*...................... Question 10: The revenue of all months by each year. ...................... */

WITH TotalSum AS (
    SELECT 
        DATEPART(YEAR, o.order_estimated_delivery_date) AS [Year],
        ROUND(SUM(op.payment_value), 2) AS total_sum
    FROM dbo.[order] AS o
    JOIN dbo.[order_payments] AS op ON o.order_id = op.order_id
    GROUP BY DATEPART(YEAR, o.order_estimated_delivery_date)
)
SELECT 
    c.Year,
    c.Month,
    ROUND(SUM(op.payment_value), 2) AS total_revenue,
    CONCAT(FORMAT(ROUND(SUM(op.payment_value) * 100.0 / ts.total_sum, 2), 'N2'), '%') AS Contribution
FROM dbo.[order] AS o
JOIN dbo.[order_payments] AS op ON o.order_id = op.order_id
JOIN dbo.[Calendar] AS c ON c.CalendarDate = o.order_estimated_delivery_date
JOIN TotalSum as ts ON DATEPART(YEAR, c.CalendarDate) = ts.[Year]
GROUP BY c.Year, c.Month, ts.total_sum
HAVING ROUND(SUM(op.payment_value) * 100.0 / ts.total_sum, 2) > 0
ORDER BY c.Year, c.Month DESC;



/*......................		Calendar & payments_value		...................... */
/*.............. Question 11: All months by each year have more revenue than the average of all months by each year. .............. */

WITH MonthlyRevenue AS (
    SELECT 
        c.Year,
        c.Month,
        ROUND(SUM(op.payment_value), 2) AS total_revenue
    FROM dbo.[order] AS o
    JOIN dbo.[order_payments] AS op ON o.order_id = op.order_id
    JOIN dbo.[Calendar] AS c ON c.CalendarDate = o.order_estimated_delivery_date
    GROUP BY c.Year, c.Month
),
AverageRevenueByYear AS (
    SELECT
        Year,
        ROUND(AVG(total_revenue), 2) AS avg_revenue
    FROM MonthlyRevenue
    GROUP BY Year
)
SELECT 
    m.Year,
    m.Month,
    m.total_revenue,
    a.avg_revenue AS average_revenue
FROM MonthlyRevenue m
JOIN AverageRevenueByYear a ON m.Year = a.Year
WHERE m.total_revenue > a.avg_revenue
ORDER BY m.Year, m.Month DESC;

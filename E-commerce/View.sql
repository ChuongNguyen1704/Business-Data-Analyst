

CREATE VIEW productName AS
	SELECT 
		column1 AS ProductName,
		column2 AS ProductName_Brasil
	FROM dbo.product_category_name_translation  



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
DROP VIEW PaymentType 
GO
CREATE VIEW PaymentType AS
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
--HAVING ROUND(SUM(op.payment_value), 2) > 0;


/*......................		customers & order_payments & order		...................... */
/*...................... Question 8: GMV Distribution by States. ...................... */

-- Views + Window Function
DROP VIEW StatePercentage 
GO
CREATE VIEW StatePercentage AS
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




/*......................		payment_value & customer_state		...................... */
/*.............. Question 12: Fetch all products of states that have the best high revenue. .............. */
-- CTEs + 3 JOINs + Window function
CREATE VIEW TotalRevenueOfState AS
WITH CustomerState_CTE AS (
    SELECT 
        o.order_id,
        c.customer_state AS Customer_State,
        p.product_category_name AS Product_Name
    FROM dbo.customers AS c
    JOIN dbo.[order] AS o ON o.customer_id = c.customer_id
    LEFT JOIN dbo.order_items AS oi ON oi.order_id = o.order_id
    LEFT JOIN dbo.products AS p ON p.product_id = oi.product_id
)
, ProductSum AS (
    SELECT 
        cs.Customer_State,
        cs.Product_Name,
        SUM(op.payment_value) AS total_revenue
    FROM CustomerState_CTE AS cs
    LEFT JOIN dbo.order_payments AS op ON cs.order_id = op.order_id
    GROUP BY
        cs.Customer_State,
        cs.Product_Name
)
, CustomerStateTotal AS (
    SELECT 
        Customer_State,
        SUM(total_revenue) AS Total_State_Sum
    FROM ProductSum
    GROUP BY Customer_State
)
SELECT 
    ps.Customer_State,
    ps.Product_Name,
    ROUND(ps.total_revenue, 2) AS Total_Revenue,
    RANK() OVER (PARTITION BY ps.Customer_State ORDER BY ps.total_revenue DESC) AS ProductName_Rank,
    CONCAT(FORMAT(ps.total_revenue * 100.0 / cst.Total_State_Sum, 'N2'), '%') AS Share_Of_Total
FROM ProductSum AS ps
JOIN CustomerStateTotal AS cst ON ps.Customer_State = cst.Customer_State;



/*......................		payment_value & customer_state		...................... */
/*.............. Question 13: Total revenue of each state from 2016 to 2018. .............. */

CREATE VIEW TotalRevenueByYear AS
WITH CustomerStateRevenue AS (
    SELECT
        o.order_id,
        c.customer_state,
        o.order_estimated_delivery_date
    FROM dbo.customers AS c
    LEFT JOIN dbo.[order] AS o
    ON o.customer_id = c.customer_id 
)
SELECT 
    csr.customer_state AS customerState,
    ROUND(SUM(CASE
              WHEN DATEPART(YEAR, csr.order_estimated_delivery_date) = 2016 THEN op.payment_value
              ELSE 0
          END), 2) AS TotalRevenue_2016,
    ROUND(SUM(CASE
              WHEN DATEPART(YEAR, csr.order_estimated_delivery_date) = 2017 THEN op.payment_value
              ELSE 0
          END), 2) AS TotalRevenue_2017,
    ROUND(SUM(CASE
              WHEN DATEPART(YEAR, csr.order_estimated_delivery_date) = 2018 THEN op.payment_value
              ELSE 0
          END), 2) AS TotalRevenue_2018
FROM 
	dbo.order_payments AS op 
LEFT JOIN 
	CustomerStateRevenue AS csr ON csr.order_id = op.order_id
GROUP BY csr.customer_state;

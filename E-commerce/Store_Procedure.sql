



/*---------------- Number of orders are purchased by seller_id ----------------*/

ALTER PROC usp_NumberOfOrderBySeller_id
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- Select the number of orders for the specified date range along with the seller_id and product_id
    SELECT oi.seller_id, oi.product_id, o.order_purchase_timestamp, COUNT(DISTINCT o.order_id) AS TotalOrders
    FROM dbo.[order] AS o
    INNER JOIN dbo.order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= @StartDate AND o.order_purchase_timestamp <= @EndDate
    GROUP BY oi.seller_id, oi.product_id
    ORDER BY TotalOrders DESC;
END;

GO
-- Replace 'Start_Date_Value' and 'End_Date_Value' with the desired dates in 'YYYY-MM-DD' format
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

EXEC usp_NumberOfOrderBySeller_id @StartDate = '2017-07-31', @EndDate = '2018-07-01';


ALTER PROCEDURE usp_TotalRevenueByState
	@StartDate DATE,
	@EndDate DATE
AS
BEGIN
	SELECT
		c.customer_state AS CustomerState,
		YEAR(o.order_purchase_timestamp) AS Year_,
		SUM(op.payment_value) AS TotalRevenue,
		DENSE_RANK() OVER (PARTITION BY YEAR(o.order_purchase_timestamp) ORDER BY SUM(op.payment_value) DESC) AS Rank_
	FROM 
		dbo.customers AS c
		JOIN dbo.[order] AS o ON o.customer_id = c.customer_id
		JOIN dbo.order_payments AS op ON op.order_id = o.order_id
	WHERE o.order_purchase_timestamp >= @StartDate AND o.order_purchase_timestamp <= @EndDate
	GROUP BY c.customer_state, YEAR(o.order_purchase_timestamp)
	ORDER BY Year_ DESC
END



GO
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

EXEC usp_TotalRevenueByState @StartDate = '2016', @EndDate = '2019';

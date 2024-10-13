
---Exploratory Analysis
--- column Data types
SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE column_name IN ('Product', 'Customer', 'Qtr_1', 'Qtr_2', 'Qtr_3', 'Qtr_4')
	AND TABLE_NAME = 'SALES'; 
	

---data rows 
SELECT COUNT(*)
FROM SALES;

---missing or NULL values 
SELECT COUNT(*) AS missing_values
FROM SALES
WHERE Qtr_1 IS NULL 
	AND Qtr_2 IS NULL 
	AND Qtr_3 IS NULL 
	AND Qtr_4 IS NULL;

--- duplicate rows 
SELECT Product, Customer, Qtr_1, Qtr_2, Qtr_3, Qtr_4, COUNT(*)
FROM SALES
GROUP BY Product, Customer, Qtr_1, Qtr_2, Qtr_3, Qtr_4
HAVING COUNT(*) > 1;

--- total Unique products and customers
SELECT COUNT(DISTINCT Product)
FROM SALES;

SELECT COUNT(DISTINCT Customer) 
FROM SALES;


---total quarterly sales 
	--- How each quarter performed compared to previous one 
	--- how each quarter contributed to total sales 
WITH quarter_sales AS(
SELECT 'Q1' AS Quarter, SUM(Qtr_1) AS sales
FROM SALES
UNION ALL
SELECT 'Q2', SUM(Qtr_2) 
FROM SALES
UNION ALL
SELECT'Q3', SUM(Qtr_3)
FROM SALES
UNION ALL 
SELECT 'Q4', SUM(Qtr_4)
FROM SALES) 

SELECT Quarter, 
	sales, 
	COALESCE(sales - LAG(sales, 1) OVER(ORDER BY Quarter ASC), 0) AS sale_change,
	CONVERT(DECIMAL(10,2),ROUND((sales*100.0)/SUM(sales) OVER(), 2)) AS percent_contribution_to_total, 
	SUM(sales) OVER() AS Total_sales
FROM quarter_sales
GROUP BY Quarter, sales; 


--- Product/ Customer performance 
	--- generally which product performed the best 
WITH sales_per_product AS (
SELECT DISTINCT Product,
	SUM(Qtr_1) AS Qone_sales,
	SUM(Qtr_2) AS Qtwo_sales,
	SUM(Qtr_3) AS Qthree_sales,
	SUM(Qtr_4) AS Qfour_sales, 
	SUM(Qtr_1 + Qtr_2 + Qtr_3 + Qtr_4) AS total_sales
FROM SALES
GROUP BY Product),
---ORDER BY total_sales DESC)

sales_rank AS(
SELECT product, Qone_sales,
	RANK() OVER(ORDER BY Qone_sales DESC) AS Qone_rank,
	Qtwo_sales,
	RANK() OVER(ORDER BY Qtwo_sales DESC) AS Qtwo_rank,
	Qthree_sales,
	RANK() OVER(ORDER BY Qthree_sales DESC) AS Qthree_rank,
	 Qfour_sales,
	RANK() OVER(ORDER BY Qfour_sales DESC) AS Qfour_rank,
	total_sales,
	RANK() OVER(ORDER BY total_sales DESC) AS total_rank
FROM sales_per_product)

SELECT Product, 
	Qone_sales, 
    CONVERT(VARCHAR(50), Qone_rank) + 
    CASE WHEN Qone_rank = 1 THEN '(Top in Q1)' 
		WHEN Qone_rank > 20 THEN '(Last in Q1)'	ELSE '' END AS Qone_Rank, 
	Qtwo_sales, 
	CONVERT(VARCHAR(50), Qtwo_rank) + 
    CASE WHEN Qtwo_rank = 1 THEN '(Top in Q2)' 
		WHEN Qtwo_rank > 20 THEN '(Last in Q2)' ELSE '' END AS Qtwo_Rank,
	Qthree_sales, 
	CONVERT(VARCHAR(50), Qthree_rank) + 
    CASE WHEN Qthree_rank = 1 THEN '(Top in Q3)' 
		WHEN Qthree_rank > 20 THEN '(Last in Q3)' ELSE '' END AS Qthree_Rank,
	Qfour_sales,
	CONVERT(VARCHAR(50), Qfour_rank) + 
    CASE WHEN Qfour_rank = 1 THEN '(Top in Q4)' 
		WHEN Qfour_rank > 20 THEN '(Last in Q4)' ELSE '' END AS Qfour_Rank,
	total_sales,
	total_rank
FROM sales_rank; 


	--- customers and how they performed 
		--- Customer with total sales more than the average total sales
SELECT DISTINCT Customer,
	SUM(Qtr_1 + Qtr_2 + Qtr_3 + Qtr_4) AS total_sales_amnt
FROM SALES
GROUP BY Customer
HAVING SUM(Qtr_1 + Qtr_2 + Qtr_3 + Qtr_4) >= (SELECT AVG(Qtr_1 + Qtr_2 + Qtr_3 + Qtr_4) AS avg_sales 
												FROM SALES)
ORDER BY total_sales_amnt DESC; 




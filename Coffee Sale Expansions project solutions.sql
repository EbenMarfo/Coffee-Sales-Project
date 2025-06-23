-- Monday Coffee Data Analysis
SELECT * FROM city
SELECT * FROM products
SELECT * FROM customers
SELECT * FROM sales

-- Report & Data Analysis

-- Q1 Coffee consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name, 
	ROUND(SUM(population * 0.25)/100, 0) coffee_consumers,
	ROUND(SUM(population * 0.25)/1000000, 2) coffee_consumers_in_millions,
	city_rank
FROM city
GROUP BY city_name, city_rank
ORDER BY 3 DESC

-- Q2. Total Revenue from coffee sales
-- What is the total revenue generated from coffee sales across all 
--cities in the last quarter of 2023?
SELECT 
	ci.city_name,
	SUM(total) AS total_revenue
FROM sales s 
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE EXTRACT(quarter from s.sale_date) = 4
	AND EXTRACT(YEAR FROM s.sale_date ) = 2023
GROUP BY 1
ORDER BY 2 DESC

--Q3. Sales count for each product
-- How many units of each coffee product has been sold
SELECT 
	product_name,
	COUNT(sale_id),  AS number_of_sales
FROM sales s
JOIN products p ON p.product_id = s.product_id
GROUP BY 1 
ORDER BY 2 DESC

--Q4 Average sale amount per city
-- what is the average sales amount per customer in each city

-- number of customers in each city
-- total revenue of each city
SELECT 
	ci.city_name as city,
	COUNT(DISTINCT c.customer_id) as total_customers,
	SUM(s.total) total_revenue,
	ROUND(
		SUM(total::NUMERIC)/ COUNT(DISTINCT c.customer_id), 
		1) AS AVG_sale_amount
FROM sales s
LEFT JOIN customers c ON c.customer_id = s.customer_id
LEFT JOIN city ci on ci.city_id = c.city_id
GROUP BY 1
ORDER BY total_revenue DESC

-- Q.5
-- City Population and Coffee Consumers (25%)

-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
WITH CTE_city AS (
SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) coffee_consumers
FROM city
),
total_customers as(
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) total_current_cx
FROM customers c
LEFT JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
)
SELECT CTE_city.city_name,
		total_customers.total_current_cx,
		CTE_city.coffee_consumers
FROM CTE_city 
LEFT JOIN total_customers  ON total_customers.city_name = CTE_city.city_name
		
-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
SELECT * FROM
(
SELECT 
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) AS total_orders,
	DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) rank
FROM sales s
LEFT JOIN products p ON p.product_id = s.product_id
LEFT JOIN customers c ON c.customer_id = s.customer_id
LEFT JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1, 2
) TTT
WHERE rank <= 3


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
SELECT 
	ci.city_name,
	COUNT(DISTINCT s.customer_id) unique_customers
FROM city ci 
JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id 
WHERE p.product_id IN 
	(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1

--Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions
WITH city_table
AS
(
		SELECT 
			city_name,
			COUNT(DISTINCT s.customer_id) total_cx,
			SUM(total) total_revenue,
			ROUND(SUM(total)::NUMERIC/COUNT(DISTINCT s.customer_id), 2) AVG_sale_PER_CX
		FROM city ci
			LEFT JOIN customers c ON c.city_id = ci.city_id
			LEFT JOIN sales s ON s.customer_id = c.customer_id
			GROUP BY city_name
),
city_rent AS 
	(
		SELECT 
			city_name,
			estimated_rent
		FROM city 
	)
SELECT 
	ct.city_name,
	estimated_rent,
	ct.total_cx,
	AVG_sale_PER_CX,
	ROUND(estimated_rent::NUMERIC/ct.total_cx, 2) AVG_rent_per_cx
FROM city_table ct
JOIN city_rent cr ON cr.city_name = ct.city_name
ORDER BY 4 DESC

-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) 
--in sales over different periods (monthly) by each city
WITH monthly_sales 
AS 
(
	SELECT 
		city_name,
		EXTRACT(MONTH FROM sale_date) months,
		EXTRACT(YEAR FROM sale_date) AS Yr,
		SUM(total) total_sales
	FROM sales s
	LEFT JOIN customers c ON c.customer_id = s.customer_id
	LEFT JOIN city ci on ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio 
AS 
(
SELECT 
	city_name,
	months,
	yr,
	total_sales as cr_month_sale,
	LAG(SUM(total_sales), 1) OVER (PARTITION BY city_name ORDER BY yr, months) last_month_sale
FROM monthly_sales
GROUP BY 1, 2, 3, 4
)
SELECT 
	city_name,
	months,
	yr,
	last_month_sale,
	cr_month_sale,
	ROUND(
		(cr_month_sale - last_month_sale)::NUMERIC / 
			last_month_sale::NUMERIC * 100, 2) growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL

-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, 
-- total customers, estimated coffee consumer
WITH city_table
AS
(
		SELECT 
			city_name,
			COUNT(DISTINCT s.customer_id) total_cx,
			SUM(total) total_revenue,
			ROUND(SUM(total)::NUMERIC/COUNT(DISTINCT s.customer_id), 2) AVG_sale_PER_CX
		FROM city ci
			LEFT JOIN customers c ON c.city_id = ci.city_id
			LEFT JOIN sales s ON s.customer_id = c.customer_id
			GROUP BY city_name
),
city_rent AS 
	(
		SELECT 
			city_name,
			estimated_rent,
			ROUND((population * 0.25)/1000000, 2) estimated_coffee_consumers_in_millions
		FROM city 
	)
SELECT 
	ct.city_name,
	total_revenue,
	estimated_rent,
	ct.total_cx,
	estimated_coffee_consumers_in_millions,
	AVG_sale_PER_CX,
	ROUND(estimated_rent::NUMERIC/ct.total_cx, 2) AVG_rent_per_cx
FROM city_table ct
JOIN city_rent cr ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.


	
	










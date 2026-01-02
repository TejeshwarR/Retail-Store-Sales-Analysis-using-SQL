
-- Creating database
CREATE DATABASE sales;

USE sales;


-- Creating tables
CREATE TABLE sales_store(
	transaction_id VARCHAR(15),
	customer_id VARCHAR(15),
	customer_name VARCHAR(30),
	customer_age INT,
	gender VARCHAR(15),
	product_id VARCHAR(15),
	product_name VARCHAR(15),
	product_category VARCHAR(15),
	quantiy INT,
	prce FLOAT,
	payment_mode VARCHAR(15),
	purchase_date DATE,
	time_of_purchase TIME,
	status VARCHAR(15)
);

-- Loading  data into database
LOAD DATA INFILE '"C:\Users\tejes\Desktop\Data Analyst\Portfolio projects\SQL\Retail Store Sales Data.csv"'
INTO TABLE sales_store
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM sales_store;




-- Checking total records
SELECT COUNT(*) as total_records FROM sales_store;

-- Checking data types and structure
DESCRIBE sales_store;


-- Checking for duplicates on key fields

SELECT transaction_id, COUNT(*)
FROM sales_store
GROUP BY transaction_id
HAVING COUNT(transaction_id) >1;



-- duplicate transaction id
-- "TXN745076"
-- "TXN855235"
-- "TXN626832"
-- "TXN240646"
-- "TXN342128"
-- "TXN981773"
-- "TXN832908"


-- ============================================
-- DATA CLEANING
-- ============================================
-- copying data into new table for data cleaning
SELECT * INTO sales FROM sales_store;

CREATE TABLE sales LIKE sales_store;

INSERT INTO sales
SELECT * FROM sales_store;


WITH duplicates AS (
    SELECT customer_id,
           ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY customer_id) AS row_num
    FROM sales
)
DELETE FROM sales
WHERE customer_id IN (
    SELECT customer_id FROM duplicates WHERE row_num > 1
);

SELECT transaction_id, COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) >1;

SELECT * FROM sales;


-- correction of headers

ALTER TABLE sales rename column quantiy to quantity;
ALTER TABLE sales rename column prce to price;

SELECT * FROM sales;


-- count null valus

SELECT COUNT(*) AS null_count
FROM sales
WHERE transaction_id IS NULL OR transaction_id = '';

DELETE FROM sales 
WHERE transaction_id IS NULL OR transaction_id = '';

-- ============================================
-- EXPLORATORY DATA ANALYSIS
-- ============================================

-- Top 5 most selling products by quantity

SELECT DISTINCT status
from sales;

SELECT product_name, SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC
limit 5;

-- business problem: we don't know which products are most in demand.
-- business impact: helps priortize stock and boost sales through targeted promotions.

-- Products which are most frequently canceled
SELECT product_name, COUNT(*) AS total_cancelled
FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC
limit 5;

-- business problem: frequently cancellations affect revenue and customer trust
-- business impact: identify poor-performing products to improve quality or remove from catelog.

-- time of the day has highest number of purchases

Select * from sales;

SELECT  
  CASE 
    WHEN TIME(time_of_purchase) BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning'
    WHEN TIME(time_of_purchase) BETWEEN '12:00:00' AND '15:59:59' THEN 'Noon'
    WHEN TIME(time_of_purchase) BETWEEN '16:00:00' AND '19:59:59' THEN 'Evening'
    WHEN TIME(time_of_purchase) BETWEEN '20:00:00' AND '23:59:59' THEN 'Night'
    WHEN TIME(time_of_purchase) BETWEEN '00:00:00' AND '04:59:59' THEN 'Night'
  END AS time_of_day,
  	COUNT(*) AS total_order
	FROM sales
	GROUP BY  
  CASE 
    WHEN TIME(time_of_purchase) BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning'
    WHEN TIME(time_of_purchase) BETWEEN '12:00:00' AND '15:59:59' THEN 'Noon'
    WHEN TIME(time_of_purchase) BETWEEN '16:00:00' AND '19:59:59' THEN 'Evening'
    WHEN TIME(time_of_purchase) BETWEEN '20:00:00' AND '23:59:59' THEN 'Night'
    WHEN TIME(time_of_purchase) BETWEEN '00:00:00' AND '04:59:59' THEN 'Night'
  END
  ORDER BY total_order DESC;

-- business problem solved: find the peak sales times
-- business impact:optimize staffing, promotions and server loads

-- top 5 highest spending customers

SELECT 
    customer_name,
    CONCAT('₹', FORMAT(SUM(price * quantity), 0)) AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY SUM(price * quantity) DESC
LIMIT 5;


-- business problem solved: identify VIP customers
-- business impact: personalized offers, loyality rewards, and retention.

SELECT * FROM sales;

-- product category to generate the highest revenue
SELECT 
    product_category,
    CONCAT('₹', FORMAT(SUM(price * quantity), 0)) AS highest_revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC
LIMIT 1;
                          

-- business problem solved: identify top-performing product categories.
-- business impact: refine product category, supply chain, and promotions.
-- allowing the business to invest more in high-margin or high-demand categories.

-- the return/cancellation rate per product category
-- cancellation
SELECT product_category,
  CONCAT(ROUND(COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*), 2),' %') AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

-- return
SELECT product_category,
  CONCAT(ROUND(COUNT(CASE WHEN status = 'returned' THEN 1 END) * 100.0 / COUNT(*), 2),' %') AS returned_percent
FROM sales
GROUP BY product_category
ORDER BY returned_percent DESC;

-- bussiness problem solved: monitor dissatisfaction trends per category
-- bussiness impact: reduce returns, improve product descriptions/expections,
-- helps indentify and fix product or logistics issues.

-- most preferred payment mode


SELECT payment_mode, COUNT(payment_mode) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count desc;

-- business problem: know which payment options customer prefer
-- business impact: streamline payment processing, prioritizw popular modes.

-- how does age group affect purchasing behaviour
SELECT 
    CASE 
        WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
        WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
        WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
        ELSE '51+'
    END AS customer_Age,
    CONCAT('₹', FORMAT(SUM(price * quantity), 0)) AS total_purchase
FROM sales
GROUP BY 
    CASE 
        WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
        WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
        WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
        ELSE '51+'
    END
ORDER BY SUM(price * quantity) DESC;


-- business problem solved: understand customer demographics.
-- business impact: targeted marketing and product recommendations by age group.

-- monthly sales trend

SELECT 
    DATE_FORMAT(purchase_date, '%Y-%m') AS month_year,
    CONCAT('₹', FORMAT(SUM(price * quantity), 0)) AS total_sales,
    SUM(quantity) AS total_quantity
FROM sales
GROUP BY DATE_FORMAT(purchase_date, '%Y-%m')
ORDER BY DATE_FORMAT(purchase_date, '%Y-%m');




-- business problem solved: sales fluctuations go unnoticed.
-- business impact: plan inventory and marketing according to seasonal trends.

-- are certain gender buying more specific product categories?

SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY gender;



-- business problem solved: gender-based product preferences.
-- business impact: personalized ads, gender-focused campaigns.
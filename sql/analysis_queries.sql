-- =============================================================================
-- RETAIL SALES ANALYSIS - SQL QUERY EXAMPLES
-- =============================================================================
-- Portfolio of SQL queries demonstrating data analysis techniques for retail 
-- sales data, including revenue analysis, customer segmentation, loyalty program 
-- evaluation, and regional performance metrics.
--
-- Data Source: TechHive retail sales database (2019-2023)
-- Tables: retail_sales (main view), customers_clean, orders, products
-- =============================================================================

-- =============================================================================
-- 1. BASIC DATA EXPLORATION & SUMMARY STATISTICS
-- =============================================================================

-- Q: What is the basic overview of our dataset?
-- Get total records, unique customers, and date range
SELECT
    COUNT(*) as total_records,
    COUNT(DISTINCT customer_id) as unique_customers,
    MIN(purchase_ts) as earliest_order,
    MAX(purchase_ts) as latest_order
FROM retail_sales;

-- Q: Get basic customer demographics overview
SELECT COUNT(*) AS total,
    COUNT(DISTINCT customer_id) AS unique_ids
FROM customers_clean;

-- Q: What is our total revenue across all years?
SELECT ROUND(SUM(purchase_price))
FROM retail_sales;

-- Q: Get data coverage by year
SELECT 
    MIN(purchase_year) as earliest_year,
    MAX(purchase_year) as latest_year,
    COUNT(DISTINCT purchase_year) as total_years
FROM retail_sales;

-- =============================================================================
-- 2. REVENUE & SALES PERFORMANCE ANALYSIS
-- =============================================================================

-- Q: How has total revenue and order volume trended annually?
SELECT
    purchase_year,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(purchase_price), 2) AS total_revenue,
    ROUND(AVG(purchase_price), 2) AS average_order_value
FROM retail_sales
GROUP BY purchase_year
ORDER BY purchase_year;

-- Q: Monthly revenue trends for USD transactions
SELECT
    strftime('%Y-%m', purchase_ts) AS month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(purchase_price), 2) AS total_revenue,
    ROUND(AVG(purchase_price), 2) AS avg_order_value
FROM retail_sales
WHERE currency = 'USD'
GROUP BY month
ORDER BY month;

-- Q: Monthly sales volume and revenue trends
SELECT
    purchase_month,
    STRFTIME('%Y-%m', purchase_ts) AS purchase_year_month,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
GROUP BY purchase_year_month
ORDER BY purchase_year_month;

-- Q: Quarterly performance analysis with aggregated metrics
WITH quarterly_totals AS (
    SELECT
        strftime('%Y', purchase_ts) AS year,
        CASE 
            WHEN strftime('%m', purchase_ts) IN ('01','02','03') THEN 'Q1'
            WHEN strftime('%m', purchase_ts) IN ('04','05','06') THEN 'Q2'
            WHEN strftime('%m', purchase_ts) IN ('07','08','09') THEN 'Q3'
            WHEN strftime('%m', purchase_ts) IN ('10','11','12') THEN 'Q4'
        END AS quarter,
        COUNT(order_id) AS orders_per_quarter
    FROM retail_sales
    GROUP BY year, quarter
)
SELECT 
    quarter,
    AVG(orders_per_quarter) AS avg_orders_per_quarter,
    MIN(orders_per_quarter) AS min_orders,
    MAX(orders_per_quarter) AS max_orders
FROM quarterly_totals
GROUP BY quarter
ORDER BY quarter;

-- =============================================================================
-- 3. ORDER STATUS & OPERATIONAL METRICS
-- =============================================================================

-- Q: Annual order status distribution (returns, cancellations, etc.)
SELECT
    purchase_year,
    order_status,
    COUNT(order_id) AS total_orders
FROM retail_sales
GROUP BY purchase_year, order_status
ORDER BY total_orders DESC;

-- Q: Total orders by year for trend analysis
SELECT
    purchase_year,
    count(order_id) AS total_orders
FROM retail_sales
GROUP BY purchase_year
ORDER BY purchase_year;

-- =============================================================================
-- 4. CUSTOMER ACQUISITION & RETENTION ANALYSIS
-- =============================================================================

-- Q: Annual new customer signups and engagement metrics
SELECT
    customer_signup_year,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(order_id) / COUNT(DISTINCT customer_id) AS avg_transactions_per_customer,
    SUM(purchase_price) / COUNT(DISTINCT customer_id) AS avg_revenue_per_customer
FROM retail_sales 
WHERE CAST(customer_signup_year AS INT) > 2018
GROUP BY customer_signup_year;

-- Q: Count distinct customer signups by signup year
SELECT 
    customer_signup_year,
    COUNT(DISTINCT customer_id) as customers_by_signup_year
FROM retail_sales
GROUP BY customer_signup_year;

-- Q: Annual new customer signups by marketing channel
SELECT
    customer_signup_year,
    COUNT(DISTINCT customer_id) AS num_customers,
    customer_marketing_channel
FROM customers_clean
WHERE CAST(customer_signup_year AS INT) > 2018
GROUP BY customer_signup_year, customer_marketing_channel;

-- =============================================================================
-- 5. LOYALTY PROGRAM PERFORMANCE ANALYSIS
-- =============================================================================

-- Q: Loyalty program impact on customer metrics by signup cohort
SELECT
    customer_signup_year,
    customer_loyalty_program, 
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(purchase_price) / COUNT(DISTINCT customer_id) AS avg_revenue_per_customer,
    SUM(purchase_price) / COUNT(order_id) AS avg_order_value,
    COUNT(order_id) / COUNT(DISTINCT customer_id) AS avg_transactions_per_customer
FROM retail_sales 
WHERE CAST(customer_signup_year AS INT) > 2018
GROUP BY customer_signup_year, customer_loyalty_program;

-- Q: Overall loyalty program performance metrics
SELECT
    customer_loyalty_program,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    AVG(purchase_price) AS avg_order_value,
    SUM(purchase_price) / COUNT(DISTINCT customer_id) AS avg_customer_value,
    COUNT(order_id) / COUNT(DISTINCT customer_id) AS purchase_frequency
FROM retail_sales
GROUP BY customer_loyalty_program
ORDER BY total_customers DESC;

-- =============================================================================
-- 6. PRODUCT CATEGORY PERFORMANCE ANALYSIS
-- =============================================================================

-- Q: Top-performing product categories with revenue share analysis
SELECT
    product_category,
    ROUND(SUM(purchase_price), 2) as total_revenue,
    ROUND(AVG(purchase_price), 2) as avg_order_value,
    COUNT(order_id) as total_orders,
    ROUND(SUM(purchase_price) / (SELECT SUM(purchase_price) FROM retail_sales) * 100, 2) as share_total_revenue,
    AVG(purchase_price) - (SELECT AVG(purchase_price) FROM retail_sales) as aov_vs_aov_overall 
FROM retail_sales
GROUP BY product_category
ORDER BY total_revenue DESC
LIMIT 10;

-- Q: Product category performance by year
SELECT 
    product_category,
    purchase_year,
    SUM(purchase_price) AS total_revenue,
    COUNT(order_id) AS total_orders
FROM retail_sales
GROUP BY product_category, purchase_year;

-- Q: Product subcategory demand trends over time
SELECT
    product_subcategory,
    strftime('%Y', purchase_ts) AS year,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(purchase_price), 2) AS total_revenue
FROM retail_sales
GROUP BY product_subcategory, year;

-- Q: Basic product category analysis
SELECT
    product_category,
    COUNT(order_id) AS total_orders,
    SUM(purchase_price) AS total_revenue,
    AVG(purchase_price) AS avg_order_value
FROM retail_sales
GROUP BY product_category
ORDER BY total_revenue DESC;

-- =============================================================================
-- 7. REGIONAL & GEOGRAPHIC ANALYSIS
-- =============================================================================

-- Q: Regional sales performance over time
SELECT
    customer_region,
    purchase_year,
    SUM(purchase_price) AS total_revenue,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(purchase_price), 2) AS average_order_value
FROM retail_sales
GROUP BY customer_region, purchase_year;

-- Q: Country-level performance metrics
SELECT
    customer_country_code,
    SUM(purchase_price) as total_revenue,
    SUM(purchase_price) / COUNT(order_id) AS avg_order_value,
    SUM(purchase_price) / COUNT(DISTINCT customer_id) AS avg_customer_value
FROM retail_sales
GROUP BY customer_country_code
ORDER BY total_revenue DESC;

-- Q: Country performance with order volume analysis
SELECT
    customer_country_code,
    SUM(order_id) AS total_orders,
    SUM(purchase_price) as total_revenue,
    SUM(purchase_price) / COUNT(order_id) AS avg_order_value,
    SUM(purchase_price) / COUNT(DISTINCT customer_id) AS avg_customer_value
FROM retail_sales
GROUP BY customer_country_code
ORDER BY avg_order_value DESC;

-- Q: Revenue trends in Asia region by country
SELECT
    customer_country_code,
    purchase_year,
    ROUND(SUM(purchase_price), 2) AS total_revenue
FROM retail_sales
WHERE customer_region = 'Asia'
GROUP BY customer_region, customer_country_code, purchase_year
ORDER BY purchase_year;

-- Q: Regional revenue with detailed country breakdown
SELECT
    customer_country_code,
    customer_region,
    purchase_year,
    ROUND(SUM(purchase_price), 2) AS total_revenue,
    ROUND(AVG(purchase_price), 2) AS average_order_value,
    ROUND(SUM(purchase_price)/COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM retail_sales
GROUP BY customer_region, customer_country_code, purchase_year
ORDER BY purchase_year;

-- =============================================================================
-- 8. COUNTRY-SPECIFIC DEEP DIVE ANALYSIS
-- =============================================================================

-- Q: Australia market performance analysis
SELECT
    customer_country_code,
    SUM(purchase_price) as total_revenue,
    COUNT(DISTINCT customer_id) AS total_customers
FROM retail_sales
WHERE customer_country_code = 'AU'
GROUP BY customer_country_code;

-- Q: Australia revenue trends by year
SELECT
    purchase_year,
    customer_country_code,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
WHERE customer_country_code = 'AU'
GROUP BY customer_country_code, purchase_year;

-- Q: Australia top product categories
SELECT
    customer_country_code,
    product_category,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
WHERE customer_country_code = 'AU'
GROUP BY customer_country_code, product_category
ORDER BY total_revenue DESC;

-- Q: India market performance by year
SELECT
    purchase_year,
    customer_country_code,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
WHERE customer_country_code = 'IN'
GROUP BY customer_country_code, purchase_year;

-- Q: US market revenue trends
SELECT
    purchase_year,
    customer_country_code,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
WHERE customer_country_code = 'US'
GROUP BY customer_country_code, purchase_year;

-- Q: Country-level customer and revenue analysis
SELECT
    purchase_year,
    customer_country_code,
    SUM(purchase_price) AS total_revenue,
    COUNT(DISTINCT customer_id) as total_customers
FROM retail_sales
GROUP BY customer_country_code, purchase_year;

-- =============================================================================
-- 9. YEAR-OVER-YEAR GROWTH ANALYSIS
-- =============================================================================

-- Q: Year-over-year revenue growth by country using window functions
SELECT
    purchase_year,
    customer_country_code,
    ROUND(SUM(purchase_price), 2) AS total_revenue,
    CASE 
        WHEN purchase_year = 2019 THEN NULL  -- No YOY growth for baseline year
        ELSE ROUND(
            (SUM(purchase_price) - LAG(SUM(purchase_price)) OVER (
                PARTITION BY customer_country_code 
                ORDER BY purchase_year
            )) / LAG(SUM(purchase_price)) OVER (
                PARTITION BY customer_country_code 
                ORDER BY purchase_year
            ) * 100, 2
        )
    END AS yoy_growth_pct
FROM retail_sales
GROUP BY purchase_year, customer_country_code
ORDER BY customer_country_code, purchase_year;

-- Q: Revenue baseline check for YoY calculations
SELECT 
    purchase_year,
    customer_country_code,
    ROUND(SUM(purchase_price), 2) AS total_revenue
FROM retail_sales
WHERE purchase_year IN (2018, 2019, 2020)  -- Check if 2018 data exists
GROUP BY purchase_year, customer_country_code
ORDER BY purchase_year, customer_country_code;

-- =============================================================================
-- 10. ADVANCED ANALYTICS & BUSINESS INTELLIGENCE
-- =============================================================================

-- Q: Revenue & AOV by loyalty program and signup year
SELECT 
    customer_loyalty_program, 
    customer_signup_year,
    SUM(purchase_price) / COUNT(order_id) AS avg_order_value,
    COUNT(order_id) / COUNT(DISTINCT customer_id) AS avg_transactions_per_customer,
    ROUND(SUM(purchase_price)/COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM retail_sales 
WHERE CAST(customer_signup_year AS INT) > 2018
GROUP BY customer_loyalty_program, customer_signup_year;

-- Q: Gaming Console performance by region (2022-2023)
SELECT 
    customer_region,
    purchase_year,
    SUM(purchase_price) AS total_revenue
FROM retail_sales
WHERE purchase_year IN ('2022', '2023') AND product_category = 'Gaming Console'
GROUP BY customer_region, purchase_year;

-- Q: Quarterly sales with date truncation (SQLite specific)
SELECT 
    date_trunc(purchase_ts, quarter) as purchase_quarter,
    count(order_id) as order_count,
    round(sum(purchase_price), 2) as total_sales,
    round(avg(purchase_price), 2) as aov
FROM retail_sales;

-- =============================================================================
-- 11. DATA VALIDATION & QUALITY CHECKS
-- =============================================================================

-- Q: Verify data integrity - check for orphaned records
SELECT * FROM retail_sales
WHERE customer_id IS NULL OR product_id IS NULL OR order_id IS NULL;

-- Q: Check for duplicate orders
SELECT order_id, COUNT(*) as duplicate_count
FROM retail_sales
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Q: Validate date ranges and temporal consistency
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN purchase_ts < customer_created_on THEN 1 END) as invalid_dates
FROM retail_sales;
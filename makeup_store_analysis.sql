USE makeup_store;
GO

/* =========================================================
   Makeup Store Sales Analysis
   Tools: SQL Server / T-SQL
   Purpose: Data validation and sales analysis for Power BI
   ========================================================= */

/* =========================================================
   1. DATA VALIDATION
   These checks should return NO ROWS when the data is valid.
   ========================================================= */

-- Orders without order items
SELECT o.order_id
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- Order items with a product that does not exist
SELECT oi.*
FROM order_items AS oi
LEFT JOIN products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Invalid quantity, price, or discount values
SELECT *
FROM order_items
WHERE quantity <= 0
   OR list_price <= 0
   OR discount < 0
   OR discount > 100;

-- Orders with a customer that does not exist
SELECT o.*
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* =========================================================
   2. TOTAL SALES
   Sales are calculated after applying the discount.
   ========================================================= */

SELECT
    SUM(
        quantity * list_price * (1 - discount / 100.0)
    ) AS total_sales
FROM order_items;

/* =========================================================
   3. SALES KPIs
   Total Orders, Total Sales, and Average Order Value (AOV)
   ========================================================= */

SELECT
    COUNT(*) AS total_orders,
    SUM(order_total) AS total_sales,
    AVG(order_total) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(
            quantity * list_price * (1 - discount / 100.0)
        ) AS order_total
    FROM order_items
    GROUP BY order_id
) AS order_summary;

/* =========================================================
   4. TOP 5 PRODUCTS BY REVENUE
   ========================================================= */

SELECT TOP 5
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY total_sales DESC;

/* =========================================================
   5. TOP 5 BRANDS BY REVENUE
   ========================================================= */

SELECT TOP 5
    b.brand_id,
    b.brand_name,
    SUM(oi.quantity) AS units_sold,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN brands AS b
    ON p.brand_id = b.brand_id
GROUP BY
    b.brand_id,
    b.brand_name
ORDER BY total_sales DESC;

/* =========================================================
   6. SALES BY CATEGORY
   ========================================================= */

SELECT
    c.category_id,
    c.category_name,
    SUM(oi.quantity) AS units_sold,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN categories AS c
    ON p.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY total_sales DESC;

/* =========================================================
   7. SALES BY CITY
   ========================================================= */

SELECT
    c.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY total_sales DESC;

/* =========================================================
   8. DAILY SALES
   Used for the Power BI Daily Sales line chart.
   ========================================================= */

SELECT
    CAST(o.order_date AS date) AS sales_date,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM orders AS o
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY CAST(o.order_date AS date)
ORDER BY sales_date;

/* =========================================================
   9. MONTHLY SALES
   Note: The current sample data contains one month only.
   ========================================================= */

SELECT
    YEAR(o.order_date) AS sales_year,
    MONTH(o.order_date) AS sales_month,
    SUM(
        oi.quantity * oi.list_price * (1 - oi.discount / 100.0)
    ) AS total_sales
FROM orders AS o
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date)
ORDER BY
    sales_year,
    sales_month;

/* =========================================================
   10. PRICE REVIEW
   Identifies products where the historical sold/list price
   differs from the current product price.
   ========================================================= */

SELECT
    oi.order_id,
    oi.product_id,
    p.product_name,
    p.product_price AS current_product_price,
    oi.list_price AS sold_list_price,
    oi.quantity,
    oi.discount
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
WHERE oi.list_price <> p.product_price
ORDER BY oi.product_id;

/* =========================================================
   END OF ANALYSIS
   ========================================================= */

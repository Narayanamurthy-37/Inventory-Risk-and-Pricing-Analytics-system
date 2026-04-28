use Inventory

/* =========================================================
   INVENTORY RISK & PRICING ANALYTICS
   SILVER LAYER – DATA TRANSFORMATION & LOADING
   ========================================================= */

------------------------------------------------------------
-- PRODUCTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.products;
GO

SELECT DISTINCT
    product_id,
    TRIM(product_name) AS product_name,
    ISNULL(purchase_price, 0) AS purchase_price,
    ISNULL(sell_price, 0) AS sell_price,
    category,
    ISNULL(base_price, sell_price) AS base_price,
    UPPER(ISNULL(status, 'ACTIVE')) AS status,
    supplier_id,
    (ISNULL(sell_price,0) - ISNULL(purchase_price,0)) AS unit_margin,
    CASE 
        WHEN ISNULL(sell_price,0) = 0 THEN 0
        ELSE 
            (ISNULL(sell_price,0) - ISNULL(purchase_price,0)) 
            / ISNULL(sell_price,0) * 100
    END AS margin_percentage
INTO silver.products
FROM raw.products;
GO

------------------------------------------------------------
-- SUPPLIERS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.suppliers;
GO

SELECT
    supplier_id,
    TRIM(supplier_name) AS supplier_name,
    CASE 
        WHEN lead_time_days <= 0 THEN 1
        ELSE lead_time_days
    END AS lead_time_days,
    reliability_flag
INTO silver.suppliers
FROM raw.suppliers;
GO

------------------------------------------------------------
-- INVENTORY TRANSACTIONS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.inventory_transactions;
GO

SELECT
    product_id,
    warehouse_id,
    transaction_date,
    time_slot,
    ISNULL(inflow_qty, 0) AS inflow_qty,
    ISNULL(outflow_qty, 0) AS outflow_qty,
    ISNULL(unit_cost, 0) AS unit_cost,
    ISNULL(unit_price, 0) AS unit_price,
    ISNULL(outflow_qty,0) * ISNULL(unit_price,0) AS revenue,
    ISNULL(outflow_qty,0) * ISNULL(unit_cost,0) AS cost,
    (ISNULL(outflow_qty,0) * ISNULL(unit_price,0))
      - (ISNULL(outflow_qty,0) * ISNULL(unit_cost,0)) AS gross_profit,
    source_system
INTO silver.inventory_transactions
FROM raw.inventory_transactions;
GO

------------------------------------------------------------
-- DISCOUNTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.discounts;
GO

SELECT
    product_id,
    CASE 
        WHEN discount_pct < 0 THEN 0
        WHEN discount_pct > 90 THEN 90
        ELSE discount_pct
    END AS discount_pct,
    discount_start_date,
    discount_end_date,
    DATEDIFF(DAY, discount_start_date, discount_end_date) AS discount_duration_days
INTO silver.discounts
FROM raw.discounts;
GO

------------------------------------------------------------
-- DATE DIMENSION TABLE (ENRICHED)
------------------------------------------------------------
DROP TABLE IF EXISTS silver.date_dim;
GO

SELECT
    date_value,
    day_of_week,
    is_weekend,
    DATENAME(MONTH, date_value) AS month_name,
    YEAR(date_value) AS year,
    MONTH(date_value) AS month_number,
    is_festival,
    festival_name
INTO silver.date_dim
FROM raw.date_dim;
GO

----------------------------------------------------------------------------------

------------------------------------------------------------
-- VALIDATION QUERIES
------------------------------------------------------------

SELECT * FROM silver.products;

SELECT * FROM silver.suppliers;

SELECT * FROM silver.inventory_transactions;

SELECT * FROM silver.discounts;

SELECT * FROM silver.date_dim;

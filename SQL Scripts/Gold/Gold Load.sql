USE Inventory;
GO

/* =========================================================
   CREATE GOLD SCHEMA
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO


/* =========================================================
   DROP TABLES
   ========================================================= */
DROP TABLE IF EXISTS gold.fact_inventory_daily;
DROP TABLE IF EXISTS gold.dim_time;
DROP TABLE IF EXISTS gold.dim_product;
DROP TABLE IF EXISTS gold.dim_supplier;
DROP TABLE IF EXISTS gold.dim_date;
GO


/* =========================================================
   DIM_SUPPLIER
   ========================================================= */
CREATE TABLE gold.dim_supplier (
    supplier_key INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id NVARCHAR(50),
    supplier_name NVARCHAR(200),
    lead_time_days INT,
    reliability_flag NVARCHAR(50)
);
GO


/* =========================================================
   DIM_PRODUCT
   ========================================================= */
CREATE TABLE gold.dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id NVARCHAR(50),
    product_name NVARCHAR(200),
    category NVARCHAR(100),
    status NVARCHAR(50),
    purchase_price DECIMAL(10,2),
    sell_price DECIMAL(10,2),
    unit_margin DECIMAL(10,2),
    margin_percentage DECIMAL(5,2),
    supplier_key INT,

    FOREIGN KEY (supplier_key)
    REFERENCES gold.dim_supplier(supplier_key)
);
GO


/* =========================================================
   DIM_DATE
   ========================================================= */
CREATE TABLE gold.dim_date (
    date_key INT PRIMARY KEY,
    date_value DATE,
    year INT,
    month_number INT,
    month_name NVARCHAR(20),
    day_of_week NVARCHAR(20),
    is_weekend NVARCHAR(10),
    is_festival NVARCHAR(10),
    festival_name NVARCHAR(200)
);
GO


/* =========================================================
   DIM_TIME
   ========================================================= */
CREATE TABLE gold.dim_time (
    time_key INT IDENTITY(1,1) PRIMARY KEY,
    time_slot NVARCHAR(50)
);
GO


/* =========================================================
   FACT TABLE
   ========================================================= */
CREATE TABLE gold.fact_inventory_daily (
    product_key INT,
    supplier_key INT,
    date_key INT,
    time_key INT,
    warehouse_id NVARCHAR(50),

    inflow_qty INT,
    outflow_qty INT,
    revenue DECIMAL(18,2),
    cost DECIMAL(18,2),
    gross_profit DECIMAL(18,2),

    discount_pct DECIMAL(5,2),
    discount_start_date DATE,
    discount_end_date DATE,
    discount_duration_days INT,

    FOREIGN KEY (product_key) REFERENCES gold.dim_product(product_key),
    FOREIGN KEY (supplier_key) REFERENCES gold.dim_supplier(supplier_key),
    FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key),
    FOREIGN KEY (time_key) REFERENCES gold.dim_time(time_key)
);
GO


/* =========================================================
   LOAD DIM_SUPPLIER
   ========================================================= */
INSERT INTO gold.dim_supplier
SELECT DISTINCT
    supplier_id,
    supplier_name,
    lead_time_days,
    reliability_flag
FROM silver.suppliers;
GO


/* =========================================================
   LOAD DIM_PRODUCT
   ========================================================= */
INSERT INTO gold.dim_product
(
 product_id, product_name, category, status,
 purchase_price, sell_price, unit_margin,
 margin_percentage, supplier_key
)
SELECT DISTINCT
    p.product_id,
    p.product_name,
    p.category,
    p.status,
    p.purchase_price,
    p.sell_price,
    p.unit_margin,
    p.margin_percentage,
    s.supplier_key
FROM silver.products p
JOIN gold.dim_supplier s
ON p.supplier_id = s.supplier_id;
GO


/* =========================================================
   LOAD DIM_DATE
   ========================================================= */
INSERT INTO gold.dim_date
SELECT DISTINCT
    YEAR(date_value)*10000 + MONTH(date_value)*100 + DAY(date_value),
    date_value,
    year,
    month_number,
    month_name,
    day_of_week,
    is_weekend,
    is_festival,
    festival_name
FROM silver.date_dim;
GO


/* =========================================================
   LOAD DIM_TIME
   ========================================================= */
INSERT INTO gold.dim_time(time_slot)
SELECT DISTINCT time_slot
FROM silver.inventory_transactions;
GO


/* =========================================================
   LOAD FACT TABLE (FIXED)
   ========================================================= */
INSERT INTO gold.fact_inventory_daily
(
 product_key, supplier_key, date_key, time_key,
 warehouse_id, inflow_qty, outflow_qty,
 revenue, cost, gross_profit,
 discount_pct, discount_start_date,
 discount_end_date, discount_duration_days
)
SELECT
    dp.product_key,
    dp.supplier_key,
    dd.date_key,
    dt.time_key,
    t.warehouse_id,

    t.inflow_qty,
    t.outflow_qty,
    t.revenue,
    t.cost,
    t.gross_profit,

    ISNULL(d.discount_pct,0),
    d.discount_start_date,
    d.discount_end_date,
    d.discount_duration_days

FROM silver.inventory_transactions t

JOIN gold.dim_product dp
    ON t.product_id = dp.product_id

JOIN gold.dim_date dd
    ON t.transaction_date = dd.date_value

JOIN gold.dim_time dt
    ON t.time_slot = dt.time_slot

LEFT JOIN silver.discounts d
    ON t.product_id = d.product_id
    AND t.transaction_date 
        BETWEEN d.discount_start_date AND d.discount_end_date;
GO


PRINT 'GOLD LAYER LOADED SUCCESSFULLY';
GO


/* =========================================================
   VALIDATION
   ========================================================= */

SELECT COUNT(*) AS silver_transactions
FROM silver.inventory_transactions;

SELECT COUNT(*) AS gold_fact_rows
FROM gold.fact_inventory_daily;

SELECT COUNT(*) AS dim_products FROM gold.dim_product;
SELECT COUNT(*) AS dim_suppliers FROM gold.dim_supplier;
SELECT COUNT(*) AS dim_dates FROM gold.dim_date;
SELECT COUNT(*) AS dim_times FROM gold.dim_time;
GO
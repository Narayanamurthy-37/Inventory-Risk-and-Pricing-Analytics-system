USE Inventory;
GO

/* =========================================================
   CREATE GOLD SCHEMA
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC ('CREATE SCHEMA gold');
GO

/* =========================================================
   DROP TABLES (FACT FIRST → THEN DIMENSIONS)
   ========================================================= */
DROP TABLE IF EXISTS gold.fact_inventory_daily;
DROP TABLE IF EXISTS gold.dim_time;
DROP TABLE IF EXISTS gold.dim_product;
DROP TABLE IF EXISTS gold.dim_supplier;
DROP TABLE IF EXISTS gold.dim_date;
GO

/* =========================================================
   CREATE DIMENSION TABLES
   ========================================================= */

------------------------------------------------------------
-- DIM_SUPPLIER
------------------------------------------------------------
CREATE TABLE gold.dim_supplier (
    supplier_key      INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id       NVARCHAR(50)  NOT NULL,
    supplier_name     NVARCHAR(200) NOT NULL,
    lead_time_days    INT           NOT NULL,
    reliability_flag  NVARCHAR(50)  NOT NULL
);

------------------------------------------------------------
-- DIM_PRODUCT
------------------------------------------------------------
CREATE TABLE gold.dim_product (
    product_key        INT IDENTITY(1,1) PRIMARY KEY,
    product_id         NVARCHAR(50)  NOT NULL,
    product_name       NVARCHAR(200) NOT NULL,
    category           NVARCHAR(100) NOT NULL,
    status             NVARCHAR(50)  NOT NULL,
    purchase_price     DECIMAL(10,2) NOT NULL,
    sell_price         DECIMAL(10,2) NOT NULL,
    unit_margin        DECIMAL(10,2) NOT NULL,
    margin_percentage  DECIMAL(5,2)  NOT NULL,
    supplier_key       INT           NOT NULL,

    CONSTRAINT FK_dim_product_supplier
        FOREIGN KEY (supplier_key)
        REFERENCES gold.dim_supplier(supplier_key)
);

------------------------------------------------------------
-- DIM_DATE (WITH FESTIVAL INFO)
------------------------------------------------------------
CREATE TABLE gold.dim_date (
    date_key       INT PRIMARY KEY,
    date_value     DATE          NOT NULL,
    year           INT           NOT NULL,
    month_number   INT           NOT NULL,
    month_name     NVARCHAR(20)  NOT NULL,
    day_of_week    NVARCHAR(20)  NOT NULL,
    is_weekend     NVARCHAR(10)  NOT NULL,
    is_festival    NVARCHAR(10)  NOT NULL,
    festival_name  NVARCHAR(200) NULL
);

------------------------------------------------------------
-- DIM_TIME (NEW)
------------------------------------------------------------
CREATE TABLE gold.dim_time (
    time_key   INT IDENTITY(1,1) PRIMARY KEY,
    time_slot  NVARCHAR(50) NOT NULL
);

/* =========================================================
   CREATE FACT TABLE
   ========================================================= */
CREATE TABLE gold.fact_inventory_daily (
    product_key   INT           NOT NULL,
    supplier_key  INT           NOT NULL,
    date_key      INT           NOT NULL,
    time_key      INT           NOT NULL,
    warehouse_id  NVARCHAR(50)  NOT NULL,

    inflow_qty    INT           NOT NULL,
    outflow_qty   INT           NOT NULL,
    revenue       DECIMAL(18,2) NOT NULL,
    cost          DECIMAL(18,2) NOT NULL,
    gross_profit  DECIMAL(18,2) NOT NULL,
    discount_pct  DECIMAL(5,2)  NOT NULL,

    CONSTRAINT FK_fact_product
        FOREIGN KEY (product_key)
        REFERENCES gold.dim_product(product_key),

    CONSTRAINT FK_fact_supplier
        FOREIGN KEY (supplier_key)
        REFERENCES gold.dim_supplier(supplier_key),

    CONSTRAINT FK_fact_date
        FOREIGN KEY (date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_time
        FOREIGN KEY (time_key)
        REFERENCES gold.dim_time(time_key)
);
GO

/* =========================================================
   LOAD DIMENSIONS FROM SILVER
   ========================================================= */

------------------------------------------------------------
-- LOAD SUPPLIERS
------------------------------------------------------------
INSERT INTO gold.dim_supplier (
    supplier_id, supplier_name, lead_time_days, reliability_flag
)
SELECT
    supplier_id,
    supplier_name,
    lead_time_days,
    reliability_flag
FROM silver.suppliers;

------------------------------------------------------------
-- LOAD PRODUCTS
------------------------------------------------------------
INSERT INTO gold.dim_product (
    product_id, product_name, category, status,
    purchase_price, sell_price, unit_margin,
    margin_percentage, supplier_key
)
SELECT
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

------------------------------------------------------------
-- LOAD DATE DIMENSION
------------------------------------------------------------
INSERT INTO gold.dim_date (
    date_key, date_value, year, month_number, month_name,
    day_of_week, is_weekend, is_festival, festival_name
)
SELECT
    CONVERT(INT, FORMAT(date_value,'yyyyMMdd')),
    date_value,
    year,
    month_number,
    month_name,
    day_of_week,
    is_weekend,
    is_festival,
    festival_name
FROM silver.date_dim;

------------------------------------------------------------
-- LOAD TIME DIMENSION
------------------------------------------------------------
INSERT INTO gold.dim_time (time_slot)
SELECT DISTINCT time_slot
FROM silver.inventory_transactions;

/* =========================================================
   LOAD FACT TABLE
   ========================================================= */
INSERT INTO gold.fact_inventory_daily (
    product_key, supplier_key, date_key, time_key,
    warehouse_id, inflow_qty, outflow_qty,
    revenue, cost, gross_profit, discount_pct
)
SELECT
    dp.product_key,
    ds.supplier_key,
    dd.date_key,
    dt.time_key,
    s.warehouse_id,
    s.inflow_qty,
    s.outflow_qty,
    s.revenue,
    s.cost,
    s.gross_profit,
    ISNULL(d.discount_pct,0)
FROM silver.inventory_transactions s

JOIN gold.dim_product dp
    ON s.product_id = dp.product_id

JOIN gold.dim_supplier ds
    ON dp.supplier_key = ds.supplier_key

JOIN gold.dim_date dd
    ON s.transaction_date = dd.date_value

JOIN gold.dim_time dt
    ON s.time_slot = dt.time_slot

LEFT JOIN silver.discounts d
    ON s.product_id = d.product_id;

PRINT 'GOLD LAYER STAR SCHEMA CREATED & LOADED SUCCESSFULLY';
GO
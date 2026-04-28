CREATE SCHEMA Silver
GO

/* =========================================================
   INVENTORY RISK & PRICING ANALYTICS
   SILVER LAYER – CLEANED & ENRICHED TABLE STRUCTURE
   ========================================================= */

------------------------------------------------------------
-- PRODUCTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.products;
GO

CREATE TABLE silver.products (
    product_id         NVARCHAR(50)  NOT NULL,
    product_name       NVARCHAR(200) NOT NULL,
    purchase_price     DECIMAL(10,2) NOT NULL,
    sell_price         DECIMAL(10,2) NOT NULL,
    category           NVARCHAR(100) NOT NULL,
    base_price         DECIMAL(10,2) NOT NULL,
    status             NVARCHAR(50)  NOT NULL,
    supplier_id        NVARCHAR(50)  NOT NULL,
    unit_margin        DECIMAL(10,2) NOT NULL,
    margin_percentage  DECIMAL(5,2)  NOT NULL
);
GO

------------------------------------------------------------
-- SUPPLIERS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.suppliers;
GO

CREATE TABLE silver.suppliers (
    supplier_id       NVARCHAR(50)  NOT NULL,
    supplier_name     NVARCHAR(200) NOT NULL,
    lead_time_days    INT           NOT NULL,
    reliability_flag  NVARCHAR(50)  NOT NULL
);
GO

------------------------------------------------------------
-- INVENTORY TRANSACTIONS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.inventory_transactions;
GO

CREATE TABLE silver.inventory_transactions (
    product_id        NVARCHAR(50)  NOT NULL,
    warehouse_id      NVARCHAR(50)  NOT NULL,
    transaction_date  DATE          NOT NULL,
    time_slot         NVARCHAR(50) NOT NULL,
    inflow_qty        INT           NOT NULL,
    outflow_qty       INT           NOT NULL,
    unit_cost         DECIMAL(10,2) NOT NULL,
    unit_price        DECIMAL(10,2) NOT NULL,
    revenue           DECIMAL(18,2) NOT NULL,
    cost              DECIMAL(18,2) NOT NULL,
    gross_profit      DECIMAL(18,2) NOT NULL,
    source_system     NVARCHAR(50)  NULL
);
GO

------------------------------------------------------------
-- DISCOUNTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS silver.discounts;
GO

CREATE TABLE silver.discounts (
    product_id              NVARCHAR(50)  NOT NULL,
    discount_pct            DECIMAL(5,2)  NOT NULL,
    discount_start_date     DATE          NOT NULL,
    discount_end_date       DATE          NOT NULL,
    discount_duration_days  INT           NOT NULL
);
GO

------------------------------------------------------------
-- DATE DIMENSION TABLE (ENRICHED)
------------------------------------------------------------
DROP TABLE IF EXISTS silver.date_dim;
GO

CREATE TABLE silver.date_dim (
    date_value     DATE          NOT NULL,
    day_of_week    NVARCHAR(20)  NOT NULL,
    is_weekend     NVARCHAR(10)  NOT NULL,
    month_name     NVARCHAR(20)  NOT NULL,
    year           INT           NOT NULL,
    month_number   INT           NOT NULL,
    is_festival     NVARCHAR(10) NOT NULL,
    festival_name   NVARCHAR(50)
);
GO

PRINT 'SILVER LAYER SETUP COMPLETED SUCCESSFULLY';


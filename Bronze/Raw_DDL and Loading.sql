/* =========================================================
   INVENTORY RISK & PRICING ANALYTICS
   RAW LAYER – COMPLETE SETUP SCRIPT
   ========================================================= */

------------------------------------------------------------
-- DATABASE
------------------------------------------------------------
IF DB_ID('Inventory') IS NULL
    CREATE DATABASE Inventory;
GO

USE Inventory;
GO

------------------------------------------------------------
-- SCHEMA
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC ('CREATE SCHEMA raw');
GO

------------------------------------------------------------
-- PRODUCTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS raw.products;
GO

CREATE TABLE raw.products (
    product_id       NVARCHAR(50)  NOT NULL,
    product_name     NVARCHAR(200) NOT NULL,
    purchase_price   DECIMAL(10,2) NOT NULL,
    sell_price       DECIMAL(10,2) NOT NULL,
    category         NVARCHAR(100) NOT NULL,
    base_price       DECIMAL(10,2) NULL,
    status           NVARCHAR(50)  NULL,
    supplier_id      NVARCHAR(50)  NOT NULL
);
GO

------------------------------------------------------------
-- SUPPLIERS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS raw.suppliers;
GO

CREATE TABLE raw.suppliers (
    supplier_id        NVARCHAR(50)  NOT NULL,
    supplier_name      NVARCHAR(200) NOT NULL,
    lead_time_days     INT           NOT NULL,
    reliability_flag   INT
);
GO

------------------------------------------------------------
-- INVENTORY TRANSACTIONS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS raw.inventory_transactions;
GO

CREATE TABLE raw.inventory_transactions (
    product_id        NVARCHAR(50) NOT NULL,
    warehouse_id      NVARCHAR(50) NOT NULL,
    transaction_date  DATE         NOT NULL,
    time_slot         NVARCHAR(50) NOT NULL,
    inflow_qty        INT          NULL,
    outflow_qty       INT          NULL,
    unit_cost         DECIMAL(10,2) NULL,
    unit_price        DECIMAL(10,2) NULL,
    source_system     NVARCHAR(50) NULL
);
GO

------------------------------------------------------------
-- DISCOUNTS TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS raw.discounts;
GO

CREATE TABLE raw.discounts (
    product_id            NVARCHAR(50) NOT NULL,
    discount_pct          DECIMAL(5,2) NOT NULL,
    discount_start_date   DATE         NOT NULL,
    discount_end_date     DATE         NOT NULL
);
GO

------------------------------------------------------------
-- DATE DIMENSION TABLE (RAW VERSION)
------------------------------------------------------------
DROP TABLE IF EXISTS raw.date_dim;
GO

CREATE TABLE raw.date_dim (
    date_value     DATE         NOT NULL,
    day_of_week    NVARCHAR(20) NOT NULL,
    is_weekend     NVARCHAR(10) NOT NULL,
    is_festival     NVARCHAR(10) NOT NULL,
    festival_name   NVARCHAR(50)
);
GO

PRINT 'RAW LAYER SETUP COMPLETED SUCCESSFULLY';

----------------------------------------------------------------------------------------------

GO   -- This separates previous batch (VERY IMPORTANT)

CREATE OR ALTER PROCEDURE raw.load_raw
AS
BEGIN
    BEGIN TRY
        PRINT 'RAW LOAD STARTED';

        ----------------------------------------------------
        -- PRODUCTS
        ----------------------------------------------------
        TRUNCATE TABLE raw.products;
        BULK INSERT raw.products
        FROM 'C:\Users\SJC-Library\Desktop\Datasets\DW\Iventory\New folder\Inv 2\products_bronze.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIELDQUOTE = '"',
            CODEPAGE = '65001'
        );

        ----------------------------------------------------
        -- SUPPLIERS
        ----------------------------------------------------
        TRUNCATE TABLE raw.suppliers;
        BULK INSERT raw.suppliers
        FROM 'C:\Users\SJC-Library\Desktop\Datasets\DW\Iventory\New folder\Inv 2\suppliers_bronze.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIELDQUOTE = '"',
            CODEPAGE = '65001'
        );

        ----------------------------------------------------
        -- INVENTORY TRANSACTIONS
        ----------------------------------------------------
        TRUNCATE TABLE raw.inventory_transactions;
        BULK INSERT raw.inventory_transactions
        FROM 'C:\Users\SJC-Library\Desktop\Datasets\DW\Iventory\New folder\Inv 2\inventory_transactions_2025.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIELDQUOTE = '"',
            CODEPAGE = '65001'
        );

        ----------------------------------------------------
        -- DISCOUNTS
        ----------------------------------------------------
        TRUNCATE TABLE raw.discounts;
        BULK INSERT raw.discounts
        FROM 'C:\Users\SJC-Library\Desktop\Datasets\DW\Iventory\New folder\Inv 2\discounts_bronze.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIELDQUOTE = '"',
            CODEPAGE = '65001'
        );

        ----------------------------------------------------
        -- DATE DIMENSION
        ----------------------------------------------------
        TRUNCATE TABLE raw.date_dim;
        BULK INSERT raw.date_dim
        FROM 'C:\Users\SJC-Library\Desktop\Datasets\DW\Iventory\New folder\Inv 2\date_dim.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIELDQUOTE = '"',
            CODEPAGE = '65001'
        );

        PRINT 'RAW LOAD COMPLETED SUCCESSFULLY';
    END TRY
    BEGIN CATCH
        PRINT 'RAW LOAD FAILED';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO

EXEC raw.load_raw;

---------------------------------------------------------------------
------------------------------------------------------------
-- RAW LAYER VALIDATION QUERIES
------------------------------------------------------------

SELECT * FROM raw.products;

SELECT * FROM raw.suppliers;

SELECT * FROM raw.inventory_transactions;

SELECT * FROM raw.discounts;

SELECT * FROM raw.date_dim;


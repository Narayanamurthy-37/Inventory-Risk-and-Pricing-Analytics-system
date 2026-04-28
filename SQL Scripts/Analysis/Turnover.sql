USE Inventory;
GO

CREATE VIEW gold.v_monthly_turnover AS

WITH base_running AS
(
    SELECT
        f.product_key,
        dp.product_name,
        d.year,
        d.month_number,
        d.month_name,
        f.date_key,
        f.outflow_qty,
        f.inflow_qty,

        SUM(f.inflow_qty - f.outflow_qty)
            OVER (PARTITION BY f.product_key
                  ORDER BY f.date_key
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS raw_running_stock

    FROM gold.fact_inventory_daily f
    JOIN gold.dim_product dp
        ON f.product_key = dp.product_key
    JOIN gold.dim_date d
        ON f.date_key = d.date_key
),

opening_stock_calc AS
(
    SELECT
        product_key,
        CASE
            WHEN MIN(raw_running_stock) < 0
                THEN ABS(MIN(raw_running_stock))
            ELSE 0
        END AS opening_stock
    FROM base_running
    GROUP BY product_key
),

adjusted_running AS
(
    SELECT
        b.product_key,
        b.product_name,
        b.year,
        b.month_number,
        b.month_name,
        b.date_key,
        b.outflow_qty,
        b.inflow_qty,
        o.opening_stock,

        b.raw_running_stock + o.opening_stock
            AS adjusted_running_stock

    FROM base_running b
    JOIN opening_stock_calc o
        ON b.product_key = o.product_key
),

monthly_calc AS
(
    SELECT
        product_key,
        product_name,
        year,
        month_number,
        month_name,

        SUM(outflow_qty) AS total_outflow,

        MIN(adjusted_running_stock) AS month_opening_stock,
        MAX(adjusted_running_stock) AS month_closing_stock

    FROM adjusted_running
    GROUP BY
        product_key,
        product_name,
        year,
        month_number,
        month_name
)

SELECT
    product_key,
    product_name,
    year,
    month_number,
    month_name,
    total_outflow,

    month_opening_stock,
    month_closing_stock,

    CAST(
        (month_opening_stock + month_closing_stock) / 2.0
        AS DECIMAL(18,2)
    ) AS avg_inventory,

    CASE
        WHEN (month_opening_stock + month_closing_stock) = 0
            THEN 0
        ELSE CAST(
            total_outflow /
            ((month_opening_stock + month_closing_stock) / 2.0)
            AS DECIMAL(10,2)
        )
    END AS monthly_turnover

FROM monthly_calc;
GO


select * from gold.v_monthly_turnover

SELECT
    SUM(inflow_qty) AS total_inflow,
    SUM(outflow_qty) AS total_outflow
FROM gold.fact_inventory_daily f
JOIN gold.dim_product p ON f.product_key = p.product_key
JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE p.product_name = 'Paneer'
  AND d.year = 2025
  AND d.month_name = 'June';


  USE Inventory;
GO

SELECT * FROM gold.v_monthly_turnover
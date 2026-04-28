USE Inventory;
GO

/* =============================================
   VIEW: Product ABC Classification
   ============================================= */

CREATE VIEW gold.v_abc_product AS

WITH product_revenue AS
(
    SELECT
        dp.product_key,
        dp.product_name,
        SUM(f.revenue) AS total_revenue
    FROM gold.fact_inventory_daily f
    JOIN gold.dim_product dp
        ON f.product_key = dp.product_key
    GROUP BY dp.product_key, dp.product_name
),

ranked_products AS
(
    SELECT
        product_key,
        product_name,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_revenue,
        SUM(total_revenue) OVER () AS grand_total
    FROM product_revenue
)

SELECT
    product_key,
    product_name,
    total_revenue,

    CAST((running_revenue * 100.0 / grand_total) AS DECIMAL(6,2))
        AS cumulative_percentage,

    CASE
        WHEN (running_revenue * 100.0 / grand_total) <= 70 THEN 'A'
        WHEN (running_revenue * 100.0 / grand_total) <= 90 THEN 'B'
        ELSE 'C'
    END AS abc_category

FROM ranked_products;
GO

select * from gold.v_abc_product



USE Inventory;
GO

/* =========================================================
   VIEW: Supplier Performance Scorecard
   Based on Gold Layer Schema
   ========================================================= */

CREATE OR ALTER VIEW gold.v_supplier_performance AS

SELECT
    s.supplier_key,
    s.supplier_id,
    s.supplier_name,
    s.lead_time_days,
    s.reliability_flag,

    COUNT(DISTINCT p.product_key) AS total_products_supplied,

    SUM(f.inflow_qty)  AS total_units_supplied,
    SUM(f.outflow_qty) AS total_units_sold,

    SUM(f.revenue)      AS total_revenue_generated,
    SUM(f.cost)         AS total_cost_incurred,
    SUM(f.gross_profit) AS total_gross_profit,

    CAST(
        SUM(f.gross_profit) * 100.0 /
        NULLIF(SUM(f.cost),0)
        AS DECIMAL(10,2)
    ) AS profit_per_rupee_spent_pct,

    AVG(p.margin_percentage) AS avg_product_margin_pct

FROM gold.fact_inventory_daily f
JOIN gold.dim_supplier s
    ON f.supplier_key = s.supplier_key
JOIN gold.dim_product p
    ON f.product_key = p.product_key

GROUP BY
    s.supplier_key,
    s.supplier_id,
    s.supplier_name,
    s.lead_time_days,
    s.reliability_flag;
GO


select * from gold.v_supplier_performance
   select * from gold.v_discount_leakage

   USE Inventory;
GO

/* =========================================================
   VIEW: Discount Leakage Analysis (Correct Lift Logic)
   Compares avg daily promo vs avg daily normal
   ========================================================= */

CREATE OR ALTER VIEW gold.v_discount_leakage AS

WITH daily_sales AS
(
    -- Step 1: Daily aggregation per product
    SELECT
        f.product_key,
        d.date_value,
        SUM(f.outflow_qty) AS daily_units,
        SUM(f.revenue) AS daily_revenue,
        SUM(f.cost) AS daily_cost,
        SUM(f.gross_profit) AS daily_profit,
        MAX(f.discount_pct) AS discount_pct
    FROM gold.fact_inventory_daily f
    JOIN gold.dim_date d
        ON f.date_key = d.date_key
    GROUP BY
        f.product_key,
        d.date_value
),

promo_period AS
(
    -- Step 2: Average daily metrics during promo
    SELECT
        product_key,
        AVG(daily_units) AS avg_daily_units_promo,
        SUM(daily_revenue) AS total_promo_revenue,
        SUM(daily_cost) AS total_promo_cost,
        SUM(daily_profit) AS total_promo_profit,
        MAX(discount_pct) AS discount_pct
    FROM daily_sales
    WHERE discount_pct > 0
    GROUP BY product_key
),

normal_period AS
(
    -- Step 3: Average daily units during non-promo
    SELECT
        product_key,
        AVG(daily_units) AS avg_daily_units_normal
    FROM daily_sales
    WHERE discount_pct = 0
    GROUP BY product_key
)

SELECT
    p.product_key,
    p.product_name,
    p.category,

    pr.discount_pct,

    pr.avg_daily_units_promo,
    np.avg_daily_units_normal,

    CAST(
        pr.avg_daily_units_promo /
        NULLIF(np.avg_daily_units_normal, 0)
        AS DECIMAL(10,2)
    ) AS sales_lift_ratio,

    pr.total_promo_revenue,
    pr.total_promo_cost,
    pr.total_promo_profit,

    CAST(
        pr.total_promo_profit * 100.0 /
        NULLIF(pr.total_promo_cost, 0)
        AS DECIMAL(10,2)
    ) AS promo_profit_margin_pct,

    CASE
        WHEN pr.total_promo_profit < 0
            THEN 'Loss-Making Promo'

        WHEN pr.discount_pct >= 25
             AND (pr.avg_daily_units_promo /
                  NULLIF(np.avg_daily_units_normal,0)) < 1.20
            THEN 'Deep Discount, Weak Lift'

        WHEN p.margin_percentage < 20
             AND pr.discount_pct > 10
            THEN 'Low Margin Product Discounted'

        WHEN (pr.avg_daily_units_promo /
              NULLIF(np.avg_daily_units_normal,0)) >= 1.20
             AND pr.total_promo_profit > 0
            THEN 'Effective Promotion'

        ELSE 'Monitor'
    END AS leakage_flag

FROM promo_period pr
JOIN normal_period np
    ON pr.product_key = np.product_key
JOIN gold.dim_product p
    ON pr.product_key = p.product_key;
GO

USE Inventory;
GO

USE Inventory;
GO

CREATE OR ALTER VIEW gold.v_discount_leakage AS

WITH daily_sales AS
(
    SELECT
        f.product_key,
        d.date_value,
        SUM(f.outflow_qty) AS daily_units,
        MAX(f.discount_pct) AS discount_pct,
        SUM(f.revenue) AS daily_revenue,
        SUM(f.cost) AS daily_cost,
        SUM(f.gross_profit) AS daily_profit
    FROM gold.fact_inventory_daily f
    JOIN gold.dim_date d
        ON f.date_key = d.date_key
    GROUP BY
        f.product_key,
        d.date_value
),

promo_sales AS
(
    SELECT
        ds.product_key,
        COUNT(DISTINCT ds.date_value) AS promo_days,
        SUM(ds.daily_units) AS units_sold_promo,
        SUM(ds.daily_revenue) AS promo_revenue,
        SUM(ds.daily_cost) AS promo_cost,
        SUM(ds.daily_profit) AS promo_profit,
        MAX(ds.discount_pct) AS discount_pct
    FROM daily_sales ds
    WHERE ds.discount_pct > 0
    GROUP BY ds.product_key
),

baseline_sales AS
(
    SELECT
        ds.product_key,
        AVG(ds.daily_units) AS avg_daily_units_normal
    FROM daily_sales ds
    WHERE ds.discount_pct = 0
    GROUP BY ds.product_key
)

SELECT
    p.product_key,
    p.product_name,
    p.category,

    ps.discount_pct,
    ps.units_sold_promo,
    ps.promo_revenue,
    ps.promo_cost,
    ps.promo_profit,

    bs.avg_daily_units_normal,

    CAST(
        (ps.units_sold_promo / NULLIF(ps.promo_days,0)) /
        NULLIF(bs.avg_daily_units_normal,0)
        AS DECIMAL(10,2)
    ) AS sales_lift_ratio,

    CASE
        WHEN ps.promo_profit < 0
            THEN '🔴 Loss-Making Promotion'

        WHEN (ps.units_sold_promo / NULLIF(ps.promo_days,0)) 
             / NULLIF(bs.avg_daily_units_normal,0) < 1.05
            THEN '🟠 Weak Promotion'

        WHEN (ps.units_sold_promo / NULLIF(ps.promo_days,0)) 
             / NULLIF(bs.avg_daily_units_normal,0) BETWEEN 1.05 AND 1.20
            THEN '🟡 Moderate Impact'

        ELSE '🟢 High Impact Promotion'
    END AS promotion_flag

FROM promo_sales ps
JOIN baseline_sales bs
    ON ps.product_key = bs.product_key
JOIN gold.dim_product p
    ON ps.product_key = p.product_key;
GO

select * from gold.v_discount_leakage
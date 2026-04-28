USE Inventory;
GO

/* =========================================================
   SUPPLIER PERFORMANCE ANALYSIS
   ========================================================= */

WITH supplier_summary AS
(
    SELECT
        s.supplier_key,
        s.supplier_name,
        s.lead_time_days,

        SUM(f.revenue) AS total_revenue,
        SUM(f.gross_profit) AS total_gross_profit,

        CASE 
            WHEN SUM(f.revenue) = 0 THEN 0
            ELSE (SUM(f.gross_profit) * 100.0 / SUM(f.revenue))
        END AS profit_margin_pct

    FROM gold.fact_inventory_daily f
    JOIN gold.dim_supplier s
        ON f.supplier_key = s.supplier_key

    GROUP BY
        s.supplier_key,
        s.supplier_name,
        s.lead_time_days
)

SELECT
    supplier_key,
    supplier_name,
    total_revenue,
    total_gross_profit,
    CAST(profit_margin_pct AS DECIMAL(6,2)) AS profit_margin_pct,
    lead_time_days,

    CASE
        WHEN total_revenue > 100000000 
             AND profit_margin_pct > 20 
             AND lead_time_days <= 5
            THEN 'Strong Supplier'

        WHEN total_revenue > 100000000 
             AND profit_margin_pct < 10
            THEN 'Low Margin Risk'

        WHEN lead_time_days > 10
            THEN 'Supply Risk'

        ELSE 'Moderate'
    END AS supplier_performance

FROM supplier_summary
ORDER BY total_revenue DESC;


USE Inventory;
GO

/* =========================================================
   LEAD TIME & SUPPLIER RISK ANALYSIS
   ========================================================= */

WITH supplier_metrics AS
(
    SELECT
        s.supplier_key,
        s.supplier_name,
        s.lead_time_days,
        s.reliability_flag,

        SUM(f.revenue) AS total_revenue,
        SUM(f.gross_profit) AS total_gross_profit,
        SUM(f.outflow_qty) AS total_outflow,
        AVG(f.inflow_qty - f.outflow_qty) AS avg_inventory_proxy

    FROM gold.fact_inventory_daily f
    JOIN gold.dim_supplier s
        ON f.supplier_key = s.supplier_key

    GROUP BY
        s.supplier_key,
        s.supplier_name,
        s.lead_time_days,
        s.reliability_flag
)

SELECT
    supplier_key,
    supplier_name,
    lead_time_days,
    reliability_flag,

    total_revenue,
    total_gross_profit,

    CAST(
        CASE 
            WHEN total_revenue = 0 THEN 0
            ELSE total_gross_profit * 100.0 / total_revenue
        END AS DECIMAL(6,2)
    ) AS profit_margin_pct,

    total_outflow,

    CAST(avg_inventory_proxy AS DECIMAL(18,2)) AS avg_inventory_proxy,

    CAST(
        CASE 
            WHEN avg_inventory_proxy = 0 THEN 0
            ELSE total_outflow / avg_inventory_proxy
        END AS DECIMAL(10,2)
    ) AS turnover_proxy,

    CASE
        WHEN lead_time_days > 10 AND reliability_flag = 'LOW'
            THEN 'High Supply Risk'

        WHEN lead_time_days > 7
            THEN 'Moderate Lead Time Risk'

        WHEN reliability_flag = 'LOW'
            THEN 'Reliability Risk'

        ELSE 'Stable Supplier'
    END AS supplier_risk_category

FROM supplier_metrics
ORDER BY total_revenue DESC;

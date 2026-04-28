# 📦 Inventory Risk & Pricing Analytics System

## 🚀 Project Overview

This project is an end-to-end **Inventory Analytics and Demand Forecasting System** built using SQL Server and Python.

It transforms raw inventory data into **actionable business insights** such as:

* Product prioritization (ABC Analysis)
* Inventory efficiency (Turnover)
* Supplier performance evaluation
* Pricing inefficiencies (Discount Leakage)
* Demand forecasting & automated replenishment

The system follows a **modern data warehouse architecture (Raw → Silver → Gold)** and supports scalable analytics.

---

## 🧱 Architecture

### 🔹 1. Raw Layer (Data Ingestion)

* Loaded structured CSV data into SQL Server using `BULK INSERT`
* Tables:

  * `products`
  * `suppliers`
  * `inventory_transactions`
  * `discounts`
  * `date_dim`

✔ Purpose: Store source data without modification

---

### 🔹 2. Silver Layer (Data Cleaning & Transformation)

* Cleaned and standardized data:

  * NULL handling (`ISNULL`)
  * Text normalization (`TRIM`, `UPPER`)
  * Data validation (lead time, discount bounds)

* Created derived metrics:

  * **Unit Margin**
  * **Margin %**
  * **Revenue, Cost, Gross Profit**

* Time enrichment:

  * Year, Month, Month Number

✔ Purpose: Make data consistent, reliable, and analytics-ready

---

### 🔹 3. Gold Layer (Star Schema)

Implemented dimensional modeling:

#### 📊 Fact Table

* `fact_inventory_daily`

  * inflow_qty
  * outflow_qty
  * revenue
  * cost
  * gross_profit

#### 🧩 Dimension Tables

* `dim_product`
* `dim_supplier`
* `dim_date`
* `dim_warehouse`

✔ Purpose: Enable fast and scalable business analytics

---

## 📊 Analytics Performed

### 🥇 ABC Analysis

* Classified products based on revenue contribution:

  * A → Top 70%
  * B → Next 20%
  * C → Bottom 10%

✔ Identifies high-priority products for inventory control

---

### 📈 Inventory Turnover

**Formula:**
Total Outflow / Average Inventory

✔ Measures how efficiently stock is moving
✔ Detects slow-moving or dead stock

---

### 🏭 Supplier Performance Analysis

* Evaluated suppliers using:

  * Revenue contribution
  * Profit contribution
  * Lead time
  * Reliability

✔ Helps identify strong vs risky suppliers

---

### 💸 Discount Leakage Analysis

* Detected:

  * High discounts with low profit
  * Ineffective promotional strategies

✔ Prevents margin loss and pricing inefficiencies

---

## 🤖 Forecasting & Replenishment (Python)

### 🔹 Data Preparation

* Merged fact and dimension tables
* Created a daily master dataset

---

### 🔹 Feature Engineering

* **Seasonality Index** (monthly demand patterns)
* **Festival Multiplier** (demand spikes)
* **Weekend Multiplier**
* **ABC-based prioritization**

---

### 🔹 Demand Forecasting

* Used **30-day moving average**
* Calculated:

  * Base demand
  * Demand variability (standard deviation)

---

### 🔹 Inventory Simulation

* Estimated current stock levels
* Adjusted demand based on:

  * Lead time
  * Supplier reliability

---

### 🔹 Reorder Strategy

| Category     | Frequency    |
| ------------ | ------------ |
| Fast-moving  | Every 3 days |
| Weekly items | Weekly       |
| Slow-moving  | Monthly      |

---

### 🔹 Output

Generated:

* Forecasted demand
* Adjusted demand
* Order quantity
* Reorder decision (YES/NO)

Stored in:
`gold.forecast_reorder_jan2026`

---

## 🧠 Key Business Impact

* 📦 Optimized inventory levels
* 📉 Reduced stockouts and overstock
* 💰 Improved profit margins
* 🏭 Better supplier selection
* 📊 Data-driven replenishment decisions

---

## 🛠️ Tech Stack

* **SQL Server** → Data warehouse (ETL + modeling)
* **Python (Pandas, NumPy)** → Forecasting & simulation
* **Power BI** → Visualization
* **Excel/CSV** → Data source

---

## 📂 Project Structure

```
├── sql/
│   ├── raw_layer.sql
│   ├── silver_layer.sql
│   ├── gold_layer.sql
│
├── python/
│   ├── forecasting.py
│
├── data/
│   ├── products.csv
│   ├── suppliers.csv
│   ├── inventory_transactions.csv
│   ├── discounts.csv
│
├── README.md
```

---

## 🏆 Key Highlights

* ✔ Built a complete **data warehouse pipeline**
* ✔ Designed a **star schema for analytics**
* ✔ Implemented **real-world business KPIs**
* ✔ Developed **forecast-driven replenishment logic**
* ✔ Combined **SQL + Python for decision intelligence**

---

## 🎯 Future Enhancements

* Machine Learning models (ARIMA / XGBoost)
* Real-time pipeline integration
* Dashboard deployment (Power BI / Tableau)
* Automated alert system for stock risks

---

## 👨‍💻 Author

**Narayanamurthy**
BCA Data Analytics

---

## ⭐ If you found this useful

Give a ⭐ on the repo — helps visibility!

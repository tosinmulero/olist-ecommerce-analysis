# Olist E-Commerce Analytics

## Project Overview

This project analyses the Olist Brazilian e-commerce dataset to uncover insights into sales performance, customer behaviour, product categories, delivery performance, payment methods and customer segmentation.

The analysis was completed using PostgreSQL for data modelling and SQL analysis, with Power BI used to build an interactive business dashboard.

The main analysis period covers delivered orders from January 2017 to August 2018 to ensure consistent monthly comparisons.

## Business Questions

This project explores:

- How did sales and order volume change over time?
- Which product categories generated the most revenue?
- Which Brazilian states generated the most customer demand?
- Where are sellers geographically concentrated?
- How does cross-state shipping affect freight costs and delivery times?
- How strongly is late delivery associated with customer review scores?
- Which payment methods are most commonly used?
- How does credit-card instalment behaviour vary with purchase value?
- How many customers make repeat purchases?
- Which customer segments contribute the most observed spend?


## Key Performance Indicators

- **Delivered Orders:** 96,211
- **Unique Customers:** 93,104
- **Merchandise Revenue:** R$13,181,027.13
- **Freight Charged:** R$2,192,092.88
- **Total Order Value:** R$15,373,120.01
- **Average Order Value:** R$159.79
- **Repeat Customers:** 3.00%
- **Late Delivery Rate:** 8.13%
- **Cross-State Orders:** 64.15%

## Key Findings

### Sales Performance

- November 2017 recorded the highest monthly total order value at approximately **R$1.15 million**.
- Delivered orders increased by approximately **139.94%** between January–August 2017 and January–August 2018.
- Total order value increased by approximately **143.36%** over the same comparable period.

### Product Performance

- **Health & Beauty** generated the highest merchandise revenue at approximately **R$1.23 million**.
- **Watches & Gifts** ranked second by merchandise revenue at approximately **R$1.16 million**, despite ranking lower by unit volume.
- **Bed, Bath & Table** recorded the highest item volume with **10,945 items sold**.
- The top five product categories generated approximately **39.88%** of merchandise revenue.

### Customer Behaviour

- **97.00%** of customers placed only one delivered order.
- Only **3.00%** of customers were repeat purchasers.
- Repeat customers generated approximately **R$308.55 average observed spend per customer**, compared with **R$160.69** for one-time customers.

### Logistics Performance

- **64.15%** of delivered orders involved at least one seller located in a different state from the customer.
- Cross-state orders had average freight charges of **R$26.94**, compared with **R$15.35** for same-state orders.
- Cross-state deliveries took an average of **15.12 days**, compared with **7.92 days** for same-state deliveries.
- The late-delivery rate was **9.27%** for cross-state orders compared with **6.09%** for same-state orders.

### Customer Satisfaction

- On-time or early deliveries received an average review score of **4.30/5**.
- Late deliveries received an average review score of only **2.57/5**.
- **53.98%** of late deliveries received review scores of 1–2, compared with only **9.17%** of on-time deliveries.
- Orders delivered more than 8 days late had an average review score of **1.73/5**.

### Customer Segmentation

RFM analysis identified several commercially useful customer groups:

- **Recent High-Value Customers:** 14,410 customers contributing **28.31%** of observed customer spend.
- **Older High-Value Customers:** 13,865 customers contributing **26.54%**.
- **Inactive High-Value Customers:** 6,738 customers contributing **13.43%**.
- **Recent Repeat Customers:** 1,197 customers.
- **At-Risk Repeat Customers:** 1,592 customers.

## Power BI Dashboard

![Olist E-Commerce Performance Dashboard](images/olist_dashboard.png)

## Tools & Technologies

- **PostgreSQL** — relational database design, data quality checks and SQL analysis
- **SQL** — joins, CTEs, window functions, aggregation, conditional logic and reusable views
- **Power BI** — interactive dashboard development and KPI reporting
- **DAX** — calculated measures for business KPIs
- **Power Query** — data type validation and model preparation
- **Git & GitHub** — version control and portfolio publishing
- **VS Code** — project development and documentation

## Project Structure

```text
olist-ecommerce-analysis/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── images/
│   └── olist_dashboard.png
│
├── notebooks/
│
├── powerbi/
│   └── Olist_Ecommerce_Analysis.pbix
│
├── sql/
│   ├── 01_data_quality_checks.sql
│   └── 02_business_analysis.sql
│
└── README.md


## SQL Methodology

The SQL analysis was designed to keep calculations reproducible and business-focused.

Key steps included:

- Validating primary keys, foreign keys, null values and duplicate records.
- Checking timestamp consistency and identifying invalid delivery sequences.
- Restricting comparable monthly analysis to **January 2017 – August 2018** because the boundary months in the source data were incomplete.
- Using only **delivered orders** for revenue, customer-value and delivery-performance analysis.
- Aggregating order-item data to the order level where necessary to prevent double counting.
- Using `customer_unique_id` rather than `customer_id` for repeat-customer analysis.
- Aggregating multiple review records to the order level before analysing customer satisfaction.
- Using CTEs, conditional aggregation, window functions and PostgreSQL views to create reusable analytical datasets for Power BI.
- Creating custom RFM frequency bands because **97% of customers placed only one delivered order**, making standard frequency quintiles unsuitable.

## Business Recommendations

### 1. Prioritise Delivery Reliability

Late delivery is strongly associated with poorer customer reviews. Olist should closely monitor orders at risk of missing the estimated delivery date and prioritise intervention before delays become severe.

### 2. Review Cross-State Logistics

Cross-state orders show higher freight charges, longer delivery times and higher late-delivery rates. Logistics planning could focus on reducing unnecessary long-distance fulfilment and improving seller-to-customer routing where operationally feasible.

### 3. Re-Engage High-Value Customers

The RFM analysis identified substantial groups of **Older High-Value** and **Inactive High-Value Customers**. These customers represent potential targets for retention and re-engagement campaigns.

### 4. Improve Repeat Purchase Behaviour

Only **3% of customers** made repeat purchases during the observed period. Customer retention initiatives, post-purchase engagement and personalised offers could be evaluated as ways to increase repeat purchasing.

### 5. Protect High-Revenue Product Categories

Health & Beauty, Watches & Gifts, Bed Bath & Table, Sports & Leisure, and Computers & Accessories contribute a substantial share of merchandise revenue. These categories should receive close attention in inventory, seller performance and fulfilment monitoring.

### 6. Monitor High-Freight Orders

Freight represented a larger proportion of merchandise value for cross-state orders. Olist could monitor freight-to-order-value ratios to identify transactions where shipping charges may disproportionately affect customer value.

## Conclusion

This project demonstrates an end-to-end e-commerce analytics workflow using PostgreSQL, SQL, Power BI, DAX and Power Query.

The analysis found that Olist experienced substantial growth during the comparable 2017–2018 period, but customer retention remained low. Delivery performance also emerged as an important operational factor: cross-state orders were more expensive to ship, took longer to arrive and were more likely to be late, while increasingly severe delays were associated with sharply lower customer review scores.

The RFM analysis further identified distinct high-value, repeat and inactive customer groups that can support more targeted customer-retention strategies.

Overall, the project demonstrates how transactional e-commerce data can be transformed into commercially relevant insights across sales, customers, products, payments and logistics.
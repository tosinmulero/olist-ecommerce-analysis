# Recruiter evidence guide — Olist E-Commerce Analytics

[**Full case study on Mulero Analytics**](https://tosinmulero.github.io/data-analytics-portfolio/case-studies/olist-ecommerce-analysis.html) · [Repository README](../README.md) · [Main portfolio](https://tosinmulero.github.io/data-analytics-portfolio/projects.html)

> **Data provenance:** Public Olist marketplace dataset; observational historical transactions, not simulated achieved client results.

## The question

How can a Brazilian marketplace analyse sales, repeat purchasing, delivery reliability and customer satisfaction using correctly joined order-level data?

## Technical approach

- Validate relational order, customer, product, delivery and review data in PostgreSQL.
- Avoid order-value double-counting through order-grain aggregation and careful joins.
- Develop RFM segmentation, fulfilment KPIs and a Power BI commercial dashboard.

## Documented results to review

- 96,211 delivered orders representing R$15.37M in total order value.
- Only 3.00% of customers were repeat purchasers in the analysed delivered-order population.
- Cross-state deliveries averaged 15.12 days versus 7.92 within a state; late deliveries averaged 2.57/5 reviews versus 4.30/5 when on time or early.

## Evidence map

| Review item | Source | What it supports |
|---|---|---|
| Recruiter summary | [Open](../docs/RECRUITER_PROJECT_SUMMARY.md) | Key indicators and analytical scope |
| Technical architecture | [Open](../docs/TECHNICAL_ARCHITECTURE.md) | Warehouse and reporting design |
| Power BI dashboard | [Open](../images/olist_dashboard.png) | Sales, logistics and customer KPIs |
| SQL workflow guide | [Open](../sql/README.md) | Technical structure of SQL artefacts |

## Reproducibility and limitations

Refer to the repository README and SQL workflow documentation. Relationships between delivery times and review scores are observational associations and should not be described as proven causes.

The repository README and linked source files remain the primary technical record. Figures in this guide summarise documented project artefacts, not independently verified third-party business outcomes.

## Suggested review path

1. Start with the [standalone case study](https://tosinmulero.github.io/data-analytics-portfolio/case-studies/olist-ecommerce-analysis.html) for an accessible summary.
2. Inspect the linked screenshots and technical documentation.
3. Check the README and source files for workflow, caveats and reproduction guidance.
4. Inspect analytical code or quality workflows as required.

---

*Independent portfolio work by Oluwatosin Mulero. Project evidence is maintained in this repository.*

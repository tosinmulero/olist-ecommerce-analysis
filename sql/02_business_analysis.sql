-- ============================================================
-- OLIST E-COMMERCE ANALYSIS
-- 02. BUSINESS ANALYSIS
-- ============================================================

-- Main analytical period for comparable monthly trends:
-- 2017-01-01 through 2018-08-31

-- 1. Create a reusable base set of orders within the analytical period

WITH analysis_orders AS (
    SELECT *
    FROM orders
    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'
)
SELECT COUNT(*) AS analysis_order_count
FROM analysis_orders;


-- 2. Order volume and delivery rate

WITH analysis_orders AS (
    SELECT *
    FROM orders
    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'
)
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / COUNT(*),
        2
    ) AS delivery_rate_pct
FROM analysis_orders;


-- 3. Delivered merchandise revenue and average order value
-- Revenue here represents the sum of product prices, excluding freight.

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        SUM(oi.price) AS merchandise_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    COUNT(*) AS delivered_orders_with_items,
    ROUND(SUM(merchandise_value), 2) AS merchandise_revenue,
    ROUND(AVG(merchandise_value), 2) AS average_order_value
FROM delivered_order_values;


-- 4. Delivered order value including freight

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        SUM(oi.price) AS merchandise_value,
        SUM(oi.freight_value) AS freight_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    ROUND(SUM(merchandise_value), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(SUM(merchandise_value + freight_value), 2) AS total_order_value,
    ROUND(AVG(merchandise_value + freight_value), 2) AS avg_order_value_including_freight
FROM delivered_order_values;


-- 5. Monthly delivered revenue and order value

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        SUM(oi.price) AS merchandise_value,
        SUM(oi.freight_value) AS freight_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
)

SELECT
    order_month,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(merchandise_value), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(merchandise_value + freight_value), 2) AS total_order_value,
    ROUND(AVG(merchandise_value + freight_value), 2) AS average_order_value
FROM delivered_order_values
GROUP BY order_month
ORDER BY order_month;


-- 6. Month-over-month revenue growth using LAG()

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date
),

monthly_revenue AS (
    SELECT
        order_month,
        COUNT(*) AS delivered_orders,
        SUM(total_order_value) AS monthly_revenue
    FROM delivered_order_values
    GROUP BY order_month
),

revenue_growth AS (
    SELECT
        order_month,
        delivered_orders,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue
    FROM monthly_revenue
)

SELECT
    order_month,
    delivered_orders,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 *
        (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS month_over_month_growth_pct
FROM revenue_growth
ORDER BY order_month;


-- 7. Year-over-year revenue comparison: Jan-Aug 2017 vs Jan-Aug 2018

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        EXTRACT(YEAR FROM o.order_purchase_timestamp)::int AS order_year,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND (
            o.order_purchase_timestamp >= '2017-01-01'
        AND o.order_purchase_timestamp < '2017-09-01'
        OR
            o.order_purchase_timestamp >= '2018-01-01'
        AND o.order_purchase_timestamp < '2018-09-01'
      )
    GROUP BY
        o.order_id,
        EXTRACT(YEAR FROM o.order_purchase_timestamp)::int
),

yearly_summary AS (
    SELECT
        order_year,
        COUNT(*) AS delivered_orders,
        SUM(total_order_value) AS revenue
    FROM delivered_order_values
    GROUP BY order_year
)

SELECT
    order_year,
    delivered_orders,
    ROUND(revenue, 2) AS revenue
FROM yearly_summary
ORDER BY order_year;


-- 8. Year-over-year growth: Jan-Aug 2017 vs Jan-Aug 2018

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        EXTRACT(YEAR FROM o.order_purchase_timestamp)::int AS order_year,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND (
            (o.order_purchase_timestamp >= '2017-01-01'
             AND o.order_purchase_timestamp < '2017-09-01')
         OR (o.order_purchase_timestamp >= '2018-01-01'
             AND o.order_purchase_timestamp < '2018-09-01')
      )
    GROUP BY
        o.order_id,
        EXTRACT(YEAR FROM o.order_purchase_timestamp)::int
),

yearly_summary AS (
    SELECT
        order_year,
        COUNT(*) AS delivered_orders,
        SUM(total_order_value) AS revenue
    FROM delivered_order_values
    GROUP BY order_year
),

year_comparison AS (
    SELECT
        order_year,
        delivered_orders,
        revenue,
        LAG(delivered_orders) OVER (ORDER BY order_year) AS previous_year_orders,
        LAG(revenue) OVER (ORDER BY order_year) AS previous_year_revenue
    FROM yearly_summary
)

SELECT
    order_year,
    delivered_orders,
    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 * (delivered_orders - previous_year_orders)
        / NULLIF(previous_year_orders, 0),
        2
    ) AS order_growth_pct,

    ROUND(
        100.0 * (revenue - previous_year_revenue)
        / NULLIF(previous_year_revenue, 0),
        2
    ) AS revenue_growth_pct

FROM year_comparison
ORDER BY order_year;


-- 9. Customer repeat-purchase analysis

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS unique_customers,
    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_count > 1
        ) / COUNT(*),
        2
    ) AS repeat_customer_pct,
    ROUND(
        AVG(order_count),
        2
    ) AS avg_orders_per_customer,
    MAX(order_count) AS max_orders_by_customer
FROM customer_orders;


-- 10. Revenue contribution: one-time vs repeat customers

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        o.customer_id
),

customer_summary AS (
    SELECT
        c.customer_unique_id,
        COUNT(d.order_id) AS order_count,
        SUM(d.total_order_value) AS customer_revenue
    FROM delivered_order_values d
    JOIN customers c
        ON d.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        order_count,
        customer_revenue,
        CASE
            WHEN order_count > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM customer_summary
),

segment_summary AS (
    SELECT
        customer_type,
        COUNT(*) AS unique_customers,
        SUM(order_count) AS orders,
        SUM(customer_revenue) AS revenue
    FROM customer_segments
    GROUP BY customer_type
)

SELECT
    customer_type,
    unique_customers,
    orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / orders, 2) AS average_order_value,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM segment_summary
ORDER BY revenue DESC;


-- 11. Customer value: one-time vs repeat customers

WITH delivered_order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.price + oi.freight_value) AS total_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        o.customer_id
),

customer_summary AS (
    SELECT
        c.customer_unique_id,
        COUNT(d.order_id) AS order_count,
        SUM(d.total_order_value) AS customer_revenue
    FROM delivered_order_values d
    JOIN customers c
        ON d.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN order_count > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM customer_summary
)

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    ROUND(AVG(customer_revenue), 2) AS avg_revenue_per_customer,
    ROUND(MIN(customer_revenue), 2) AS min_customer_revenue,
    ROUND(MAX(customer_revenue), 2) AS max_customer_revenue
FROM customer_segments
GROUP BY customer_type
ORDER BY avg_revenue_per_customer DESC;


-- 12. Top product categories by delivered merchandise revenue

WITH category_performance AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,

        COUNT(*) AS items_sold,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.price) AS merchandise_revenue,
        AVG(oi.price) AS average_item_price

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN products p
        ON oi.product_id = p.product_id

    LEFT JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    product_category,
    items_sold,
    orders,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue,
    ROUND(average_item_price, 2) AS average_item_price
FROM category_performance
ORDER BY merchandise_revenue DESC
LIMIT 15;


-- 13. Product category revenue share

WITH category_performance AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,

        COUNT(*) AS items_sold,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.price) AS merchandise_revenue

    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    product_category,
    items_sold,
    orders,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue,
    ROUND(
        100.0 * merchandise_revenue
        / SUM(merchandise_revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM category_performance
ORDER BY merchandise_revenue DESC
LIMIT 15;


-- 14. Top product categories by items sold

WITH category_performance AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,

        COUNT(*) AS items_sold,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.price) AS merchandise_revenue

    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    product_category,
    items_sold,
    orders,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue
FROM category_performance
ORDER BY items_sold DESC
LIMIT 15;


-- 15. Revenue concentration among top product categories

WITH category_revenue AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,
        SUM(oi.price) AS merchandise_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        )
),

ranked_categories AS (
    SELECT
        product_category,
        merchandise_revenue,
        ROW_NUMBER() OVER (
            ORDER BY merchandise_revenue DESC
        ) AS revenue_rank
    FROM category_revenue
)

SELECT
    ROUND(
        100.0 * SUM(merchandise_revenue)
            FILTER (WHERE revenue_rank <= 5)
        / SUM(merchandise_revenue),
        2
    ) AS top_5_revenue_share_pct,

    ROUND(
        100.0 * SUM(merchandise_revenue)
            FILTER (WHERE revenue_rank <= 10)
        / SUM(merchandise_revenue),
        2
    ) AS top_10_revenue_share_pct,

    COUNT(*) AS total_categories
FROM ranked_categories;


-- 16. Top sellers by delivered merchandise revenue

WITH seller_performance AS (
    SELECT
        s.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT o.order_id) AS orders,
        COUNT(*) AS items_sold,
        SUM(oi.price) AS merchandise_revenue,
        SUM(oi.freight_value) AS freight_value

    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        s.seller_id,
        s.seller_city,
        s.seller_state
)

SELECT
    seller_id,
    seller_city,
    seller_state,
    orders,
    items_sold,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue,
    ROUND(freight_value, 2) AS freight_value
FROM seller_performance
ORDER BY merchandise_revenue DESC
LIMIT 15;


-- 17. Seller performance by state

WITH seller_state_performance AS (
    SELECT
        s.seller_state,
        COUNT(DISTINCT s.seller_id) AS sellers,
        COUNT(DISTINCT o.order_id) AS orders,
        COUNT(*) AS items_sold,
        SUM(oi.price) AS merchandise_revenue,
        SUM(oi.freight_value) AS freight_value

    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY s.seller_state
)

SELECT
    seller_state,
    sellers,
    orders,
    items_sold,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue,
    ROUND(
        100.0 * merchandise_revenue
        / SUM(merchandise_revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM seller_state_performance
ORDER BY merchandise_revenue DESC;


-- 18. Customer demand by state

WITH customer_state_performance AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.price) AS merchandise_revenue

    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY c.customer_state
)

SELECT
    customer_state,
    unique_customers,
    orders,
    ROUND(merchandise_revenue, 2) AS merchandise_revenue,
    ROUND(
        100.0 * merchandise_revenue
        / SUM(merchandise_revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM customer_state_performance
ORDER BY merchandise_revenue DESC;


-- 19. Same-state vs cross-state order analysis

WITH order_state_pairs AS (
    SELECT DISTINCT
        o.order_id,
        c.customer_state,
        s.seller_state
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
)

SELECT
    CASE
        WHEN customer_state = seller_state
            THEN 'Same State'
        ELSE 'Cross State'
    END AS shipping_type,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct
FROM order_state_pairs
GROUP BY
    CASE
        WHEN customer_state = seller_state
            THEN 'Same State'
        ELSE 'Cross State'
    END
ORDER BY orders DESC;


-- 20. Corrected same-state vs cross-state analysis at ORDER level
-- An order is classified as Cross State if ANY seller on the order
-- is located in a different state from the customer.

WITH order_shipping_type AS (
    SELECT
        o.order_id,
        BOOL_OR(s.seller_state <> c.customer_state) AS has_cross_state_seller
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN sellers s
        ON oi.seller_id = s.seller_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY o.order_id
)

SELECT
    CASE
        WHEN has_cross_state_seller THEN 'Cross State'
        ELSE 'Same State'
    END AS shipping_type,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct
FROM order_shipping_type
GROUP BY has_cross_state_seller
ORDER BY orders DESC;


-- 21. Freight cost: same-state vs cross-state orders

WITH order_shipping_summary AS (
    SELECT
        o.order_id,

        BOOL_OR(
            s.seller_state <> c.customer_state
        ) AS has_cross_state_seller,

        SUM(oi.price) AS merchandise_value,
        SUM(oi.freight_value) AS freight_value

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY o.order_id
)

SELECT
    CASE
        WHEN has_cross_state_seller THEN 'Cross State'
        ELSE 'Same State'
    END AS shipping_type,

    COUNT(*) AS orders,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight_per_order,

    ROUND(
        AVG(merchandise_value),
        2
    ) AS avg_merchandise_value,

    ROUND(
        100.0 * SUM(freight_value)
        / NULLIF(SUM(merchandise_value), 0),
        2
    ) AS freight_as_pct_of_merchandise

FROM order_shipping_summary

GROUP BY has_cross_state_seller
ORDER BY avg_freight_per_order DESC;


-- 22. Delivery time: same-state vs cross-state orders
-- Only use delivered orders with valid purchase and delivery timestamps.

WITH order_shipping_summary AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,

        BOOL_OR(
            s.seller_state <> c.customer_state
        ) AS has_cross_state_seller

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp

    GROUP BY
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
)

SELECT
    CASE
        WHEN has_cross_state_seller THEN 'Cross State'
        ELSE 'Same State'
    END AS shipping_type,

    COUNT(*) AS orders,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )) / 86400
        )::numeric,
        2
    ) AS avg_delivery_days

FROM order_shipping_summary

GROUP BY has_cross_state_seller
ORDER BY avg_delivery_days DESC;


-- 23. Late-delivery rate: same-state vs cross-state orders

WITH order_shipping_summary AS (
    SELECT
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        BOOL_OR(
            s.seller_state <> c.customer_state
        ) AS has_cross_state_seller

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL

    GROUP BY
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    CASE
        WHEN has_cross_state_seller THEN 'Cross State'
        ELSE 'Same State'
    END AS shipping_type,

    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  > order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct

FROM order_shipping_summary

GROUP BY has_cross_state_seller
ORDER BY late_delivery_rate_pct DESC;


-- 24. Customer satisfaction: on-time vs late deliveries

WITH order_reviews_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),

delivery_review_analysis AS (
    SELECT
        o.order_id,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
                THEN 'Late Delivery'
            ELSE 'On-Time Delivery'
        END AS delivery_status,

        r.avg_review_score

    FROM orders o

    JOIN order_reviews_summary r
        ON o.order_id = r.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_status,
    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(avg_review_score),
        2
    ) AS average_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE avg_review_score <= 2
        ) / COUNT(*),
        2
    ) AS low_review_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE avg_review_score = 5
        ) / COUNT(*),
        2
    ) AS five_star_review_pct

FROM delivery_review_analysis

GROUP BY delivery_status
ORDER BY average_review_score DESC;


-- 25. Review score by delivery-delay severity

WITH order_reviews_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),

delivery_analysis AS (
    SELECT
        o.order_id,

        EXTRACT(
            EPOCH FROM (
                o.order_delivered_customer_date
                - o.order_estimated_delivery_date
            )
        ) / 86400.0 AS days_vs_estimate,

        r.avg_review_score

    FROM orders o

    JOIN order_reviews_summary r
        ON o.order_id = r.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

delay_groups AS (
    SELECT
        *,
        CASE
            WHEN days_vs_estimate <= 0
                THEN 'On Time / Early'
            WHEN days_vs_estimate <= 3
                THEN '1-3 Days Late'
            WHEN days_vs_estimate <= 7
                THEN '4-7 Days Late'
            ELSE '8+ Days Late'
        END AS delay_group
    FROM delivery_analysis
)

SELECT
    delay_group,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(avg_review_score), 2) AS average_review_score,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE avg_review_score <= 2
        ) / COUNT(*),
        2
    ) AS low_review_pct

FROM delay_groups

GROUP BY delay_group

ORDER BY
    CASE delay_group
        WHEN 'On Time / Early' THEN 1
        WHEN '1-3 Days Late' THEN 2
        WHEN '4-7 Days Late' THEN 3
        WHEN '8+ Days Late' THEN 4
    END;


    -- 26. Payment method usage and value

SELECT
    op.payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT op.order_id) AS orders,

    ROUND(
        SUM(op.payment_value),
        2
    ) AS payment_value,

    ROUND(
        100.0 * SUM(op.payment_value)
        / SUM(SUM(op.payment_value)) OVER (),
        2
    ) AS payment_value_share_pct,

    ROUND(
        AVG(op.payment_installments),
        2
    ) AS avg_installments

FROM order_payments op

JOIN orders o
    ON op.order_id = o.order_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'

GROUP BY op.payment_type

ORDER BY payment_value DESC;


-- 27. Credit-card instalment behaviour

SELECT
    payment_installments,
    COUNT(DISTINCT op.order_id) AS orders,

    ROUND(
        AVG(op.payment_value),
        2
    ) AS avg_payment_value,

    ROUND(
        SUM(op.payment_value),
        2
    ) AS total_payment_value

FROM order_payments op

JOIN orders o
    ON op.order_id = o.order_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'
  AND op.payment_type = 'credit_card'

GROUP BY payment_installments

ORDER BY payment_installments;

-- 28. Credit-card instalment bands

WITH installment_groups AS (
    SELECT
        op.order_id,
        op.payment_value,
        CASE
            WHEN op.payment_installments <= 1 THEN '1 Instalment'
            WHEN op.payment_installments BETWEEN 2 AND 3 THEN '2-3 Instalments'
            WHEN op.payment_installments BETWEEN 4 AND 6 THEN '4-6 Instalments'
            WHEN op.payment_installments BETWEEN 7 AND 10 THEN '7-10 Instalments'
            ELSE '11+ Instalments'
        END AS installment_band
    FROM order_payments op
    JOIN orders o
        ON op.order_id = o.order_id
    AND o.order_status = 'delivered'
AND op.payment_type = 'credit_card'
AND op.payment_installments > 0
)

SELECT
    installment_band,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(payment_value), 2) AS avg_payment_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM installment_groups
GROUP BY installment_band
ORDER BY
    CASE installment_band
        WHEN '1 Instalment' THEN 1
        WHEN '2-3 Instalments' THEN 2
        WHEN '4-6 Instalments' THEN 3
        WHEN '7-10 Instalments' THEN 4
        WHEN '11+ Instalments' THEN 5
    END;


    -- 29. Inspect credit-card payments with zero instalments

SELECT
    op.order_id,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value,
    o.order_status,
    o.order_purchase_timestamp
FROM order_payments op
JOIN orders o
    ON op.order_id = o.order_id
WHERE op.payment_type = 'credit_card'
  AND op.payment_installments = 0
ORDER BY o.order_purchase_timestamp;


-- 30. Build customer-level RFM metrics
-- Snapshot date: 2018-09-01
-- Analysis window: 2017-01-01 to 2018-08-31

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values

    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS customers,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    MAX(frequency) AS max_frequency,
    ROUND(MAX(monetary_value), 2) AS max_monetary_value
FROM rfm;


-- 31. Customer purchase-frequency distribution

WITH customer_frequency AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    frequency,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct
FROM customer_frequency
GROUP BY frequency
ORDER BY frequency;


-- 32. Recency and monetary percentile thresholds for RFM scoring

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(order_value) AS monetary_value

    FROM order_values
    GROUP BY customer_unique_id
)

SELECT
    ROUND(
        PERCENTILE_CONT(0.20)
        WITHIN GROUP (ORDER BY recency_days)::numeric,
        2
    ) AS recency_p20,

    ROUND(
        PERCENTILE_CONT(0.40)
        WITHIN GROUP (ORDER BY recency_days)::numeric,
        2
    ) AS recency_p40,

    ROUND(
        PERCENTILE_CONT(0.60)
        WITHIN GROUP (ORDER BY recency_days)::numeric,
        2
    ) AS recency_p60,

    ROUND(
        PERCENTILE_CONT(0.80)
        WITHIN GROUP (ORDER BY recency_days)::numeric,
        2
    ) AS recency_p80,

    ROUND(
        PERCENTILE_CONT(0.20)
        WITHIN GROUP (ORDER BY monetary_value)::numeric,
        2
    ) AS monetary_p20,

    ROUND(
        PERCENTILE_CONT(0.40)
        WITHIN GROUP (ORDER BY monetary_value)::numeric,
        2
    ) AS monetary_p40,

    ROUND(
        PERCENTILE_CONT(0.60)
        WITHIN GROUP (ORDER BY monetary_value)::numeric,
        2
    ) AS monetary_p60,

    ROUND(
        PERCENTILE_CONT(0.80)
        WITHIN GROUP (ORDER BY monetary_value)::numeric,
        2
    ) AS monetary_p80

FROM rfm;


-- 33. Assign customer RFM scores

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values
    GROUP BY customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,

        CASE
            WHEN recency_days <= 94 THEN 5
            WHEN recency_days <= 179 THEN 4
            WHEN recency_days <= 270 THEN 3
            WHEN recency_days <= 383 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3
        END AS f_score,

        CASE
            WHEN monetary_value <= 55.24 THEN 1
            WHEN monetary_value <= 87.33 THEN 2
            WHEN monetary_value <= 132.59 THEN 3
            WHEN monetary_value <= 208.47 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm
)

SELECT
    r_score,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct
FROM rfm_scores
GROUP BY r_score
ORDER BY r_score DESC;


-- 34. Validate Monetary score distribution

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values
    GROUP BY customer_unique_id
),

rfm_scores AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,

        CASE
            WHEN recency_days <= 94 THEN 5
            WHEN recency_days <= 179 THEN 4
            WHEN recency_days <= 270 THEN 3
            WHEN recency_days <= 383 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3
        END AS f_score,

        CASE
            WHEN monetary_value <= 55.24 THEN 1
            WHEN monetary_value <= 87.33 THEN 2
            WHEN monetary_value <= 132.59 THEN 3
            WHEN monetary_value <= 208.47 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm
)

SELECT
    m_score,
    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct

FROM rfm_scores

GROUP BY m_score
ORDER BY m_score DESC;


-- 35. Create actionable RFM customer segments

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values
    GROUP BY customer_unique_id
),

rfm_scores AS (
    SELECT
        *,

        CASE
            WHEN recency_days <= 94 THEN 5
            WHEN recency_days <= 179 THEN 4
            WHEN recency_days <= 270 THEN 3
            WHEN recency_days <= 383 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3
        END AS f_score,

        CASE
            WHEN monetary_value <= 55.24 THEN 1
            WHEN monetary_value <= 87.33 THEN 2
            WHEN monetary_value <= 132.59 THEN 3
            WHEN monetary_value <= 208.47 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm
),

customer_segments AS (
    SELECT
        *,

        CASE
            WHEN frequency >= 2
                 AND r_score >= 4
                THEN 'Recent Repeat Customers'

            WHEN frequency >= 2
                 AND r_score <= 3
                THEN 'At-Risk Repeat Customers'

            WHEN frequency = 1
                 AND r_score >= 4
                 AND m_score >= 4
                THEN 'Recent High-Value Customers'

            WHEN frequency = 1
                 AND r_score >= 4
                 AND m_score <= 3
                THEN 'Recent Standard Customers'

            WHEN frequency = 1
                 AND r_score BETWEEN 2 AND 3
                 AND m_score >= 4
                THEN 'Older High-Value Customers'

            WHEN frequency = 1
                 AND r_score BETWEEN 2 AND 3
                 AND m_score <= 3
                THEN 'Older Standard Customers'

            WHEN frequency = 1
                 AND r_score = 1
                 AND m_score >= 4
                THEN 'Inactive High-Value Customers'

            ELSE 'Inactive Standard Customers'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_pct,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_frequency,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value

FROM customer_segments

GROUP BY customer_segment
ORDER BY customers DESC;


-- 36. Customer segment contribution to observed spend

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values
    GROUP BY customer_unique_id
),

rfm_scores AS (
    SELECT
        *,

        CASE
            WHEN recency_days <= 94 THEN 5
            WHEN recency_days <= 179 THEN 4
            WHEN recency_days <= 270 THEN 3
            WHEN recency_days <= 383 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3
        END AS f_score,

        CASE
            WHEN monetary_value <= 55.24 THEN 1
            WHEN monetary_value <= 87.33 THEN 2
            WHEN monetary_value <= 132.59 THEN 3
            WHEN monetary_value <= 208.47 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm
),

customer_segments AS (
    SELECT
        *,

        CASE
            WHEN frequency >= 2
                 AND r_score >= 4
                THEN 'Recent Repeat Customers'

            WHEN frequency >= 2
                 AND r_score <= 3
                THEN 'At-Risk Repeat Customers'

            WHEN frequency = 1
                 AND r_score >= 4
                 AND m_score >= 4
                THEN 'Recent High-Value Customers'

            WHEN frequency = 1
                 AND r_score >= 4
                 AND m_score <= 3
                THEN 'Recent Standard Customers'

            WHEN frequency = 1
                 AND r_score BETWEEN 2 AND 3
                 AND m_score >= 4
                THEN 'Older High-Value Customers'

            WHEN frequency = 1
                 AND r_score BETWEEN 2 AND 3
                 AND m_score <= 3
                THEN 'Older Standard Customers'

            WHEN frequency = 1
                 AND r_score = 1
                 AND m_score >= 4
                THEN 'Inactive High-Value Customers'

            ELSE 'Inactive Standard Customers'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS observed_customer_spend,

    ROUND(
        100.0 * SUM(monetary_value)
        / SUM(SUM(monetary_value)) OVER (),
        2
    ) AS spend_share_pct

FROM customer_segments

GROUP BY customer_segment

ORDER BY observed_customer_spend DESC;


-- 37. Create reusable RFM customer segmentation view

CREATE OR REPLACE VIEW vw_customer_rfm_segments AS

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(oi.price + oi.freight_value) AS order_value

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

rfm AS (
    SELECT
        customer_unique_id,

        DATE '2018-09-01'
        - MAX(order_purchase_timestamp)::date
        AS recency_days,

        COUNT(DISTINCT order_id) AS frequency,

        ROUND(
            SUM(order_value),
            2
        ) AS monetary_value

    FROM order_values

    GROUP BY customer_unique_id
),

rfm_scores AS (
    SELECT
        *,

        CASE
            WHEN recency_days <= 94 THEN 5
            WHEN recency_days <= 179 THEN 4
            WHEN recency_days <= 270 THEN 3
            WHEN recency_days <= 383 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3
        END AS f_score,

        CASE
            WHEN monetary_value <= 55.24 THEN 1
            WHEN monetary_value <= 87.33 THEN 2
            WHEN monetary_value <= 132.59 THEN 3
            WHEN monetary_value <= 208.47 THEN 4
            ELSE 5
        END AS m_score

    FROM rfm
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary_value,
    r_score,
    f_score,
    m_score,

    CASE
        WHEN frequency >= 2
             AND r_score >= 4
            THEN 'Recent Repeat Customers'

        WHEN frequency >= 2
             AND r_score <= 3
            THEN 'At-Risk Repeat Customers'

        WHEN frequency = 1
             AND r_score >= 4
             AND m_score >= 4
            THEN 'Recent High-Value Customers'

        WHEN frequency = 1
             AND r_score >= 4
             AND m_score <= 3
            THEN 'Recent Standard Customers'

        WHEN frequency = 1
             AND r_score BETWEEN 2 AND 3
             AND m_score >= 4
            THEN 'Older High-Value Customers'

        WHEN frequency = 1
             AND r_score BETWEEN 2 AND 3
             AND m_score <= 3
            THEN 'Older Standard Customers'

        WHEN frequency = 1
             AND r_score = 1
             AND m_score >= 4
            THEN 'Inactive High-Value Customers'

        ELSE 'Inactive Standard Customers'

    END AS customer_segment

FROM rfm_scores;


-- 38. Validate RFM view row count

SELECT COUNT(*) AS customers
FROM vw_customer_rfm_segments;


-- 39. Validate customer segment totals from RFM view

SELECT
    customer_segment,
    COUNT(*) AS customers
FROM vw_customer_rfm_segments
GROUP BY customer_segment
ORDER BY customers DESC;


-- 40. Create reusable monthly sales performance view

CREATE OR REPLACE VIEW vw_monthly_sales_performance AS

WITH order_values AS (
    SELECT
        o.order_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS order_month,

        SUM(oi.price) AS merchandise_value,
        SUM(oi.freight_value) AS freight_value,
        SUM(oi.price + oi.freight_value) AS total_order_value

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        o.order_id,
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date
)

SELECT
    order_month,

    COUNT(*) AS delivered_orders,

    ROUND(
        SUM(merchandise_value),
        2
    ) AS merchandise_revenue,

    ROUND(
        SUM(freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(total_order_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(total_order_value),
        2
    ) AS average_order_value

FROM order_values

GROUP BY order_month

ORDER BY order_month;



-- 41. Validate monthly sales performance view

SELECT
    COUNT(*) AS months,
    SUM(delivered_orders) AS delivered_orders,
    ROUND(SUM(merchandise_revenue), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(total_order_value), 2) AS total_order_value
FROM vw_monthly_sales_performance;


-- 42. Create reusable product category performance view

CREATE OR REPLACE VIEW vw_product_category_performance AS

SELECT
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS items_sold,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS merchandise_revenue,

    ROUND(
        SUM(oi.freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_translation pct
    ON p.product_category_name = pct.product_category_name

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'

GROUP BY
    COALESCE(
        pct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    );



    -- 43. Validate product category performance view

SELECT
    COUNT(*) AS categories,
    SUM(items_sold) AS items_sold,
    ROUND(SUM(merchandise_revenue), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(total_order_value), 2) AS total_order_value
FROM vw_product_category_performance;


-- 44. Create reusable delivery and logistics view

CREATE OR REPLACE VIEW vw_delivery_performance AS

WITH order_logistics AS (
    SELECT
        o.order_id,
        c.customer_state,

        BOOL_OR(
            s.seller_state <> c.customer_state
        ) AS has_cross_state_seller,

        SUM(oi.price) AS merchandise_value,
        SUM(oi.freight_value) AS freight_value,

        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date

    FROM orders o

    JOIN customers c
        ON o.customer_id = c.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND o.order_status = 'delivered'

    GROUP BY
        o.order_id,
        c.customer_state,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

review_summary AS (
    SELECT
        order_id,
        ROUND(AVG(review_score), 2) AS average_review_score
    FROM order_reviews
    GROUP BY order_id
)

SELECT
    ol.order_id,
    ol.customer_state,

    CASE
        WHEN ol.has_cross_state_seller
            THEN 'Cross State'
        ELSE 'Same State'
    END AS shipping_type,

    ROUND(ol.merchandise_value, 2) AS merchandise_value,
    ROUND(ol.freight_value, 2) AS freight_value,

    ROUND(
        ol.merchandise_value + ol.freight_value,
        2
    ) AS total_order_value,

    CASE
        WHEN ol.order_delivered_customer_date IS NOT NULL
         AND ol.order_delivered_customer_date >= ol.order_purchase_timestamp
        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        ol.order_delivered_customer_date
                        - ol.order_purchase_timestamp
                    )
                ) / 86400.0
            )::numeric,
            2
        )
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN ol.order_delivered_customer_date IS NULL
          OR ol.order_estimated_delivery_date IS NULL
            THEN NULL

        WHEN ol.order_delivered_customer_date
             > ol.order_estimated_delivery_date
            THEN 'Late'

        ELSE 'On Time / Early'
    END AS delivery_status,

    CASE
        WHEN ol.order_delivered_customer_date IS NOT NULL
         AND ol.order_estimated_delivery_date IS NOT NULL
        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        ol.order_delivered_customer_date
                        - ol.order_estimated_delivery_date
                    )
                ) / 86400.0
            )::numeric,
            2
        )
        ELSE NULL
    END AS days_vs_estimate,

    rs.average_review_score

FROM order_logistics ol

LEFT JOIN review_summary rs
    ON ol.order_id = rs.order_id;


    -- 45. Validate delivery performance view

SELECT
    COUNT(*) AS delivered_orders,
    COUNT(delivery_days) AS orders_with_valid_delivery_days,
    COUNT(average_review_score) AS reviewed_orders
FROM vw_delivery_performance;


-- 46. Validate shipping type distribution from delivery view

SELECT
    shipping_type,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct,
    ROUND(AVG(freight_value), 2) AS avg_freight_per_order,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM vw_delivery_performance
GROUP BY shipping_type
ORDER BY orders DESC;


-- 47. Create reusable customer state performance view

CREATE OR REPLACE VIEW vw_customer_state_performance AS

SELECT
    c.customer_state,

    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS merchandise_revenue,

    ROUND(
        SUM(oi.freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_order_value

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'

GROUP BY c.customer_state;


-- 48. Validate customer state performance view

SELECT
    COUNT(*) AS states,
    SUM(delivered_orders) AS delivered_orders,
    ROUND(SUM(merchandise_revenue), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(total_order_value), 2) AS total_order_value
FROM vw_customer_state_performance;


-- 49. Create reusable payment method performance view

CREATE OR REPLACE VIEW vw_payment_method_performance AS

SELECT
    op.payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT op.order_id) AS orders,

    ROUND(
        SUM(op.payment_value),
        2
    ) AS payment_value,

    ROUND(
        AVG(op.payment_installments),
        2
    ) AS average_installments

FROM order_payments op

JOIN orders o
    ON op.order_id = o.order_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'

GROUP BY op.payment_type;



-- 50. Validate payment method performance view

SELECT
    COUNT(*) AS payment_methods,
    SUM(payment_records) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM vw_payment_method_performance;


-- 51. Create reusable seller state performance view

CREATE OR REPLACE VIEW vw_seller_state_performance AS

SELECT
    s.seller_state,

    COUNT(DISTINCT s.seller_id) AS sellers,

    COUNT(DISTINCT o.order_id) AS orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(oi.price),
        2
    ) AS merchandise_revenue,

    ROUND(
        SUM(oi.freight_value),
        2
    ) AS freight_value,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_order_value

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN sellers s
    ON oi.seller_id = s.seller_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND o.order_status = 'delivered'

GROUP BY s.seller_state;



-- 52. Validate seller state performance view

SELECT
    COUNT(*) AS seller_states,
    SUM(sellers) AS active_sellers,
    SUM(items_sold) AS items_sold,
    ROUND(SUM(merchandise_revenue), 2) AS merchandise_revenue,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(total_order_value), 2) AS total_order_value
FROM vw_seller_state_performance;



SELECT
    current_database() AS database_name,
    current_setting('port') AS port;
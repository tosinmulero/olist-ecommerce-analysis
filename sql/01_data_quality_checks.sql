-- ============================================================
-- OLIST E-COMMERCE ANALYSIS
-- 01. DATA QUALITY & INTEGRITY CHECKS
-- ============================================================

-- 1. Verify row counts across all imported tables

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

-- 2. Check for null values in key customer fields

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_customer_unique_id,
    COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS null_customer_zip,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS null_customer_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_customer_state
FROM customers;

-- 3. Check for null values in order fields

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_timestamp,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_customer_delivery_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_delivery_date
FROM orders;

-- 4. Review order status distribution

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 5. Check missing order timestamps by order status

SELECT
    order_status,
    COUNT(*) AS order_count,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_customer_delivery_date
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 6. Inspect delivered orders with missing timestamps

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered'
  AND (
      order_approved_at IS NULL
      OR order_delivered_carrier_date IS NULL
      OR order_delivered_customer_date IS NULL
  )
ORDER BY order_purchase_timestamp;

-- 7. Check order_items for nulls and invalid numeric values

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS null_shipping_limit_date,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight_value,
    COUNT(*) FILTER (WHERE price <= 0) AS non_positive_price,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight
FROM order_items;

-- 8. Check order_payments for nulls and invalid values

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS null_payment_sequential,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_installments IS NULL) AS null_payment_installments,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value,
    COUNT(*) FILTER (WHERE payment_installments < 0) AS negative_installments,
    COUNT(*) FILTER (WHERE payment_value < 0) AS negative_payment_value
FROM order_payments;

-- 9. Check order_reviews for nulls and invalid review scores

SELECT
    COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score,
    COUNT(*) FILTER (WHERE review_score < 1 OR review_score > 5) AS invalid_review_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_review_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_review_message,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS null_review_creation_date,
    COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS null_review_answer_timestamp
FROM order_reviews;

-- 10. Check for blank review comments stored as empty strings

SELECT
    COUNT(*) FILTER (
        WHERE TRIM(COALESCE(review_comment_title, '')) = ''
    ) AS missing_review_title,

    COUNT(*) FILTER (
        WHERE TRIM(COALESCE(review_comment_message, '')) = ''
    ) AS missing_review_message
FROM order_reviews;

-- 11. Check products for missing attributes and invalid measurements

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (
        WHERE TRIM(COALESCE(product_category_name, '')) = ''
    ) AS missing_category,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_length,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_description_length,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photos_qty,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width,
    COUNT(*) FILTER (
        WHERE product_weight_g <= 0
           OR product_length_cm <= 0
           OR product_height_cm <= 0
           OR product_width_cm <= 0
    ) AS invalid_dimensions
FROM products;

-- 12. Check whether Portuguese product categories have English translations

SELECT
    COUNT(DISTINCT p.product_category_name) AS distinct_product_categories,
    COUNT(DISTINCT t.product_category_name) AS translated_categories,
    COUNT(DISTINCT p.product_category_name)
        - COUNT(DISTINCT t.product_category_name) AS untranslated_categories
FROM products p
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL;

-- 13. Identify product categories without English translations

SELECT DISTINCT
    p.product_category_name
FROM products p
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY p.product_category_name;

-- 14. Compare customer records with unique customers

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- 15. Identify repeat customers

SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count
    FROM customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customer_summary;

-- 16. Check for orders without matching customer records

SELECT
    COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 17. Check order_items foreign-key integrity

SELECT
    COUNT(*) FILTER (WHERE o.order_id IS NULL) AS items_without_order,
    COUNT(*) FILTER (WHERE p.product_id IS NULL) AS items_without_product,
    COUNT(*) FILTER (WHERE s.seller_id IS NULL) AS items_without_seller
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id;

    -- 18. Check payments and reviews foreign-key integrity

SELECT
    (SELECT COUNT(*)
     FROM order_payments op
     LEFT JOIN orders o
         ON op.order_id = o.order_id
     WHERE o.order_id IS NULL) AS payments_without_order,

    (SELECT COUNT(*)
     FROM order_reviews r
     LEFT JOIN orders o
         ON r.order_id = o.order_id
     WHERE o.order_id IS NULL) AS reviews_without_order;

     -- 19. Check for duplicate customer, order, product and seller IDs

SELECT
    (SELECT COUNT(*)
     FROM (
         SELECT customer_id
         FROM customers
         GROUP BY customer_id
         HAVING COUNT(*) > 1
     ) x) AS duplicate_customer_ids,

    (SELECT COUNT(*)
     FROM (
         SELECT order_id
         FROM orders
         GROUP BY order_id
         HAVING COUNT(*) > 1
     ) x) AS duplicate_order_ids,

    (SELECT COUNT(*)
     FROM (
         SELECT product_id
         FROM products
         GROUP BY product_id
         HAVING COUNT(*) > 1
     ) x) AS duplicate_product_ids,

    (SELECT COUNT(*)
     FROM (
         SELECT seller_id
         FROM sellers
         GROUP BY seller_id
         HAVING COUNT(*) > 1
     ) x) AS duplicate_seller_ids;

     -- 20. Check for illogical order timestamp sequences

SELECT
    COUNT(*) FILTER (
        WHERE order_approved_at < order_purchase_timestamp
    ) AS approved_before_purchase,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS customer_delivery_before_carrier,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_purchase_timestamp
    ) AS delivery_before_purchase
FROM orders;

-- 21. Investigate timestamp anomalies by order status

SELECT
    order_status,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS delivery_before_carrier
FROM orders
GROUP BY order_status
ORDER BY order_status;

-- 22. Measure the size of timestamp anomalies

SELECT
    ROUND(
        MIN(
            EXTRACT(EPOCH FROM (
                order_delivered_carrier_date - order_approved_at
            )) / 3600
        )::numeric,
        2
    ) AS min_carrier_vs_approval_hours,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                order_delivered_carrier_date - order_approved_at
            )) / 3600
        ) FILTER (
            WHERE order_delivered_carrier_date < order_approved_at
        )::numeric,
        2
    ) AS avg_carrier_vs_approval_hours,

    ROUND(
        MAX(
            EXTRACT(EPOCH FROM (
                order_delivered_carrier_date - order_approved_at
            )) / 3600
        ) FILTER (
            WHERE order_delivered_carrier_date < order_approved_at
        )::numeric,
        2
    ) AS max_carrier_vs_approval_hours,

    ROUND(
        MIN(
            EXTRACT(EPOCH FROM (
                order_delivered_customer_date - order_delivered_carrier_date
            ))
        ) FILTER (
            WHERE order_delivered_customer_date < order_delivered_carrier_date
        ) / 3600::numeric,
        2
    ) AS min_delivery_vs_carrier_hours
FROM orders;

-- 23. Quantify timestamp anomaly rates

SELECT
    COUNT(*) FILTER (
        WHERE order_approved_at IS NOT NULL
          AND order_delivered_carrier_date IS NOT NULL
    ) AS approval_carrier_eligible_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    ) AS carrier_before_approval_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_carrier_date < order_approved_at
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE order_approved_at IS NOT NULL
                  AND order_delivered_carrier_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS carrier_before_approval_pct,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NOT NULL
          AND order_delivered_customer_date IS NOT NULL
    ) AS carrier_delivery_eligible_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    ) AS delivery_before_carrier_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date < order_delivered_carrier_date
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE order_delivered_carrier_date IS NOT NULL
                  AND order_delivered_customer_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS delivery_before_carrier_pct
FROM orders;

-- 24. Check geolocation table for exact duplicate rows

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )) AS unique_rows
FROM geolocation;

-- 25. Check geolocation ZIP-code coverage

SELECT
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes,
    MIN(records_per_zip) AS min_records_per_zip,
    ROUND(AVG(records_per_zip), 2) AS avg_records_per_zip,
    MAX(records_per_zip) AS max_records_per_zip
FROM (
    SELECT
        geolocation_zip_code_prefix,
        COUNT(*) AS records_per_zip
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix
) AS zip_summary;

-- 26. Check customer and seller ZIP coverage in geolocation

SELECT
    (SELECT COUNT(*)
     FROM customers c
     LEFT JOIN (
         SELECT DISTINCT geolocation_zip_code_prefix
         FROM geolocation
     ) g
       ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
     WHERE g.geolocation_zip_code_prefix IS NULL
    ) AS customers_without_geolocation,

    (SELECT COUNT(*)
     FROM sellers s
     LEFT JOIN (
         SELECT DISTINCT geolocation_zip_code_prefix
         FROM geolocation
     ) g
       ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
     WHERE g.geolocation_zip_code_prefix IS NULL
    ) AS sellers_without_geolocation;

    -- 27. Check overall order date range

SELECT
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM orders;

-- 28. Check monthly order volume across the dataset

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_month
ORDER BY order_month;

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS order_count
FROM orders
WHERE order_purchase_timestamp >= '2017-07-01'
  AND order_purchase_timestamp < '2018-02-01'
GROUP BY order_month
ORDER BY order_month;

-- ============================================================
-- ANALYTICAL DATE-WINDOW DECISION
-- ============================================================

-- The raw order data spans September 2016 to October 2018.
-- However, the boundary periods contain very sparse order volumes.
--
-- For comparable monthly trend, revenue, and growth analysis,
-- use the period:
--
--     2017-01-01 through 2018-08-31
--
-- Records outside this period remain in the raw database and may
-- still be used where appropriate, but are excluded from normal
-- month-to-month trend comparisons.
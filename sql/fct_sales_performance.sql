CREATE OR REPLACE TABLE `crm_analytics.fct_sales_performance` AS

WITH orders_base AS (
SELECT
    order_id,
    user_id,
    status,
    DATE(created_at) AS data_compra,
    DATE(shipped_at) AS data_envio
FROM `bigquery-public-data.thelook_ecommerce.orders`
)

SELECT
    o.order_id,
    o.user_id,
    o.data_compra,
    o.data_envio,
    o.status,

    COUNT(oi.id) AS total_items,
    SUM(oi.sale_price) AS receita,

    DATE_DIFF(o.data_envio, o.data_compra, DAY) AS tempo_envio

FROM orders_base o
LEFT JOIN `bigquery-public-data.thelook_ecommerce.order_items` oi
ON o.order_id = oi.order_id

GROUP BY
    o.order_id,
    o.user_id,
    o.data_compra,
    o.data_envio,
    o.status

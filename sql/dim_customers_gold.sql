--CONSULTA SQL PARA CRIAÇÃO DA TABELA GOLD

CREATE OR REPLACE TABLE `crm_analytics.dim_customers_gold` AS

WITH users_clean AS (

SELECT
  id AS user_id,
  LOWER(TRIM(email)) AS email_tratado,
  UPPER(TRIM(gender)) AS genero_tratado,
  UPPER(TRIM(country)) AS pais_tratado,
  UPPER(TRIM(state)) AS estado_tratado,
  COALESCE(age, 0) AS idade_limpa,
  CAST(created_at AS TIMESTAMP) AS data_cadastro

FROM `bigquery-public-data.thelook_ecommerce.users`
),

orders_metrics AS (

SELECT
  o.user_id,
  MAX(o.created_at) AS ultima_compra,
  DATE_DIFF(CURRENT_DATE(),DATE(MAX(o.created_at)),DAY) AS dias_inativo,
  COUNT(DISTINCT o.order_id) AS total_pedidos,
  SUM(oi.sale_price) AS valor_total
FROM `bigquery-public-data.thelook_ecommerce.orders` o

LEFT JOIN `bigquery-public-data.thelook_ecommerce.order_items` oi
ON o.order_id = oi.order_id

GROUP BY o.user_id
)

SELECT
u.user_id,
u.email_tratado,
u.genero_tratado,
u.pais_tratado,
u.estado_tratado,
u.idade_limpa,
u.data_cadastro,
o.ultima_compra,
o.dias_inativo,
o.total_pedidos,
o.valor_total,

-- RECÊNCIA --
CASE
  WHEN total_pedidos IS NULL THEN 'Sem compra'
  WHEN dias_inativo <= 30 THEN 'Ativo'
  WHEN dias_inativo <= 90 THEN 'Em risco'
  WHEN dias_inativo > 90 THEN 'Churn'
END AS segmento_recencia,

-- FREQUÊNCIA--
CASE
  WHEN total_pedidos >= 3 THEN 'Muito recorrente'
  WHEN total_pedidos = 2 THEN 'Recorrente'
  WHEN total_pedidos = 1 THEN 'Compra única'
  ELSE 'Sem compra'
END AS segmento_frequencia,

-- MONETÁRIO --
CASE
  WHEN valor_total >= 180.39 THEN 'Premium'
  WHEN valor_total >= 89.5 THEN 'Alto valor'
  WHEN valor_total >= 41.25 THEN 'Médio valor'
  WHEN valor_total > 0 THEN 'Baixo valor'
  ELSE 'Sem compra'
END AS segmento_valor

FROM users_clean u
LEFT JOIN orders_metrics o
ON u.user_id = o.user_id

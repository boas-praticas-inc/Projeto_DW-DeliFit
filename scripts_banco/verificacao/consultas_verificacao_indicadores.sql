USE DeliFitDB;
GO

/*
   1. VENDAS DIARIAS
*/

SELECT data_venda,
       quantidade_pedidos,
       quantidade_itens_vendidos,
       faturamento_diario,
       ticket_medio_diario
FROM dw.agg_vendas_diarias
ORDER BY data_venda;
GO


/*
   2. VENDAS MENSAIS
*/

SELECT ano,
       mes,
       quantidade_pedidos,
       quantidade_itens_vendidos,
       faturamento_mensal,
       ticket_medio_mensal
FROM dw.agg_vendas_mensais
ORDER BY ano, mes;
GO


/*
   3. FATURAMENTO E TICKET MEDIO ANUAL
*/

SELECT ano,
       SUM(quantidade_pedidos) AS quantidade_pedidos,
       SUM(quantidade_itens_vendidos) AS quantidade_itens_vendidos,
       CAST(SUM(faturamento_mensal) AS DECIMAL(18,2)) AS faturamento_anual,
       CAST(
           SUM(faturamento_mensal) / NULLIF(SUM(quantidade_pedidos), 0)
           AS DECIMAL(18,2)
       ) AS ticket_medio_anual
FROM dw.agg_vendas_mensais
GROUP BY ano
ORDER BY ano;
GO


/*
   4. TICKET MEDIO GERAL
*/

WITH pedidos AS
(
    SELECT ft.pedido_id,
           SUM(ft.valor_total_item + ft.valor_frete_rateado) AS valor_total_pedido
    FROM dw.ft_venda AS ft
    INNER JOIN dw.dim_status AS ds
        ON ds.id_status = ft.id_status
    WHERE ds.status_pedido <> 'CANCELADO'
    GROUP BY ft.pedido_id
)
SELECT COUNT(*) AS quantidade_pedidos,
       CAST(SUM(valor_total_pedido) AS DECIMAL(18,2)) AS faturamento_total,
       CAST(AVG(valor_total_pedido) AS DECIMAL(18,2)) AS ticket_medio_geral
FROM pedidos;
GO


/*
   5. VENDAS POR RESTAURANTE
*/

SELECT r.restaurante_id,
       r.nome_fantasia,
       r.cidade,
       r.estado,
       a.quantidade_pedidos,
       a.quantidade_itens_vendidos,
       a.faturamento,
       a.ticket_medio
FROM dw.agg_vendas_restaurante AS a
INNER JOIN dw.dim_restaurante AS r
    ON r.id_restaurante = a.id_restaurante
ORDER BY a.faturamento DESC, a.quantidade_pedidos DESC;
GO


/*
   6. VENDAS POR CATEGORIA
*/

SELECT categoria,
       quantidade_itens_vendidos,
       receita_categoria,
       valor_medio_itens_vendidos
FROM dw.agg_vendas_categoria
ORDER BY receita_categoria DESC, quantidade_itens_vendidos DESC;
GO


/*
   7. PEDIDOS POR STATUS
*/

SELECT s.status_pedido,
       COUNT(*) AS quantidade_pedidos,
       CAST(
           100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0)
           AS DECIMAL(5,2)
       ) AS percentual_pedidos
FROM dw.vw_pedidos_analitico AS p
INNER JOIN dw.dim_status AS s
    ON s.id_status = p.id_status
GROUP BY s.status_pedido
ORDER BY quantidade_pedidos DESC, s.status_pedido;
GO


/*
   8. TAXA DE CANCELAMENTO
*/

SELECT COUNT(*) AS total_pedidos,
       SUM(CASE WHEN s.status_pedido = 'CANCELADO' THEN 1 ELSE 0 END) AS pedidos_cancelados,
       CAST(
           100.0 * SUM(CASE WHEN s.status_pedido = 'CANCELADO' THEN 1 ELSE 0 END)
           / NULLIF(COUNT(*), 0)
           AS DECIMAL(5,2)
       ) AS taxa_cancelamento_percentual
FROM dw.vw_pedidos_analitico AS p
INNER JOIN dw.dim_status AS s
    ON s.id_status = p.id_status;
GO


/*
   9. TEMPO MEDIO DE ENTREGA
*/

SELECT t.ano,
       t.mes,
       COUNT(*) AS pedidos_entregues,
       CAST(AVG(p.tempo_entrega_minutos) AS DECIMAL(10,2)) AS tempo_medio_entrega_minutos
FROM dw.vw_pedidos_analitico AS p
INNER JOIN dw.dim_tempo AS t
    ON t.id_tempo = p.id_tempo_criacao
WHERE p.tempo_entrega_minutos IS NOT NULL
GROUP BY t.ano, t.mes
ORDER BY ano, mes;
GO


/*
   10. CLIENTES CADASTRADOS
*/

SELECT COUNT(*) AS clientes_cadastrados
FROM dw.dim_cliente
WHERE registro_ativo = 1;
GO


/*
   11. CLIENTES QUE MAIS COMPRAM
*/

SELECT TOP (10)
       dc.cliente_id,
       u.nome AS nome_cliente,
       COUNT(DISTINCT ft.pedido_id) AS quantidade_pedidos,
       SUM(CONVERT(BIGINT, ft.quantidade)) AS quantidade_itens_comprados,
       CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)) AS valor_total_gasto
FROM dw.ft_venda AS ft
INNER JOIN dw.dim_cliente AS dc
    ON dc.id_cliente = ft.id_cliente
INNER JOIN dw.dim_status AS ds
    ON ds.id_status = ft.id_status
INNER JOIN oltp.clientes AS c
    ON c.cliente_id = dc.cliente_id
INNER JOIN oltp.usuarios AS u
    ON u.usuario_id = c.usuario_id
WHERE ds.status_pedido <> 'CANCELADO'
GROUP BY dc.cliente_id, u.nome
ORDER BY quantidade_pedidos DESC, valor_total_gasto DESC;
GO


/*
   12. CLIENTES QUE MAIS GASTAM
*/

SELECT TOP (10)
       dc.cliente_id,
       u.nome AS nome_cliente,
       COUNT(DISTINCT ft.pedido_id) AS quantidade_pedidos,
       CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)) AS valor_total_gasto,
       CAST(
           SUM(ft.valor_total_item + ft.valor_frete_rateado)
           / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
           AS DECIMAL(18,2)
       ) AS ticket_medio_cliente
FROM dw.ft_venda AS ft
INNER JOIN dw.dim_cliente AS dc
    ON dc.id_cliente = ft.id_cliente
INNER JOIN dw.dim_status AS ds
    ON ds.id_status = ft.id_status
INNER JOIN oltp.clientes AS c
    ON c.cliente_id = dc.cliente_id
INNER JOIN oltp.usuarios AS u
    ON u.usuario_id = c.usuario_id
WHERE ds.status_pedido <> 'CANCELADO'
GROUP BY dc.cliente_id, u.nome
ORDER BY valor_total_gasto DESC, quantidade_pedidos DESC;
GO


/*
   13. TICKET MEDIO POR CLIENTE
*/

SELECT dc.cliente_id,
       u.nome AS nome_cliente,
       COUNT(DISTINCT ft.pedido_id) AS quantidade_pedidos,
       CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)) AS valor_total_gasto,
       CAST(
           SUM(ft.valor_total_item + ft.valor_frete_rateado)
           / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
           AS DECIMAL(18,2)
       ) AS ticket_medio_cliente
FROM dw.ft_venda AS ft
INNER JOIN dw.dim_cliente AS dc
    ON dc.id_cliente = ft.id_cliente
INNER JOIN dw.dim_status AS ds
    ON ds.id_status = ft.id_status
INNER JOIN oltp.clientes AS c
    ON c.cliente_id = dc.cliente_id
INNER JOIN oltp.usuarios AS u
    ON u.usuario_id = c.usuario_id
WHERE ds.status_pedido <> 'CANCELADO'
GROUP BY dc.cliente_id, u.nome
ORDER BY ticket_medio_cliente DESC, valor_total_gasto DESC;
GO


/*
   14. ITENS MAIS VENDIDOS
*/

SELECT TOP (10)
       i.item_cardapio_id,
       i.nome AS nome_item,
       i.categoria,
       SUM(CONVERT(BIGINT, ft.quantidade)) AS quantidade_vendida,
       CAST(SUM(ft.valor_total_item) AS DECIMAL(18,2)) AS receita_item
FROM dw.ft_venda AS ft
INNER JOIN dw.dim_item AS i
    ON i.id_item = ft.id_item
INNER JOIN dw.dim_status AS ds
    ON ds.id_status = ft.id_status
WHERE ds.status_pedido <> 'CANCELADO'
GROUP BY i.item_cardapio_id, i.nome, i.categoria
ORDER BY quantidade_vendida DESC, receita_item DESC;
GO


/*
   15. PEDIDOS POR FORMA DE PAGAMENTO
*/

SELECT pg.forma_pagamento,
       COUNT(*) AS quantidade_pedidos,
       CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(5,2)) AS percentual_pedidos
FROM dw.vw_pedidos_analitico AS p
INNER JOIN dw.dim_pagamento AS pg
    ON pg.id_pagamento = p.id_pagamento
GROUP BY pg.forma_pagamento
ORDER BY quantidade_pedidos DESC, pg.forma_pagamento;
GO


/*
   16. TAXAS DE PAGAMENTO
*/

SELECT pg.status_pagamento,
       COUNT(*) AS quantidade_pedidos,
       CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(5,2)) AS percentual_pedidos
FROM dw.vw_pedidos_analitico AS p
INNER JOIN dw.dim_pagamento AS pg
    ON pg.id_pagamento = p.id_pagamento
GROUP BY pg.status_pagamento
ORDER BY quantidade_pedidos DESC, pg.status_pagamento;
GO

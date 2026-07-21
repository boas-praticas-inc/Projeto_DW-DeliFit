/* 06 - Views analiticas do DW */
USE DeliFitDB;
GO

/*
   A ft_venda permanece na granularidade de item do pedido.
   Esta view consolida os itens para uma linha por pedido e evita
   contar um mesmo pedido varias vezes nos indicadores de pedido.
*/
CREATE OR ALTER VIEW dw.vw_pedidos_analitico
AS
SELECT
    pedido_id,
    MAX(id_tempo) AS id_tempo_criacao,
    MAX(id_tempo_entrega) AS id_tempo_entrega,
    MAX(id_tempo_cancelamento) AS id_tempo_cancelamento,
    MAX(id_tempo_pagamento) AS id_tempo_pagamento,
    MAX(id_cliente) AS id_cliente,
    MAX(id_endereco) AS id_endereco,
    MAX(id_restaurante) AS id_restaurante,
    MAX(id_pagamento) AS id_pagamento,
    MAX(id_status) AS id_status,
    SUM(quantidade) AS quantidade_itens,
    CAST(SUM(valor_total_item + valor_frete_rateado) AS DECIMAL(18,2)) AS valor_total_pedido,
    MAX(tempo_entrega_minutos) AS tempo_entrega_minutos
FROM dw.ft_venda
GROUP BY pedido_id;
GO

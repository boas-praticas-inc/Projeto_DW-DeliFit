
USE DeliFitDB;
GO

CREATE OR ALTER PROCEDURE dw.sp_validar_staging
    @lote_execucao INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

    SELECT @lote_execucao = ISNULL(MAX(lote_execucao), 0) + 1
    FROM violacao.ft_venda_violacao WITH (TABLOCKX, HOLDLOCK);

    -- 1) cliente_id inexistente
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'Cliente referenciado não encontrado no staging',
           'cliente_id', CAST(p.cliente_id AS VARCHAR(50))
    FROM stg.stg_pedidos p
    LEFT JOIN stg.stg_clientes c ON c.cliente_id = p.cliente_id
    WHERE c.cliente_id IS NULL;

    -- 2) restaurante_id inexistente
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'Restaurante referenciado não encontrado no staging',
           'restaurante_id', CAST(p.restaurante_id AS VARCHAR(50))
    FROM stg.stg_pedidos p
    LEFT JOIN stg.stg_restaurantes r ON r.restaurante_id = p.restaurante_id
    WHERE r.restaurante_id IS NULL;

    -- 3) endereco_entrega_id inexistente
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'Endereço de entrega não encontrado no staging',
           'endereco_entrega_id', CAST(p.endereco_entrega_id AS VARCHAR(50))
    FROM stg.stg_pedidos p
    LEFT JOIN stg.stg_enderecos e ON e.endereco_id = p.endereco_entrega_id
    WHERE e.endereco_id IS NULL;

    -- 4) valor_total não bate com subtotal + frete
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'valor_total não corresponde a valor_subtotal + valor_frete',
           'valor_total', CAST(p.valor_total AS VARCHAR(50))
    FROM stg.stg_pedidos p
    WHERE ISNULL(p.valor_total, -1) <> ISNULL(p.valor_subtotal, 0) + ISNULL(p.valor_frete, 0);

    -- 5) pagamento marcado como PAGO sem data de pagamento
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'status_pagamento = PAGO sem pago_em preenchido',
           'pago_em', 'NULL'
    FROM stg.stg_pedidos p
    WHERE p.status_pagamento = 'PAGO' AND p.pago_em IS NULL;

    -- 6) pedido cancelado sem data de cancelamento
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, p.pedido_id, NULL,
           'status_pedido = CANCELADO sem cancelado_em preenchido',
           'cancelado_em', 'NULL'
    FROM stg.stg_pedidos p
    WHERE p.status_pedido = 'CANCELADO' AND p.cancelado_em IS NULL;

    -- 7) pedido_id inexistente (item órfão)
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, ip.pedido_id, ip.item_pedido_id,
           'Pedido referenciado pelo item não encontrado no staging',
           'pedido_id', CAST(ip.pedido_id AS VARCHAR(50))
    FROM stg.stg_itens_pedido ip
    LEFT JOIN stg.stg_pedidos p ON p.pedido_id = ip.pedido_id
    WHERE p.pedido_id IS NULL;

    -- 8) item_cardapio_id inexistente
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, ip.pedido_id, ip.item_pedido_id,
           'Item de cardápio referenciado não encontrado no staging',
           'item_cardapio_id', CAST(ip.item_cardapio_id AS VARCHAR(50))
    FROM stg.stg_itens_pedido ip
    LEFT JOIN stg.stg_itens_cardapio ic ON ic.item_cardapio_id = ip.item_cardapio_id
    WHERE ic.item_cardapio_id IS NULL;

    -- 9) valor_total_item não bate com preco_unitario_snapshot * quantidade
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, ip.pedido_id, ip.item_pedido_id,
           'valor_total_item não corresponde a preco_unitario_snapshot * quantidade',
           'valor_total_item', CAST(ip.valor_total_item AS VARCHAR(50))
    FROM stg.stg_itens_pedido ip
    WHERE ISNULL(ip.valor_total_item, -1) <> ISNULL(ip.preco_unitario_snapshot, 0) * ISNULL(ip.quantidade, 0);

    -- 10) quantidade inválida
    INSERT INTO violacao.ft_venda_violacao
        (lote_execucao, pedido_id, item_pedido_id, motivo, campo, valor_encontrado)
    SELECT @lote_execucao, ip.pedido_id, ip.item_pedido_id,
           'Quantidade deve ser maior que zero',
           'quantidade', CAST(ip.quantidade AS VARCHAR(50))
    FROM stg.stg_itens_pedido ip
    WHERE ip.quantidade IS NULL OR ip.quantidade <= 0;

    COMMIT TRANSACTION;

    SELECT @lote_execucao AS lote_execucao, COUNT(*) AS total_violacoes
    FROM violacao.ft_venda_violacao
    WHERE lote_execucao = @lote_execucao;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO



-- Consultar as violações do último lote
/*
SELECT * FROM violacao.ft_venda_violacao
WHERE lote_execucao = (SELECT MAX(lote_execucao) FROM violacao.ft_venda_violacao)
ORDER BY pedido_id, item_pedido_id;
*/
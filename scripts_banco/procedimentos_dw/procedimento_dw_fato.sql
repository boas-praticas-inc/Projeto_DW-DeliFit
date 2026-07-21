USE DeliFitDB;
GO

/*
   CARGA DA FATO VENDAS
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_ft_venda
    @lote_execucao INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @lote_execucao IS NULL
        THROW 51002, 'O lote de validacao deve ser informado.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            p.pedido_id,
            ip.item_pedido_id,
            t.id_tempo,
            te.id_tempo AS id_tempo_entrega,
            tc.id_tempo AS id_tempo_cancelamento,
            tp.id_tempo AS id_tempo_pagamento,
            c.id_cliente,
            e.id_endereco,
            r.id_restaurante,
            i.id_item,
            pg.id_pagamento,
            st.id_status,
            ip.quantidade,
            ip.preco_unitario_snapshot AS valor_unitario,
            ip.valor_total_item,
            CAST(
                CASE
                    WHEN p.valor_subtotal > 0
                        THEN p.valor_frete * ip.valor_total_item / p.valor_subtotal
                    ELSE 0
                END AS DECIMAL(10,2)
            ) AS valor_frete_rateado,
            CASE
                WHEN p.entregue_em IS NOT NULL
                    THEN DATEDIFF(MINUTE, p.criado_em, p.entregue_em)
                ELSE NULL
            END AS tempo_entrega_minutos
        INTO #candidatos
        FROM stg.stg_pedidos AS p
        INNER JOIN stg.stg_itens_pedido AS ip
            ON ip.pedido_id = p.pedido_id
        INNER JOIN dw.dim_tempo AS t
            ON t.data = CAST(p.criado_em AS DATE)
        LEFT JOIN dw.dim_tempo AS te
            ON te.data = CAST(p.entregue_em AS DATE)
        LEFT JOIN dw.dim_tempo AS tc
            ON tc.data = CAST(p.cancelado_em AS DATE)
        LEFT JOIN dw.dim_tempo AS tp
            ON tp.data = CAST(p.pago_em AS DATE)
        CROSS APPLY
        (
            SELECT TOP (1) d.id_cliente
            FROM dw.dim_cliente AS d
            WHERE d.cliente_id = p.cliente_id
              AND d.data_inicio <= p.criado_em
              AND (d.data_fim IS NULL OR p.criado_em < d.data_fim)
            ORDER BY d.data_inicio DESC
        ) AS c
        CROSS APPLY
        (
            SELECT TOP (1) d.id_endereco
            FROM dw.dim_endereco AS d
            WHERE d.endereco_id = p.endereco_entrega_id
              AND d.data_inicio <= p.criado_em
              AND (d.data_fim IS NULL OR p.criado_em < d.data_fim)
            ORDER BY d.data_inicio DESC
        ) AS e
        CROSS APPLY
        (
            SELECT TOP (1) d.id_restaurante
            FROM dw.dim_restaurante AS d
            WHERE d.restaurante_id = p.restaurante_id
              AND d.data_inicio <= p.criado_em
              AND (d.data_fim IS NULL OR p.criado_em < d.data_fim)
            ORDER BY d.data_inicio DESC
        ) AS r
        CROSS APPLY
        (
            SELECT TOP (1) d.id_item
            FROM dw.dim_item AS d
            WHERE d.item_cardapio_id = ip.item_cardapio_id
              AND d.data_inicio <= p.criado_em
              AND (d.data_fim IS NULL OR p.criado_em < d.data_fim)
            ORDER BY d.data_inicio DESC
        ) AS i
        INNER JOIN dw.dim_pagamento AS pg
            ON pg.forma_pagamento = p.forma_pagamento
           AND pg.status_pagamento = p.status_pagamento
        INNER JOIN dw.dim_status AS st
            ON st.status_pedido = p.status_pedido
        WHERE p.criado_em IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM violacao.ft_venda_violacao AS v
              WHERE v.lote_execucao = @lote_execucao
                AND v.pedido_id = p.pedido_id
                AND (
                    v.item_pedido_id IS NULL
                    OR v.item_pedido_id = ip.item_pedido_id
                )
          );

        /* Atualiza linhas já existentes quando o pedido muda de status,
           pagamento ou recebe a data de entrega/cancelamento. */
        UPDATE f
        SET f.id_tempo = c.id_tempo,
            f.id_tempo_entrega = c.id_tempo_entrega,
            f.id_tempo_cancelamento = c.id_tempo_cancelamento,
            f.id_tempo_pagamento = c.id_tempo_pagamento,
            f.id_cliente = c.id_cliente,
            f.id_endereco = c.id_endereco,
            f.id_restaurante = c.id_restaurante,
            f.id_item = c.id_item,
            f.id_pagamento = c.id_pagamento,
            f.id_status = c.id_status,
            f.quantidade = c.quantidade,
            f.valor_unitario = c.valor_unitario,
            f.valor_total_item = c.valor_total_item,
            f.valor_frete_rateado = c.valor_frete_rateado,
            f.tempo_entrega_minutos = c.tempo_entrega_minutos
        FROM dw.ft_venda AS f
        INNER JOIN #candidatos AS c
            ON c.item_pedido_id = f.item_pedido_id;

        DECLARE @linhas_atualizadas INT = @@ROWCOUNT;

        INSERT INTO dw.ft_venda
        (
            id_tempo,
            id_tempo_entrega,
            id_tempo_cancelamento,
            id_tempo_pagamento,
            id_cliente,
            id_endereco,
            id_restaurante,
            id_item,
            id_pagamento,
            id_status,
            pedido_id,
            item_pedido_id,
            quantidade,
            valor_unitario,
            valor_total_item,
            valor_frete_rateado,
            tempo_entrega_minutos
        )
        SELECT
            c.id_tempo,
            c.id_tempo_entrega,
            c.id_tempo_cancelamento,
            c.id_tempo_pagamento,
            c.id_cliente,
            c.id_endereco,
            c.id_restaurante,
            c.id_item,
            c.id_pagamento,
            c.id_status,
            c.pedido_id,
            c.item_pedido_id,
            c.quantidade,
            c.valor_unitario,
            c.valor_total_item,
            c.valor_frete_rateado,
            c.tempo_entrega_minutos
        FROM #candidatos AS c
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dw.ft_venda AS f WITH (UPDLOCK, HOLDLOCK)
            WHERE f.item_pedido_id = c.item_pedido_id
        );

        DECLARE @linhas_carregadas INT = @@ROWCOUNT;

        DROP TABLE #candidatos;

        COMMIT TRANSACTION;

        SELECT @linhas_carregadas AS linhas_carregadas,
               @linhas_atualizadas AS linhas_atualizadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

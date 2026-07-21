USE DeliFitDB;
GO

/*
   CARGA DA FATO VENDAS
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_ft_venda
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH candidatos AS
        (
            SELECT
                p.pedido_id,
                ip.item_pedido_id,
                t.id_tempo,
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
                ) AS valor_frete_rateado
            FROM stg.stg_pedidos AS p
            INNER JOIN stg.stg_itens_pedido AS ip
                ON ip.pedido_id = p.pedido_id
            INNER JOIN dw.dim_tempo AS t
                ON t.data = CAST(p.criado_em AS DATE)
            INNER JOIN dw.dim_cliente AS c
                ON c.cliente_id = p.cliente_id
               AND c.registro_ativo = 1
            INNER JOIN dw.dim_endereco AS e
                ON e.endereco_id = p.endereco_entrega_id
               AND e.registro_ativo = 1
            INNER JOIN dw.dim_restaurante AS r
                ON r.restaurante_id = p.restaurante_id
               AND r.registro_ativo = 1
            INNER JOIN dw.dim_item AS i
                ON i.item_cardapio_id = ip.item_cardapio_id
               AND i.registro_ativo = 1
            INNER JOIN dw.dim_pagamento AS pg
                ON pg.forma_pagamento = p.forma_pagamento
               AND pg.status_pagamento = p.status_pagamento
            INNER JOIN dw.dim_status AS st
                ON st.status_pedido = p.status_pedido
            WHERE p.criado_em IS NOT NULL
              AND p.valor_subtotal IS NOT NULL
              AND p.valor_frete IS NOT NULL
              AND p.valor_total = p.valor_subtotal + p.valor_frete
              AND ip.preco_unitario_snapshot IS NOT NULL
              AND ip.quantidade > 0
              AND ip.valor_total_item = ip.preco_unitario_snapshot * ip.quantidade
        )
        INSERT INTO dw.ft_venda
        (
            id_tempo,
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
            valor_frete_rateado
        )
        SELECT
            c.id_tempo,
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
            c.valor_frete_rateado
        FROM candidatos AS c
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dw.ft_venda AS f WITH (UPDLOCK, HOLDLOCK)
            WHERE f.item_pedido_id = c.item_pedido_id
        );

        DECLARE @linhas_carregadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @linhas_carregadas AS linhas_carregadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


/* ETL:
   EXEC stg.sp_extrair_staging_completo;
   EXEC dw.sp_validar_staging;
   EXEC dw.sp_carregar_dimensoes;
   EXEC dw.sp_carregar_ft_venda;
   EXEC dw.sp_carga_agregados;
*/

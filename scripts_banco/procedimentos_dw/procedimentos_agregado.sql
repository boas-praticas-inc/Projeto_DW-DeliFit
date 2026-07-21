USE DeliFitDB;
GO

/*
   1. CARGA DE VENDAS DIÁRIAS
*/
CREATE OR ALTER PROCEDURE dw.sp_carga_agg_vendas_diarias
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dw.agg_vendas_diarias;

        INSERT INTO dw.agg_vendas_diarias
        (
            id_tempo,
            data_venda,
            quantidade_pedidos,
            quantidade_itens_vendidos,
            faturamento_diario,
            ticket_medio_diario,
            data_carga
        )
        SELECT
            ft.id_tempo,
            dt.data,
            COUNT(DISTINCT ft.pedido_id),
            SUM(CONVERT(BIGINT, ft.quantidade)),
            CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)),
            CAST(
                SUM(ft.valor_total_item + ft.valor_frete_rateado)
                / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
                AS DECIMAL(18,2)
            ),
            SYSDATETIME()
        FROM dw.ft_venda AS ft
        INNER JOIN dw.dim_tempo AS dt
            ON dt.id_tempo = ft.id_tempo
        GROUP BY
            ft.id_tempo,
            dt.data;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*
    2.CARGA DE VENDAS MENSAIS
 */

CREATE OR ALTER PROCEDURE dw.sp_carga_agg_vendas_mensais
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dw.agg_vendas_mensais;

        INSERT INTO dw.agg_vendas_mensais
        (
            ano,
            mes,
            quantidade_pedidos,
            quantidade_itens_vendidos,
            faturamento_mensal,
            ticket_medio_mensal,
            data_carga
        )
        SELECT
            dt.ano,
            dt.mes,
            COUNT(DISTINCT ft.pedido_id),
            SUM(CONVERT(BIGINT, ft.quantidade)),
            CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)),
            CAST(
                SUM(ft.valor_total_item + ft.valor_frete_rateado)
                / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
                AS DECIMAL(18,2)
            ),
            SYSDATETIME()
        FROM dw.ft_venda AS ft
        INNER JOIN dw.dim_tempo AS dt
            ON dt.id_tempo = ft.id_tempo
        GROUP BY
            dt.ano,
            dt.mes;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*
    3.CARGA DE VENDAS POR RESTAURANTE
*/

CREATE OR ALTER PROCEDURE dw.sp_carga_agg_vendas_restaurante
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dw.agg_vendas_restaurante;

        INSERT INTO dw.agg_vendas_restaurante
        (
            id_restaurante,
            quantidade_pedidos,
            quantidade_itens_vendidos,
            faturamento,
            ticket_medio,
            data_carga
        )
        SELECT
            ft.id_restaurante,
            COUNT(DISTINCT ft.pedido_id),
            SUM(CONVERT(BIGINT, ft.quantidade)),
            CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)),
            CAST(
                SUM(ft.valor_total_item + ft.valor_frete_rateado)
                / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
                AS DECIMAL(18,2)
            ),
            SYSDATETIME()
        FROM dw.ft_venda AS ft
        GROUP BY
            ft.id_restaurante;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*
    4.CARGA DE VENDAS POR CATEGORIA
*/

CREATE OR ALTER PROCEDURE dw.sp_carga_agg_vendas_categoria
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dw.agg_vendas_categoria;

        INSERT INTO dw.agg_vendas_categoria
        (
            categoria,
            quantidade_itens_vendidos,
            receita_categoria,
            valor_medio_itens_vendidos,
            data_carga
        )
        SELECT
            COALESCE(NULLIF(LTRIM(RTRIM(di.categoria)), ''), 'SEM CATEGORIA'),
            SUM(CONVERT(BIGINT, ft.quantidade)),
            CAST(SUM(ft.valor_total_item) AS DECIMAL(18,2)),
            CAST(
                SUM(ft.valor_total_item)
                / NULLIF(SUM(CONVERT(DECIMAL(18,2), ft.quantidade)), 0)
                AS DECIMAL(18,2)
            ),
            SYSDATETIME()
        FROM dw.ft_venda AS ft
        INNER JOIN dw.dim_item AS di
            ON di.id_item = ft.id_item
        GROUP BY
            COALESCE(NULLIF(LTRIM(RTRIM(di.categoria)), ''), 'SEM CATEGORIA');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*
    5.CARGA DE VENDAS POR CLIENTE
*/

CREATE OR ALTER PROCEDURE dw.sp_carga_agg_vendas_cliente
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE dw.agg_vendas_cliente;

        INSERT INTO dw.agg_vendas_cliente
        (
            id_cliente,
            quantidade_pedidos,
            quantidade_itens_comprados,
            valor_total_gasto,
            ticket_medio_cliente,
            data_carga
        )
        SELECT
            ft.id_cliente,
            COUNT(DISTINCT ft.pedido_id),
            SUM(CONVERT(BIGINT, ft.quantidade)),
            CAST(SUM(ft.valor_total_item + ft.valor_frete_rateado) AS DECIMAL(18,2)),
            CAST(
                SUM(ft.valor_total_item + ft.valor_frete_rateado)
                / NULLIF(COUNT(DISTINCT ft.pedido_id), 0)
                AS DECIMAL(18,2)
            ),
            SYSDATETIME()
        FROM dw.ft_venda AS ft
        GROUP BY
            ft.id_cliente;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*
   CARGA DE TODOS OS AGREGADOS
*/

CREATE OR ALTER PROCEDURE dw.sp_carga_agregados
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dw.sp_carga_agg_vendas_diarias;
    EXEC dw.sp_carga_agg_vendas_mensais;
    EXEC dw.sp_carga_agg_vendas_restaurante;
    EXEC dw.sp_carga_agg_vendas_categoria;
    EXEC dw.sp_carga_agg_vendas_cliente;
END;
GO




 EXEC dw.sp_carga_agregados;



SELECT * FROM dw.agg_vendas_diarias ORDER BY data_venda;
SELECT * FROM dw.agg_vendas_mensais ORDER BY ano, mes;
SELECT * FROM dw.agg_vendas_restaurante ORDER BY faturamento DESC;
SELECT * FROM dw.agg_vendas_categoria ORDER BY receita_categoria DESC;
SELECT * FROM dw.agg_vendas_cliente ORDER BY valor_total_gasto DESC;

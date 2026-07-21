/* Executa o fluxo completo do ETL do DeliFit. */
USE DeliFitDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

EXEC stg.sp_extrair_staging_completo;
DECLARE @lote_execucao INT;
EXEC dw.sp_validar_staging @lote_execucao = @lote_execucao OUTPUT;
EXEC dw.sp_carregar_dimensoes;
EXEC dw.sp_carregar_ft_venda @lote_execucao = @lote_execucao;
EXEC dw.sp_carga_agregados;
GO

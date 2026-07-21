/* Executa o fluxo completo do ETL do DeliFit. */
USE DeliFitDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

EXEC stg.sp_extrair_staging_completo;
EXEC dw.sp_validar_staging;
EXEC dw.sp_carregar_dimensoes;
EXEC dw.sp_carregar_ft_venda;
EXEC dw.sp_carga_agregados;
GO

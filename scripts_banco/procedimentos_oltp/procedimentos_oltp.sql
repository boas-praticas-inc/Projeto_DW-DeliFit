/*
   Procedures de extração: oltp -> stg - full load.
*/
USE DeliFitDB;
GO

/*
   1. SP_EXTRAIR_STG_USUARIO
   oltp.usuarios -> stg.stg_usuarios
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_usuario
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_usuarios;

    INSERT INTO stg.stg_usuarios
    (
        usuario_id, nome, email, telefone,
        tipo_usuario, ativo, data_cadastro
    )
    SELECT
        usuario_id, nome, email, telefone,
        tipo_usuario, ativo, data_cadastro
    FROM oltp.usuarios;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   2. SP_EXTRAIR_STG_CLIENTE
   oltp.clientes -> stg.stg_clientes
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_cliente
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_clientes;

    INSERT INTO stg.stg_clientes
    (
        cliente_id, usuario_id, data_nascimento
    )
    SELECT
        cliente_id, usuario_id, data_nascimento
    FROM oltp.clientes;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   3. SP_EXTRAIR_STG_ENDERECO
   oltp.enderecos -> stg.stg_enderecos
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_endereco
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_enderecos;

    INSERT INTO stg.stg_enderecos
    (
        endereco_id, cliente_id, nome_endereco, cep, logradouro,
        numero, complemento, bairro, cidade, estado,
        endereco_principal, ativo
    )
    SELECT
        endereco_id, cliente_id, nome_endereco, cep, logradouro,
        numero, complemento, bairro, cidade, estado,
        endereco_principal, ativo
    FROM oltp.enderecos;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   4. SP_EXTRAIR_STG_RESTAURANTE
   oltp.restaurantes -> stg.stg_restaurantes
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_restaurante
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_restaurantes;

    INSERT INTO stg.stg_restaurantes
    (
        restaurante_id, usuario_id, nome_fantasia, cnpj, descricao,
        telefone, cep, logradouro, numero, complemento,
        bairro, cidade, estado, ativo, data_cadastro
    )
    SELECT
        restaurante_id, usuario_id, nome_fantasia, cnpj, descricao,
        telefone, cep, logradouro, numero, complemento,
        bairro, cidade, estado, ativo, data_cadastro
    FROM oltp.restaurantes;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   5. SP_EXTRAIR_STG_CATEGORIA_CARDAPIO
   oltp.categorias_cardapio -> stg.stg_categorias_cardapio
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_categoria_cardapio
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_categorias_cardapio;

    INSERT INTO stg.stg_categorias_cardapio
    (
        categoria_id, nome, descricao, ativo
    )
    SELECT
        categoria_id, nome, descricao, ativo
    FROM oltp.categorias_cardapio;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   6. SP_EXTRAIR_STG_ITEM_CARDAPIO
   oltp.itens_cardapio -> stg.stg_itens_cardapio
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_item_cardapio
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_itens_cardapio;

    INSERT INTO stg.stg_itens_cardapio
    (
        item_cardapio_id, restaurante_id, categoria_id, nome, descricao,
        preco, calorias, proteinas, carboidratos, gorduras,
        restricao_alimentar, disponivel, data_cadastro
    )
    SELECT
        item_cardapio_id, restaurante_id, categoria_id, nome, descricao,
        preco, calorias, proteinas, carboidratos, gorduras,
        restricao_alimentar, disponivel, data_cadastro
    FROM oltp.itens_cardapio;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   7. SP_EXTRAIR_STG_PEDIDO
   oltp.pedidos -> stg.stg_pedidos
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_pedido
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_pedidos;

    INSERT INTO stg.stg_pedidos
    (
        pedido_id, cliente_id, restaurante_id, endereco_entrega_id,
        status_pedido, forma_pagamento, status_pagamento,
        valor_subtotal, valor_frete, valor_total, observacao,
        criado_em, confirmado_em, entregue_em, cancelado_em, pago_em
    )
    SELECT
        pedido_id, cliente_id, restaurante_id, endereco_entrega_id,
        status_pedido, forma_pagamento, status_pagamento,
        valor_subtotal, valor_frete, valor_total, observacao,
        criado_em, confirmado_em, entregue_em, cancelado_em, pago_em
    FROM oltp.pedidos;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   8. SP_EXTRAIR_STG_ITEM_PEDIDO
   oltp.itens_pedido -> stg.stg_itens_pedido
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_stg_item_pedido
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.stg_itens_pedido;

    INSERT INTO stg.stg_itens_pedido
    (
        item_pedido_id, pedido_id, item_cardapio_id,
        nome_item_snapshot, descricao_snapshot, preco_unitario_snapshot,
        quantidade, valor_total_item
    )
    SELECT
        item_pedido_id, pedido_id, item_cardapio_id,
        nome_item_snapshot, descricao_snapshot, preco_unitario_snapshot,
        quantidade, valor_total_item
    FROM oltp.itens_pedido;

    SELECT @@ROWCOUNT AS linhas_extraidas;
END;
GO

/*
   9. SP_EXTRAIR_STAGING_COMPLETO
*/

CREATE OR ALTER PROCEDURE stg.sp_extrair_staging_completo
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC stg.sp_extrair_stg_usuario;
        EXEC stg.sp_extrair_stg_cliente;
        EXEC stg.sp_extrair_stg_endereco;
        EXEC stg.sp_extrair_stg_restaurante;
        EXEC stg.sp_extrair_stg_categoria_cardapio;
        EXEC stg.sp_extrair_stg_item_cardapio;
        EXEC stg.sp_extrair_stg_pedido;
        EXEC stg.sp_extrair_stg_item_pedido;

        COMMIT TRANSACTION;

        PRINT 'Extração para staging concluída com sucesso.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

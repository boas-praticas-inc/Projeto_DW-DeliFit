
USE DeliFitDB;
GO

/*
   1. SP_CARREGAR_DIM_RESTAURANTE (SCD2)
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_restaurante
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @agora DATETIME = SYSDATETIME();

    DECLARE @alterados TABLE (restaurante_id BIGINT PRIMARY KEY);

    INSERT INTO @alterados (restaurante_id)
    SELECT s.restaurante_id
    FROM stg.stg_restaurantes s
    JOIN dw.dim_restaurante d
        ON d.restaurante_id = s.restaurante_id
       AND d.registro_ativo = 1
    WHERE d.nome_fantasia <> s.nome_fantasia
       OR ISNULL(d.cidade, '')                        <> ISNULL(s.cidade, '')
       OR ISNULL(d.estado, '')                         <> ISNULL(s.estado, '')
       OR ISNULL(d.data_cadastro, '19000101')          <> ISNULL(CAST(s.data_cadastro AS DATE), '19000101')
       OR d.ativo <> s.ativo;

    UPDATE d
    SET data_fim = @agora, registro_ativo = 0
    FROM dw.dim_restaurante d
    JOIN @alterados a ON a.restaurante_id = d.restaurante_id
    WHERE d.registro_ativo = 1;

    INSERT INTO dw.dim_restaurante
        (restaurante_id, nome_fantasia, cidade, estado, data_cadastro, ativo,
         data_inicio, data_fim, registro_ativo)
    SELECT
        s.restaurante_id, s.nome_fantasia, s.cidade, s.estado,
        CAST(s.data_cadastro AS DATE), s.ativo,
        @agora, NULL, 1
    FROM stg.stg_restaurantes s
    WHERE s.restaurante_id IN (SELECT restaurante_id FROM @alterados)
       OR NOT EXISTS (
            SELECT 1 FROM dw.dim_restaurante d WHERE d.restaurante_id = s.restaurante_id
          );

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   2. SP_CARREGAR_DIM_CLIENTE (SCD2)
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_cliente
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @agora DATETIME = SYSDATETIME();

    -- Monta a origem já com idade/faixa_etaria calculadas
    ;WITH origem AS (
        SELECT
            c.cliente_id,
            CASE
                WHEN (MONTH(c.data_nascimento) > MONTH(GETDATE()))
                  OR (MONTH(c.data_nascimento) = MONTH(GETDATE()) AND DAY(c.data_nascimento) > DAY(GETDATE()))
                THEN DATEDIFF(YEAR, c.data_nascimento, GETDATE()) - 1
                ELSE DATEDIFF(YEAR, c.data_nascimento, GETDATE())
            END AS idade,
            CAST(u.data_cadastro AS DATE) AS data_cadastro
        FROM stg.stg_clientes c
        JOIN stg.stg_usuarios u ON u.usuario_id = c.usuario_id
        WHERE c.data_nascimento IS NOT NULL
    ),
    origem_final AS (
        SELECT
            cliente_id,
            idade,
            CASE
                WHEN idade BETWEEN 18 AND 25 THEN '18-25'
                WHEN idade BETWEEN 26 AND 35 THEN '26-35'
                WHEN idade BETWEEN 36 AND 45 THEN '36-45'
                WHEN idade BETWEEN 46 AND 60 THEN '46-60'
                WHEN idade > 60               THEN '60+'
                ELSE 'Não informado'
            END AS faixa_etaria,
            data_cadastro
        FROM origem
    )

    SELECT cliente_id, idade, faixa_etaria, data_cadastro
    INTO #origem_cliente
    FROM origem_final;

    DECLARE @alterados TABLE (cliente_id BIGINT PRIMARY KEY);

    INSERT INTO @alterados (cliente_id)
    SELECT o.cliente_id
    FROM #origem_cliente o
    JOIN dw.dim_cliente d
        ON d.cliente_id = o.cliente_id
       AND d.registro_ativo = 1
    WHERE ISNULL(d.faixa_etaria, '')       <> ISNULL(o.faixa_etaria, '')
       OR ISNULL(d.idade, -1)              <> ISNULL(o.idade, -1)
       OR ISNULL(d.data_cadastro, '19000101') <> ISNULL(o.data_cadastro, '19000101');

    UPDATE d
    SET data_fim = @agora, registro_ativo = 0
    FROM dw.dim_cliente d
    JOIN @alterados a ON a.cliente_id = d.cliente_id
    WHERE d.registro_ativo = 1;

    INSERT INTO dw.dim_cliente
        (cliente_id, faixa_etaria, idade, data_cadastro, data_inicio, data_fim, registro_ativo)
    SELECT
        o.cliente_id, o.faixa_etaria, o.idade, o.data_cadastro,
        @agora, NULL, 1
    FROM #origem_cliente o
    WHERE o.cliente_id IN (SELECT cliente_id FROM @alterados)
       OR NOT EXISTS (
            SELECT 1 FROM dw.dim_cliente d WHERE d.cliente_id = o.cliente_id
          );

    DROP TABLE #origem_cliente;

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   3. SP_CARREGAR_DIM_ENDERECO (SCD2)
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_endereco
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @agora DATETIME = SYSDATETIME();

    DECLARE @alterados TABLE (endereco_id BIGINT PRIMARY KEY);

    INSERT INTO @alterados (endereco_id)
    SELECT s.endereco_id
    FROM stg.stg_enderecos s
    JOIN dw.dim_endereco d
        ON d.endereco_id = s.endereco_id
       AND d.registro_ativo = 1
    WHERE ISNULL(d.cep, '')          <> ISNULL(s.cep, '')
       OR ISNULL(d.logradouro, '')   <> ISNULL(s.logradouro, '')
       OR ISNULL(d.bairro, '')       <> ISNULL(s.bairro, '')
       OR ISNULL(d.numero, '')       <> ISNULL(s.numero, '')
       OR ISNULL(d.cidade, '')       <> ISNULL(s.cidade, '')
       OR ISNULL(d.estado, '')       <> ISNULL(s.estado, '')
       OR ISNULL(d.complemento, '')  <> ISNULL(s.complemento, '');

    UPDATE d
    SET data_fim = @agora, registro_ativo = 0
    FROM dw.dim_endereco d
    JOIN @alterados a ON a.endereco_id = d.endereco_id
    WHERE d.registro_ativo = 1;

    INSERT INTO dw.dim_endereco
        (endereco_id, cep, logradouro, bairro, numero, cidade, estado, complemento,
         data_inicio, data_fim, registro_ativo)
    SELECT
        s.endereco_id, s.cep, s.logradouro, s.bairro, s.numero, s.cidade, s.estado, s.complemento,
        @agora, NULL, 1
    FROM stg.stg_enderecos s
    WHERE s.endereco_id IN (SELECT endereco_id FROM @alterados)
       OR NOT EXISTS (
            SELECT 1 FROM dw.dim_endereco d WHERE d.endereco_id = s.endereco_id
          );

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   4. SP_CARREGAR_DIM_ITEM (SCD2)
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_item
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @agora DATETIME = SYSDATETIME();

    SELECT
        i.item_cardapio_id,
        i.nome,
        cat.nome AS categoria,
        i.calorias,
        i.proteinas,
        i.carboidratos,
        i.gorduras,
        i.restricao_alimentar,
        CASE
            WHEN i.preco <= 15 THEN 'Até R$15'
            WHEN i.preco <= 30 THEN 'R$15-30'
            WHEN i.preco <= 50 THEN 'R$30-50'
            ELSE 'Acima de R$50'
        END AS faixa_preco,
        i.disponivel,
        i.preco AS preco_atual
    INTO #origem_item
    FROM stg.stg_itens_cardapio i
    LEFT JOIN stg.stg_categorias_cardapio cat
        ON cat.categoria_id = i.categoria_id;

    DECLARE @alterados TABLE (item_cardapio_id BIGINT PRIMARY KEY);

    INSERT INTO @alterados (item_cardapio_id)
    SELECT o.item_cardapio_id
    FROM #origem_item o
    JOIN dw.dim_item d
        ON d.item_cardapio_id = o.item_cardapio_id
       AND d.registro_ativo = 1
    WHERE d.nome <> o.nome
       OR ISNULL(d.categoria, '')             <> ISNULL(o.categoria, '')
       OR ISNULL(d.calorias, -1)              <> ISNULL(o.calorias, -1)
       OR ISNULL(d.proteinas, -1)             <> ISNULL(o.proteinas, -1)
       OR ISNULL(d.carboidratos, -1)          <> ISNULL(o.carboidratos, -1)
       OR ISNULL(d.gorduras, -1)              <> ISNULL(o.gorduras, -1)
       OR ISNULL(d.restricao_alimentar, '')   <> ISNULL(o.restricao_alimentar, '')
       OR d.faixa_preco <> o.faixa_preco
       OR d.disponivel <> o.disponivel
       OR ISNULL(d.preco_atual, -1)           <> ISNULL(o.preco_atual, -1);

    UPDATE d
    SET data_fim = @agora, registro_ativo = 0
    FROM dw.dim_item d
    JOIN @alterados a ON a.item_cardapio_id = d.item_cardapio_id
    WHERE d.registro_ativo = 1;

    INSERT INTO dw.dim_item
        (item_cardapio_id, nome, categoria, calorias, proteinas, carboidratos, gorduras,
         restricao_alimentar, faixa_preco, disponivel, preco_atual,
         data_inicio, data_fim, registro_ativo)
    SELECT
        o.item_cardapio_id, o.nome, o.categoria, o.calorias, o.proteinas, o.carboidratos, o.gorduras,
        o.restricao_alimentar, o.faixa_preco, o.disponivel, o.preco_atual,
        @agora, NULL, 1
    FROM #origem_item o
    WHERE o.item_cardapio_id IN (SELECT item_cardapio_id FROM @alterados)
       OR NOT EXISTS (
            SELECT 1 FROM dw.dim_item d WHERE d.item_cardapio_id = o.item_cardapio_id
          );

    DROP TABLE #origem_item;

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   5. SP_CARREGAR_DIM_PAGAMENTO
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_pagamento
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.dim_pagamento (forma_pagamento, status_pagamento)
    SELECT DISTINCT s.forma_pagamento, s.status_pagamento
    FROM stg.stg_pedidos s
    WHERE s.forma_pagamento IS NOT NULL
      AND s.status_pagamento IS NOT NULL
      AND NOT EXISTS (
            SELECT 1 FROM dw.dim_pagamento d
            WHERE d.forma_pagamento = s.forma_pagamento
              AND d.status_pagamento = s.status_pagamento
          );

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   6. SP_CARREGAR_DIM_STATUS (Tipo 0)
  */

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_status
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.dim_status (status_pedido)
    SELECT DISTINCT s.status_pedido
    FROM stg.stg_pedidos s
    WHERE s.status_pedido IS NOT NULL
      AND NOT EXISTS (
            SELECT 1 FROM dw.dim_status d WHERE d.status_pedido = s.status_pedido
          );

    SELECT @@ROWCOUNT AS linhas_afetadas;
END;
GO

/*
   7. SP_CARREGAR_DIMENSOES
*/

CREATE OR ALTER PROCEDURE dw.sp_carregar_dimensoes
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC dw.sp_carregar_dim_restaurante;
        EXEC dw.sp_carregar_dim_pagamento;
        EXEC dw.sp_carregar_dim_status;
        EXEC dw.sp_carregar_dim_cliente;
        EXEC dw.sp_carregar_dim_endereco;
        EXEC dw.sp_carregar_dim_item;

        COMMIT TRANSACTION;

        PRINT 'Dimensões carregadas com sucesso.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

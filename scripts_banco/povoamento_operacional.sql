USE DeliFitDB;
GO
/*
Procedura cadastrar clientes
*/
CREATE OR ALTER PROCEDURE oltp.sp_cadastrar_cliente @nome VARCHAR(150),
                                                    @email VARCHAR(150),
                                                    @senha_hash VARCHAR(255),
                                                    @telefone VARCHAR(20) = NULL,
                                                    @data_nascimento DATE = NULL,
                                                    @data_cadastro DATETIME2 = NULL,
                                                    @cliente_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1
                   FROM oltp.usuarios
                   WHERE email = @email)
            BEGIN
                THROW 50001, 'Já existe um usuário cadastrado com este e-mail.', 1;
            END;

        IF @data_cadastro IS NULL
            SET @data_cadastro = SYSDATETIME();

        INSERT INTO oltp.usuarios
        (nome,
         email,
         senha_hash,
         telefone,
         tipo_usuario,
         ativo,
         data_cadastro)
        VALUES (@nome,
                @email,
                @senha_hash,
                @telefone,
                'CLIENTE',
                1,
                @data_cadastro);

        DECLARE @usuario_id BIGINT = SCOPE_IDENTITY();

        INSERT INTO oltp.clientes
        (usuario_id,
         data_nascimento)
        VALUES (@usuario_id,
                @data_nascimento);

        SET @cliente_id = SCOPE_IDENTITY();

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
# 2. Procedure para cadastrar endereço
*/
CREATE OR ALTER PROCEDURE oltp.sp_cadastrar_endereco @cliente_id BIGINT,
                                                     @nome_endereco VARCHAR(50) = NULL,
                                                     @cep VARCHAR(9),
                                                     @logradouro VARCHAR(150),
                                                     @numero VARCHAR(20),
                                                     @complemento VARCHAR(100) = NULL,
                                                     @bairro VARCHAR(100),
                                                     @cidade VARCHAR(100),
                                                     @estado CHAR(2),
                                                     @endereco_principal BIT = 0,
                                                     @endereco_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.clientes
                   WHERE cliente_id = @cliente_id)
        BEGIN
            THROW 50002, 'Cliente não encontrado.', 1;
        END;

    SET @estado = UPPER(@estado);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @endereco_principal = 1
            BEGIN
                UPDATE oltp.enderecos
                SET endereco_principal = 0
                WHERE cliente_id = @cliente_id;
            END;

        INSERT INTO oltp.enderecos
        (cliente_id,
         nome_endereco,
         cep,
         logradouro,
         numero,
         complemento,
         bairro,
         cidade,
         estado,
         endereco_principal,
         ativo)
        VALUES (@cliente_id,
                @nome_endereco,
                @cep,
                @logradouro,
                @numero,
                @complemento,
                @bairro,
                @cidade,
                @estado,
                @endereco_principal,
                1);

        SET @endereco_id = SCOPE_IDENTITY();

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
# 3. Procedure para cadastrar restaurante
*/
CREATE OR ALTER PROCEDURE oltp.sp_cadastrar_restaurante @nome_responsavel VARCHAR(150),
                                                        @email VARCHAR(150),
                                                        @senha_hash VARCHAR(255),
                                                        @nome_fantasia VARCHAR(150),
                                                        @cnpj VARCHAR(18),
                                                        @descricao VARCHAR(500) = NULL,
                                                        @telefone VARCHAR(20) = NULL,
                                                        @cep VARCHAR(9),
                                                        @logradouro VARCHAR(150),
                                                        @numero VARCHAR(20),
                                                        @complemento VARCHAR(100) = NULL,
                                                        @bairro VARCHAR(100),
                                                        @cidade VARCHAR(100),
                                                        @estado CHAR(2),
                                                        @data_cadastro DATETIME2 = NULL,
                                                        @restaurante_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1
                   FROM oltp.usuarios
                   WHERE email = @email)
            BEGIN
                THROW 50003, 'Já existe um usuário cadastrado com este e-mail.', 1;
            END;

        IF EXISTS (SELECT 1
                   FROM oltp.restaurantes
                   WHERE cnpj = @cnpj)
            BEGIN
                THROW 50004, 'Já existe um restaurante cadastrado com este CNPJ.', 1;
            END;

        IF @data_cadastro IS NULL
            SET @data_cadastro = SYSDATETIME();

        SET @estado = UPPER(@estado);

        INSERT INTO oltp.usuarios
        (nome,
         email,
         senha_hash,
         telefone,
         tipo_usuario,
         ativo,
         data_cadastro)
        VALUES (@nome_responsavel,
                @email,
                @senha_hash,
                @telefone,
                'RESTAURANTE',
                1,
                @data_cadastro);

        DECLARE @usuario_id BIGINT = SCOPE_IDENTITY();

        INSERT INTO oltp.restaurantes
        (usuario_id,
         nome_fantasia,
         cnpj,
         descricao,
         telefone,
         cep,
         logradouro,
         numero,
         complemento,
         bairro,
         cidade,
         estado,
         ativo,
         data_cadastro)
        VALUES (@usuario_id,
                @nome_fantasia,
                @cnpj,
                @descricao,
                @telefone,
                @cep,
                @logradouro,
                @numero,
                @complemento,
                @bairro,
                @cidade,
                @estado,
                1,
                @data_cadastro);

        SET @restaurante_id = SCOPE_IDENTITY();

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
# 4. Procedure para cadastrar categoria
*/
CREATE OR ALTER PROCEDURE oltp.sp_cadastrar_categoria @nome VARCHAR(100),
                                                      @descricao VARCHAR(300) = NULL,
                                                      @categoria_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM oltp.categorias_cardapio
               WHERE nome = @nome)
        BEGIN
            SELECT @categoria_id = categoria_id
            FROM oltp.categorias_cardapio
            WHERE nome = @nome;

            RETURN;
        END;

    INSERT INTO oltp.categorias_cardapio
    (nome,
     descricao,
     ativo)
    VALUES (@nome,
            @descricao,
            1);

    SET @categoria_id = SCOPE_IDENTITY();
END;
GO

/*
# 5. Procedure para cadastrar item do cardápio
*/
CREATE OR ALTER PROCEDURE oltp.sp_cadastrar_item_cardapio @restaurante_id BIGINT,
                                                          @categoria_id INT,
                                                          @nome VARCHAR(150),
                                                          @descricao VARCHAR(500) = NULL,
                                                          @preco DECIMAL(10, 2),
                                                          @calorias DECIMAL(10, 2) = NULL,
                                                          @proteinas DECIMAL(10, 2) = NULL,
                                                          @carboidratos DECIMAL(10, 2) = NULL,
                                                          @gorduras DECIMAL(10, 2) = NULL,
                                                          @restricao_alimentar VARCHAR(50) = NULL,
                                                          @data_cadastro DATETIME2 = NULL,
                                                          @item_cardapio_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.restaurantes
                   WHERE restaurante_id = @restaurante_id)
        BEGIN
            THROW 50005, 'Restaurante não encontrado.', 1;
        END;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.categorias_cardapio
                   WHERE categoria_id = @categoria_id)
        BEGIN
            THROW 50006, 'Categoria não encontrada.', 1;
        END;

    IF @preco <= 0
        BEGIN
            THROW 50007, 'O preço do item deve ser maior que zero.', 1;
        END;

    IF @data_cadastro IS NULL
        SET @data_cadastro = SYSDATETIME();

    INSERT INTO oltp.itens_cardapio
    (restaurante_id,
     categoria_id,
     nome,
     descricao,
     preco,
     calorias,
     proteinas,
     carboidratos,
     gorduras,
     restricao_alimentar,
     disponivel,
     data_cadastro)
    VALUES (@restaurante_id,
            @categoria_id,
            @nome,
            @descricao,
            @preco,
            @calorias,
            @proteinas,
            @carboidratos,
            @gorduras,
            @restricao_alimentar,
            1,
            @data_cadastro);

    SET @item_cardapio_id = SCOPE_IDENTITY();
END;
GO


/*
# 6. Procedure para criar pedido
*/
CREATE OR ALTER PROCEDURE oltp.sp_criar_pedido @cliente_id BIGINT,
                                               @restaurante_id BIGINT,
                                               @endereco_entrega_id BIGINT,
                                               @forma_pagamento VARCHAR(30),
                                               @valor_frete DECIMAL(10, 2) = 0,
                                               @observacao VARCHAR(500) = NULL,
                                               @criado_em DATETIME2 = NULL,
                                               @pedido_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.clientes
                   WHERE cliente_id = @cliente_id)
        BEGIN
            THROW 50008, 'Cliente não encontrado.', 1;
        END;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.restaurantes
                   WHERE restaurante_id = @restaurante_id)
        BEGIN
            THROW 50009, 'Restaurante não encontrado.', 1;
        END;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.enderecos
                   WHERE endereco_id = @endereco_entrega_id
                     AND cliente_id = @cliente_id
                     AND ativo = 1)
        BEGIN
            THROW 50010, 'O endereço não pertence ao cliente ou está inativo.', 1;
        END;

    IF @forma_pagamento NOT IN (
                                'PIX',
                                'CARTAO_CREDITO',
                                'CARTAO_DEBITO',
                                'DINHEIRO'
        )
        BEGIN
            THROW 50011, 'Forma de pagamento inválida.', 1;
        END;

    IF @valor_frete < 0
        BEGIN
            THROW 50012, 'O valor do frete não pode ser negativo.', 1;
        END;

    IF @criado_em IS NULL
        SET @criado_em = SYSDATETIME();

    INSERT INTO oltp.pedidos
    (cliente_id,
     restaurante_id,
     endereco_entrega_id,
     status_pedido,
     forma_pagamento,
     status_pagamento,
     valor_subtotal,
     valor_frete,
     valor_total,
     observacao,
     criado_em)
    VALUES (@cliente_id,
            @restaurante_id,
            @endereco_entrega_id,
            'PENDENTE',
            @forma_pagamento,
            'PENDENTE',
            0,
            @valor_frete,
            @valor_frete,
            @observacao,
            @criado_em);

    SET @pedido_id = SCOPE_IDENTITY();
END;
GO


/*
# 7. Procedure para adicionar item ao pedido
*/
CREATE OR ALTER PROCEDURE oltp.sp_adicionar_item_pedido @pedido_id BIGINT,
                                                        @item_cardapio_id BIGINT,
                                                        @quantidade INT,
                                                        @item_pedido_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @quantidade <= 0
        BEGIN
            THROW 50013, 'A quantidade deve ser maior que zero.', 1;
        END;

    DECLARE
        @restaurante_pedido_id BIGINT,
        @restaurante_item_id BIGINT,
        @status_pedido VARCHAR(30),
        @nome_item VARCHAR(150),
        @descricao_item VARCHAR(500),
        @preco_item DECIMAL(10, 2),
        @disponivel BIT,
        @valor_total_item DECIMAL(10, 2);

    SELECT @restaurante_pedido_id = restaurante_id,
           @status_pedido = status_pedido
    FROM oltp.pedidos
    WHERE pedido_id = @pedido_id;

    IF @restaurante_pedido_id IS NULL
        BEGIN
            THROW 50014, 'Pedido não encontrado.', 1;
        END;

    IF @status_pedido <> 'PENDENTE'
        BEGIN
            THROW 50015, 'Somente pedidos pendentes podem receber novos itens.', 1;
        END;

    SELECT @restaurante_item_id = restaurante_id,
           @nome_item = nome,
           @descricao_item = descricao,
           @preco_item = preco,
           @disponivel = disponivel
    FROM oltp.itens_cardapio
    WHERE item_cardapio_id = @item_cardapio_id;

    IF @restaurante_item_id IS NULL
        BEGIN
            THROW 50016, 'Item do cardápio não encontrado.', 1;
        END;

    IF @restaurante_item_id <> @restaurante_pedido_id
        BEGIN
            THROW 50017, 'O item não pertence ao restaurante do pedido.', 1;
        END;

    IF @disponivel = 0
        BEGIN
            THROW 50018, 'O item não está disponível para venda.', 1;
        END;

    SET @valor_total_item = @preco_item * @quantidade;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO oltp.itens_pedido
        (pedido_id,
         item_cardapio_id,
         nome_item_snapshot,
         descricao_snapshot,
         preco_unitario_snapshot,
         quantidade,
         valor_total_item)
        VALUES (@pedido_id,
                @item_cardapio_id,
                @nome_item,
                @descricao_item,
                @preco_item,
                @quantidade,
                @valor_total_item);

        SET @item_pedido_id = SCOPE_IDENTITY();

        UPDATE oltp.pedidos
        SET valor_subtotal = valor_subtotal + @valor_total_item,
            valor_total    = valor_subtotal + @valor_total_item + valor_frete
        WHERE pedido_id = @pedido_id;

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
# 8. Procedure para atualizar pedido
*/
CREATE OR ALTER PROCEDURE oltp.sp_atualizar_status_pedido @pedido_id BIGINT,
                                                          @novo_status VARCHAR(30),
                                                          @data_evento DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.pedidos
                   WHERE pedido_id = @pedido_id)
        BEGIN
            THROW 50019, 'Pedido não encontrado.', 1;
        END;

    IF @novo_status NOT IN (
                            'PENDENTE',
                            'CONFIRMADO',
                            'EM_PREPARO',
                            'SAIU_PARA_ENTREGA',
                            'ENTREGUE',
                            'CANCELADO'
        )
        BEGIN
            THROW 50020, 'Status do pedido inválido.', 1;
        END;

    IF @data_evento IS NULL
        SET @data_evento = SYSDATETIME();

    IF @novo_status = 'CONFIRMADO'
        BEGIN
            IF NOT EXISTS (SELECT 1
                           FROM oltp.itens_pedido
                           WHERE pedido_id = @pedido_id)
                BEGIN
                    THROW 50021, 'Não é possível confirmar um pedido sem itens.', 1;
                END;

            UPDATE oltp.pedidos
            SET status_pedido = 'CONFIRMADO',
                confirmado_em = @data_evento
            WHERE pedido_id = @pedido_id;
        END
    ELSE
        IF @novo_status = 'ENTREGUE'
            BEGIN
                UPDATE oltp.pedidos
                SET status_pedido = 'ENTREGUE',
                    entregue_em   = @data_evento
                WHERE pedido_id = @pedido_id;
            END
        ELSE
            IF @novo_status = 'CANCELADO'
                BEGIN
                    UPDATE oltp.pedidos
                    SET status_pedido = 'CANCELADO',
                        cancelado_em  = @data_evento
                    WHERE pedido_id = @pedido_id;
                END
            ELSE
                BEGIN
                    UPDATE oltp.pedidos
                    SET status_pedido = @novo_status
                    WHERE pedido_id = @pedido_id;
                END;
END;
GO

/*
# 9. Procedure para atualizar pagamento
*/
CREATE OR ALTER PROCEDURE oltp.sp_atualizar_status_pagamento @pedido_id BIGINT,
                                                             @novo_status VARCHAR(20),
                                                             @data_pagamento DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM oltp.pedidos
                   WHERE pedido_id = @pedido_id)
        BEGIN
            THROW 50022, 'Pedido não encontrado.', 1;
        END;

    IF @novo_status NOT IN (
                            'PENDENTE',
                            'PAGO',
                            'FALHOU',
                            'CANCELADO'
        )
        BEGIN
            THROW 50023, 'Status de pagamento inválido.', 1;
        END;

    IF @novo_status = 'PAGO'
        BEGIN
            IF @data_pagamento IS NULL
                SET @data_pagamento = SYSDATETIME();

            UPDATE oltp.pedidos
            SET status_pagamento = 'PAGO',
                pago_em          = @data_pagamento
            WHERE pedido_id = @pedido_id;
        END
    ELSE
        BEGIN
            UPDATE oltp.pedidos
            SET status_pagamento = @novo_status,
                pago_em          = NULL
            WHERE pedido_id = @pedido_id;
        END;
END;
GO


/*
================================================
# 10. Procedure principal para povoar o ambiente
================================================
*/
CREATE OR ALTER PROCEDURE oltp.sp_povoar_ambiente
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (SELECT 1 FROM oltp.pedidos)
        OR EXISTS (SELECT 1 FROM oltp.clientes)
        OR EXISTS (SELECT 1 FROM oltp.restaurantes)
        BEGIN
            THROW 50024,
                'O ambiente OLTP já possui dados. O povoamento foi cancelado.',
                1;
        END;

    DECLARE
        @categoria_marmita INT,
        @categoria_lanche INT,
        @categoria_bebida INT,
        @categoria_sobremesa INT,

        @cliente_ana BIGINT,
        @cliente_bruno BIGINT,
        @cliente_carla BIGINT,

        @endereco_ana BIGINT,
        @endereco_bruno BIGINT,
        @endereco_carla BIGINT,

        @restaurante_fit BIGINT,
        @restaurante_natural BIGINT,

        @item_frango BIGINT,
        @item_carne BIGINT,
        @item_sanduiche BIGINT,
        @item_suco BIGINT,
        @item_brownie BIGINT,

        @pedido_1 BIGINT,
        @pedido_2 BIGINT,
        @pedido_3 BIGINT,
        @pedido_4 BIGINT,
        @pedido_5 BIGINT,
        @pedido_6 BIGINT,
        @pedido_7 BIGINT,
        @pedido_8 BIGINT,
        @pedido_9 BIGINT,
        @pedido_10 BIGINT,
        @pedido_11 BIGINT,
        @pedido_12 BIGINT,

        @item_pedido_id BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Categorias */

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Marmitas',
             @descricao = 'Refeições completas e balanceadas',
             @categoria_id = @categoria_marmita OUTPUT;

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Lanches Naturais',
             @descricao = 'Sanduíches e lanches saudáveis',
             @categoria_id = @categoria_lanche OUTPUT;

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Bebidas',
             @descricao = 'Sucos naturais e bebidas funcionais',
             @categoria_id = @categoria_bebida OUTPUT;

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Sobremesas',
             @descricao = 'Sobremesas com ingredientes saudáveis',
             @categoria_id = @categoria_sobremesa OUTPUT;

        /* Clientes */

        EXEC oltp.sp_cadastrar_cliente
             @nome = 'Ana Souza',
             @email = 'ana.souza@delifit.com',
             @senha_hash = 'HASH_ANA_001',
             @telefone = '(79) 99911-1111',
             @data_nascimento = '1998-04-15',
             @data_cadastro = '2025-01-10 09:00:00',
             @cliente_id = @cliente_ana OUTPUT;

        EXEC oltp.sp_cadastrar_cliente
             @nome = 'Bruno Santos',
             @email = 'bruno.santos@delifit.com',
             @senha_hash = 'HASH_BRUNO_001',
             @telefone = '(79) 99922-2222',
             @data_nascimento = '1994-08-22',
             @data_cadastro = '2025-02-05 10:30:00',
             @cliente_id = @cliente_bruno OUTPUT;

        EXEC oltp.sp_cadastrar_cliente
             @nome = 'Carla Lima',
             @email = 'carla.lima@delifit.com',
             @senha_hash = 'HASH_CARLA_001',
             @telefone = '(79) 99933-3333',
             @data_nascimento = '2000-11-03',
             @data_cadastro = '2025-03-18 14:20:00',
             @cliente_id = @cliente_carla OUTPUT;

        /* Endereços */

        EXEC oltp.sp_cadastrar_endereco
             @cliente_id = @cliente_ana,
             @nome_endereco = 'Casa',
             @cep = '49000-001',
             @logradouro = 'Rua das Flores',
             @numero = '100',
             @bairro = 'Centro',
             @cidade = 'Aracaju',
             @estado = 'SE',
             @endereco_principal = 1,
             @endereco_id = @endereco_ana OUTPUT;

        EXEC oltp.sp_cadastrar_endereco
             @cliente_id = @cliente_bruno,
             @nome_endereco = 'Apartamento',
             @cep = '49020-100',
             @logradouro = 'Avenida Beira-Mar',
             @numero = '850',
             @complemento = 'Apto 304',
             @bairro = '13 de Julho',
             @cidade = 'Aracaju',
             @estado = 'SE',
             @endereco_principal = 1,
             @endereco_id = @endereco_bruno OUTPUT;

        EXEC oltp.sp_cadastrar_endereco
             @cliente_id = @cliente_carla,
             @nome_endereco = 'Casa',
             @cep = '49045-200',
             @logradouro = 'Rua dos Ipês',
             @numero = '45',
             @bairro = 'Jardins',
             @cidade = 'Aracaju',
             @estado = 'SE',
             @endereco_principal = 1,
             @endereco_id = @endereco_carla OUTPUT;

        /* Restaurantes */

        EXEC oltp.sp_cadastrar_restaurante
             @nome_responsavel = 'Marcos Oliveira',
             @email = 'contato@fitfood.com',
             @senha_hash = 'HASH_FITFOOD_001',
             @nome_fantasia = 'Fit Food',
             @cnpj = '11.111.111/0001-11',
             @descricao = 'Restaurante especializado em refeições fitness',
             @telefone = '(79) 3333-1111',
             @cep = '49010-100',
             @logradouro = 'Avenida Central',
             @numero = '450',
             @bairro = 'Centro',
             @cidade = 'Aracaju',
             @estado = 'SE',
             @data_cadastro = '2024-12-01 08:00:00',
             @restaurante_id = @restaurante_fit OUTPUT;

        EXEC oltp.sp_cadastrar_restaurante
             @nome_responsavel = 'Juliana Costa',
             @email = 'contato@sabornatural.com',
             @senha_hash = 'HASH_SABOR_001',
             @nome_fantasia = 'Sabor Natural',
             @cnpj = '22.222.222/0001-22',
             @descricao = 'Lanches, bebidas e sobremesas naturais',
             @telefone = '(79) 3333-2222',
             @cep = '49025-200',
             @logradouro = 'Rua da Saúde',
             @numero = '300',
             @bairro = 'São José',
             @cidade = 'Aracaju',
             @estado = 'SE',
             @data_cadastro = '2024-12-15 08:00:00',
             @restaurante_id = @restaurante_natural OUTPUT;

        /* Itens */

        EXEC oltp.sp_cadastrar_item_cardapio
             @restaurante_id = @restaurante_fit,
             @categoria_id = @categoria_marmita,
             @nome = 'Frango Grelhado com Batata-doce',
             @descricao = 'Frango grelhado, batata-doce e legumes',
             @preco = 28.90,
             @calorias = 480,
             @proteinas = 42,
             @carboidratos = 38,
             @gorduras = 9,
             @restricao_alimentar = 'SEM_GLUTEN',
             @item_cardapio_id = @item_frango OUTPUT;

        EXEC oltp.sp_cadastrar_item_cardapio
             @restaurante_id = @restaurante_fit,
             @categoria_id = @categoria_marmita,
             @nome = 'Carne Magra com Arroz Integral',
             @descricao = 'Carne magra, arroz integral e vegetais',
             @preco = 32.50,
             @calorias = 520,
             @proteinas = 40,
             @carboidratos = 45,
             @gorduras = 12,
             @item_cardapio_id = @item_carne OUTPUT;

        EXEC oltp.sp_cadastrar_item_cardapio
             @restaurante_id = @restaurante_natural,
             @categoria_id = @categoria_lanche,
             @nome = 'Sanduíche Natural de Frango',
             @descricao = 'Pão integral, frango, alface e cenoura',
             @preco = 16.90,
             @calorias = 310,
             @proteinas = 22,
             @carboidratos = 32,
             @gorduras = 8,
             @item_cardapio_id = @item_sanduiche OUTPUT;

        EXEC oltp.sp_cadastrar_item_cardapio
             @restaurante_id = @restaurante_natural,
             @categoria_id = @categoria_bebida,
             @nome = 'Suco Verde',
             @descricao = 'Couve, limão, maçã e gengibre',
             @preco = 9.50,
             @calorias = 110,
             @proteinas = 2,
             @carboidratos = 24,
             @gorduras = 0,
             @restricao_alimentar = 'VEGANO',
             @item_cardapio_id = @item_suco OUTPUT;

        EXEC oltp.sp_cadastrar_item_cardapio
             @restaurante_id = @restaurante_natural,
             @categoria_id = @categoria_sobremesa,
             @nome = 'Brownie Fit',
             @descricao = 'Brownie de cacau sem açúcar refinado',
             @preco = 12.00,
             @calorias = 190,
             @proteinas = 6,
             @carboidratos = 20,
             @gorduras = 9,
             @restricao_alimentar = 'SEM_ACUCAR',
             @item_cardapio_id = @item_brownie OUTPUT;

        /* Pedido 1 */

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_ana,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_ana,
             @forma_pagamento = 'PIX',
             @valor_frete = 5.00,
             @criado_em = '2025-04-05 11:30:00',
             @pedido_id = @pedido_1 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_1,
             @item_cardapio_id = @item_frango,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_1,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-04-05 11:32:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_1,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-04-05 11:34:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_1,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-04-05 12:20:00';

        /* Pedido 2 */

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_bruno,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_bruno,
             @forma_pagamento = 'CARTAO_CREDITO',
             @valor_frete = 6.50,
             @criado_em = '2025-04-08 18:10:00',
             @pedido_id = @pedido_2 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_2,
             @item_cardapio_id = @item_sanduiche,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_2,
             @item_cardapio_id = @item_suco,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_2,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-04-08 18:12:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_2,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-04-08 18:15:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_2,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-04-08 19:05:00';

        /* Pedido 3 cancelado */

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_carla,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_carla,
             @forma_pagamento = 'CARTAO_DEBITO',
             @valor_frete = 4.50,
             @criado_em = '2025-04-10 20:00:00',
             @pedido_id = @pedido_3 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_3,
             @item_cardapio_id = @item_brownie,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_3,
             @novo_status = 'FALHOU';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_3,
             @novo_status = 'CANCELADO',
             @data_evento = '2025-04-10 20:05:00';

        /* PEDIDO 4 - Entregue, PIX Ana comprando no Fit Food  */
        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_ana,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_ana,
             @forma_pagamento = 'PIX',
             @valor_frete = 5.00,
             @observacao = 'Sem cebola',
             @criado_em = '2025-04-15 12:10:00',
             @pedido_id = @pedido_4 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_4,
             @item_cardapio_id = @item_carne,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_4,
             @item_cardapio_id = @item_frango,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_4,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-04-15 12:12:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_4,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-04-15 12:15:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_4,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-04-15 13:05:00';


        /* PEDIDO 5 - Entregue, dinheiro -> Bruno comprando no Fit Food*/
        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_bruno,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_bruno,
             @forma_pagamento = 'DINHEIRO',
             @valor_frete = 7.00,
             @observacao = 'Troco para 100 reais',
             @criado_em = '2025-04-20 19:30:00',
             @pedido_id = @pedido_5 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_5,
             @item_cardapio_id = @item_carne,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_5,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-04-20 19:35:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_5,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-04-20 20:25:00';

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_5,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-04-20 20:25:00';


        /*PEDIDO 6 - Entregue, cartão de débito -> Carla comprando no Sabor Natural */

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_carla,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_carla,
             @forma_pagamento = 'CARTAO_DEBITO',
             @valor_frete = 4.50,
             @criado_em = '2025-05-02 16:20:00',
             @pedido_id = @pedido_6 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_6,
             @item_cardapio_id = @item_sanduiche,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_6,
             @item_cardapio_id = @item_suco,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_6,
             @item_cardapio_id = @item_brownie,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_6,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-05-02 16:22:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_6,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-05-02 16:25:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_6,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-05-02 17:10:00';


        /*PEDIDO 7 - Cancelado com pagamento cancelado -> Ana comprando no Sabor Natural */

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_ana,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_ana,
             @forma_pagamento = 'PIX',
             @valor_frete = 5.50,
             @criado_em = '2025-05-06 20:00:00',
             @pedido_id = @pedido_7 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_7,
             @item_cardapio_id = @item_sanduiche,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_7,
             @item_cardapio_id = @item_suco,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_7,
             @novo_status = 'CANCELADO';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_7,
             @novo_status = 'CANCELADO',
             @data_evento = '2025-05-06 20:08:00';


        /*PEDIDO 8 - Em preparo -> Bruno comprando no Sabor Natural*/

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_bruno,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_bruno,
             @forma_pagamento = 'CARTAO_CREDITO',
             @valor_frete = 6.50,
             @criado_em = '2025-05-10 11:40:00',
             @pedido_id = @pedido_8 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_8,
             @item_cardapio_id = @item_sanduiche,
             @quantidade = 3,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_8,
             @item_cardapio_id = @item_suco,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_8,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-05-10 11:42:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_8,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-05-10 11:44:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_8,
             @novo_status = 'EM_PREPARO',
             @data_evento = '2025-05-10 11:50:00';


        /*PEDIDO 9 - Saiu para entrega -> Carla comprando no Fit Food*/

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_carla,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_carla,
             @forma_pagamento = 'PIX',
             @valor_frete = 6.00,
             @criado_em = '2025-05-14 12:00:00',
             @pedido_id = @pedido_9 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_9,
             @item_cardapio_id = @item_frango,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_9,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-05-14 12:02:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_9,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-05-14 12:04:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_9,
             @novo_status = 'EM_PREPARO',
             @data_evento = '2025-05-14 12:10:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_9,
             @novo_status = 'SAIU_PARA_ENTREGA',
             @data_evento = '2025-05-14 12:40:00';


        /*PEDIDO 10 - Pendente e ainda não pago -> Ana comprando no Fit Food*/

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_ana,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_ana,
             @forma_pagamento = 'CARTAO_CREDITO',
             @valor_frete = 5.00,
             @criado_em = '2025-06-01 18:30:00',
             @pedido_id = @pedido_10 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_10,
             @item_cardapio_id = @item_carne,
             @quantidade = 1,
             @item_pedido_id = @item_pedido_id OUTPUT;


        /*PEDIDO 11 - Pagamento falhou e pedido cancelado -> Bruno comprando no Fit Food*/

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_bruno,
             @restaurante_id = @restaurante_fit,
             @endereco_entrega_id = @endereco_bruno,
             @forma_pagamento = 'CARTAO_DEBITO',
             @valor_frete = 7.00,
             @criado_em = '2025-06-04 20:15:00',
             @pedido_id = @pedido_11 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_11,
             @item_cardapio_id = @item_frango,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_11,
             @novo_status = 'FALHOU';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_11,
             @novo_status = 'CANCELADO',
             @data_evento = '2025-06-04 20:20:00';


        /*PEDIDO 12 - Entregue, cartão de crédito -> Carla comprando no Sabor Natural*/

        EXEC oltp.sp_criar_pedido
             @cliente_id = @cliente_carla,
             @restaurante_id = @restaurante_natural,
             @endereco_entrega_id = @endereco_carla,
             @forma_pagamento = 'CARTAO_CREDITO',
             @valor_frete = 4.50,
             @observacao = 'Entregar na portaria',
             @criado_em = '2025-06-10 19:00:00',
             @pedido_id = @pedido_12 OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_12,
             @item_cardapio_id = @item_sanduiche,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_adicionar_item_pedido
             @pedido_id = @pedido_12,
             @item_cardapio_id = @item_brownie,
             @quantidade = 2,
             @item_pedido_id = @item_pedido_id OUTPUT;

        EXEC oltp.sp_atualizar_status_pagamento
             @pedido_id = @pedido_12,
             @novo_status = 'PAGO',
             @data_pagamento = '2025-06-10 19:02:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_12,
             @novo_status = 'CONFIRMADO',
             @data_evento = '2025-06-10 19:05:00';

        EXEC oltp.sp_atualizar_status_pedido
             @pedido_id = @pedido_12,
             @novo_status = 'ENTREGUE',
             @data_evento = '2025-06-10 19:55:00';

        COMMIT TRANSACTION;

        PRINT 'Ambiente OLTP povoado com sucesso.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/*
Executar o povoamento
*/
EXEC oltp.sp_povoar_ambiente;
GO



/*Limpar dados */
CREATE OR ALTER PROCEDURE oltp.sp_limpar_ambiente
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Filhas */

        DELETE FROM oltp.itens_pedido;
        DELETE FROM oltp.pedidos;

        /* Dependências de restaurantes e clientes */

        DELETE FROM oltp.itens_cardapio;
        DELETE FROM oltp.categorias_cardapio;

        DELETE FROM oltp.enderecos;
        DELETE FROM oltp.restaurantes;
        DELETE FROM oltp.clientes;

        /* Tabela raiz */

        DELETE FROM oltp.usuarios;

        /* Reinicia os IDs */

        DBCC CHECKIDENT ('oltp.itens_pedido', RESEED, 0);
        DBCC CHECKIDENT ('oltp.pedidos', RESEED, 0);
        DBCC CHECKIDENT ('oltp.itens_cardapio', RESEED, 0);
        DBCC CHECKIDENT ('oltp.categorias_cardapio', RESEED, 0);
        DBCC CHECKIDENT ('oltp.enderecos', RESEED, 0);
        DBCC CHECKIDENT ('oltp.restaurantes', RESEED, 0);
        DBCC CHECKIDENT ('oltp.clientes', RESEED, 0);
        DBCC CHECKIDENT ('oltp.usuarios', RESEED, 0);

        COMMIT TRANSACTION;

        PRINT 'Ambiente OLTP limpo com sucesso.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

/* Executando limpeza */
EXEC oltp.sp_limpar_ambiente;
GO

SELECT *
FROM oltp.usuarios;
SELECT *
FROM oltp.clientes;
SELECT *
FROM oltp.enderecos;
SELECT *
FROM oltp.restaurantes;
SELECT *
FROM oltp.categorias_cardapio;
SELECT *
FROM oltp.itens_cardapio;
SELECT *
FROM oltp.pedidos;
SELECT *
FROM oltp.itens_pedido;

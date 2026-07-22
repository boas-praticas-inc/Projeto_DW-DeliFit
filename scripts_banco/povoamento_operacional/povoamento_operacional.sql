USE DeliFitDB;
GO

--Procedura cadastrar clientes

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

--2. Procedure para cadastrar endereço

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

--3. Procedure para cadastrar restaurante

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

--4. Procedure para cadastrar categoria

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

--5. Procedure para cadastrar item do cardápio

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

--6. Procedure para criar pedido

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

--7. Procedure para adicionar item ao pedido

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

--8. Procedure para atualizar pedido

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

--9. Procedure para atualizar pagamento

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

--10. Procedure principal para povoar o ambiente

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

        @item_pedido_id BIGINT,

        @categoria_salada INT,
        @categoria_snack INT,
        @novo_cliente_id BIGINT,
        @novo_endereco_id BIGINT,
        @novo_restaurante_id BIGINT,
        @novo_item_id BIGINT,
        @novo_pedido_id BIGINT,
        @categoria_item_id INT,
        @indice INT,
        @subindice INT,
        @nome VARCHAR(150),
        @email VARCHAR(150),
        @telefone VARCHAR(20),
        @data_nascimento DATE,
        @cep VARCHAR(9),
        @logradouro VARCHAR(150),
        @numero VARCHAR(20),
        @bairro VARCHAR(100),
        @nome_fantasia VARCHAR(150),
        @cnpj VARCHAR(18),
        @preco DECIMAL(10,2),
        @calorias DECIMAL(10,2),
        @proteinas DECIMAL(10,2),
        @carboidratos DECIMAL(10,2),
        @gorduras DECIMAL(10,2),
        @restricao VARCHAR(50),
        @cliente_pedido_id BIGINT,
        @endereco_pedido_id BIGINT,
        @restaurante_pedido_id BIGINT,
        @item_pedido_cardapio_id BIGINT,
        @quantidade INT,
        @quantidade_linhas INT,
        @quantidade_itens_restaurante INT,
        @forma_pagamento VARCHAR(30),
        @valor_frete DECIMAL(10,2),
        @data_pedido DATETIME2,
        @data_evento DATETIME2,
        @cenario_status INT;

    DECLARE @clientes_carga TABLE
    (
        ordem INT IDENTITY(1,1),
        cliente_id BIGINT,
        endereco_id BIGINT
    );

    DECLARE @restaurantes_carga TABLE
    (
        ordem INT IDENTITY(1,1),
        restaurante_id BIGINT
    );

    DECLARE @itens_carga TABLE
    (
        item_cardapio_id BIGINT,
        restaurante_id BIGINT
    );

    DECLARE @dados_clientes TABLE
    (
        ordem INT PRIMARY KEY,
        nome VARCHAR(150),
        data_nascimento DATE,
        bairro VARCHAR(100),
        logradouro VARCHAR(150)
    );

    DECLARE @dados_restaurantes TABLE
    (
        ordem INT PRIMARY KEY,
        responsavel VARCHAR(150),
        nome_fantasia VARCHAR(150),
        bairro VARCHAR(100)
    );

    DECLARE @dados_itens TABLE
    (
        ordem INT PRIMARY KEY,
        restaurante_ordem INT,
        categoria_ordem INT,
        nome VARCHAR(150),
        preco DECIMAL(10,2),
        calorias DECIMAL(10,2),
        proteinas DECIMAL(10,2),
        carboidratos DECIMAL(10,2),
        gorduras DECIMAL(10,2),
        restricao VARCHAR(50)
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        --Categorias

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

        --Clientes

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

        --Endereços

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

        --Restaurantes

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

        --Itens

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

        --Pedido 1

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

        --Pedido 2

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

        --Pedido 3 cancelado

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

        --PEDIDO 4 - Entregue, PIX Ana comprando no Fit Food

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


        --PEDIDO 5 - Entregue, dinheiro -> Bruno comprando no Fit Food

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

        --PEDIDO 6 - Entregue, cartão de débito -> Carla comprando no Sabor Natural

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


        --PEDIDO 7 - Cancelado com pagamento cancelado -> Ana comprando no Sabor Natural

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

        --PEDIDO 8 - Em preparo -> Bruno comprando no Sabor Natural

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

        --PEDIDO 9 - Saiu para entrega -> Carla comprando no Fit Food

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

        --PEDIDO 10 - Pendente e ainda não pago -> Ana comprando no Fit Food

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

        --PEDIDO 11 - Pagamento falhou e pedido cancelado -> Bruno comprando no Fit Food

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

        --PEDIDO 12 - Entregue, cartão de crédito -> Carla comprando no Sabor Natural

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

        --Carga adicional: categorias

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Saladas e Bowls',
             @descricao = 'Saladas, bowls e refeicoes leves e balanceadas',
             @categoria_id = @categoria_salada OUTPUT;

        EXEC oltp.sp_cadastrar_categoria
             @nome = 'Snacks Saudaveis',
             @descricao = 'Opcoes praticas para lanches entre as refeicoes',
             @categoria_id = @categoria_snack OUTPUT;

        --Cadastros usados na carga adicional

        INSERT INTO @clientes_carga (cliente_id, endereco_id)
        VALUES (@cliente_ana, @endereco_ana),
               (@cliente_bruno, @endereco_bruno),
               (@cliente_carla, @endereco_carla);

        INSERT INTO @restaurantes_carga (restaurante_id)
        VALUES (@restaurante_fit),
               (@restaurante_natural);

        INSERT INTO @itens_carga (item_cardapio_id, restaurante_id)
        VALUES (@item_frango, @restaurante_fit),
               (@item_carne, @restaurante_fit),
               (@item_sanduiche, @restaurante_natural),
               (@item_suco, @restaurante_natural),
               (@item_brownie, @restaurante_natural);

        INSERT INTO @dados_clientes (ordem, nome, data_nascimento, bairro, logradouro)
        VALUES
            (1, 'Lucas Ferreira', '1996-02-11', 'Atalaia', 'Rua Niceu Dantas'),
            (2, 'Mariana Alves', '1999-07-23', 'Farolandia', 'Avenida Murilo Dantas'),
            (3, 'Rafael Nunes', '1992-12-05', 'Luzia', 'Rua Francisco Portugal'),
            (4, 'Beatriz Rocha', '2001-03-17', 'Jabotiana', 'Avenida Tancredo Neves'),
            (5, 'Gabriel Costa', '1995-09-28', 'Grageru', 'Rua Dr. Bezerra de Menezes'),
            (6, 'Larissa Melo', '1998-06-14', 'Coroa do Meio', 'Avenida Mario Jorge'),
            (7, 'Thiago Martins', '1990-11-09', 'Siqueira Campos', 'Rua Bahia'),
            (8, 'Camila Ribeiro', '1997-01-30', 'Suissa', 'Rua Riachuelo'),
            (9, 'Felipe Andrade', '1993-04-21', 'Salgado Filho', 'Rua Cedro'),
            (10, 'Juliana Barros', '2000-10-12', 'Ponto Novo', 'Rua Rio Grande do Sul'),
            (11, 'Daniel Oliveira', '1989-08-03', 'Industrial', 'Avenida Joao Rodrigues'),
            (12, 'Isabela Santos', '2002-05-19', 'Aracaju', 'Rua Propria'),
            (13, 'Matheus Lima', '1994-01-07', 'Bugio', 'Avenida Centenario'),
            (14, 'Amanda Freitas', '1996-12-26', 'Cirurgia', 'Rua Lagarto'),
            (15, 'Pedro Henrique', '1991-07-15', 'Inacio Barbosa', 'Avenida Paulo VI'),
            (16, 'Natalia Gomes', '1999-02-08', 'Aeroporto', 'Rua Renato Fonseca'),
            (17, 'Victor Souza', '1988-09-20', 'Santo Antonio', 'Rua Sao Joao'),
            (18, 'Leticia Carvalho', '2001-11-11', 'Treze de Julho', 'Rua Campo do Brito'),
            (19, 'Eduardo Moraes', '1995-05-06', 'America', 'Rua Acre'),
            (20, 'Renata Lopes', '1997-08-18', 'Cidade Nova', 'Avenida Euclides Figueiredo'),
            (21, 'Henrique Araujo', '1992-03-25', 'Olaria', 'Rua Santa Catarina'),
            (22, 'Patricia Monteiro', '1987-10-04', 'Jose Conrado de Araujo', 'Rua Porto Alegre'),
            (23, 'Caio Dantas', '2000-06-29', 'Pereira Lobo', 'Rua Dom Bosco'),
            (24, 'Sabrina Vieira', '1998-01-16', 'Dezoito do Forte', 'Rua Carlos Correia'),
            (25, 'Bruno Tavares', '1993-12-22', 'Getulio Vargas', 'Rua Siriri'),
            (26, 'Vanessa Cardoso', '1996-04-10', 'Novo Paraiso', 'Avenida Osvaldo Aranha'),
            (27, 'Diego Fontes', '1990-07-31', 'Palestina', 'Rua Paraiba'),
            (28, 'Aline Farias', '2002-09-13', 'Soledade', 'Avenida Carlos Marques'),
            (29, 'Gustavo Reis', '1994-06-02', 'Capucho', 'Rua Projetada'),
            (30, 'Monica Sales', '1989-11-24', 'Zona de Expansao', 'Rodovia dos Naufragos');

        --Carga adicional: 30 clientes e 30 enderecos

        SET @indice = 1;

        WHILE @indice <= 30
        BEGIN
            SELECT @nome = nome,
                   @data_nascimento = data_nascimento,
                   @bairro = bairro,
                   @logradouro = logradouro
            FROM @dados_clientes
            WHERE ordem = @indice;

            SET @email = 'cliente' + RIGHT('00' + CAST(@indice AS VARCHAR(2)), 2) + '@delifit.com';
            SET @telefone = '(79) 998' + RIGHT('00' + CAST(@indice AS VARCHAR(2)), 2) + '-' + RIGHT('0000' + CAST(1000 + @indice AS VARCHAR(4)), 4);
            SET @data_evento = DATEADD(DAY, @indice, CAST('2025-06-15 09:00:00' AS DATETIME2));

            EXEC oltp.sp_cadastrar_cliente
                 @nome = @nome,
                 @email = @email,
                 @senha_hash = 'HASH_CLIENTE_CARGA_001',
                 @telefone = @telefone,
                 @data_nascimento = @data_nascimento,
                 @data_cadastro = @data_evento,
                 @cliente_id = @novo_cliente_id OUTPUT;

            SET @cep = '490' + RIGHT('00' + CAST(@indice AS VARCHAR(2)), 2) + '-' + RIGHT('000' + CAST(100 + @indice AS VARCHAR(3)), 3);
            SET @numero = CAST(100 + (@indice * 7) AS VARCHAR(20));

            EXEC oltp.sp_cadastrar_endereco
                 @cliente_id = @novo_cliente_id,
                 @nome_endereco = 'Casa',
                 @cep = @cep,
                 @logradouro = @logradouro,
                 @numero = @numero,
                 @bairro = @bairro,
                 @cidade = 'Aracaju',
                 @estado = 'SE',
                 @endereco_principal = 1,
                 @endereco_id = @novo_endereco_id OUTPUT;

            INSERT INTO @clientes_carga (cliente_id, endereco_id)
            VALUES (@novo_cliente_id, @novo_endereco_id);

            SET @indice += 1;
        END;

        INSERT INTO @dados_restaurantes (ordem, responsavel, nome_fantasia, bairro)
        VALUES
            (1, 'Ricardo Menezes', 'Verde no Prato', 'Jardins'),
            (2, 'Fernanda Correia', 'Bowl & Vida', 'Grageru'),
            (3, 'Paulo Santana', 'Leve Sabor', 'Atalaia'),
            (4, 'Cristina Ramos', 'Nutri House', 'Farolandia'),
            (5, 'Marcelo Brito', 'Raiz Saudavel', 'Treze de Julho');

        --Carga adicional: 5 restaurantes e seus usuarios responsaveis

        SET @indice = 1;

        WHILE @indice <= 5
        BEGIN
            SELECT @nome = responsavel,
                   @nome_fantasia = nome_fantasia,
                   @bairro = bairro
            FROM @dados_restaurantes
            WHERE ordem = @indice;

            SET @email = 'restaurante' + CAST(@indice AS VARCHAR(2)) + '@delifit.com';
            SET @telefone = '(79) 3344-' + RIGHT('0000' + CAST(2000 + @indice AS VARCHAR(4)), 4);
            SET @cnpj = '33.333.33' + CAST(@indice AS VARCHAR(1)) + '/0001-00';
            SET @cep = '49040-' + RIGHT('000' + CAST(200 + @indice AS VARCHAR(3)), 3);
            SET @numero = CAST(500 + (@indice * 20) AS VARCHAR(20));
            SET @data_evento = DATEADD(DAY, @indice, CAST('2025-06-20 08:00:00' AS DATETIME2));

            EXEC oltp.sp_cadastrar_restaurante
                 @nome_responsavel = @nome,
                 @email = @email,
                 @senha_hash = 'HASH_RESTAURANTE_CARGA_001',
                 @nome_fantasia = @nome_fantasia,
                 @cnpj = @cnpj,
                 @descricao = 'Restaurante parceiro especializado em alimentacao saudavel',
                 @telefone = @telefone,
                 @cep = @cep,
                 @logradouro = 'Avenida dos Restaurantes',
                 @numero = @numero,
                 @bairro = @bairro,
                 @cidade = 'Aracaju',
                 @estado = 'SE',
                 @data_cadastro = @data_evento,
                 @restaurante_id = @novo_restaurante_id OUTPUT;

            INSERT INTO @restaurantes_carga (restaurante_id)
            VALUES (@novo_restaurante_id);

            SET @indice += 1;
        END;

        INSERT INTO @dados_itens
        (ordem, restaurante_ordem, categoria_ordem, nome, preco, calorias, proteinas, carboidratos, gorduras, restricao)
        VALUES
            (1, 1, 1, 'Bowl de Frango e Quinoa', 29.90, 430, 36, 42, 10, 'SEM_GLUTEN'),
            (2, 1, 1, 'Salada Mediterranea', 24.50, 280, 12, 30, 11, 'VEGETARIANO'),
            (3, 1, 2, 'Chips de Batata-doce', 11.90, 170, 3, 32, 4, 'VEGANO'),
            (4, 1, 2, 'Mix de Castanhas', 14.90, 220, 7, 14, 16, 'SEM_GLUTEN'),
            (5, 1, 1, 'Bowl Vegano de Grao-de-bico', 27.90, 390, 18, 52, 9, 'VEGANO'),
            (6, 2, 1, 'Bowl de Salmao', 36.90, 460, 34, 38, 17, 'SEM_GLUTEN'),
            (7, 2, 1, 'Bowl Tropical', 25.90, 340, 10, 55, 8, 'VEGANO'),
            (8, 2, 2, 'Barra de Cereal Artesanal', 8.50, 140, 4, 24, 5, 'VEGETARIANO'),
            (9, 2, 2, 'Cookie Integral', 9.90, 180, 5, 27, 7, 'SEM_ACUCAR'),
            (10, 2, 1, 'Salada Caesar Light', 26.50, 310, 28, 18, 13, NULL),
            (11, 3, 1, 'Salada de Atum', 28.90, 330, 31, 20, 14, 'SEM_GLUTEN'),
            (12, 3, 1, 'Bowl de Carne e Legumes', 32.90, 490, 39, 41, 15, NULL),
            (13, 3, 2, 'Pao de Queijo Fit', 10.90, 160, 6, 21, 6, 'SEM_GLUTEN'),
            (14, 3, 2, 'Iogurte com Granola', 13.50, 210, 10, 32, 5, 'VEGETARIANO'),
            (15, 3, 1, 'Bowl Caprese', 24.90, 300, 16, 25, 14, 'VEGETARIANO'),
            (16, 4, 1, 'Salada Proteica', 30.50, 410, 42, 24, 13, 'SEM_GLUTEN'),
            (17, 4, 1, 'Bowl de Tofu Grelhado', 27.50, 360, 24, 39, 12, 'VEGANO'),
            (18, 4, 2, 'Muffin de Banana', 9.50, 175, 5, 31, 5, 'SEM_ACUCAR'),
            (19, 4, 2, 'Palitos de Cenoura com Homus', 12.90, 190, 7, 25, 8, 'VEGANO'),
            (20, 4, 1, 'Salada de Frango com Abacate', 31.90, 440, 35, 22, 21, 'SEM_GLUTEN'),
            (21, 5, 1, 'Bowl Nordestino Fit', 28.50, 420, 32, 48, 11, 'SEM_GLUTEN'),
            (22, 5, 1, 'Salada de Graos', 23.90, 320, 14, 46, 9, 'VEGANO'),
            (23, 5, 2, 'Brownie de Batata-doce', 12.50, 185, 6, 28, 7, 'SEM_ACUCAR'),
            (24, 5, 2, 'Bolinha Energetica de Cacau', 10.50, 155, 5, 20, 7, 'VEGANO'),
            (25, 5, 1, 'Bowl de Peru e Arroz Integral', 31.50, 470, 38, 49, 12, NULL);

        --Carga adicional: 25 itens de cardapio

        SET @indice = 1;

        WHILE @indice <= 25
        BEGIN
            SELECT @subindice = restaurante_ordem,
                   @nome = nome,
                   @preco = preco,
                   @calorias = calorias,
                   @proteinas = proteinas,
                   @carboidratos = carboidratos,
                   @gorduras = gorduras,
                   @restricao = restricao,
                   @categoria_item_id = categoria_ordem
            FROM @dados_itens
            WHERE ordem = @indice;

            SELECT @novo_restaurante_id = restaurante_id
            FROM @restaurantes_carga
            WHERE ordem = @subindice + 2;

            SET @categoria_item_id = CASE WHEN @categoria_item_id = 1 THEN @categoria_salada ELSE @categoria_snack END;
            SET @data_evento = DATEADD(DAY, @indice, CAST('2025-06-25 08:00:00' AS DATETIME2));

            EXEC oltp.sp_cadastrar_item_cardapio
                 @restaurante_id = @novo_restaurante_id,
                 @categoria_id = @categoria_item_id,
                 @nome = @nome,
                 @descricao = 'Item preparado com ingredientes frescos e selecionados',
                 @preco = @preco,
                 @calorias = @calorias,
                 @proteinas = @proteinas,
                 @carboidratos = @carboidratos,
                 @gorduras = @gorduras,
                 @restricao_alimentar = @restricao,
                 @data_cadastro = @data_evento,
                 @item_cardapio_id = @novo_item_id OUTPUT;

            INSERT INTO @itens_carga (item_cardapio_id, restaurante_id)
            VALUES (@novo_item_id, @novo_restaurante_id);

            SET @indice += 1;
        END;

        --Carga adicional: 120 pedidos e 300 itens de pedido

        SET @indice = 1;

        WHILE @indice <= 120
        BEGIN
            SELECT @cliente_pedido_id = cliente_id,
                   @endereco_pedido_id = endereco_id
            FROM @clientes_carga
            WHERE ordem = ((@indice - 1) % 33) + 1;

            SELECT @restaurante_pedido_id = restaurante_id
            FROM @restaurantes_carga
            WHERE ordem = ((@indice - 1) % 7) + 1;

            SET @forma_pagamento = CASE @indice % 4
                                       WHEN 0 THEN 'PIX'
                                       WHEN 1 THEN 'CARTAO_CREDITO'
                                       WHEN 2 THEN 'CARTAO_DEBITO'
                                       ELSE 'DINHEIRO'
                                   END;
            SET @valor_frete = 4.00 + (@indice % 6);
            SET @data_pedido = DATEADD(MINUTE, 660 + ((@indice * 37) % 600),
                                       DATEADD(DAY, @indice - 1, CAST('2025-07-01' AS DATETIME2)));

            EXEC oltp.sp_criar_pedido
                 @cliente_id = @cliente_pedido_id,
                 @restaurante_id = @restaurante_pedido_id,
                 @endereco_entrega_id = @endereco_pedido_id,
                 @forma_pagamento = @forma_pagamento,
                 @valor_frete = @valor_frete,
                 @criado_em = @data_pedido,
                 @pedido_id = @novo_pedido_id OUTPUT;

            SET @quantidade_linhas = CASE WHEN @indice <= 60 THEN 2 ELSE 3 END;
            SET @subindice = 1;

            SELECT @quantidade_itens_restaurante = COUNT(*)
            FROM @itens_carga
            WHERE restaurante_id = @restaurante_pedido_id;

            WHILE @subindice <= @quantidade_linhas
            BEGIN
                SELECT @item_pedido_cardapio_id = item_cardapio_id
                FROM
                (
                    SELECT item_cardapio_id,
                           ROW_NUMBER() OVER (ORDER BY item_cardapio_id) AS ordem_item
                    FROM @itens_carga
                    WHERE restaurante_id = @restaurante_pedido_id
                ) itens_restaurante
                WHERE ordem_item = ((@indice + @subindice - 2) % @quantidade_itens_restaurante) + 1;

                SET @quantidade = 1 + ((@indice + @subindice) % 3);

                EXEC oltp.sp_adicionar_item_pedido
                     @pedido_id = @novo_pedido_id,
                     @item_cardapio_id = @item_pedido_cardapio_id,
                     @quantidade = @quantidade,
                     @item_pedido_id = @item_pedido_id OUTPUT;

                SET @subindice += 1;
            END;

            SET @cenario_status = ((@indice - 1) % 8) + 1;

            IF @cenario_status <= 4
            BEGIN
                SET @data_evento = DATEADD(MINUTE, 2, @data_pedido);
                EXEC oltp.sp_atualizar_status_pagamento
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'PAGO',
                     @data_pagamento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 5, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'CONFIRMADO',
                     @data_evento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 45 + (@indice % 31), @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'ENTREGUE',
                     @data_evento = @data_evento;
            END
            ELSE IF @cenario_status = 5
            BEGIN
                EXEC oltp.sp_atualizar_status_pagamento
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'FALHOU';

                SET @data_evento = DATEADD(MINUTE, 10, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'CANCELADO',
                     @data_evento = @data_evento;
            END
            ELSE IF @cenario_status = 6
            BEGIN
                SET @data_evento = DATEADD(MINUTE, 2, @data_pedido);
                EXEC oltp.sp_atualizar_status_pagamento
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'PAGO',
                     @data_pagamento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 5, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'CONFIRMADO',
                     @data_evento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 15, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'EM_PREPARO',
                     @data_evento = @data_evento;
            END
            ELSE IF @cenario_status = 7
            BEGIN
                SET @data_evento = DATEADD(MINUTE, 2, @data_pedido);
                EXEC oltp.sp_atualizar_status_pagamento
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'PAGO',
                     @data_pagamento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 5, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'CONFIRMADO',
                     @data_evento = @data_evento;

                SET @data_evento = DATEADD(MINUTE, 35, @data_pedido);
                EXEC oltp.sp_atualizar_status_pedido
                     @pedido_id = @novo_pedido_id,
                     @novo_status = 'SAIU_PARA_ENTREGA',
                     @data_evento = @data_evento;
            END;

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

--Executar o povoamento

EXEC oltp.sp_povoar_ambiente;
GO


--Limpar dados
CREATE OR ALTER PROCEDURE oltp.sp_limpar_ambiente
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        --Filhas

        DELETE FROM oltp.itens_pedido;
        DELETE FROM oltp.pedidos;

        --Dependências de restaurantes e clientes

        DELETE FROM oltp.itens_cardapio;
        DELETE FROM oltp.categorias_cardapio;

        DELETE FROM oltp.enderecos;
        DELETE FROM oltp.restaurantes;
        DELETE FROM oltp.clientes;

        --Tabela raiz

        DELETE FROM oltp.usuarios;

        --Reinicia os IDs

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

--Executando limpeza
--EXEC oltp.sp_limpar_ambiente;
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

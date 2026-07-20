/* =========================================================
   BANCO DE DADOS: DELIFIT
   SGBD: SQL SERVER
   AMBIENTE: OLTP
   ========================================================= */

/* =========================================================
    DDL
   ========================================================= */

USE master;
GO

IF DB_ID('DeliFitDB') IS NULL
BEGIN
    CREATE DATABASE DeliFitDB;
END;
GO

USE DeliFitDB;
GO

/* =========================================================
   Criação  schema OLTP
   ========================================================= */

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'oltp'
)
BEGIN
    EXEC('CREATE SCHEMA oltp');
END;
GO

/* =========================================================
   1. USUÁRIOS
   ========================================================= */

CREATE TABLE oltp.usuarios
(
    usuario_id          BIGINT IDENTITY(1,1) NOT NULL,
    nome                VARCHAR(150) NOT NULL,
    email               VARCHAR(150) NOT NULL,
    senha_hash          VARCHAR(255) NOT NULL,
    telefone            VARCHAR(20) NULL,
    tipo_usuario        VARCHAR(20) NOT NULL,
    ativo               BIT NOT NULL
        CONSTRAINT df_usuarios_ativo DEFAULT 1,
    data_cadastro       DATETIME2 NOT NULL
        CONSTRAINT df_usuarios_data_cadastro DEFAULT SYSDATETIME(),

    CONSTRAINT pk_usuarios
        PRIMARY KEY (usuario_id),

    CONSTRAINT uq_usuarios_email
        UNIQUE (email),

    CONSTRAINT ck_usuarios_tipo
        CHECK (tipo_usuario IN ('CLIENTE', 'RESTAURANTE'))
);
GO

/* =========================================================
   2. CLIENTES
   ========================================================= */

CREATE TABLE oltp.clientes
(
    cliente_id          BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id          BIGINT NOT NULL,
    data_nascimento     DATE NULL,

    CONSTRAINT pk_clientes
        PRIMARY KEY (cliente_id),

    CONSTRAINT uq_clientes_usuario
        UNIQUE (usuario_id),

    CONSTRAINT fk_clientes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES oltp.usuarios (usuario_id)
);
GO

/* =========================================================
   3. ENDEREÇOS
   ========================================================= */

CREATE TABLE oltp.enderecos
(
    endereco_id         BIGINT IDENTITY(1,1) NOT NULL,
    cliente_id          BIGINT NOT NULL,
    nome_endereco       VARCHAR(50) NULL,
    cep                 VARCHAR(9) NOT NULL,
    logradouro          VARCHAR(150) NOT NULL,
    numero              VARCHAR(20) NOT NULL,
    complemento         VARCHAR(100) NULL,
    bairro              VARCHAR(100) NOT NULL,
    cidade              VARCHAR(100) NOT NULL,
    estado              CHAR(2) NOT NULL,
    endereco_principal  BIT NOT NULL
        CONSTRAINT df_enderecos_principal DEFAULT 0,
    ativo               BIT NOT NULL
        CONSTRAINT df_enderecos_ativo DEFAULT 1,

    CONSTRAINT pk_enderecos
        PRIMARY KEY (endereco_id),

    CONSTRAINT fk_enderecos_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES oltp.clientes (cliente_id),

    CONSTRAINT ck_enderecos_estado
        CHECK (LEN(estado) = 2)
);
GO

/* =========================================================
   4. RESTAURANTES
   ========================================================= */

CREATE TABLE oltp.restaurantes
(
    restaurante_id      BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id          BIGINT NOT NULL,
    nome_fantasia       VARCHAR(150) NOT NULL,
    cnpj                VARCHAR(18) NOT NULL,
    descricao           VARCHAR(500) NULL,
    telefone            VARCHAR(20) NULL,

    cep                 VARCHAR(9) NOT NULL,
    logradouro          VARCHAR(150) NOT NULL,
    numero              VARCHAR(20) NOT NULL,
    complemento         VARCHAR(100) NULL,
    bairro              VARCHAR(100) NOT NULL,
    cidade              VARCHAR(100) NOT NULL,
    estado              CHAR(2) NOT NULL,

    ativo               BIT NOT NULL
        CONSTRAINT df_restaurantes_ativo DEFAULT 1,
    data_cadastro       DATETIME2 NOT NULL
        CONSTRAINT df_restaurantes_data_cadastro DEFAULT SYSDATETIME(),

    CONSTRAINT pk_restaurantes
        PRIMARY KEY (restaurante_id),

    CONSTRAINT uq_restaurantes_usuario
        UNIQUE (usuario_id),

    CONSTRAINT uq_restaurantes_cnpj
        UNIQUE (cnpj),

    CONSTRAINT fk_restaurantes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES oltp.usuarios (usuario_id),

    CONSTRAINT ck_restaurantes_estado
        CHECK (LEN(estado) = 2)
);
GO

/* =========================================================
   5. CATEGORIAS DO CARDÁPIO
   ========================================================= */

CREATE TABLE oltp.categorias_cardapio
(
    categoria_id        INT IDENTITY(1,1) NOT NULL,
    nome                VARCHAR(100) NOT NULL,
    descricao           VARCHAR(300) NULL,
    ativo               BIT NOT NULL
        CONSTRAINT df_categorias_ativo DEFAULT 1,

    CONSTRAINT pk_categorias_cardapio
        PRIMARY KEY (categoria_id),

    CONSTRAINT uq_categorias_cardapio_nome
        UNIQUE (nome)
);
GO

/* =========================================================
   6. ITENS DO CARDÁPIO
   ========================================================= */

CREATE TABLE oltp.itens_cardapio
(
    item_cardapio_id    BIGINT IDENTITY(1,1) NOT NULL,
    restaurante_id      BIGINT NOT NULL,
    categoria_id        INT NOT NULL,
    nome                VARCHAR(150) NOT NULL,
    descricao           VARCHAR(500) NULL,
    preco               DECIMAL(10,2) NOT NULL,

    calorias            DECIMAL(10,2) NULL,
    proteinas           DECIMAL(10,2) NULL,
    carboidratos        DECIMAL(10,2) NULL,
    gorduras            DECIMAL(10,2) NULL,
    restricao_alimentar VARCHAR(50) NULL,

    disponivel          BIT NOT NULL
        CONSTRAINT df_itens_disponivel DEFAULT 1,
    data_cadastro       DATETIME2 NOT NULL
        CONSTRAINT df_itens_data_cadastro DEFAULT SYSDATETIME(),

    CONSTRAINT pk_itens_cardapio
        PRIMARY KEY (item_cardapio_id),

    CONSTRAINT fk_itens_restaurante
        FOREIGN KEY (restaurante_id)
        REFERENCES oltp.restaurantes (restaurante_id),

    CONSTRAINT fk_itens_categoria
        FOREIGN KEY (categoria_id)
        REFERENCES oltp.categorias_cardapio (categoria_id),

    CONSTRAINT ck_itens_preco
        CHECK (preco > 0),

    CONSTRAINT ck_itens_calorias
        CHECK (calorias IS NULL OR calorias >= 0),

    CONSTRAINT ck_itens_proteinas
        CHECK (proteinas IS NULL OR proteinas >= 0),

    CONSTRAINT ck_itens_carboidratos
        CHECK (carboidratos IS NULL OR carboidratos >= 0),

    CONSTRAINT ck_itens_gorduras
        CHECK (gorduras IS NULL OR gorduras >= 0)
);
GO

/* =========================================================
   7. PEDIDOS
   ========================================================= */

CREATE TABLE oltp.pedidos
(
    pedido_id               BIGINT IDENTITY(1,1) NOT NULL,
    cliente_id              BIGINT NOT NULL,
    restaurante_id          BIGINT NOT NULL,
    endereco_entrega_id     BIGINT NOT NULL,

    status_pedido           VARCHAR(30) NOT NULL
        CONSTRAINT df_pedidos_status DEFAULT 'PENDENTE',

    forma_pagamento         VARCHAR(30) NOT NULL,
    status_pagamento        VARCHAR(20) NOT NULL
        CONSTRAINT df_pedidos_status_pagamento DEFAULT 'PENDENTE',

    valor_subtotal          DECIMAL(10,2) NOT NULL,
    valor_frete             DECIMAL(10,2) NOT NULL
        CONSTRAINT df_pedidos_frete DEFAULT 0,
    valor_total             DECIMAL(10,2) NOT NULL,

    observacao              VARCHAR(500) NULL,

    criado_em               DATETIME2 NOT NULL
        CONSTRAINT df_pedidos_criado_em DEFAULT SYSDATETIME(),
    confirmado_em           DATETIME2 NULL,
    entregue_em             DATETIME2 NULL,
    cancelado_em            DATETIME2 NULL,
    pago_em                 DATETIME2 NULL,

    CONSTRAINT pk_pedidos
        PRIMARY KEY (pedido_id),

    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES oltp.clientes (cliente_id),

    CONSTRAINT fk_pedidos_restaurante
        FOREIGN KEY (restaurante_id)
        REFERENCES oltp.restaurantes (restaurante_id),

    CONSTRAINT fk_pedidos_endereco
        FOREIGN KEY (endereco_entrega_id)
        REFERENCES oltp.enderecos (endereco_id),

    CONSTRAINT ck_pedidos_status
        CHECK (
            status_pedido IN (
                'PENDENTE',
                'CONFIRMADO',
                'EM_PREPARO',
                'SAIU_PARA_ENTREGA',
                'ENTREGUE',
                'CANCELADO'
            )
        ),

    CONSTRAINT ck_pedidos_forma_pagamento
        CHECK (
            forma_pagamento IN (
                'PIX',
                'CARTAO_CREDITO',
                'CARTAO_DEBITO',
                'DINHEIRO'
            )
        ),

    CONSTRAINT ck_pedidos_status_pagamento
        CHECK (
            status_pagamento IN (
                'PENDENTE',
                'PAGO',
                'FALHOU',
                'CANCELADO'
            )
        ),

    CONSTRAINT ck_pedidos_valores
        CHECK (
            valor_subtotal >= 0
            AND valor_frete >= 0
            AND valor_total >= 0
        ),

    CONSTRAINT ck_pedidos_total
        CHECK (
            valor_total = valor_subtotal + valor_frete
        ),

    CONSTRAINT ck_pedidos_confirmacao
        CHECK (
            confirmado_em IS NULL
            OR confirmado_em >= criado_em
        ),

    CONSTRAINT ck_pedidos_entrega
        CHECK (
            entregue_em IS NULL
            OR entregue_em >= criado_em
        ),

    CONSTRAINT ck_pedidos_cancelamento
        CHECK (
            cancelado_em IS NULL
            OR cancelado_em >= criado_em
        ),

    CONSTRAINT ck_pedidos_pagamento
        CHECK (
            pago_em IS NULL
            OR pago_em >= criado_em
        )
);
GO

/* =========================================================
   8. ITENS DO PEDIDO
   ========================================================= */

CREATE TABLE oltp.itens_pedido
(
    item_pedido_id          BIGINT IDENTITY(1,1) NOT NULL,
    pedido_id               BIGINT NOT NULL,
    item_cardapio_id        BIGINT NOT NULL,

    nome_item_snapshot      VARCHAR(150) NOT NULL,
    descricao_snapshot      VARCHAR(500) NULL,
    preco_unitario_snapshot DECIMAL(10,2) NOT NULL,

    quantidade              INT NOT NULL,
    valor_total_item        DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_itens_pedido
        PRIMARY KEY (item_pedido_id),

    CONSTRAINT fk_itens_pedido_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES oltp.pedidos (pedido_id),

    CONSTRAINT fk_itens_pedido_item
        FOREIGN KEY (item_cardapio_id)
        REFERENCES oltp.itens_cardapio (item_cardapio_id),

    CONSTRAINT ck_itens_pedido_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT ck_itens_pedido_preco
        CHECK (preco_unitario_snapshot >= 0),

    CONSTRAINT ck_itens_pedido_total
        CHECK (
            valor_total_item =
            preco_unitario_snapshot * quantidade
        )
);
GO

/* =========================================================
   Indices
   ========================================================= */

CREATE INDEX ix_enderecos_cliente
    ON oltp.enderecos (cliente_id);
GO

CREATE INDEX ix_itens_restaurante
    ON oltp.itens_cardapio (restaurante_id);
GO

CREATE INDEX ix_itens_categoria
    ON oltp.itens_cardapio (categoria_id);
GO

CREATE INDEX ix_pedidos_cliente
    ON oltp.pedidos (cliente_id);
GO

CREATE INDEX ix_pedidos_restaurante
    ON oltp.pedidos (restaurante_id);
GO

CREATE INDEX ix_pedidos_data
    ON oltp.pedidos (criado_em);
GO

CREATE INDEX ix_pedidos_status
    ON oltp.pedidos (status_pedido);
GO

CREATE INDEX ix_itens_pedido_pedido
    ON oltp.itens_pedido (pedido_id);
GO

CREATE INDEX ix_itens_pedido_item
    ON oltp.itens_pedido (item_cardapio_id);
GO

/* =========================================================
   Criação Schema DW
   ========================================================= */

IF NOT EXISTS (
    SELECT *
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO

/* Criação das dimensões */

/*=========================================================
    1.DIMENSÃO TEMPO
=========================================================*/

CREATE TABLE dw.dim_tempo
(
    id_tempo        INT IDENTITY(1,1) PRIMARY KEY,
    dia             TINYINT NOT NULL,
    data            DATE NOT NULL UNIQUE,
    mes             TINYINT NOT NULL,
    trimestre       TINYINT NOT NULL,
    semestre        TINYINT NOT NULL,
    ano             SMALLINT NOT NULL,
    dia_semana      VARCHAR(20) NOT NULL,
    feriado         BIT NOT NULL

);
GO


/*=========================================================
    2.DIMENSÃO CLIENTE
=========================================================*/

CREATE TABLE dw.dim_cliente
(
    id_cliente          INT IDENTITY(1,1) PRIMARY KEY,
    cliente_id          BIGINT NOT NULL,
    faixa_etaria        VARCHAR(30),
    idade               INT,
    data_cadastro       DATE,
    data_inicio         DATETIME NOT NULL,
    data_fim            DATETIME NULL,
    registro_ativo      BIT NOT NULL
);
GO

/*=========================================================
    3.DIMENSÃO ENDEREÇO
=========================================================*/

CREATE TABLE dw.dim_endereco
(
    id_endereco         INT IDENTITY(1,1) PRIMARY KEY,
    endereco_id         BIGINT NOT NULL,
    cep                 VARCHAR(10),
    logradouro          VARCHAR(150),
    bairro              VARCHAR(100),
    numero              VARCHAR(20),
    cidade              VARCHAR(100),
    estado              CHAR(2),
    complemento         VARCHAR(150),
    data_inicio         DATETIME NOT NULL,
    data_fim            DATETIME NULL,
    registro_ativo      BIT NOT NULL
);
GO

/*=========================================================
    4.DIMENSÃO RESTAURANTE
=========================================================*/

CREATE TABLE dw.dim_restaurante
(
    id_restaurante      INT IDENTITY(1,1) PRIMARY KEY,
    restaurante_id      BIGINT NOT NULL,
    nome_fantasia       VARCHAR(150) NOT NULL,
    cidade              VARCHAR(100),
    estado              CHAR(2),
    data_cadastro       DATE,
    ativo               BIT NOT NULL
);
GO

/*=========================================================
    5.DIMENSÃO ITEM
=========================================================*/

CREATE TABLE dw.dim_item
(
    id_item                 INT IDENTITY(1,1) PRIMARY KEY,
    item_cardapio_id        BIGINT NOT NULL,
    nome                    VARCHAR(150) NOT NULL,
    categoria               VARCHAR(100),
    calorias                DECIMAL(10,2),
    proteinas               DECIMAL(10,2),
    carboidratos             DECIMAL(10,2),
    gorduras                 DECIMAL(10,2),
    restricao_alimentar     VARCHAR(100),
    faixa_preco             VARCHAR(50),
    disponivel              BIT NOT NULL,
    preco_atual             DECIMAL(10,2),
    data_inicio         DATETIME NOT NULL,
    data_fim            DATETIME NULL,
    registro_ativo      BIT NOT NULL
);
GO

/*=========================================================
    6.DIMENSÃO PAGAMENTO
=========================================================*/

CREATE TABLE dw.dim_pagamento
(
    id_pagamento        INT IDENTITY(1,1) PRIMARY KEY,
    forma_pagamento     VARCHAR(50) NOT NULL,
    status_pagamento    VARCHAR(50) NOT NULL
);

ALTER TABLE dw.dim_pagamento
ADD CONSTRAINT UQ_dim_pagamento
UNIQUE (forma_pagamento, status_pagamento);
GO

/*=========================================================
    7.DIMENSÃO STATUS
=========================================================*/

CREATE TABLE dw.dim_status
(
    id_status           INT IDENTITY(1,1) PRIMARY KEY,
    status_pedido       VARCHAR(50) NOT NULL UNIQUE
);
GO

/*=========================================================
    Criação do fato vendas
  =========================================================*/
CREATE TABLE dw.ft_venda
(
    id_venda                BIGINT IDENTITY(1,1) PRIMARY KEY,

    id_tempo                INT NOT NULL,
    id_cliente              INT NOT NULL,
    id_endereco             INT NOT NULL,
    id_restaurante          INT NOT NULL,
    id_item                 INT NOT NULL,
    id_pagamento            INT NOT NULL,
    id_status               INT NOT NULL,

    pedido_id               BIGINT NOT NULL,
    item_pedido_id          BIGINT NOT NULL,

    quantidade              INT NOT NULL,
    valor_unitario          DECIMAL(10,2) NOT NULL,
    valor_total_item        DECIMAL(12,2) NOT NULL,
    valor_frete_rateado     DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_FT_TEMPO
        FOREIGN KEY (id_tempo)
        REFERENCES dw.dim_tempo(id_tempo),

    CONSTRAINT FK_FT_CLIENTE
        FOREIGN KEY (id_cliente)
        REFERENCES dw.dim_cliente(id_cliente),

    CONSTRAINT FK_FT_ENDERECO
        FOREIGN KEY (id_endereco)
        REFERENCES dw.dim_endereco(id_endereco),

    CONSTRAINT FK_FT_RESTAURANTE
        FOREIGN KEY (id_restaurante)
        REFERENCES dw.dim_restaurante(id_restaurante),

    CONSTRAINT FK_FT_ITEM
        FOREIGN KEY (id_item)
        REFERENCES dw.dim_item(id_item),

    CONSTRAINT FK_FT_PAGAMENTO
        FOREIGN KEY (id_pagamento)
        REFERENCES dw.dim_pagamento(id_pagamento),

    CONSTRAINT FK_FT_STATUS
        FOREIGN KEY (id_status)
        REFERENCES dw.dim_status(id_status)
);
GO

/*=========================================================
    ÍNDICES
=========================================================*/

CREATE INDEX IX_FT_TEMPO
ON dw.ft_venda(id_tempo);

CREATE INDEX IX_FT_CLIENTE
ON dw.ft_venda(id_cliente);

CREATE INDEX IX_FT_RESTAURANTE
ON dw.ft_venda(id_restaurante);

CREATE INDEX IX_FT_ITEM
ON dw.ft_venda(id_item);

CREATE INDEX IX_FT_PAGAMENTO
ON dw.ft_venda(id_pagamento);

CREATE INDEX IX_FT_STATUS
ON dw.ft_venda(id_status);

CREATE INDEX IX_FT_PEDIDO
ON dw.ft_venda(pedido_id);
GO


/* =========================================================
   Criação schema STG
   ========================================================= */

IF NOT EXISTS (
    SELECT 1 FROM sys.schemas WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO

/* =========================================================
   1. STG_USUARIOS
   ========================================================= */

CREATE TABLE stg.stg_usuarios
(
    usuario_id       BIGINT       NOT NULL,
    nome             VARCHAR(150) NULL,
    email            VARCHAR(150) NULL,
    telefone         VARCHAR(20)  NULL,
    tipo_usuario     VARCHAR(20)  NULL,
    ativo            BIT          NULL,
    data_cadastro    DATETIME     NULL,
    dt_extracao      DATETIME     NOT NULL
        CONSTRAINT df_stg_usuarios_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_usuarios
        PRIMARY KEY (usuario_id)
);
GO

/* =========================================================
   2. STG_CLIENTES
   ========================================================= */

CREATE TABLE stg.stg_clientes
(
    cliente_id       BIGINT   NOT NULL,
    usuario_id       BIGINT   NULL,
    data_nascimento  DATE     NULL,
    dt_extracao      DATETIME NOT NULL
        CONSTRAINT df_stg_clientes_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_clientes
        PRIMARY KEY (cliente_id)
);
GO

/* =========================================================
   3. STG_ENDERECOS
   ========================================================= */

CREATE TABLE stg.stg_enderecos
(
    endereco_id         BIGINT       NOT NULL,
    cliente_id          BIGINT       NULL,
    nome_endereco       VARCHAR(50)  NULL,
    cep                 VARCHAR(9)   NULL,
    logradouro          VARCHAR(150) NULL,
    numero              VARCHAR(20)  NULL,
    complemento         VARCHAR(100) NULL,
    bairro              VARCHAR(100) NULL,
    cidade              VARCHAR(100) NULL,
    estado              CHAR(2)      NULL,
    endereco_principal  BIT          NULL,
    ativo               BIT          NULL,
    dt_extracao         DATETIME     NOT NULL
        CONSTRAINT df_stg_enderecos_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_enderecos
        PRIMARY KEY (endereco_id)
);
GO

/* =========================================================
   4. STG_RESTAURANTES
   ========================================================= */

CREATE TABLE stg.stg_restaurantes
(
    restaurante_id   BIGINT       NOT NULL,
    usuario_id       BIGINT       NULL,
    nome_fantasia    VARCHAR(150) NULL,
    cnpj             VARCHAR(18)  NULL,
    descricao        VARCHAR(500) NULL,
    telefone         VARCHAR(20)  NULL,
    cep              VARCHAR(9)   NULL,
    logradouro       VARCHAR(150) NULL,
    numero           VARCHAR(20)  NULL,
    complemento      VARCHAR(100) NULL,
    bairro           VARCHAR(100) NULL,
    cidade           VARCHAR(100) NULL,
    estado           CHAR(2)      NULL,
    ativo            BIT          NULL,
    data_cadastro    DATETIME     NULL,
    dt_extracao      DATETIME     NOT NULL
        CONSTRAINT df_stg_restaurantes_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_restaurantes
        PRIMARY KEY (restaurante_id)
);
GO

/* =========================================================
   5. STG_CATEGORIAS_CARDAPIO
   ========================================================= */

CREATE TABLE stg.stg_categorias_cardapio
(
    categoria_id     INT          NOT NULL,
    nome             VARCHAR(100) NULL,
    descricao        VARCHAR(300) NULL,
    ativo            BIT          NULL,
    dt_extracao      DATETIME     NOT NULL
        CONSTRAINT df_stg_categorias_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_categorias_cardapio
        PRIMARY KEY (categoria_id)
);
GO

/* =========================================================
   6. STG_ITENS_CARDAPIO
   ========================================================= */

CREATE TABLE stg.stg_itens_cardapio
(
    item_cardapio_id     BIGINT        NOT NULL,
    restaurante_id       BIGINT        NULL,
    categoria_id         INT           NULL,
    nome                 VARCHAR(150)  NULL,
    descricao            VARCHAR(500)  NULL,
    preco                DECIMAL(10,2) NULL,
    calorias             DECIMAL(10,2) NULL,
    proteinas            DECIMAL(10,2) NULL,
    carboidratos         DECIMAL(10,2) NULL,
    gorduras             DECIMAL(10,2) NULL,
    restricao_alimentar  VARCHAR(50)   NULL,
    disponivel           BIT           NULL,
    data_cadastro        DATETIME      NULL,
    dt_extracao          DATETIME      NOT NULL
        CONSTRAINT df_stg_itens_cardapio_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_itens_cardapio
        PRIMARY KEY (item_cardapio_id)
);
GO

/* =========================================================
   7. STG_PEDIDOS
   ========================================================= */

CREATE TABLE stg.stg_pedidos
(
    pedido_id               BIGINT        NOT NULL,
    cliente_id              BIGINT        NULL,
    restaurante_id          BIGINT        NULL,
    endereco_entrega_id     BIGINT        NULL,
    status_pedido           VARCHAR(30)   NULL,
    forma_pagamento         VARCHAR(30)   NULL,
    status_pagamento        VARCHAR(20)   NULL,
    valor_subtotal          DECIMAL(10,2) NULL,
    valor_frete             DECIMAL(10,2) NULL,
    valor_total             DECIMAL(10,2) NULL,
    observacao              VARCHAR(500)  NULL,
    criado_em               DATETIME      NULL,
    confirmado_em           DATETIME      NULL,
    entregue_em              DATETIME      NULL,
    cancelado_em            DATETIME      NULL,
    pago_em                 DATETIME      NULL,
    dt_extracao             DATETIME      NOT NULL
        CONSTRAINT df_stg_pedidos_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_pedidos
        PRIMARY KEY (pedido_id)
);
GO

/* =========================================================
   8. STG_ITENS_PEDIDO
   ========================================================= */

CREATE TABLE stg.stg_itens_pedido
(
    item_pedido_id          BIGINT        NOT NULL,
    pedido_id               BIGINT        NULL,
    item_cardapio_id        BIGINT        NULL,
    nome_item_snapshot      VARCHAR(150)  NULL,
    descricao_snapshot      VARCHAR(500)  NULL,
    preco_unitario_snapshot DECIMAL(10,2) NULL,
    quantidade               INT          NULL,
    valor_total_item        DECIMAL(10,2) NULL,
    dt_extracao              DATETIME     NOT NULL
        CONSTRAINT df_stg_itens_pedido_dt_extracao DEFAULT SYSDATETIME(),

    CONSTRAINT pk_stg_itens_pedido
        PRIMARY KEY (item_pedido_id)
);
GO

/* =========================================================
   ÍNDICES
   ========================================================= */

CREATE INDEX ix_stg_clientes_usuario
    ON stg.stg_clientes (usuario_id);
GO

CREATE INDEX ix_stg_enderecos_cliente
    ON stg.stg_enderecos (cliente_id);
GO

CREATE INDEX ix_stg_restaurantes_usuario
    ON stg.stg_restaurantes (usuario_id);
GO

CREATE INDEX ix_stg_itens_cardapio_restaurante
    ON stg.stg_itens_cardapio (restaurante_id);
GO

CREATE INDEX ix_stg_itens_cardapio_categoria
    ON stg.stg_itens_cardapio (categoria_id);
GO

CREATE INDEX ix_stg_pedidos_cliente
    ON stg.stg_pedidos (cliente_id);
GO

CREATE INDEX ix_stg_pedidos_restaurante
    ON stg.stg_pedidos (restaurante_id);
GO

CREATE INDEX ix_stg_pedidos_endereco
    ON stg.stg_pedidos (endereco_entrega_id);
GO

CREATE INDEX ix_stg_itens_pedido_pedido
    ON stg.stg_itens_pedido (pedido_id);
GO

CREATE INDEX ix_stg_itens_pedido_item
    ON stg.stg_itens_pedido (item_cardapio_id);
GO



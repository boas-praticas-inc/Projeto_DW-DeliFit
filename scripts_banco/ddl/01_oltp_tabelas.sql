/* 01 - Tabelas e indices do ambiente operacional */
USE DeliFitDB;
GO

CREATE TABLE oltp.usuarios
(
    usuario_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    telefone VARCHAR(20) NULL,
    tipo_usuario VARCHAR(20) NOT NULL,
    ativo BIT NOT NULL CONSTRAINT df_usuarios_ativo DEFAULT 1,
    data_cadastro DATETIME2 NOT NULL CONSTRAINT df_usuarios_data_cadastro DEFAULT SYSDATETIME(),
    CONSTRAINT ck_usuarios_tipo CHECK (tipo_usuario IN ('CLIENTE', 'RESTAURANTE'))
);
GO

CREATE TABLE oltp.clientes
(
    cliente_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    data_nascimento DATE NULL,
    CONSTRAINT fk_clientes_usuario FOREIGN KEY (usuario_id) REFERENCES oltp.usuarios(usuario_id)
);
GO

CREATE TABLE oltp.enderecos
(
    endereco_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    nome_endereco VARCHAR(50) NULL,
    cep VARCHAR(9) NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100) NULL,
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado CHAR(2) NOT NULL,
    endereco_principal BIT NOT NULL CONSTRAINT df_enderecos_principal DEFAULT 0,
    ativo BIT NOT NULL CONSTRAINT df_enderecos_ativo DEFAULT 1,
    CONSTRAINT fk_enderecos_cliente FOREIGN KEY (cliente_id) REFERENCES oltp.clientes(cliente_id),
    CONSTRAINT ck_enderecos_estado CHECK (LEN(estado) = 2)
);
GO

CREATE TABLE oltp.restaurantes
(
    restaurante_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    usuario_id BIGINT NOT NULL UNIQUE,
    nome_fantasia VARCHAR(150) NOT NULL,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    descricao VARCHAR(500) NULL,
    telefone VARCHAR(20) NULL,
    cep VARCHAR(9) NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100) NULL,
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado CHAR(2) NOT NULL,
    ativo BIT NOT NULL CONSTRAINT df_restaurantes_ativo DEFAULT 1,
    data_cadastro DATETIME2 NOT NULL CONSTRAINT df_restaurantes_data_cadastro DEFAULT SYSDATETIME(),
    CONSTRAINT fk_restaurantes_usuario FOREIGN KEY (usuario_id) REFERENCES oltp.usuarios(usuario_id),
    CONSTRAINT ck_restaurantes_estado CHECK (LEN(estado) = 2)
);
GO

CREATE TABLE oltp.categorias_cardapio
(
    categoria_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao VARCHAR(300) NULL,
    ativo BIT NOT NULL CONSTRAINT df_categorias_ativo DEFAULT 1
);
GO

CREATE TABLE oltp.itens_cardapio
(
    item_cardapio_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    restaurante_id BIGINT NOT NULL,
    categoria_id INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao VARCHAR(500) NULL,
    preco DECIMAL(10,2) NOT NULL,
    calorias DECIMAL(10,2) NULL,
    proteinas DECIMAL(10,2) NULL,
    carboidratos DECIMAL(10,2) NULL,
    gorduras DECIMAL(10,2) NULL,
    restricao_alimentar VARCHAR(50) NULL,
    disponivel BIT NOT NULL CONSTRAINT df_itens_disponivel DEFAULT 1,
    data_cadastro DATETIME2 NOT NULL CONSTRAINT df_itens_data_cadastro DEFAULT SYSDATETIME(),
    CONSTRAINT fk_itens_restaurante FOREIGN KEY (restaurante_id) REFERENCES oltp.restaurantes(restaurante_id),
    CONSTRAINT fk_itens_categoria FOREIGN KEY (categoria_id) REFERENCES oltp.categorias_cardapio(categoria_id),
    CONSTRAINT ck_itens_preco CHECK (preco > 0),
    CONSTRAINT ck_itens_calorias CHECK (calorias IS NULL OR calorias >= 0),
    CONSTRAINT ck_itens_proteinas CHECK (proteinas IS NULL OR proteinas >= 0),
    CONSTRAINT ck_itens_carboidratos CHECK (carboidratos IS NULL OR carboidratos >= 0),
    CONSTRAINT ck_itens_gorduras CHECK (gorduras IS NULL OR gorduras >= 0)
);
GO

CREATE TABLE oltp.pedidos
(
    pedido_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    restaurante_id BIGINT NOT NULL,
    endereco_entrega_id BIGINT NOT NULL,
    status_pedido VARCHAR(30) NOT NULL CONSTRAINT df_pedidos_status DEFAULT 'PENDENTE',
    forma_pagamento VARCHAR(30) NOT NULL,
    status_pagamento VARCHAR(20) NOT NULL CONSTRAINT df_pedidos_status_pagamento DEFAULT 'PENDENTE',
    valor_subtotal DECIMAL(10,2) NOT NULL,
    valor_frete DECIMAL(10,2) NOT NULL CONSTRAINT df_pedidos_frete DEFAULT 0,
    valor_total DECIMAL(10,2) NOT NULL,
    observacao VARCHAR(500) NULL,
    criado_em DATETIME2 NOT NULL CONSTRAINT df_pedidos_criado_em DEFAULT SYSDATETIME(),
    confirmado_em DATETIME2 NULL,
    entregue_em DATETIME2 NULL,
    cancelado_em DATETIME2 NULL,
    pago_em DATETIME2 NULL,
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (cliente_id) REFERENCES oltp.clientes(cliente_id),
    CONSTRAINT fk_pedidos_restaurante FOREIGN KEY (restaurante_id) REFERENCES oltp.restaurantes(restaurante_id),
    CONSTRAINT fk_pedidos_endereco FOREIGN KEY (endereco_entrega_id) REFERENCES oltp.enderecos(endereco_id),
    CONSTRAINT ck_pedidos_status CHECK (status_pedido IN ('PENDENTE','CONFIRMADO','EM_PREPARO','SAIU_PARA_ENTREGA','ENTREGUE','CANCELADO')),
    CONSTRAINT ck_pedidos_forma_pagamento CHECK (forma_pagamento IN ('PIX','CARTAO_CREDITO','CARTAO_DEBITO','DINHEIRO')),
    CONSTRAINT ck_pedidos_status_pagamento CHECK (status_pagamento IN ('PENDENTE','PAGO','FALHOU','CANCELADO')),
    CONSTRAINT ck_pedidos_valores CHECK (valor_subtotal >= 0 AND valor_frete >= 0 AND valor_total >= 0),
    CONSTRAINT ck_pedidos_total CHECK (valor_total = valor_subtotal + valor_frete),
    CONSTRAINT ck_pedidos_confirmacao CHECK (confirmado_em IS NULL OR confirmado_em >= criado_em),
    CONSTRAINT ck_pedidos_entrega CHECK (entregue_em IS NULL OR entregue_em >= criado_em),
    CONSTRAINT ck_pedidos_cancelamento CHECK (cancelado_em IS NULL OR cancelado_em >= criado_em),
    CONSTRAINT ck_pedidos_pagamento CHECK (pago_em IS NULL OR pago_em >= criado_em)
);
GO

CREATE TABLE oltp.itens_pedido
(
    item_pedido_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    pedido_id BIGINT NOT NULL,
    item_cardapio_id BIGINT NOT NULL,
    nome_item_snapshot VARCHAR(150) NOT NULL,
    descricao_snapshot VARCHAR(500) NULL,
    preco_unitario_snapshot DECIMAL(10,2) NOT NULL,
    quantidade INT NOT NULL,
    valor_total_item DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_itens_pedido_pedido FOREIGN KEY (pedido_id) REFERENCES oltp.pedidos(pedido_id),
    CONSTRAINT fk_itens_pedido_item FOREIGN KEY (item_cardapio_id) REFERENCES oltp.itens_cardapio(item_cardapio_id),
    CONSTRAINT ck_itens_pedido_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_itens_pedido_preco CHECK (preco_unitario_snapshot >= 0),
    CONSTRAINT ck_itens_pedido_total CHECK (valor_total_item = preco_unitario_snapshot * quantidade)
);
GO

CREATE INDEX ix_enderecos_cliente ON oltp.enderecos(cliente_id);
CREATE INDEX ix_itens_restaurante ON oltp.itens_cardapio(restaurante_id);
CREATE INDEX ix_itens_categoria ON oltp.itens_cardapio(categoria_id);
CREATE INDEX ix_pedidos_cliente ON oltp.pedidos(cliente_id);
CREATE INDEX ix_pedidos_restaurante ON oltp.pedidos(restaurante_id);
CREATE INDEX ix_pedidos_data ON oltp.pedidos(criado_em);
CREATE INDEX ix_pedidos_status ON oltp.pedidos(status_pedido);
CREATE INDEX ix_itens_pedido_pedido ON oltp.itens_pedido(pedido_id);
CREATE INDEX ix_itens_pedido_item ON oltp.itens_pedido(item_cardapio_id);
GO

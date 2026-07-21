/* 03 - Area de staging (full load) */
USE DeliFitDB;
GO

CREATE TABLE stg.stg_usuarios
(
    usuario_id BIGINT NOT NULL PRIMARY KEY, nome VARCHAR(150) NULL, email VARCHAR(150) NULL,
    telefone VARCHAR(20) NULL, tipo_usuario VARCHAR(20) NULL, ativo BIT NULL,
    data_cadastro DATETIME NULL, dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_clientes
(
    cliente_id BIGINT NOT NULL PRIMARY KEY, usuario_id BIGINT NULL, data_nascimento DATE NULL,
    dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_enderecos
(
    endereco_id BIGINT NOT NULL PRIMARY KEY, cliente_id BIGINT NULL, nome_endereco VARCHAR(50) NULL,
    cep VARCHAR(9) NULL, logradouro VARCHAR(150) NULL, numero VARCHAR(20) NULL,
    complemento VARCHAR(100) NULL, bairro VARCHAR(100) NULL, cidade VARCHAR(100) NULL,
    estado CHAR(2) NULL, endereco_principal BIT NULL, ativo BIT NULL,
    dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_restaurantes
(
    restaurante_id BIGINT NOT NULL PRIMARY KEY, usuario_id BIGINT NULL, nome_fantasia VARCHAR(150) NULL,
    cnpj VARCHAR(18) NULL, descricao VARCHAR(500) NULL, telefone VARCHAR(20) NULL,
    cep VARCHAR(9) NULL, logradouro VARCHAR(150) NULL, numero VARCHAR(20) NULL,
    complemento VARCHAR(100) NULL, bairro VARCHAR(100) NULL, cidade VARCHAR(100) NULL,
    estado CHAR(2) NULL, ativo BIT NULL, data_cadastro DATETIME NULL,
    dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_categorias_cardapio
(
    categoria_id INT NOT NULL PRIMARY KEY, nome VARCHAR(100) NULL, descricao VARCHAR(300) NULL,
    ativo BIT NULL, dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_itens_cardapio
(
    item_cardapio_id BIGINT NOT NULL PRIMARY KEY, restaurante_id BIGINT NULL, categoria_id INT NULL,
    nome VARCHAR(150) NULL, descricao VARCHAR(500) NULL, preco DECIMAL(10,2) NULL,
    calorias DECIMAL(10,2) NULL, proteinas DECIMAL(10,2) NULL, carboidratos DECIMAL(10,2) NULL,
    gorduras DECIMAL(10,2) NULL, restricao_alimentar VARCHAR(50) NULL, disponivel BIT NULL,
    data_cadastro DATETIME NULL, dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_pedidos
(
    pedido_id BIGINT NOT NULL PRIMARY KEY, cliente_id BIGINT NULL, restaurante_id BIGINT NULL,
    endereco_entrega_id BIGINT NULL, status_pedido VARCHAR(30) NULL, forma_pagamento VARCHAR(30) NULL,
    status_pagamento VARCHAR(20) NULL, valor_subtotal DECIMAL(10,2) NULL,
    valor_frete DECIMAL(10,2) NULL, valor_total DECIMAL(10,2) NULL, observacao VARCHAR(500) NULL,
    criado_em DATETIME NULL, confirmado_em DATETIME NULL, entregue_em DATETIME NULL,
    cancelado_em DATETIME NULL, pago_em DATETIME NULL,
    dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE stg.stg_itens_pedido
(
    item_pedido_id BIGINT NOT NULL PRIMARY KEY, pedido_id BIGINT NULL, item_cardapio_id BIGINT NULL,
    nome_item_snapshot VARCHAR(150) NULL, descricao_snapshot VARCHAR(500) NULL,
    preco_unitario_snapshot DECIMAL(10,2) NULL, quantidade INT NULL, valor_total_item DECIMAL(10,2) NULL,
    dt_extracao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE INDEX ix_stg_clientes_usuario ON stg.stg_clientes(usuario_id);
CREATE INDEX ix_stg_enderecos_cliente ON stg.stg_enderecos(cliente_id);
CREATE INDEX ix_stg_restaurantes_usuario ON stg.stg_restaurantes(usuario_id);
CREATE INDEX ix_stg_itens_cardapio_restaurante ON stg.stg_itens_cardapio(restaurante_id);
CREATE INDEX ix_stg_itens_cardapio_categoria ON stg.stg_itens_cardapio(categoria_id);
CREATE INDEX ix_stg_pedidos_cliente ON stg.stg_pedidos(cliente_id);
CREATE INDEX ix_stg_pedidos_restaurante ON stg.stg_pedidos(restaurante_id);
CREATE INDEX ix_stg_pedidos_endereco ON stg.stg_pedidos(endereco_entrega_id);
CREATE INDEX ix_stg_itens_pedido_pedido ON stg.stg_itens_pedido(pedido_id);
CREATE INDEX ix_stg_itens_pedido_item ON stg.stg_itens_pedido(item_cardapio_id);
GO

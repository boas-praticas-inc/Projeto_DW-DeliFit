/* 02 - Dimensoes, fato e indices do DW */
USE DeliFitDB;
GO

CREATE TABLE dw.dim_tempo
(
    id_tempo INT IDENTITY(1,1) PRIMARY KEY,
    dia TINYINT NOT NULL,
    data DATE NOT NULL UNIQUE,
    mes TINYINT NOT NULL,
    trimestre TINYINT NOT NULL,
    semestre TINYINT NOT NULL,
    ano SMALLINT NOT NULL,
    dia_semana VARCHAR(20) NOT NULL,
    feriado BIT NOT NULL
);
GO

CREATE TABLE dw.dim_cliente
(
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    faixa_etaria VARCHAR(30), idade INT, data_cadastro DATE,
    data_inicio DATETIME NOT NULL, data_fim DATETIME NULL, registro_ativo BIT NOT NULL
);
GO

CREATE TABLE dw.dim_endereco
(
    id_endereco INT IDENTITY(1,1) PRIMARY KEY,
    endereco_id BIGINT NOT NULL,
    cep VARCHAR(10), logradouro VARCHAR(150), bairro VARCHAR(100), numero VARCHAR(20),
    cidade VARCHAR(100), estado CHAR(2), complemento VARCHAR(150),
    data_inicio DATETIME NOT NULL, data_fim DATETIME NULL, registro_ativo BIT NOT NULL
);
GO

CREATE TABLE dw.dim_restaurante
(
    id_restaurante INT IDENTITY(1,1) PRIMARY KEY,
    restaurante_id BIGINT NOT NULL, nome_fantasia VARCHAR(150) NOT NULL,
    cidade VARCHAR(100), estado CHAR(2), data_cadastro DATE, ativo BIT NOT NULL,
    data_inicio DATETIME NOT NULL, data_fim DATETIME NULL, registro_ativo BIT NOT NULL
);
GO

CREATE TABLE dw.dim_item
(
    id_item INT IDENTITY(1,1) PRIMARY KEY,
    item_cardapio_id BIGINT NOT NULL, nome VARCHAR(150) NOT NULL, categoria VARCHAR(100),
    calorias DECIMAL(10,2), proteinas DECIMAL(10,2), carboidratos DECIMAL(10,2),
    gorduras DECIMAL(10,2), restricao_alimentar VARCHAR(100), faixa_preco VARCHAR(50),
    disponivel BIT NOT NULL, preco_atual DECIMAL(10,2),
    data_inicio DATETIME NOT NULL, data_fim DATETIME NULL, registro_ativo BIT NOT NULL
);
GO

CREATE TABLE dw.dim_pagamento
(
    id_pagamento INT IDENTITY(1,1) PRIMARY KEY,
    forma_pagamento VARCHAR(50) NOT NULL,
    status_pagamento VARCHAR(50) NOT NULL,
    CONSTRAINT UQ_dim_pagamento UNIQUE (forma_pagamento, status_pagamento)
);
GO

CREATE TABLE dw.dim_status
(
    id_status INT IDENTITY(1,1) PRIMARY KEY,
    status_pedido VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE dw.ft_venda
(
    id_venda BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_tempo INT NOT NULL, id_tempo_entrega INT NULL, id_tempo_cancelamento INT NULL,
    id_tempo_pagamento INT NULL,
    id_cliente INT NOT NULL, id_endereco INT NOT NULL,
    id_restaurante INT NOT NULL, id_item INT NOT NULL, id_pagamento INT NOT NULL, id_status INT NOT NULL,
    pedido_id BIGINT NOT NULL, item_pedido_id BIGINT NOT NULL,
    quantidade INT NOT NULL, valor_unitario DECIMAL(10,2) NOT NULL,
    valor_total_item DECIMAL(12,2) NOT NULL, valor_frete_rateado DECIMAL(10,2) NOT NULL,
    tempo_entrega_minutos INT NULL,
    CONSTRAINT FK_FT_TEMPO FOREIGN KEY (id_tempo) REFERENCES dw.dim_tempo(id_tempo),
    CONSTRAINT FK_FT_TEMPO_ENTREGA FOREIGN KEY (id_tempo_entrega) REFERENCES dw.dim_tempo(id_tempo),
    CONSTRAINT FK_FT_TEMPO_CANCELAMENTO FOREIGN KEY (id_tempo_cancelamento) REFERENCES dw.dim_tempo(id_tempo),
    CONSTRAINT FK_FT_TEMPO_PAGAMENTO FOREIGN KEY (id_tempo_pagamento) REFERENCES dw.dim_tempo(id_tempo),
    CONSTRAINT FK_FT_CLIENTE FOREIGN KEY (id_cliente) REFERENCES dw.dim_cliente(id_cliente),
    CONSTRAINT FK_FT_ENDERECO FOREIGN KEY (id_endereco) REFERENCES dw.dim_endereco(id_endereco),
    CONSTRAINT FK_FT_RESTAURANTE FOREIGN KEY (id_restaurante) REFERENCES dw.dim_restaurante(id_restaurante),
    CONSTRAINT FK_FT_ITEM FOREIGN KEY (id_item) REFERENCES dw.dim_item(id_item),
    CONSTRAINT FK_FT_PAGAMENTO FOREIGN KEY (id_pagamento) REFERENCES dw.dim_pagamento(id_pagamento),
    CONSTRAINT FK_FT_STATUS FOREIGN KEY (id_status) REFERENCES dw.dim_status(id_status)
);
GO

CREATE INDEX IX_FT_TEMPO ON dw.ft_venda(id_tempo);
CREATE INDEX IX_FT_CLIENTE ON dw.ft_venda(id_cliente);
CREATE INDEX IX_FT_RESTAURANTE ON dw.ft_venda(id_restaurante);
CREATE INDEX IX_FT_ITEM ON dw.ft_venda(id_item);
CREATE INDEX IX_FT_PAGAMENTO ON dw.ft_venda(id_pagamento);
CREATE INDEX IX_FT_STATUS ON dw.ft_venda(id_status);
CREATE INDEX IX_FT_PEDIDO ON dw.ft_venda(pedido_id);
CREATE UNIQUE INDEX UX_FT_ITEM_PEDIDO ON dw.ft_venda(item_pedido_id);
GO

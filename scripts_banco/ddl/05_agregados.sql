/* 05 - Tabelas agregadas do DW */
USE DeliFitDB;
GO

CREATE TABLE dw.agg_vendas_diarias
(
    id_tempo INT NOT NULL PRIMARY KEY,
    data_venda DATE NOT NULL,
    quantidade_pedidos BIGINT NOT NULL,
    quantidade_itens_vendidos BIGINT NOT NULL,
    faturamento_diario DECIMAL(18,2) NOT NULL,
    ticket_medio_diario DECIMAL(18,2) NOT NULL,
    data_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT fk_agg_vendas_diarias_tempo FOREIGN KEY (id_tempo) REFERENCES dw.dim_tempo(id_tempo)
);
GO
CREATE TABLE dw.agg_vendas_mensais
(
    ano SMALLINT NOT NULL, mes TINYINT NOT NULL,
    quantidade_pedidos BIGINT NOT NULL, quantidade_itens_vendidos BIGINT NOT NULL,
    faturamento_mensal DECIMAL(18,2) NOT NULL, ticket_medio_mensal DECIMAL(18,2) NOT NULL,
    data_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT pk_agg_vendas_mensais PRIMARY KEY (ano, mes),
    CONSTRAINT ck_agg_vendas_mensais_mes CHECK (mes BETWEEN 1 AND 12)
);
GO
CREATE TABLE dw.agg_vendas_restaurante
(
    id_restaurante INT NOT NULL PRIMARY KEY, quantidade_pedidos BIGINT NOT NULL,
    quantidade_itens_vendidos BIGINT NOT NULL, faturamento DECIMAL(18,2) NOT NULL,
    ticket_medio DECIMAL(18,2) NOT NULL, data_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT fk_agg_vendas_restaurante FOREIGN KEY (id_restaurante) REFERENCES dw.dim_restaurante(id_restaurante)
);
GO
CREATE TABLE dw.agg_vendas_categoria
(
    categoria VARCHAR(100) NOT NULL PRIMARY KEY, quantidade_itens_vendidos BIGINT NOT NULL,
    receita_categoria DECIMAL(18,2) NOT NULL, valor_medio_itens_vendidos DECIMAL(18,2) NOT NULL,
    data_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE TABLE dw.agg_vendas_cliente
(
    id_cliente INT NOT NULL PRIMARY KEY, quantidade_pedidos BIGINT NOT NULL,
    quantidade_itens_comprados BIGINT NOT NULL, valor_total_gasto DECIMAL(18,2) NOT NULL,
    ticket_medio_cliente DECIMAL(18,2) NOT NULL, data_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT fk_agg_vendas_cliente FOREIGN KEY (id_cliente) REFERENCES dw.dim_cliente(id_cliente)
);
GO

CREATE INDEX ix_agg_vendas_diarias_data ON dw.agg_vendas_diarias(data_venda);
CREATE INDEX ix_agg_vendas_mensais_ano_mes ON dw.agg_vendas_mensais(ano, mes);
GO

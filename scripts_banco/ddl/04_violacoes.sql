/* 04 - Registro de violacoes encontradas no ETL */
USE DeliFitDB;
GO

CREATE TABLE violacao.ft_venda_violacao
(
    id_violacao BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    lote_execucao INT NOT NULL,
    pedido_id BIGINT NOT NULL,
    item_pedido_id BIGINT NULL,
    motivo VARCHAR(500) NOT NULL,
    campo VARCHAR(100) NULL,
    valor_encontrado VARCHAR(500) NULL,
    data_violacao DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE INDEX ix_violacao_pedido ON violacao.ft_venda_violacao(pedido_id);
CREATE INDEX ix_violacao_item_pedido ON violacao.ft_venda_violacao(item_pedido_id);
CREATE INDEX ix_violacao_data ON violacao.ft_venda_violacao(data_violacao);
CREATE INDEX ix_violacao_lote ON violacao.ft_venda_violacao(lote_execucao);
GO

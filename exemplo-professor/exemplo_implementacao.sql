/* ============================================================
   DEMONSTRAÇÃO DE UM AMBIENTE DE DATA WAREHOUSE

   Cenário: Gestão de chamados e incidentes

   Camadas:
   - OLTP: ambiente operacional;
   - STAGING: área intermediária;
   - DW: ambiente dimensional.

   Convenções:
   - cod_: chave operacional ou chave natural;
   - id_: chave substituta, surrogate key;
   - data_carga: data de execução do processo ETL.

   Dimensões:
   - dim_servico: SCD Tipo 1;
   - dim_solicitante: SCD Tipo 2;
   - dim_tempo: dimensão estática carregada por intervalo.

   Granularidade da fato:
   - uma linha para cada incidente.
   ============================================================ */


/* ============================================================
   1. CRIAÇÃO DO BANCO DE DADOS
   ============================================================ */

USE master;
GO

IF DB_ID('DW_Chamados') IS NULL
    CREATE DATABASE DW_Chamados;
GO

USE DW_Chamados;
GO


/* ============================================================
   2. CRIAÇÃO DOS SCHEMAS
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'oltp')
    EXEC('CREATE SCHEMA oltp');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');
GO


/* ============================================================
   3. REMOÇÃO DOS OBJETOS ANTERIORES

   Essa etapa permite executar novamente todo o script.
   Os procedimentos são removidos antes das tabelas.
   ============================================================ */

DROP PROCEDURE IF EXISTS dw.sp_executar_etl;
DROP PROCEDURE IF EXISTS dw.sp_carregar_fato_incidente;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tempo;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_solicitante;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_servico;
DROP PROCEDURE IF EXISTS staging.sp_carregar_staging;
GO

DROP TABLE IF EXISTS dw.fato_incidente;
DROP TABLE IF EXISTS dw.dim_tempo;
DROP TABLE IF EXISTS dw.dim_solicitante;
DROP TABLE IF EXISTS dw.dim_servico;

DROP TABLE IF EXISTS staging.stg_incidente;
DROP TABLE IF EXISTS staging.stg_solicitante;
DROP TABLE IF EXISTS staging.stg_tipo_servico;

DROP TABLE IF EXISTS oltp.incidente;
DROP TABLE IF EXISTS oltp.solicitante;
DROP TABLE IF EXISTS oltp.tipo_servico;
GO


/* ============================================================
   4. AMBIENTE OPERACIONAL - OLTP
   ============================================================ */

/* Tipos de serviço oferecidos. */

CREATE TABLE oltp.tipo_servico (
    cod_tipo_servico INT IDENTITY(1,1) PRIMARY KEY,
    nome_tipo_servico VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL
);


/* Solicitantes responsáveis pela abertura dos chamados. */

CREATE TABLE oltp.solicitante (
    cod_solicitante INT IDENTITY(1,1) PRIMARY KEY,
    nome_solicitante VARCHAR(100) NOT NULL,
    setor VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL
);


/* Incidentes registrados no sistema operacional. */

CREATE TABLE oltp.incidente (
    cod_incidente INT IDENTITY(1,1) PRIMARY KEY,
    cod_tipo_servico INT NOT NULL,
    cod_solicitante INT NOT NULL,
    data_abertura DATETIME2 NOT NULL,
    data_fechamento DATETIME2 NULL,
    status_incidente VARCHAR(30) NOT NULL,
    prioridade VARCHAR(20) NOT NULL,
    CONSTRAINT fk_incidente_tipo_servico FOREIGN KEY (cod_tipo_servico) REFERENCES oltp.tipo_servico(cod_tipo_servico),
    CONSTRAINT fk_incidente_solicitante FOREIGN KEY (cod_solicitante) REFERENCES oltp.solicitante(cod_solicitante)
);
GO


/* ============================================================
   5. DADOS INICIAIS DO AMBIENTE OPERACIONAL
   ============================================================ */

INSERT INTO oltp.tipo_servico (nome_tipo_servico, categoria) VALUES ('Suporte ao sistema', 'Software');
INSERT INTO oltp.tipo_servico (nome_tipo_servico, categoria) VALUES ('Manutenção de computador', 'Hardware');
INSERT INTO oltp.tipo_servico (nome_tipo_servico, categoria) VALUES ('Configuração de rede', 'Infraestrutura');

INSERT INTO oltp.solicitante (nome_solicitante, setor, cidade) VALUES ('Ana Souza', 'Financeiro', 'Aracaju');
INSERT INTO oltp.solicitante (nome_solicitante, setor, cidade) VALUES ('Carlos Lima', 'Recursos Humanos', 'Itabaiana');
INSERT INTO oltp.solicitante (nome_solicitante, setor, cidade) VALUES ('Mariana Santos', 'Administrativo', 'Lagarto');

INSERT INTO oltp.incidente (cod_tipo_servico, cod_solicitante, data_abertura, data_fechamento, status_incidente, prioridade) VALUES (1, 1, '2026-07-01 08:00:00', '2026-07-01 12:00:00', 'Fechado', 'Alta');
INSERT INTO oltp.incidente (cod_tipo_servico, cod_solicitante, data_abertura, data_fechamento, status_incidente, prioridade) VALUES (2, 2, '2026-07-02 09:00:00', NULL, 'Aberto', 'Média');
INSERT INTO oltp.incidente (cod_tipo_servico, cod_solicitante, data_abertura, data_fechamento, status_incidente, prioridade) VALUES (1, 3, '2026-07-03 10:00:00', '2026-07-03 13:30:00', 'Fechado', 'Baixa');
GO


/* ============================================================
   6. ÁREA DE STAGING

   A staging armazena uma fotografia dos dados operacionais
   para cada data de carga.

   Ao reprocessar uma data:
   - somente os registros daquela data são removidos;
   - as demais cargas são preservadas.
   ============================================================ */

CREATE TABLE staging.stg_tipo_servico (
    cod_tipo_servico INT NOT NULL,
    nome_tipo_servico VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    data_carga DATE NOT NULL
);

CREATE TABLE staging.stg_solicitante (
    cod_solicitante INT NOT NULL,
    nome_solicitante VARCHAR(100) NOT NULL,
    setor VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    data_carga DATE NOT NULL
);

CREATE TABLE staging.stg_incidente (
    cod_incidente INT NOT NULL,
    cod_tipo_servico INT NOT NULL,
    cod_solicitante INT NOT NULL,
    data_abertura DATETIME2 NOT NULL,
    data_fechamento DATETIME2 NULL,
    status_incidente VARCHAR(30) NOT NULL,
    prioridade VARCHAR(20) NOT NULL,
    data_carga DATE NOT NULL
);
GO


/* Índices para facilitar a localização dos dados de uma carga. */

CREATE INDEX ix_stg_tipo_servico_data_carga ON staging.stg_tipo_servico(data_carga);
CREATE INDEX ix_stg_solicitante_data_carga ON staging.stg_solicitante(data_carga);
CREATE INDEX ix_stg_incidente_data_carga ON staging.stg_incidente(data_carga);
GO


/* ============================================================
   7. AMBIENTE DIMENSIONAL
   ============================================================ */


/* ============================================================
   7.1 DIMENSÃO SERVIÇO

   Estratégia SCD Tipo 1.

   Quando um serviço for alterado:
   - o registro existente será atualizado;
   - o valor anterior será sobrescrito;
   - não haverá preservação de histórico.
   ============================================================ */

CREATE TABLE dw.dim_servico (
    id_servico INT IDENTITY(1,1) PRIMARY KEY,
    cod_tipo_servico INT NOT NULL,
    nome_tipo_servico VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    data_atualizacao DATE NOT NULL,
    CONSTRAINT uq_dim_servico_cod_tipo_servico UNIQUE (cod_tipo_servico)
);


/* ============================================================
   7.2 DIMENSÃO SOLICITANTE

   Estratégia SCD Tipo 2.

   Quando um atributo histórico for alterado:
   - a versão atual será encerrada;
   - uma nova versão será criada;
   - o histórico será preservado.
   ============================================================ */

CREATE TABLE dw.dim_solicitante (
    id_solicitante INT IDENTITY(1,1) PRIMARY KEY,
    cod_solicitante INT NOT NULL,
    nome_solicitante VARCHAR(100) NOT NULL,
    setor VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    registro_atual BIT NOT NULL
);


/* Impede mais de uma versão atual para o mesmo solicitante. */

CREATE UNIQUE INDEX ux_dim_solicitante_registro_atual
ON dw.dim_solicitante(cod_solicitante)
WHERE registro_atual = 1;


/* Facilita a busca da versão histórica correspondente. */

CREATE INDEX ix_dim_solicitante_historico
ON dw.dim_solicitante(cod_solicitante, data_inicio, data_fim);


/* ============================================================
   7.3 DIMENSÃO TEMPO

   A dimensão tempo é carregada separadamente.

   id_tempo:
   - chave substituta;
   - valor gerado automaticamente por IDENTITY.

   data_completa:
   - representa a chave natural da dimensão.
   ============================================================ */

CREATE TABLE dw.dim_tempo (
    id_tempo INT IDENTITY(1,1) PRIMARY KEY,
    data_completa DATE NOT NULL,
    dia INT NOT NULL,
    mes INT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,
    trimestre INT NOT NULL,
    ano INT NOT NULL,
    numero_dia_semana INT NOT NULL,
    nome_dia_semana VARCHAR(20) NOT NULL,
    CONSTRAINT uq_dim_tempo_data_completa UNIQUE (data_completa)
);


/* ============================================================
   7.4 TABELA FATO

   Granularidade:
   - uma linha para cada incidente.

   Medidas:
   - quantidade;
   - tempo_resolucao_horas.

   Dimensão tempo:
   - id_tempo_abertura;
   - id_tempo_fechamento.
   ============================================================ */

CREATE TABLE dw.fato_incidente (
    id_fato_incidente BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_incidente INT NOT NULL,
    id_servico INT NOT NULL,
    id_solicitante INT NOT NULL,
    id_tempo_abertura INT NOT NULL,
    id_tempo_fechamento INT NULL,
    status_incidente VARCHAR(30) NOT NULL,
    prioridade VARCHAR(20) NOT NULL,
    quantidade INT NOT NULL,
    tempo_resolucao_horas DECIMAL(10,2) NULL,
    data_carga DATE NOT NULL,
    CONSTRAINT uq_fato_incidente_cod_incidente UNIQUE (cod_incidente),
    CONSTRAINT fk_fato_incidente_servico FOREIGN KEY (id_servico) REFERENCES dw.dim_servico(id_servico),
    CONSTRAINT fk_fato_incidente_solicitante FOREIGN KEY (id_solicitante) REFERENCES dw.dim_solicitante(id_solicitante),
    CONSTRAINT fk_fato_incidente_tempo_abertura FOREIGN KEY (id_tempo_abertura) REFERENCES dw.dim_tempo(id_tempo),
    CONSTRAINT fk_fato_incidente_tempo_fechamento FOREIGN KEY (id_tempo_fechamento) REFERENCES dw.dim_tempo(id_tempo)
);
GO


/* ============================================================
   8. PROCEDIMENTO DE CARGA DA STAGING

   Recebe a data da carga por parâmetro.

   Etapas:
   1. remove os registros da mesma data;
   2. mantém os registros das outras cargas;
   3. extrai novamente os dados do OLTP.
   ============================================================ */

CREATE OR ALTER PROCEDURE staging.sp_carregar_staging
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;

    /* Remove somente os registros da carga que será reprocessada. */

    DELETE FROM staging.stg_incidente WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_solicitante WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_tipo_servico WHERE data_carga = @data_carga;

    /* Extrai os tipos de serviço do ambiente operacional. */

    INSERT INTO staging.stg_tipo_servico (cod_tipo_servico, nome_tipo_servico, categoria, data_carga)
    SELECT cod_tipo_servico, nome_tipo_servico, categoria, @data_carga
    FROM oltp.tipo_servico;

    /* Extrai os solicitantes do ambiente operacional. */

    INSERT INTO staging.stg_solicitante (cod_solicitante, nome_solicitante, setor, cidade, data_carga)
    SELECT cod_solicitante, nome_solicitante, setor, cidade, @data_carga
    FROM oltp.solicitante;

    /* Extrai os incidentes do ambiente operacional. */

    INSERT INTO staging.stg_incidente (cod_incidente, cod_tipo_servico, cod_solicitante, data_abertura, data_fechamento, status_incidente, prioridade, data_carga)
    SELECT cod_incidente, cod_tipo_servico, cod_solicitante, data_abertura, data_fechamento, status_incidente, prioridade, @data_carga
    FROM oltp.incidente;
END;
GO


/* ============================================================
   9. PROCEDIMENTO DA DIMENSÃO SERVIÇO

   Implementação da estratégia SCD Tipo 1.

   Etapas:
   1. atualiza os registros existentes;
   2. insere os novos registros.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_servico
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50002, 'A data da carga deve ser informada.', 1;

    /* Atualiza os serviços que sofreram alterações. */

    UPDATE destino
    SET destino.nome_tipo_servico = origem.nome_tipo_servico,
        destino.categoria = origem.categoria,
        destino.data_atualizacao = @data_carga
    FROM dw.dim_servico destino
    INNER JOIN staging.stg_tipo_servico origem ON origem.cod_tipo_servico = destino.cod_tipo_servico
    WHERE origem.data_carga = @data_carga
      AND (destino.nome_tipo_servico <> origem.nome_tipo_servico OR destino.categoria <> origem.categoria);

    /* Insere os serviços que ainda não existem. */

    INSERT INTO dw.dim_servico (cod_tipo_servico, nome_tipo_servico, categoria, data_atualizacao)
    SELECT origem.cod_tipo_servico, origem.nome_tipo_servico, origem.categoria, @data_carga
    FROM staging.stg_tipo_servico origem
    WHERE origem.data_carga = @data_carga
      AND NOT EXISTS (
          SELECT 1
          FROM dw.dim_servico destino
          WHERE destino.cod_tipo_servico = origem.cod_tipo_servico
      );
END;
GO


/* ============================================================
   10. PROCEDIMENTO DA DIMENSÃO SOLICITANTE

   Implementação da estratégia SCD Tipo 2.

   Etapas:
   1. atualiza uma versão criada na mesma data;
   2. encerra versões antigas alteradas;
   3. insere solicitantes novos ou novas versões.

   Para este exemplo, recomenda-se executar as cargas em
   ordem cronológica.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_solicitante
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50003, 'A data da carga deve ser informada.', 1;

    /*
       Se a versão atual tiver sido criada na mesma data da carga,
       os valores serão apenas atualizados.

       Isso evita criar duas versões para o mesmo dia.
    */

    UPDATE destino
    SET destino.nome_solicitante = origem.nome_solicitante,
        destino.setor = origem.setor,
        destino.cidade = origem.cidade
    FROM dw.dim_solicitante destino
    INNER JOIN staging.stg_solicitante origem ON origem.cod_solicitante = destino.cod_solicitante
    WHERE origem.data_carga = @data_carga
      AND destino.registro_atual = 1
      AND destino.data_inicio = @data_carga
      AND (
          destino.nome_solicitante <> origem.nome_solicitante
          OR destino.setor <> origem.setor
          OR destino.cidade <> origem.cidade
      );

    /*
       Encerra a versão atual quando os dados forem alterados.

       A versão anterior termina no dia anterior à nova versão.
    */

    UPDATE destino
    SET destino.data_fim = DATEADD(DAY, -1, @data_carga),
        destino.registro_atual = 0
    FROM dw.dim_solicitante destino
    INNER JOIN staging.stg_solicitante origem ON origem.cod_solicitante = destino.cod_solicitante
    WHERE origem.data_carga = @data_carga
      AND destino.registro_atual = 1
      AND destino.data_inicio < @data_carga
      AND (
          destino.nome_solicitante <> origem.nome_solicitante
          OR destino.setor <> origem.setor
          OR destino.cidade <> origem.cidade
      );

    /*
       Insere:
       - solicitantes que ainda não existem;
       - novas versões dos solicitantes alterados.

       Para o primeiro registro conhecido, utiliza-se 01/01/1900
       como data inicial, permitindo associar incidentes antigos.
    */

    INSERT INTO dw.dim_solicitante (cod_solicitante, nome_solicitante, setor, cidade, data_inicio, data_fim, registro_atual)
    SELECT origem.cod_solicitante,
           origem.nome_solicitante,
           origem.setor,
           origem.cidade,
           CASE
               WHEN EXISTS (
                   SELECT 1
                   FROM dw.dim_solicitante historico
                   WHERE historico.cod_solicitante = origem.cod_solicitante
               ) THEN @data_carga
               ELSE '1900-01-01'
           END,
           '9999-12-31',
           1
    FROM staging.stg_solicitante origem
    WHERE origem.data_carga = @data_carga
      AND NOT EXISTS (
          SELECT 1
          FROM dw.dim_solicitante atual
          WHERE atual.cod_solicitante = origem.cod_solicitante
            AND atual.registro_atual = 1
      );
END;
GO


/* ============================================================
   11. PROCEDIMENTO DA DIMENSÃO TEMPO

   A dimensão tempo não recebe a data da carga.

   Ela recebe:
   - data inicial;
   - data final.

   Exemplo:
   - 01/01/2026 até 31/12/2027.

   O procedimento:
   1. gera uma linha para cada dia do intervalo;
   2. insere apenas as datas ainda inexistentes;
   3. utiliza IDENTITY para gerar id_tempo.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_carregar_dim_tempo
    @data_inicial DATE,
    @data_final DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_inicial IS NULL OR @data_final IS NULL
        THROW 50004, 'A data inicial e a data final devem ser informadas.', 1;

    IF @data_inicial > @data_final
        THROW 50005, 'A data inicial não pode ser maior que a data final.', 1;

    /*
       A CTE recursiva gera todas as datas do intervalo.
    */

    ;WITH datas AS (
        SELECT @data_inicial AS data_completa

        UNION ALL

        SELECT DATEADD(DAY, 1, data_completa)
        FROM datas
        WHERE data_completa < @data_final
    )
    INSERT INTO dw.dim_tempo (data_completa, dia, mes, nome_mes, trimestre, ano, numero_dia_semana, nome_dia_semana)
    SELECT datas.data_completa,
           DAY(datas.data_completa),
           MONTH(datas.data_completa),
           CASE MONTH(datas.data_completa)
               WHEN 1 THEN 'Janeiro'
               WHEN 2 THEN 'Fevereiro'
               WHEN 3 THEN 'Março'
               WHEN 4 THEN 'Abril'
               WHEN 5 THEN 'Maio'
               WHEN 6 THEN 'Junho'
               WHEN 7 THEN 'Julho'
               WHEN 8 THEN 'Agosto'
               WHEN 9 THEN 'Setembro'
               WHEN 10 THEN 'Outubro'
               WHEN 11 THEN 'Novembro'
               WHEN 12 THEN 'Dezembro'
           END,
           DATEPART(QUARTER, datas.data_completa),
           YEAR(datas.data_completa),
           DATEDIFF(DAY, '19000101', datas.data_completa) % 7 + 1,
           CASE DATEDIFF(DAY, '19000101', datas.data_completa) % 7
               WHEN 0 THEN 'Segunda-feira'
               WHEN 1 THEN 'Terça-feira'
               WHEN 2 THEN 'Quarta-feira'
               WHEN 3 THEN 'Quinta-feira'
               WHEN 4 THEN 'Sexta-feira'
               WHEN 5 THEN 'Sábado'
               WHEN 6 THEN 'Domingo'
           END
    FROM datas
    WHERE NOT EXISTS (
        SELECT 1
        FROM dw.dim_tempo destino
        WHERE destino.data_completa = datas.data_completa
    )
    OPTION (MAXRECURSION 0);
END;
GO


/* ============================================================
   12. PROCEDIMENTO DA TABELA FATO

   Etapas:
   1. atualiza incidentes já existentes;
   2. insere novos incidentes;
   3. substitui as chaves naturais pelas surrogate keys.

   Na dimensão SCD Tipo 2, é selecionada a versão válida
   na data de abertura do incidente.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_carregar_fato_incidente
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50006, 'A data da carga deve ser informada.', 1;

    /*
       Atualiza os incidentes já existentes na tabela fato.

       Isso permite atualizar:
       - status;
       - prioridade;
       - data de fechamento;
       - tempo de resolução;
       - relacionamentos com dimensões.
    */

    UPDATE destino
    SET destino.id_servico = servico.id_servico,
        destino.id_solicitante = solicitante.id_solicitante,
        destino.id_tempo_abertura = tempo_abertura.id_tempo,
        destino.id_tempo_fechamento = tempo_fechamento.id_tempo,
        destino.status_incidente = incidente.status_incidente,
        destino.prioridade = incidente.prioridade,
        destino.quantidade = 1,
        destino.tempo_resolucao_horas =
            CASE
                WHEN incidente.data_fechamento IS NOT NULL
                    THEN CAST(DATEDIFF(MINUTE, incidente.data_abertura, incidente.data_fechamento) / 60.0 AS DECIMAL(10,2))
                ELSE NULL
            END,
        destino.data_carga = @data_carga
    FROM dw.fato_incidente destino
    INNER JOIN staging.stg_incidente incidente ON incidente.cod_incidente = destino.cod_incidente
    INNER JOIN dw.dim_servico servico ON servico.cod_tipo_servico = incidente.cod_tipo_servico
    INNER JOIN dw.dim_solicitante solicitante ON solicitante.cod_solicitante = incidente.cod_solicitante
        AND CAST(incidente.data_abertura AS DATE) BETWEEN solicitante.data_inicio AND solicitante.data_fim
    INNER JOIN dw.dim_tempo tempo_abertura ON tempo_abertura.data_completa = CAST(incidente.data_abertura AS DATE)
    LEFT JOIN dw.dim_tempo tempo_fechamento ON tempo_fechamento.data_completa = CAST(incidente.data_fechamento AS DATE)
    WHERE incidente.data_carga = @data_carga;

    /*
       Insere os incidentes que ainda não existem na tabela fato.
    */

    INSERT INTO dw.fato_incidente (
        cod_incidente,
        id_servico,
        id_solicitante,
        id_tempo_abertura,
        id_tempo_fechamento,
        status_incidente,
        prioridade,
        quantidade,
        tempo_resolucao_horas,
        data_carga
    )
    SELECT incidente.cod_incidente,
           servico.id_servico,
           solicitante.id_solicitante,
           tempo_abertura.id_tempo,
           tempo_fechamento.id_tempo,
           incidente.status_incidente,
           incidente.prioridade,
           1,
           CASE
               WHEN incidente.data_fechamento IS NOT NULL
                   THEN CAST(DATEDIFF(MINUTE, incidente.data_abertura, incidente.data_fechamento) / 60.0 AS DECIMAL(10,2))
               ELSE NULL
           END,
           @data_carga
    FROM staging.stg_incidente incidente
    INNER JOIN dw.dim_servico servico ON servico.cod_tipo_servico = incidente.cod_tipo_servico
    INNER JOIN dw.dim_solicitante solicitante ON solicitante.cod_solicitante = incidente.cod_solicitante
        AND CAST(incidente.data_abertura AS DATE) BETWEEN solicitante.data_inicio AND solicitante.data_fim
    INNER JOIN dw.dim_tempo tempo_abertura ON tempo_abertura.data_completa = CAST(incidente.data_abertura AS DATE)
    LEFT JOIN dw.dim_tempo tempo_fechamento ON tempo_fechamento.data_completa = CAST(incidente.data_fechamento AS DATE)
    WHERE incidente.data_carga = @data_carga
      AND NOT EXISTS (
          SELECT 1
          FROM dw.fato_incidente destino
          WHERE destino.cod_incidente = incidente.cod_incidente
      );
END;
GO


/* ============================================================
   13. PROCEDIMENTO PRINCIPAL DO ETL

   O procedimento principal recebe somente a data da carga.

   A dimensão tempo não é carregada aqui, pois ela deve ser
   preparada previamente para um intervalo completo.

   Ordem:
   1. staging;
   2. dimensão serviço;
   3. dimensão solicitante;
   4. tabela fato.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_executar_etl
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @data_carga IS NULL
        THROW 50007, 'A data da carga deve ser informada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC staging.sp_carregar_staging @data_carga = @data_carga;
        EXEC dw.sp_carregar_dim_servico @data_carga = @data_carga;
        EXEC dw.sp_carregar_dim_solicitante @data_carga = @data_carga;
        EXEC dw.sp_carregar_fato_incidente @data_carga = @data_carga;

        COMMIT TRANSACTION;

        PRINT CONCAT('ETL executado com sucesso. Data da carga: ', CONVERT(VARCHAR(10), @data_carga, 103));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


/* ============================================================
   14. CARGA INICIAL DA DIMENSÃO TEMPO

   A dimensão tempo será preenchida para um intervalo de
   dois anos completos: 2026 e 2027.

   Essa execução deve ocorrer antes da carga da tabela fato.
   ============================================================ */

EXEC dw.sp_carregar_dim_tempo @data_inicial = '2026-01-01', @data_final = '2027-12-31';
GO


/* ============================================================
   15. VERIFICAÇÃO DA DIMENSÃO TEMPO
   ============================================================ */

SELECT MIN(data_completa) AS primeira_data,
       MAX(data_completa) AS ultima_data,
       COUNT(*) AS quantidade_dias
FROM dw.dim_tempo;

SELECT TOP 10 *
FROM dw.dim_tempo
ORDER BY data_completa;
GO


/* ============================================================
   16. PRIMEIRA EXECUÇÃO DO ETL
   ============================================================ */

EXEC dw.sp_executar_etl @data_carga = '2026-07-04';
GO


/* ============================================================
   17. CONSULTAS APÓS A PRIMEIRA CARGA
   ============================================================ */

/* Dados da staging. */

SELECT * FROM staging.stg_tipo_servico ORDER BY data_carga, cod_tipo_servico;
SELECT * FROM staging.stg_solicitante ORDER BY data_carga, cod_solicitante;
SELECT * FROM staging.stg_incidente ORDER BY data_carga, cod_incidente;


/* Dados do Data Warehouse. */

SELECT * FROM dw.dim_servico ORDER BY id_servico;
SELECT * FROM dw.dim_solicitante ORDER BY cod_solicitante, data_inicio;
SELECT * FROM dw.dim_tempo ORDER BY data_completa;
SELECT * FROM dw.fato_incidente ORDER BY cod_incidente;
GO


/* ============================================================
   18. TESTE DA DIMENSÃO SCD TIPO 1

   O nome do serviço será alterado no ambiente operacional.

   Como dim_servico é Tipo 1:
   - o valor anterior será substituído;
   - uma nova linha não será criada.
   ============================================================ */

UPDATE oltp.tipo_servico
SET nome_tipo_servico = 'Suporte a sistemas corporativos'
WHERE cod_tipo_servico = 1;

EXEC dw.sp_executar_etl @data_carga = '2026-07-05';

SELECT * FROM dw.dim_servico WHERE cod_tipo_servico = 1;
GO


/* ============================================================
   19. TESTE DA DIMENSÃO SCD TIPO 2

   O setor da solicitante será alterado.

   Como dim_solicitante é Tipo 2:
   - a versão anterior será encerrada;
   - uma nova versão será criada;
   - o histórico será mantido.
   ============================================================ */

UPDATE oltp.solicitante
SET setor = 'Contabilidade'
WHERE cod_solicitante = 1;

EXEC dw.sp_executar_etl @data_carga = '2026-07-06';

SELECT id_solicitante,
       cod_solicitante,
       nome_solicitante,
       setor,
       cidade,
       data_inicio,
       data_fim,
       registro_atual
FROM dw.dim_solicitante
WHERE cod_solicitante = 1
ORDER BY data_inicio;
GO


/* ============================================================
   20. HISTÓRICO DAS CARGAS DA STAGING
   ============================================================ */

SELECT data_carga, COUNT(*) AS quantidade_registros
FROM staging.stg_incidente
GROUP BY data_carga
ORDER BY data_carga;
GO


/* ============================================================
   21. REPROCESSAMENTO DE UMA DATA

   Ao reexecutar a carga de 06/07/2026:
   - somente os registros dessa data serão removidos da staging;
   - as cargas anteriores serão preservadas.
   ============================================================ */

EXEC dw.sp_executar_etl @data_carga = '2026-07-06';

SELECT data_carga, COUNT(*) AS quantidade_registros
FROM staging.stg_incidente
GROUP BY data_carga
ORDER BY data_carga;
GO


/* ============================================================
   22. CONSULTA ANALÍTICA POR TIPO DE SERVIÇO
   ============================================================ */

SELECT servico.nome_tipo_servico,
       servico.categoria,
       SUM(fato.quantidade) AS quantidade_incidentes,
       AVG(fato.tempo_resolucao_horas) AS media_horas_resolucao
FROM dw.fato_incidente fato
INNER JOIN dw.dim_servico servico ON servico.id_servico = fato.id_servico
GROUP BY servico.nome_tipo_servico, servico.categoria
ORDER BY quantidade_incidentes DESC;
GO


/* ============================================================
   23. CONSULTA ANALÍTICA POR TEMPO E SETOR
   ============================================================ */

SELECT tempo.ano,
       tempo.mes,
       tempo.nome_mes,
       solicitante.setor,
       SUM(fato.quantidade) AS quantidade_incidentes
FROM dw.fato_incidente fato
INNER JOIN dw.dim_tempo tempo ON tempo.id_tempo = fato.id_tempo_abertura
INNER JOIN dw.dim_solicitante solicitante ON solicitante.id_solicitante = fato.id_solicitante
GROUP BY tempo.ano, tempo.mes, tempo.nome_mes, solicitante.setor
ORDER BY tempo.ano, tempo.mes, solicitante.setor;
GO
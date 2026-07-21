--POVOAMENTO_DIMENSAO_TEMPO

USE DeliFitDB;
GO

/* 
   1. FUNCTION
   Algoritmo de Meeus ->  Usado para derivar os feriados móveis: Carnaval, Sexta-feira Santa, Páscoa e Corpus Christi.
*/

CREATE OR ALTER FUNCTION dw.fn_calcula_pascoa (@ano INT)
RETURNS DATE
AS
BEGIN
    DECLARE @a INT = @ano % 19;
    DECLARE @b INT = @ano / 100;
    DECLARE @c INT = @ano % 100;
    DECLARE @d INT = @b / 4;
    DECLARE @e INT = @b % 4;
    DECLARE @f INT = (@b + 8) / 25;
    DECLARE @g INT = (@b - @f + 1) / 3;
    DECLARE @h INT = (19 * @a + @b - @d - @g + 15) % 30;
    DECLARE @i INT = @c / 4;
    DECLARE @k INT = @c % 4;
    DECLARE @l INT = (32 + 2 * @e + 2 * @i - @h - @k) % 7;
    DECLARE @m INT = (@a + 11 * @h + 22 * @l) / 451;
    DECLARE @mes INT = (@h + @l - 7 * @m + 114) / 31;
    DECLARE @dia INT = ((@h + @l - 7 * @m + 114) % 31) + 1;

    RETURN DATEFROMPARTS(@ano, @mes, @dia);
END;
GO

--2. POVOAMENTO DA DIM_TEMPO

CREATE OR ALTER PROCEDURE dw.sp_povoar_dim_tempo
(
    @data_inicio DATE,
    @data_fim    DATE
)
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 7;  -- garante 1 = Domingo ... 7 = Sábado no DATEPART(WEEKDAY,...)

    IF @data_inicio > @data_fim
    BEGIN
        THROW 50010, 'data_inicio não pode ser maior que data_fim.', 1;
    END

    DECLARE @ano_inicio INT = YEAR(@data_inicio);
    DECLARE @ano_fim    INT = YEAR(@data_fim);

    --2.1 Monta a lista de feriados nacionais do intervalo

    CREATE TABLE #feriados (data_feriado DATE NOT NULL PRIMARY KEY);

    -- Feriados fixos + móveis, tudo em um único INSERT para que o UNION
    -- deduplique corretamente mesmo quando um feriado móvel cai em cima
    -- de um feriado fixo (ex: em 2030 a Páscoa cai em 21/04, mesmo dia
    -- de Tiradentes).
    ;WITH anos AS (
        SELECT @ano_inicio AS ano
        UNION ALL
        SELECT ano + 1 FROM anos WHERE ano < @ano_fim
    )
    INSERT INTO #feriados (data_feriado)
    SELECT DATEFROMPARTS(ano, 1, 1)                        FROM anos   -- Confraternização Universal
    UNION SELECT DATEFROMPARTS(ano, 4, 21)                 FROM anos   -- Tiradentes
    UNION SELECT DATEFROMPARTS(ano, 5, 1)                  FROM anos   -- Dia do Trabalho
    UNION SELECT DATEFROMPARTS(ano, 9, 7)                  FROM anos   -- Independência
    UNION SELECT DATEFROMPARTS(ano, 10, 12)                FROM anos   -- Nossa Sra. Aparecida
    UNION SELECT DATEFROMPARTS(ano, 11, 2)                 FROM anos   -- Finados
    UNION SELECT DATEFROMPARTS(ano, 11, 15)                FROM anos   -- Proclamação da República
    UNION SELECT DATEFROMPARTS(ano, 12, 25)                FROM anos   -- Natal
    UNION SELECT DATEADD(DAY, -47, dw.fn_calcula_pascoa(ano)) FROM anos  -- Carnaval (segunda)
    UNION SELECT DATEADD(DAY, -46, dw.fn_calcula_pascoa(ano)) FROM anos  -- Carnaval (terça)
    UNION SELECT DATEADD(DAY, -2,  dw.fn_calcula_pascoa(ano)) FROM anos  -- Sexta-feira Santa
    UNION SELECT dw.fn_calcula_pascoa(ano)                    FROM anos  -- Páscoa
    UNION SELECT DATEADD(DAY, 60,  dw.fn_calcula_pascoa(ano)) FROM anos  -- Corpus Christi
    OPTION (MAXRECURSION 1000);

--2.2 Gera as datas do intervalo (set-based, sem loop)

    DECLARE @qtd_dias INT = DATEDIFF(DAY, @data_inicio, @data_fim) + 1;

    ;WITH
    L0 AS (SELECT 1 AS c UNION ALL SELECT 1),              -- 2
    L1 AS (SELECT 1 AS c FROM L0 A, L0 B),                 -- 4
    L2 AS (SELECT 1 AS c FROM L1 A, L1 B),                 -- 16
    L3 AS (SELECT 1 AS c FROM L2 A, L2 B),                 -- 256
    L4 AS (SELECT 1 AS c FROM L3 A, L3 B),                 -- 65.536 (~179 anos de cobertura)
    Numeros AS (
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM L4
    ),
    Datas AS (
        SELECT DATEADD(DAY, n, @data_inicio) AS data
        FROM Numeros
        WHERE n < @qtd_dias
    )
    INSERT INTO dw.dim_tempo (dia, data, mes, trimestre, semestre, ano, dia_semana, feriado)
    SELECT
        DAY(d.data)                                         AS dia,
        d.data,
        MONTH(d.data)                                       AS mes,
        DATEPART(QUARTER, d.data)                            AS trimestre,
        CASE WHEN MONTH(d.data) <= 6 THEN 1 ELSE 2 END       AS semestre,
        YEAR(d.data)                                         AS ano,
        CASE DATEPART(WEEKDAY, d.data)
            WHEN 1 THEN 'Domingo'
            WHEN 2 THEN 'Segunda-feira'
            WHEN 3 THEN 'Terça-feira'
            WHEN 4 THEN 'Quarta-feira'
            WHEN 5 THEN 'Quinta-feira'
            WHEN 6 THEN 'Sexta-feira'
            WHEN 7 THEN 'Sábado'
        END                                                  AS dia_semana,
        CASE WHEN f.data_feriado IS NOT NULL THEN 1 ELSE 0 END AS feriado
    FROM Datas d
    LEFT JOIN #feriados f ON f.data_feriado = d.data
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_tempo t WHERE t.data = d.data
    );

    DROP TABLE #feriados;

    SELECT COUNT(*) AS dias_inseridos
    FROM dw.dim_tempo
    WHERE data BETWEEN @data_inicio AND @data_fim;
END;
GO


/*
EXEC dw.sp_povoar_dim_tempo
    @data_inicio = '2020-01-01',
    @data_fim    = '2030-12-31';
*/

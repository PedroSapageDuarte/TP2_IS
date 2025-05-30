USE [Producao]
GO
/****** Object:  Table [dbo].[Produto]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Produto](
	[ID_Produto] [int] IDENTITY(1,1) NOT NULL,
	[Codigo_Peca] [char](8) NOT NULL,
	[Data_Producao] [date] NOT NULL,
	[Hora_Producao] [time](7) NOT NULL,
	[Tempo_Producao] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_Produto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo_Peca] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Testes]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Testes](
	[ID_Teste] [int] IDENTITY(1,1) NOT NULL,
	[ID_Produto] [int] NOT NULL,
	[Codigo_Resultado] [char](2) NOT NULL,
	[Data_Teste] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_Teste] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Testes]  WITH CHECK ADD  CONSTRAINT [FK_Testes_Produto] FOREIGN KEY([ID_Produto])
REFERENCES [dbo].[Produto] ([ID_Produto])
GO
ALTER TABLE [dbo].[Testes] CHECK CONSTRAINT [FK_Testes_Produto]
GO
/****** Object:  StoredProcedure [dbo].[SP_AtualizarProduto]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Declaração da SP
CREATE PROCEDURE [dbo].[SP_AtualizarProduto]
    @id_Produto INT,
    @codigoPeca CHAR(8),
    @dataProducao DATE,
    @horaProducao TIME,
    @tempoProducao INT,
    @codigoResultado CHAR(2),
    @dataTeste DATE            
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verifica se o produto existe
    IF NOT EXISTS (SELECT 1 FROM Produto WHERE ID_Produto = @id_Produto)
    BEGIN
        RAISERROR ('Produto não encontrado.', 16, 1);
        RETURN;
    END
    
    -- Atualiza a tabela Produto
    UPDATE Produto
    SET Codigo_Peca = @codigoPeca,
        Data_Producao = @dataProducao,
        Hora_Producao = @horaProducao,
        Tempo_Producao = @tempoProducao
    WHERE ID_Produto = @id_Produto;

    -- Atualiza a tabela Testes
    UPDATE Testes
    SET Codigo_Resultado = @codigoResultado,
        Data_Teste = @dataTeste
    WHERE ID_Produto = @id_Produto;
    
    -- Recalcula os valores para Custos_Peca (mesma lógica da trigger)
    DECLARE @tipo CHAR(2) = LEFT(@codigoPeca, 2);
    DECLARE @custoProducao DECIMAL(10,2),
            @valorVenda DECIMAL(10,2),
            @prejuizo DECIMAL(10,2),
            @custoFalha DECIMAL(10,2),
            @lucro DECIMAL(10,2);
    
	--Atualizar também na tabela de Custos
	--Filtrar pelo tipo
    IF @tipo = 'aa'
    BEGIN
        SET @custoProducao = @tempoProducao * 1.9;
        SET @valorVenda = 120;
        SET @prejuizo = @tempoProducao * 0.9;
    END
    ELSE IF @tipo = 'ab'
    BEGIN
        SET @custoProducao = @tempoProducao * 1.3;
        SET @valorVenda = 100;
        SET @prejuizo = @tempoProducao * 1.1;
    END
    ELSE IF @tipo = 'ba'
    BEGIN
        SET @custoProducao = @tempoProducao * 1.7;
        SET @valorVenda = 110;
        SET @prejuizo = @tempoProducao * 1.2;
    END
    ELSE IF @tipo = 'bb'
    BEGIN
        SET @custoProducao = @tempoProducao * 1.2;
        SET @valorVenda = 90;
        SET @prejuizo = @tempoProducao * 1.3;
    END
    ELSE
    BEGIN
        SET @custoProducao = 0;
        SET @valorVenda = 0;
        SET @prejuizo = 0;
    END

    --Determina o custo do tipo de falha com base no código do teste
    IF @codigoResultado = '01'
        SET @custoFalha = 0;
    ELSE IF @codigoResultado = '02'
        SET @custoFalha = 3;
    ELSE IF @codigoResultado = '03'
        SET @custoFalha = 2;
    ELSE IF @codigoResultado = '04'
        SET @custoFalha = 2.4;
    ELSE IF @codigoResultado = '05'
        SET @custoFalha = 1.7;
    ELSE IF @codigoResultado = '06'
        SET @custoFalha = 4.5;
    ELSE
        SET @custoFalha = 0;
    
    SET @prejuizo = @prejuizo + @custoFalha;
    SET @lucro = @valorVenda - (@custoProducao + @prejuizo);

    -- Atualiza o registro na tabela Custos_Peca na base Contabilidade
    UPDATE Contabilidade.dbo.Custos_Peca
    SET Codigo_Peca = @codigoPeca,
        Tempo_Producao = @tempoProducao,
        Custo_Producao = @custoProducao,
        Lucro = @lucro,
        Prejuizo = @prejuizo
    WHERE ID_Produto = @id_Produto;
    
    SELECT 'Produto, Testes e Custos atualizados com sucesso' AS Mensagem;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_CustosTotaisProducaoPeriodo]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2) Custo Total de Produção num período
CREATE   PROCEDURE [dbo].[SP_CustosTotaisProducaoPeriodo]
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SUM(cp.Custo_Producao)
    FROM Contabilidade.dbo.Custos_Peca cp
    JOIN Producao.dbo.Produto p ON cp.ID_Produto = p.ID_Produto
    WHERE p.Data_Producao BETWEEN @StartDate AND @EndDate;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_GetDetalhesFinanceirosPorPeca]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5) Dados Financeiros Detalhados por peça
CREATE   PROCEDURE [dbo].[SP_GetDetalhesFinanceirosPorPeca]
    @PieceCode CHAR(8)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.Codigo_Peca       AS PieceCode,
        cp.Custo_Producao   AS TotalCost,
        (cp.Lucro + cp.Prejuizo) AS TotalRevenue,
        (cp.Lucro - cp.Prejuizo) AS ProfitOrLoss,
        p.Data_Producao     AS LastProducedDate
    FROM Contabilidade.dbo.Custos_Peca cp
    JOIN Producao.dbo.Produto p ON cp.ID_Produto = p.ID_Produto
    WHERE p.Codigo_Peca = @PieceCode;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_GetPecaMaiorPrejuizo]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1) Peça com Maior Prejuízo
CREATE   PROCEDURE [dbo].[SP_GetPecaMaiorPrejuizo]
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        cp.Codigo_Peca
    FROM Contabilidade.dbo.Custos_Peca cp
    JOIN Producao.dbo.Produto p ON cp.ID_Produto = p.ID_Produto
    WHERE p.Data_Producao BETWEEN @StartDate AND @EndDate
    ORDER BY cp.Prejuizo DESC;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_InserirPecas]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Declaração da SP
CREATE PROCEDURE [dbo].[SP_InserirPecas]
    @codigoPeca CHAR(8),
    @dataProducao DATE,
    @horaProducao TIME,
    @tempoProducao INT,
    @codigoResultado CHAR(2),
    @dataTeste DATE           
AS
BEGIN
	--Verificar se já existe uma peça com o código atual e interrompe a inserção (caso haja)
    IF EXISTS (SELECT 1 FROM Produto WHERE Codigo_Peca = @codigoPeca)
    BEGIN
        RAISERROR ('Produto com este código já existe já existe.', 16, 1);
        RETURN;
    END

	--Caso contrário, inserir peça na tabela "Produto" com os respetivos valores
    INSERT INTO Produto (Codigo_Peca, Data_Producao, Hora_Producao, Tempo_Producao)
    VALUES (@CodigoPeca, @DataProducao, @HoraProducao, @TempoProducao);
    
    --Recupera o ID do produto recém-inserido
    DECLARE @NovoID INT;
    SET @NovoID = SCOPE_IDENTITY(); --Retorna o ID do último ID inserido na tabela
    
    --Se não for informado o código do teste, define como "06" (Desconhecido)
    IF (@codigoResultado IS NULL)
        SET @codigoResultado = '06';
    
    --Se não for informada a data do teste, usar a data atual
    IF (@dataTeste IS NULL)
        SET @dataTeste = CONVERT(DATE, GETDATE());
    
    --Inserir o registo do teste na tabela Testes
    INSERT INTO Testes (ID_Produto, Codigo_Resultado, Data_Teste)
    VALUES (@NovoID, @codigoResultado, @dataTeste);
    
    SELECT @NovoID AS ProdutoID, 'Inserção realizada com sucesso' AS Mensagem;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LucroTotalPeriodo]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3) Lucro Total num período
CREATE   PROCEDURE [dbo].[SP_LucroTotalPeriodo]
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SUM(cp.Lucro)
    FROM Contabilidade.dbo.Custos_Peca cp
    JOIN Producao.dbo.Produto p ON cp.ID_Produto = p.ID_Produto
    WHERE p.Data_Producao BETWEEN @StartDate AND @EndDate;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_PrejuizoTotalCadaPecaPeriodo]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4) Prejuízo Total de cada peça num período
CREATE   PROCEDURE [dbo].[SP_PrejuizoTotalCadaPecaPeriodo]
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        p.Codigo_Peca,
        SUM(cp.Prejuizo) AS TotalLoss
    FROM Contabilidade.dbo.Custos_Peca cp
    JOIN Producao.dbo.Produto p ON cp.ID_Produto = p.ID_Produto
    WHERE p.Data_Producao BETWEEN @StartDate AND @EndDate
    GROUP BY p.Codigo_Peca;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_RemoveProduto]    Script Date: 30/05/2025 09:47:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Declaração da SP
CREATE PROCEDURE [dbo].[SP_RemoveProduto]
    @id_Produto INT
AS
BEGIN    
    SET NOCOUNT ON;
    
    --Verifica se o produto existe
    IF NOT EXISTS (SELECT 1 FROM Produto WHERE ID_Produto = @id_Produto)
    BEGIN
        RAISERROR ('Produto não encontrado.', 16, 1);
        RETURN;
    END
    
    --Remove os registros dependentes em Testes
    DELETE FROM Testes WHERE ID_Produto = @id_Produto;
    
    --Remove o registro na tabela Custos_Peca na base Contabilidade
    DELETE FROM Contabilidade.dbo.Custos_Peca WHERE ID_Produto = @id_Produto;
    
    --Remove o produto na tabela Produto
    DELETE FROM Produto WHERE ID_Produto = @id_Produto;
    
    SELECT 'Produto, Testes e Custos removidos com sucesso' AS Mensagem;
END;
GO

Use CBDLeiloes
Go

--Triggers que disparam--
IF OBJECT_ID ('SchemaLicitacao.TrLicitacao', 'TR') IS NOT NULL
	DROP Trigger SchemaLicitacao.TrLicitacao ;
GO
CREATE TRIGGER SchemaLicitacao.TrLicitacao
ON SchemaLicitacao.Licitacao
AFTER INSERT 
AS
Declare @data datetime
Declare @produto int
Declare @licitacao int
Declare @valor decimal
Declare @userID int
Declare @valorMax decimal
BEGIN
	select @produto=LicitacaoProdutoID, @licitacao=LicitacaoId, @valor=LicitacaoValorActual, 
		@userID=LicitacaoUtilizadorID, @valorMax=LicitacaoValorMax  
		from inserted

	execute SchemaLicitacao.procLicitarProd @userID,@produto,@valor, @valorMax
END
Go

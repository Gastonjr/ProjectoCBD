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
BEGIN
	select @data =LicitacaoData, @produto=LicitacaoProdutoID, @licitacao=LicitacaoId, @valor=LicitacaoValorActual, 
		@userID=LicitacaoUtilizadorID 
		from inserted
	if @valor is null
	Begin
		if exists (select 1 from SchemaProduto.Historico where @produto=HistoricoProdutoID)
		begin
			select @valor=(ProdutoValorActual+0.01) from SchemaProduto.Produto where @produto=ProdutoId
		end
		else
		begin
			select @valor=ProdutoValorActual from SchemaProduto.Produto where @produto=ProdutoId
		end
   End
   execute SchemaProduto.procLicitarProd @userID,N'Faz chorar',N'2016-10-12',10,N'mail@io.at',N'Pass'

	--update SchemaProduto.Produto
	--set ProdutoValorActual= @valor where ProdutoId=@produto
	
END
Go


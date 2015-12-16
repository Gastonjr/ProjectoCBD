Use CBDLeiloes
Go

--Triggers que disparam--
CREATE TRIGGER SchemaLicitacao.TrLicitacao
ON SchemaLicitacao.Licitacao
AFTER INSERT 
AS
Declare @data datetime
Declare @produto int
Declare @licitacao int
Declare @valor decimal
BEGIN
	select @data =LicitacaoData, @produto=LicitacaoProdutoID, @licitacao=LicitacaoId, @valor=LicitacaoValorActual from inserted
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
   insert into SchemaProduto.Historico(
   HistoricoValorLicitacao,HistoricoDataCompetLicitacao ,HistoricoProdutoID, HistoricoLicitacaoID
   )values(@valor, getdate(),@produto,@licitacao)

	--update SchemaProduto.Produto
	--set ProdutoValorActual= @valor where ProdutoId=@produto
	
END
Go


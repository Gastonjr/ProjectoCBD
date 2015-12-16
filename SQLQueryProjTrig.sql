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

	update SchemaProduto.Produto
	set ProdutoValorActual= @valor where ProdutoId=@produto
	
	update Licitacao
	set LicitacaoValorActual = @valor where LicitacaoId =@licitacao
END
Go

CREATE TRIGGER SchemaProduto.TrHistorico
ON SchemaProduto.Historico
AFTER INSERT 
AS
BEGIN
	Declare @produto int
	Declare @licitacao int
	Declare @valor decimal
	Declare @valorNov decimal
	Declare @valorMax decimal
	if exists (select 1 from SchemaLicitacao.Licitacao, inserted 
		where HistoricoProdutoID=LicitacaoProdutoID and HistoricoLicitacaoID!=LicitacaoID )
	Begin
		select @valorMax=Max( LicitacaoValorMax ) from SchemaLicitacao.Licitacao, inserted where LicitacaoID != HistoricoLicitacaoID
		select @licitacao=LicitacaoId from SchemaLicitacao.Licitacao where LicitacaoValorMax=@valorMax
		select @valor=(HistoricoValorLicitacao+0.01), @produto=HistoricoProdutoID from inserted
		if @valor<=@valorMax
		begin
			insert into SchemaProduto.Historico(
				HistoricoValorLicitacao,HistoricoDataCompetLicitacao,HistoricoProdutoID, HistoricoLicitacaoID
				)values(@valor, GETDATE(), @produto,@licitacao)
			update SchemaProduto.Produto
			set ProdutoValorActual= @valor where ProdutoId=@produto
			
			update Licitacao
			set LicitacaoValorActual = @valor where LicitacaoId =@licitacao
		end 
	end
	
 END
Go
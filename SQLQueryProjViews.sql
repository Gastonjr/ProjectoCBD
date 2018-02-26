---criação de views---
Use CBDLeiloes
Go
IF OBJECT_ID ('SchemaProduto.vUtilizadorProvendoAvenda', 'V') IS NOT NULL
	DROP View SchemaProduto.vUtilizadorProvendoAvenda;
GO
Create view SchemaProduto.vUtilizadorProvendoAvenda /*a view que lista o numero de produtos a venda no momento*/
as 
SELECT ProdutoUtilizadorID, COUNT(ProdutoId) as ProdutosVendidos  
from  SchemaProduto.Produto,SchemaUtilizador.Utilizador       
where   UtilizadorId= ProdutoUtilizadorID and DATEDIFF(S, GETDATE(), ProdutoDataLimiteLeilao)>0
group by ProdutoUtilizadorID;
Go
 --select * from SchemaProduto.vUtilizadorProvendoAvenda;

-----------------------criação de view que lista o numero de produtos vendidos--------------------------------------------------------------------------
IF OBJECT_ID ('SchemaProduto.vUtilizadorProdutosVendidos', 'V') IS NOT NULL
	DROP View SchemaProduto.vUtilizadorProdutosVendidos;
GO
create view SchemaProduto.vUtilizadorProdutosVendidos
as
select UtilizadorId,  count(ProdutoId) as Produtosvendidos from SchemaUtilizador.Utilizador, SchemaProduto.Produto

where ProdutoUtilizadorID= UtilizadorId and DATEDIFF(S, GETDATE(), ProdutoDataLimiteLeilao)<0 group by UtilizadorId;
Go

-----------------------criação de view que  lista o numero de produtos comprados ------------------------------------------------------------------------


IF OBJECT_ID ('SchemaUtilizador.vUtililizadorLicitacaoCompra', 'V') IS NOT NULL
	DROP View SchemaUtilizador.vUtililizadorLicitacaoCompra;
GO
create view SchemaUtilizador.vUtililizadorLicitacaoCompra
as
select UtilizadorNome, COUNT(CompraProdutoID) as ProdutoComprado  from SchemaUtilizador.Compra, SchemaUtilizador.Utilizador, SchemaLicitacao.Licitacao
where LicitacaoUtilizadorID= UtilizadorId and CompraLicitacaoID= LicitacaoId
group by UtilizadorNome;
Go


------------------------criação da view que lista o utilizador com a melhor classificação------------------------------------------------------------------
IF OBJECT_ID ('SchemaUtilizador.vUtilizadoresMelhorClassificação', 'V') IS NOT NULL
	DROP View SchemaUtilizador.vUtilizadoresMelhorClassificação;
GO
create view SchemaUtilizador.vUtilizadoresMelhorClassificação
as
	select Top 10 UtilizadorId , AVG(CompraClassificacao) as 'Classificao Media'  from SchemaUtilizador.Compra, SchemaUtilizador.Utilizador, SchemaLicitacao.Licitacao
	where LicitacaoUtilizadorID= UtilizadorId and CompraLicitacaoID= LicitacaoId
	group by UtilizadorId;
Go


-------------------------criação da view que lista a classificação media de utilizador-----------------------------------------------------------------------
IF OBJECT_ID ('SchemaUtilizador.vUtilizadoresMelhorClassificaoMes', 'V') IS NOT NULL
	DROP View SchemaUtilizador.vUtilizadoresMelhorClassificaoMes;
GO
create view SchemaUtilizador.vUtilizadoresMelhorClassificaoMes
as
	select Top 10 UtilizadorId , AVG(CompraClassificacao) as 'Classificao Media'  from SchemaUtilizador.Compra, SchemaUtilizador.Utilizador, SchemaLicitacao.Licitacao, SchemaProduto.Produto
	where LicitacaoUtilizadorID= UtilizadorId and CompraLicitacaoID= LicitacaoId and DATEDIFF(d,ProdutoDataLimiteLeilao,GETDATE())<=30 and LicitacaoProdutoID=ProdutoId
	group by UtilizadorId;
Go


-----------------------criação da view que lista o tipo de utilzador existente na base de dados---------------------------------------------------------------
IF OBJECT_ID ('SchemaUtilizador.vUtipoUtilizador', 'V') IS NOT NULL
	DROP View SchemaUtilizador.vUtipoUtilizador;
GO
create view SchemaUtilizador.vUtipoUtilizador
as 

select UtilizadorNome, TipoUtilizadorNome, UtilizadorDataRegisto from  SchemaUtilizador.Utilizador 
join SchemaUtilizador.TipoUtilizador on TipoUtilizadorId=UtilizadorTipoUtilizadorID;
Go		


	


---criação de views---
Use CBDLeiloes
Go
Create view SchemaProduto.vUtilizadorProvendoAvenda /*a view que lista o numero de produtos a venda no momento*/
as 

SELECT ProdutoUtilizadorID, COUNT(ProdutoId) as ProdutosVendidos  
from  SchemaProduto.Produto,SchemaUtilizador.Utilizador       
where   UtilizadorId= ProdutoUtilizadorID and DATEDIFF(S, GETDATE(), ProdutoDataLimiteLeilao)>0
group by ProdutoUtilizadorID;
 
 --select * from SchemaProduto.vUtilizadorProvendoAvenda;
--criação de view que lista o numero de produtos vendidos.
GO
create view SchemaProduto.vUtilizadorProdutosVendidos
as
select UtilizadorId,  count(ProdutoId) as Produtosvendidos from SchemaUtilizador.Utilizador, SchemaProduto.Produto

where ProdutoUtilizadorID= UtilizadorId and DATEDIFF(S, GETDATE(), ProdutoDataLimiteLeilao)<0 group by UtilizadorId;

 Go

 create view SchemaUtilizador.vUtililizadorLicitacaoCompra
  as 
  
  select UtilizadorId , COUNT(CompraProdutoID) as ProdutoComprado  from SchemaUtilizador.Compra, SchemaUtilizador.Utilizador, SchemaLicitacao.Licitacao
  
  where LicitacaoUtilizadorID= UtilizadorId and CompraLicitacaoID= LicitacaoId
   group by UtilizadorId;
Go     
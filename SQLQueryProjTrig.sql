Use CBDLeiloes
Go

--Triggers que disparam--

IF OBJECT_ID ('SchemaProduto.TrProduto', 'TR') IS NOT NULL
	DROP Trigger SchemaProduto.TrProduto;
GO
CREATE TRIGGER SchemaProduto.TrProduto
ON SchemaProduto.Produto
AFTER INSERT 
AS
BEGIN
	DECLARE @produtoID int
	select @produtoID = ProdutoId from inserted
	exec SchemaUtilizador.FinalizarCompra @produtoID
END
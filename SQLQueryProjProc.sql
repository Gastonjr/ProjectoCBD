Use CBDLeiloes
Go

--Procedimentos que Procedem ou procedure --
--Procedimento para registar o utilizador--
IF OBJECT_ID ('SchemaUtilizador.procRegUser', 'P') IS NOT NULL
	DROP Proc SchemaUtilizador.procRegUser;
GO
create proc SchemaUtilizador.procRegUser
		(@username varchar(40), @password varchar(32), @email varchar(255),
		@userDoB varchar(50),@userPhone varchar(9))
as
BEGIN
Set nocount on/*não conta as linhas que foram afeitadas, sempre	que alterar e inserir*/
	declare @Hash varchar(32)
	DECLARE @msgErro varchar(500)

	if @email not like '%@%.%' /*verifica se o email está com a forma correcta*/
	begin
		set @msgErro = 'O Email é inválido: ' + CONVERT(VARCHAR, @email)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	if exists (select 1 from Utilizador where UtilizadorEmail=@email)/*verifica se existe o Email , e enviar a mensagem de erro  */
	begin
		set @msgErro = 'O utilizador já existe: ' + CONVERT(VARCHAR, @email)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	
	set @Hash= SchemaUtilizador.funcPassToHash(@password)

	insert into SchemaUtilizador.Utilizador(UtilizadorEmail,UtilizadorNome,UtilizadorSenha,UtilizadorDataRegisto,UtilizadorDataNascimento,UtilizadorTelefone)
							  values (@email,@username,@Hash,GETDATE(),@userDoB,@userPhone)

	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no insert com erro: ' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO
--Teste do procedimento procRegUser--
--execute SchemaUtilizador.procRegUser N'Rui',N'Pass',N'mail@io.at',N'1991-10-12',N'919942285';
--Go

--Procedimento para colocar um produto à venda--
IF OBJECT_ID ('SchemaProduto.procVenderProd', 'P') IS NOT NULL
	DROP proc SchemaProduto.procVenderProd;
GO
Create proc SchemaProduto.procVenderProd
			(@ProdDesc varchar(100), @ProdNome varchar(50), @ProdDataLimite varchar(50), 
			 @ProdValorMin int,@userID int)/*verifica se utilizador está autenticado ou login*/
as
BEGIN
	Set nocount on
	DECLARE @msgErro varchar(500)
	if datediff(s,getdate(),@ProdDataLimite)<0/*verifica se já passou o ultimo segundo do leilão*/
	begin
		set @msgErro = 'A data limite do leilão é inválida: ' + CONVERT(VARCHAR, @ProdDataLimite)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	if exists (Select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@userID)
	Begin
		set @msgErro = 'O utilizador não se encontra nos registos. '
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	Insert into SchemaProduto.Produto (ProdutoNome,ProdutoDescricao,  ProdutoDataLimiteLeilao, ProdutoValorMinVenda,ProdutoUtilizadorID )
		values (@ProdNome, @ProdDesc, @ProdDataLimite, @ProdValorMin,@userID)
END
Go
--Teste do procedimento procVenderProd--
--execute SchemaProduto.procVenderProd N'cebola',N'Faz chorar',N'2016-10-12',10,N'mail@io.at',N'Pass';
--select * from SchemaProduto.Produto where ProdutoNome='cebola'
--Go

--Procedimento para licitar num produto--
IF OBJECT_ID ('SchemaLicitacao.procLicitarProd', 'P') IS NOT NULL
	DROP proc SchemaLicitacao.procLicitarProd;
GO
Create proc SchemaLicitacao.procLicitarProd
			(@NuserID int, @prodID int, @licitaValMax decimal(9,2))
as
BEGIN
	DECLARE @msgErro varchar(500)
	Declare @VuserID int
	DECLARE @valActual decimal(9,2)
	DECLARE @valActualMax decimal(9,2)
	DECLARE @prodDate datetime
	DECLARE @ProdVal DECIMAL(9,2)
	DECLARE @FLiciVal DECIMAL(9,2)
	DECLARE @FLiciValMax DECIMAL(9,2)
	DECLARE @FuserID int
	Declare @VendedorID int
	Set nocount on
	if not exists (Select 1 from SchemaProduto.Produto where ProdutoId=@prodID)
	begin 
		set @msgErro = 'O produto não se encontra nos registos.'
		RAISERROR(@msgErro,16,1)
		RETURN 
	end

	if not exists (Select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@NuserID)
	begin
		set @msgErro = 'O utilizador não se encontra nos registos.'
		RAISERROR(@msgErro,16,1)
		RETURN 
	end

	select @VendedorID=ProdutoUtilizadorID, @prodDate = ProdutoDataLimiteLeilao,@ProdVal=ProdutoValorMinVenda from SchemaProduto.Produto where @prodid=ProdutoId
	if (@VendedorID=@NuserID)
	begin
		set @msgErro = 'Não podes licitar no teu próprio produto. ' + CONVERT(VARCHAR, @VendedorID)
		RAISERROR(@msgErro,16,1)
		RETURN 
	end
	if datediff(s,getdate(),@prodDate)<0
	begin
		set @msgErro = 'Já passou o tempo para licitar. ' + CONVERT(VARCHAR, @prodDate)
		RAISERROR(@msgErro,16,1)
		RETURN 
	end

	if (@ProdVal>@licitaValMax)
	begin
		set @msgErro = 'O valor da licitação é menor que o valor mínimo.'
		RAISERROR(@msgErro,16,1)
		RETURN 
	end
	
	--Procurar o valor da licitação actual de um produto.
	if not exists (select 1 from SchemaLicitacao.Licitacao where LicitacaoProdutoID=@prodID)
	begin
		select @FLiciVal=ProdutoValorMinVenda from SchemaProduto.Produto where ProdutoId = @prodID
		set @FLiciValMax=@licitaValMax
		set @FuserID=@NuserID
	end
	else
	begin
		select TOP 1 @valActual= LicitacaoValorActual, @valActualMax=LicitacaoValorMax, @VuserID=LicitacaoUtilizadorID 
			from Licitacao where LicitacaoProdutoID=@prodID
			Order by LicitacaoValorActual Desc
		if @NuserID=@VuserID
		begin
			set @msgErro = 'Já licitaste neste produto: ' + CONVERT(VARCHAR, @prodID)
			RAISERROR(@msgErro,16,1)
			RETURN 
		end
		if @licitaValMax <= @valActual
		begin
			set @msgErro = 'A licitação é menor ou igual ao valor actual: ' + CONVERT(VARCHAR, @licitaValMax) +' < '+ CONVERT(VARCHAR, @valActual)
			RAISERROR(@msgErro,16,1)
			RETURN 
		end
		--Corte e costura

		if(@valActualMax > @licitaValMax)
		begin
			set @FLiciVal=(@licitaValMax+0.01)
			set @FLiciValMax=@valActualMax
			set @FuserID=@VuserID
			Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual,LicitacaoData)
					values(@NuserID, @prodid,@licitaValMax, (@valActual+0.01),Getdate())
		end
		else
		begin
			if(@valActualMax=@licitaValMax)
			begin
				set @FLiciVal=@valActualMax
				set @FLiciValMax=@valActualMax
				set @FuserID=@VuserID
				if(@valActual<(@valActualMax-0.01))
				begin
					Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual,LicitacaoData)
						values(@NuserID, @prodid,@licitaValMax, (@valActual+0.01),Getdate())
				end
			end
			else
			begin
				set @FLiciVal=(@valActualMax+0.01)
				set @FLiciValMax=@licitaValMax
				set @FuserID=@NuserID
			end
		end
	end
	
	Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual,LicitacaoData)
			values(@Fuserid, @prodid,@FLiciValMax, @FLiciVal,Getdate())
	
END
Go
--Teste do procedimento procLicitarProd--
/*
--Prod 20 autor 10 valormin 47.06
execute SchemaLicitacao.procLicitarProd 5,20,731.53
execute SchemaLicitacao.procLicitarProd 6,20,531.53
execute SchemaLicitacao.procLicitarProd 10,20,731.53
execute SchemaLicitacao.procLicitarProd 6,20,731.53
*/



-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------fase 2 continuação------------------------------------------
--****************** procedimento que funcionam na fase 2 *************************---

---procedimento que modifica a password de um utilizador , recebendo a pass antiga para nova
IF OBJECT_ID ('SchemaUtilizador.ModificarPassword', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.ModificarPassword;
GO
create proc SchemaUtilizador.ModificarPassword
		(@username varchar(255), @passwordAntiga varchar(32),
		@passwordNova varchar(32))
as
BEGIN
	DECLARE @msgErro varchar(500)
	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorEmail=@username)
	begin
		set @msgErro = 'O username é  inválido: ' + CONVERT(VARCHAR,@username)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	if  not exists (select 1 from SchemaUtilizador.Utilizador 
		where UtilizadorEmail=@username and  UtilizadorSenha= @passwordAntiga)
		/*verifica se existe a passworda antiga */
	begin
		set @msgErro = 'A password antiga é inválida: ' + CONVERT(VARCHAR,@passwordAntiga)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	update SchemaUtilizador.Utilizador set UtilizadorSenha= @passwordNova where UtilizadorSenha= @passwordAntiga and UtilizadorEmail= @username
	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no update com erro: ' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO

---------***procedimento que devolve uma lista de produto  seguido por um determinado uttilizador***------------------------------------

IF OBJECT_ID ('SchemaUtilizador.ProdutoSeguido', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.ProdutoSeguido;
GO
create proc SchemaUtilizador.ProdutoSeguido
		(@utilizadorID int )
as
BEGIN
	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@utilizadorID)
	begin
		set @msgErro = 'não existe o produto seguido por utilizador ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	select SeguirProdutoProdutoId from SchemaUtilizador.SeguirProduto 
		where SeguirProdutoUtilizadorID=@utilizadorID;	
	
	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no Select com erro: ' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO

---------*** Procedimento que devolve uma lista com produtos actualemnte a venda por um utilzador seguido***-------------------------------- 

IF OBJECT_ID ('SchemaUtilizadorSeguidor.ProdutoVendaActual', 'P') IS NOT NULL
	DROP proc SchemaUtilizadorSeguidor.ProdutoVendaActual;
GO
create proc SchemaUtilizador.ProdutoVendaActual
		(@utilizadorSeguidorID int )
as
BEGIN
	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Seguidor where SeguidorSeguidorID=@utilizadorSeguidorID  )
	begin
		set @msgErro = ' não existe o utilizador a seguir outro' + CONVERT(int ,@utilizadorSeguidorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	select p.*, p.ProdutoValorMinVenda as 'Produto atual Vendido ' from SchemaUtilizador.Seguidor s join   SchemaProduto.Produto p on(s.SeguidorSeguidorID= @utilizadorSeguidorID) 
	where  p.ProdutoUtilizadorID= s.SeguidorTableId;

if @@ERROR <>0
	begin
		set @msgErro = 'Falha no select com erro:' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO


------*** Procedimento que mostra as licitações ativas  de um determinado utilizador**------------------------------------------------
IF OBJECT_ID ('SchemaUtilizador.MostrarLicitacaoActiva', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.MostrarLicitacaoActiva;
GO
create proc SchemaUtilizador.MostrarLicitacaoActiva
		(@utilizadorID int )
as
BEGIN

	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@utilizadorID)
	begin
		set @msgErro = 'não existe licitação ativa de um utilizador ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end


	if  not exists (select 1 from SchemaLicitacao.Licitacao where LicitacaoUtilizadorID=@utilizadorID)
	begin
		set @msgErro = 'O utilizador não licitou ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	select l.*from SchemaLicitacao.Licitacao l , SchemaProduto.Produto p
		where l.LicitacaoProdutoID= p.ProdutoId and p.ProdutoDataLimiteLeilao > GETDATE() and l.LicitacaoUtilizadorID= @utilizadorID;
	
	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no select com erro:' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO

---------------------***procedimento que devolve uma lista todos produtos vendidos por um utilizador***-----------------------------------------------------

--select UtilizadorId, UtilizadorNome  from SchemaUtilizador.Utilizador, SchemaProduto.Produto where ProdutoUtilizadorID=2;
--select UtilizadorId, UtilizadorNome from SchemaUtilizador.Utilizador, SchemaUtilizador.Compra where CompraClassificacao= null;
--select * from SchemaLicitacao.Licitacao

IF OBJECT_ID ('SchemaUtilizador.MostrarProdutoVendido', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.MostrarProdutoVendido;
GO
create proc SchemaUtilizador.MostrarProdutoVendido
		(@utilizadorID int)
as
BEGIN

	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@utilizadorID)
	begin
		set @msgErro = 'não existe vendas de produtos por um utilizador ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end


	if  not exists (select 1 from SchemaProduto.Produto where ProdutoUtilizadorID=@utilizadorID )
	begin
		set @msgErro = 'O utilizador não vendeu produto ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	select  p.*, p.ProdutoNome as 'PRODUTO VENDIDO' from SchemaUtilizador.Utilizador u, SchemaProduto.Produto p where p.ProdutoUtilizadorID= u.UtilizadorId and p.ProdutoUtilizadorID= @utilizadorID ;
	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no select com erro:' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO


-------procedimento que apresenta as compras de um utilizador , que tem  uma classificação pendente--------------------------------------------

IF OBJECT_ID ('SchemaUtilizador.ApresentarCompras', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.ApresentarCompras;
GO
create proc SchemaUtilizador.ApresentarCompras
		(@utilizadorID int)
as
BEGIN

	DECLARE @produtoID int
	DECLARE @compraID int 
	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@utilizadorID)
	begin
		set @msgErro = 'não existe o utilizador   ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end


	if  not exists (select 1 from SchemaProduto.Produto where ProdutoUtilizadorID=@utilizadorID  )
	begin
		set @msgErro = 'não existe o utilizador inserido com  compras de produtos  ' + CONVERT(int ,@utilizadorID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	
if  not exists (select 1 from SchemaUtilizador.Compra where CompraProdutoID = @produtoID )
	begin
		set @msgErro = 'O não existe o produto inserido   ' + CONVERT(int ,@produtoID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	if  not exists (select 1 from SchemaUtilizador.Compra where CompraId= @compraID )
	begin
		set @msgErro = 'O utilizador com  compras pendentes  ' + CONVERT(int ,@compraID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end 

	select UtilizadorId, c.* from SchemaUtilizador.Utilizador, SchemaUtilizador.Compra c where c.CompraClassificacao is null;
	
	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no select com erro:' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end

END

GO


---------------------------------procedimento que classifica a compra por um determinado utilizador---------------------------------------------------------------------


	IF OBJECT_ID ('SchemaUtilizador.ClassificarCompra', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.ClassificarCompra;
GO
create proc SchemaUtilizador.ClassificarCompra
		(@licitacaoID int  , @compraclassificacao int )
as
BEGIN

	DECLARE @msgErro varchar(500)
	DECLARE @dataLimiteLeilao datetime
	Declare @produtoID int
	if   (@compraclassificacao >0 or @compraclassificacao<5 )
	begin
		set @msgErro = 'classificação é invalida ' + CONVERT(int ,@compraclassificacao)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	if  not exists (select 1 from SchemaLicitacao.Licitacao where LicitacaoId= @licitacaoID )
	begin
		set @msgErro = 'não existe a licitacao do  produto  ' + CONVERT(int ,@licitacaoID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	if  exists (select 1 from SchemaUtilizador.Compra where CompraLicitacaoID= @licitacaoID  )
	begin
		set @msgErro = ' a compra já foi classificada  ' + CONVERT(int ,@licitacaoID)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	select @dataLimiteLeilao= ProdutoDataLimiteLeilao, @produtoID = LicitacaoProdutoID from SchemaLicitacao.Licitacao, SchemaProduto.Produto 
		where LicitacaoProdutoID=ProdutoId;
	if( datediff(s,getdate(),@dataLimiteLeilao)>0 )
	begin
		set @msgErro = 'o tempo  da licitacao de um produto já passou   ' + CONVERT(int ,@dataLimiteLeilao)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	
end

------------------------------------Procedimento que apresenta os utilizadores com melhore classificação , nos produto vendidos -----------------------------------------------------------------------



--select  max(c.CompraClassificacao) from  SchemaUtilizador.Utilizador u, SchemaProduto.Produto  p, SchemaUtilizador.Compra c

--where p.ProdutoUtilizadorID= u.UtilizadorId and c.CompraProdutoID= p.ProdutoId;


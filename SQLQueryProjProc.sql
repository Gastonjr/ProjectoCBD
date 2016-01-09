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
			(@NuserID int, @prodID int, @licitaValMax decimal)
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
	Set nocount on

	if SchemaLicitacao.CheckProduto(@prodID)=0
	begin
		return
	end

	if SchemaLicitacao.CheckUtilizador(@NuserID)=0
	BEGIN
		RETURN
	END

	select @prodDate = ProdutoDataLimiteLeilao,@ProdVal=ProdutoValorMinVenda from SchemaProduto.Produto where @prodid=ProdutoId
	
	if SchemaLicitacao.CheckDataLeilao(@prodDate)=0
	begin
		return
	end

	if SchemaLicitacao.CheckDataLeilao(@ProdVal,@licitaValMax)=0
	begin
		return
	end
	
	

	--Procurar o valor da licitação actual de um produto.
	if not exists (select MAX(LicitacaoValorActual) from Licitacao where LicitacaoProdutoID=@prodID)
	begin
		select @FLiciVal=ProdutoValorMinVenda from SchemaProduto.Produto where ProdutoId = @prodID
		set @FLiciValMax=@licitaValMax
		set @FuserID=@NuserID
	end
	else
	begin
		select @valActual= MAX(LicitacaoValorActual), @valActualMax=LicitacaoValorMax 
			from Licitacao where LicitacaoProdutoID=@prodID
			group by LicitacaoValorMax

		if @licitaValMax <= @valActual
		begin
			set @msgErro = 'A licitação é menor ou igual ao valor actual: ' + CONVERT(VARCHAR, @licitaValMax) +' < '+ CONVERT(VARCHAR, @valActual)
			RAISERROR(@msgErro,16,1)
			RETURN 
		end

		if(@valActual!=@licitaValMax and @licitaValMax != (@valActual+0.01))
		begin
		Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual)
			values(@Nuserid, @prodid,@licitaValMax, (@valActual+0.01))
		end
		else
		begin
			if()
			begin
				Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual)
					values(@Nuserid, @prodid,@licitaValMax, (@valActual+0.01))
			end
		end

		if(@valActualMax < @licitaValMax)
		begin
			set @FLiciVal=(@licitaValMax+0.01)
			set @FLiciValMax=@valActualMax
			set @FuserID=@VuserID
		end
		else
		begin
			if(@valActualMax=@licitaValMax)
			begin
				set @FLiciVal=@valActualMax
				set @FLiciValMax=@valActualMax
				set @FuserID=@VuserID
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
--****************** procedimento que funcionam na fase 2 *************************---

IF OBJECT_ID ('SchemaUtilizador.ModificarPassword', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.ModificarPassword;
GO
create proc SchemaUtilizador.ModificarPassword
		(@username varchar(40), @passwordAntiga varchar(32),
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

---***procedure de uma lista de produtos seguido por um utilizador***---

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
		set @msgErro = 'Id é invalido ' + CONVERT(int ,@utilizadorID)
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


--*** mostrar uma licitação que está no prazo**---
IF OBJECT_ID ('SchemaUtilizador.MostrarLicitacaoActivas', 'P') IS NOT NULL
	DROP proc SchemaUtilizador.MostrarLicitacaoActivas;
GO
create proc SchemaUtilizador.MostrarLicitacaoActivas
		(@utilizadorID int )
as
BEGIN

	DECLARE @msgErro varchar(500)

	if  not exists (select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@utilizadorID)
	begin
		set @msgErro = 'Id é invalido ' + CONVERT(int ,@utilizadorID)
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
		set @msgErro = 'Falha no select com erro: ' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO

--select * from SchemaProduto.Produto;
--select * from SchemaLicitacao.Licitacao

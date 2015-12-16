--Procedimentos que Procedem--
--Procedimento para registar o utilizador--
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

Create proc SchemaProduto.procVenderProd
			(@ProdDesc varchar(100), @ProdNome varchar(50), @ProdDataLimite varchar(50), 
			 @ProdValorMin int,@userID int)/*verifica se utilizador está autenticado ou login*/
as
BEGIN
	Set nocount on
	DECLARE @msgErro varchar(500)
	if datediff(s,getdate(),@ProdDataLimite)<0/*verifica se já passou o ultimo segundo do leilão*/
	begin
		set @msgErro = 'Já passou o tempo para licitar.' + CONVERT(VARCHAR, @ProdDataLimite)
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
Create proc SchemaLicitacao.procLicitarProd
			(@email varchar(255),@pass varchar(32), @prodid int, @licitaval int)
as
BEGIN
	DECLARE @msgErro varchar(500)
	Declare @valActual decimal(9,2)
	Declare @userID int
	Declare @prodDate datetime
	Set nocount on
	select @prodDate = ProdutoDataLimiteLeilao from SchemaProduto.Produto where @prodid=ProdutoId
	if datediff(s,getdate(),@prodDate)<0
	begin
		set @msgErro = 'Já passou o tempo para licitar.' + CONVERT(VARCHAR, @prodDate)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	Select @userID=UtilizadorId from SchemaUtilizador.Utilizador where @email=UtilizadorEmail
	
	if SchemaUtilizador.funcPassConfirm(@userID,@pass)=0
	begin
		set @msgErro = 'O utilizador ou a password está errada certifica se o email está correcto: ' + CONVERT(VARCHAR, @email)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	--Procurar o valor da licitação actual de um produto.
	if not exists (select MAX( LicitacaoValorActual) from Licitacao where @prodid=LicitacaoProdutoID)
	begin
		select @valActual= ProdutoValorMinVenda from SchemaProduto.Produto where @prodid=ProdutoId
	end
	else 
	begin
		select @valActual = MAX(LicitacaoValorActual) from Licitacao where @prodid=LicitacaoProdutoID
	end

	if @licitaval< @valActual
	begin
		set @msgErro = 'A licitação é menor do que o valor actual:' + CONVERT(VARCHAR, @licitaval) +'<'+ CONVERT(VARCHAR, @valActual)
		RAISERROR(@msgErro,16,1) 
		RETURN 
	end

	Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax,LicitacaoValorActual,LicitacaoData)
				values(@userid, @prodid,@licitaval, @valActual,Getdate())
END
Go
--Teste do procedimento procLicitarProd--
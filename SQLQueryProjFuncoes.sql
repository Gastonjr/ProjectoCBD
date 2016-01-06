Use CBDLeiloes
Go

--Funções que devem funcionar.--
--Converte a password para uma hash--
IF OBJECT_ID ('SchemaUtilizador.funcPassToHash', 'FS') IS NOT NULL
	DROP function SchemaUtilizador.funcPassToHash;
GO
CREATE FUNCTION SchemaUtilizador.funcPassToHash (@pass NVARCHAR)
RETURNS NVARCHAR(32)
AS
BEGIN
	DECLARE @hash Nvarchar(32)
	set @hash= CONVERT(NVARCHAR(32), HASHBYTES('SHA1', @pass), 2)
	return @hash
END;
GO

/*--Teste da conversão da pass
--select SchemaUtilizador.funcPassToHash('OAS53QMI5JS')/*exemplo que o mais precisa-se no projeto*/
select SchemaUtilizador.funcPassToHash('password1')/*exemplo que o mais precisa-se no projeto*/
*/
IF OBJECT_ID ('SchemaUtilizador.funcIdadeTens', 'FS') IS NOT NULL
	DROP function SchemaUtilizador.funcIdadeTens;
GO
--Calcular a idade a partir da data --/* sofreu a alteração na aula de Lab*/
CREATE FUNCTION SchemaUtilizador.funcIdadeTens(@userId int)
RETURNS int
AS
BEGIN
	DECLARE @idade int
	DECLARE @dataNasc date

	--reaver data nascimento do utilizador especificado--
	select @dataNasc = UtilizadorDataNascimento from SchemaUtilizador.Utilizador where UtilizadorId = @userId

	--mediante data obtida, calcular idade em relação à data atual--
	select @idade = datediff(YYYY,@dataNasc, GETDATE()) 
	
	if(@idade is NULL)
		return 0

	return @idade
END
GO

--Teste da idade--
--select u.UtilizadorNome, u.UtilizadorDataNascimento, SchemaUtilizador.funcIdadeTens(u.UtilizadorId) as Idade  from SchemaUtilizador.Utilizador u 
--GO


--Compara a password do utilizador (usar em logins)--
IF OBJECT_ID ('SchemaUtilizador.funcPassConfirm', 'FS') IS NOT NULL
	DROP function SchemaUtilizador.funcPassConfirm;
GO
CREATE FUNCTION SchemaUtilizador.funcPassConfirm(@user int, @pass NVARCHAR)
RETURNS int
AS
BEGIN
	DECLARE @returnVal int
	if exists(select UtilizadorId, UtilizadorSenha from SchemaUtilizador.Utilizador 
	where UtilizadorId=@user and UtilizadorSenha= SchemaUtilizador.funcPassToHash(@pass)) /*compara a pass guardada do utilizador e a que foi inserida */
		set @returnVal=1
	else
		set @returnVal=0
	return @returnVal
END;
Go

--Compara 2 valores e vê o maior 0=erro, 1=Licitacao Velha e 2=Licitacao Nova
IF OBJECT_ID ('SchemaLicitacao.funcCompLicita', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.funcCompLicita;
GO
Create FUNCTION SchemaLicitacao.funcCompLicita(@licitacaoNovaVal decimal,@licitacaoVelhaID int, @prodID int)
returns int
as
BEGIN
	DECLARE @prodVal decimal(9,2)
	DECLARE @licitacaoVelhaVal decimal(9,2)
	DECLARE @licitacaoVelhaValMax decimal(9,2)
	select @prodVal=ProdutoValorMinVenda from SchemaProduto.Produto where ProdutoId=@prodID
	if(@prodVal> @licitacaoNovaVal)
	begin
		return 0
	end
	select @licitacaoVelhaVal= LicitacaoValorActual, @licitacaoVelhaValMax=Max(LicitacaoValorMax) from Licitacao where LicitacaoProdutoID=@prodID
	if(@licitacaoVelhaValMax<@licitacaoNovaVal)
	begin
		return 2
	end
	else
	begin
		return 1
	end
END
Go

--Calcular a licitacao a partir de 2 valores 
IF OBJECT_ID ('SchemaLicitacao.funcCompLicita', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.funcCompLicita;
GO
Create FUNCTION SchemaLicitacao.funcCompLicita(@licitacaoNovaVal decimal,@licitacaoVelha decimal)
returns decimal
as
Begin
	Declare @return decimal
	if(@licitacaoNovaVal<@licitacaoVelha)
	begin
		set @return = (@licitacaoNovaVal+0.01)
	end
	else
	begin
		if (@licitacaoNovaVal=@licitacaoVelha)
		begin
			set @return= @licitacaoVelha
		end
		else
		begin
			set @return=(@licitacaoVelha+0.01)
		end
	end
	return @return 
end
go

--Funcoes de apoio ao procLicitarProd--
IF OBJECT_ID ('SchemaLicitacao.CheckProduto', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.CheckProduto;
GO
Create FUNCTION SchemaLicitacao.CheckProduto(@prodID int)
returns int
as
Begin
	Declare @msgErro varchar(500)
	if not exists (Select 1 from SchemaProduto.Produto where ProdutoId=@prodID)
	begin 
		set @msgErro = 'O produto não se encontra nos registos.'
		RAISERROR(@msgErro,16,1)
		RETURN 0
	end
	Return 1
End
Go

IF OBJECT_ID ('SchemaLicitacao.CheckDataLeilao', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.CheckDataLeilao;
GO
Create FUNCTION SchemaLicitacao.CheckDataLeilao(@prodDate datetime)
returns int
as
Begin
	Declare @msgErro varchar(500)
	if datediff(s,getdate(),@prodDate)<0
	begin
		set @msgErro = 'Já passou o tempo para licitar. ' + CONVERT(VARCHAR, @prodDate)
		RAISERROR(@msgErro,16,1)
		RETURN 0
	end
	return 1
end
GO

IF OBJECT_ID ('SchemaLicitacao.CheckValorProduto', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.CheckValorProduto;
GO
Create FUNCTION SchemaLicitacao.CheckValorProduto(@ProdVal decimal(9,2),@licitaValMax decimal(9,2))
returns int
as
Begin
	Declare @msgErro varchar(500)
	if (@ProdVal>@licitaValMax)
	begin
		set @msgErro = 'O valor da licitação é menor que o valor mínimo.'
		RAISERROR(@msgErro,16,1)
		RETURN 0
	end
	RETURN 1
END
GO

IF OBJECT_ID ('SchemaLicitacao.CheckUtilizador', 'FS') IS NOT NULL
	DROP function SchemaLicitacao.CheckUtilizador;
GO
Create FUNCTION SchemaLicitacao.CheckUtilizador(@NuserID int)
returns int
as
Begin
	Declare @msgErro varchar(500)
	if not exists (Select 1 from SchemaUtilizador.Utilizador where UtilizadorId=@NuserID)
	begin
		set @msgErro = 'O utilizador não se encontra nos registos.'
		RAISERROR(@msgErro,16,1)
		RETURN 0
	end
	RETURN 1
END
GO
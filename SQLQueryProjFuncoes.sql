Use CBDLeiloes
Go

--Funções que devem funcionar.--
--Converte a password para uma hash--
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
CREATE FUNCTION SchemaUtilizador.funcPassConfirm (@user int, @pass NVARCHAR)
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

--Compara 2 valores e devolve a diferença
Create FUNCTION SchemaLicitacao.funcCompValor(@valor1 decimal,@valor2 decimal)
returns decimal
as
BEGIN
	DECLARE @returnVal decimal(9,2)
	set @returnVal =(@valor1-@valor2)
	return @returnVal
END
Go
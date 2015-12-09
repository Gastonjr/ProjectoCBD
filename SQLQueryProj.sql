--Coisa que acontece no momento que deviam acontecer coisas--
--temos de criar um schema a cada tabela 
USE master
GO

IF (db_id('CBDLeiloes') is not null)
	Drop database CBDLeiloes;
Go

CREATE DATABASE CBDLeiloes;
Go

If DB_ID('CBDLeiloes') is null
	Raiserror('BD não criada',16,1)
Go

Use CBDLeiloes
Go

Create Schema SchemaProduto;
Go
Create Schema SchemaUtilizador;
Go
Create Schema SchemaLicitacao;
Go


--Criação de coisas onde se metem outras coisas--
Create table schemaUtilizador.Utilizador (
	UtilizadorId int identity(1,1) not null,
	UtilizadorNome varchar(50),
	UtilizadorSenha varchar(50),	
	UtilizadorEmail varchar(255)
	constraint mail_constraint
		check (UtilizadorEmail like '%@%.%') ,
	UtilizadorDataRegisto date,
	UtilizadorDataNascimento date,
	UtilizadorTelefone varchar(9)
	constraint uk_Telefone
		unique (UtilizadorTelefone )
	constraint CK_Telelfone
		check (UtilizadorTelefone like'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

Create table SchemaUtilizador.Seguidor (
	SeguidorTableId  int identity(1,1) not null,
	SeguidorSeguidorID int not null,
	SeguidorSeguidoID int not null
);
--por norma o id tem de ser em primeiro lugar

Create table SchemaProduto.Produto (
	ProdutoId int identity(1,1) not null, 
	ProdutoNome varchar(50),
	ProdutoDescricao varchar(255),
	ProdutoValorMinVenda decimal(7, 2),
	ProdutoDataLimiteLeilao date,
	ProdutoUtilizadorID int not null
);

Create table SchemaLicitacao.Licitacao (
	LicitacaoId int identity(1,1) not null,
	LicitacaoData date,
	LicitacaoValorMax decimal(9,2),
	LicitacaoValorActual decimal(9,2),
	LicitacaoProdutoID int not null,
	LicitacaoUtilizadorID int not null
);

Create table SchemaUtilizador.SeguirProduto (
	SeguirProdutoTableId int identity(1,1) not null,
	SeguirProdutoProdutoId int not null,
	SeguirProdutoUtilizadorID int not null
);
Go

--Adicionadas restrições às coisas para não se armarem em espertas ou restrições de chaves primarias--

Alter table SchemaUtilizador.Utilizador add constraint pk_Utilizador primary key (UtilizadorId);

Alter table SchemaUtilizador.Seguidor add constraint pk_Seguidor primary key (SeguidorTableId);

Alter table SchemaProduto.Produto add constraint pk_Produto primary key (ProdutoId);

Alter table SchemaUtilizador.SeguirProduto add constraint pk_SeguirProduto primary key (SeguirProdutoTableId);

Alter table SchemaLicitacao.Licitacao add constraint pk_Licitacao primary key (LicitacaoId);

Go

--Adicionadas mais restrições porque restrições nunca são de mais ou as restrições de chaves estrangeiras--

Alter table SchemaProduto.Produto add constraint Produto_fk_Utilizador
            foreign key (ProdutoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId) on delete cascade;

Alter table SchemaUtilizador.Seguidor add constraint Seguidor_fk_Utilizador
            foreign key (SeguidorSeguidorID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaUtilizador.Seguidor add constraint Seguido_fk_Utilizador
            foreign key (SeguidorSeguidoID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaUtilizador.SeguirProduto add constraint SeguirProduto_fk_Produto
            foreign key (SeguirProdutoProdutoID) references SchemaProduto.Produto(ProdutoId);

Alter table SchemaUtilizador.SeguirProduto add constraint SeguirProduto_fk_Utilizador
            foreign key (SeguirProdutoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId);

Alter table SchemaLicitacao.Licitacao add constraint Licitacao_fk_Produto
            foreign key (LicitacaoProdutoID) references SchemaProduto.Produto(ProdutoId) ;

Alter table SchemaLicitacao.Licitacao add constraint Licitacao_fk_Utilizador
            foreign key (LicitacaoUtilizadorID) references SchemaUtilizador.Utilizador(UtilizadorId) on delete cascade;



Go

--Funções que devem funcionar.--
--Converte a password para uma hash--/* sofreu a alteração na aula de Lab*/
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
select SchemaUtilizador.funcPassToHash('password1')/*exemplo que o mais precisa-se no projeto*/
*/
--Calcular a idade a partir da data --/* sofreu a alteração na aula de Lab*/
CREATE FUNCTION SchemaUtilizador.funcIdadeTens(@userId int)
RETURNS int
AS
BEGIN
	DECLARE @idade int
	DECLARE @dataNasc date

	--reaver data nascimento do utilizador especificado
	select @dataNasc = UtilizadorDataNascimento from SchemaUtilizador.Utilizador where UtilizadorId = @userId

	--mediante data obtida, calcular idade em relação à data atual
	select @idade = datediff(YYYY,@dataNasc, GETDATE()) 
	
	if(@idade is NULL)
		return 0

	return @idade
END
GO

/*--Teste da idade--
select u.UtilizadorNome, u.UtilizadorDataNascimento, SchemaUtilizador.funcIdadeTens(u.UtilizadorId) as Idade  from SchemaUtilizador.Utilizador u 
*/
GO
--Compara a pass do utilizador (usar em logins)--
CREATE FUNCTION SchemaUtilizador.funcPassConfirm (@user int, @pass NVARCHAR)
RETURNS int
AS
BEGIN
	DECLARE @returnVal Nvarchar(500)
	if exists(select UtilizadorId, UtilizadorSenha from SchemaUtilizador.Utilizador 
	where UtilizadorId=@user and UtilizadorSenha= SchemaUtilizador.funcPassToHash(@pass))
  set @returnVal=1
  else
  set @returnVal=0
	return @returnVal
END;
Go
--Procedimentos que Procedem--

--Procedimento para registar o utilizador(Precisa ainda de uns retoques)--
create proc SchemaUtilizador.procRegUser
		(@username varchar(40), @password varchar(32), @email varchar(255),
		@userDoB varchar(50),@userPhone varchar(9))
as
BEGIN
	declare @Hash varchar(32)
	DECLARE @msgErro varchar(500)

	if @email not like '%@%.%'
	begin
		set @msgErro = 'O Email é inválido: ' + CONVERT(VARCHAR, @email)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end

	if exists (select 1 from Utilizador where UtilizadorEmail=@email)
	begin
		set @msgErro = 'O utilizador já existe: ' + CONVERT(VARCHAR, @email)
		RAISERROR(@msgErro,16,1) 
		RETURN
	end
	
	set @Hash= SchemaUtilizador.funcPassToHash(@password)

	insert into SchemaUtilizador.Utilizador(UtilizadorEmail,UtilizadorNome,[UtilizadorSenha],UtilizadorDataRegisto,UtilizadorDataNascimento,UtilizadorTelefone)
							  values (@email,@username,@Hash,GETDATE(),@userDoB,@userPhone)

	if @@ERROR <>0
	begin
		set @msgErro = 'Falha no insert com erro: ' + CONVERT(VARCHAR, ERROR_MESSAGE())
		RAISERROR (@msgErro, 16,1)
	end
END
GO
--Teste do procedimento procRegUser--
execute SchemaUtilizador.procRegUser N'Rui',N'Pass',N'mail@io.at',N'1991-10-12',N'919942285';

Go

--Procedimento para colocar um produto à venda--

Create proc SchemaProduto.procVenderProd
			(@ProdDesc varchar(100), @ProdNome varchar(50), @ProdDataLimite varchar(50), @ProdValorMin int)
as
BEGIN
	Insert into SchemaProduto.Produto (ProdutoNome,ProdutoDescricao,  ProdutoDataLimiteLeilao, ProdutoValorMinVenda )
		values (@ProdNome, @ProdDesc, @ProdDataLimite, @ProdValorMin)
END
Go

--Procedimento para licitar num produto--
Create proc SchemaProduto.procLicitarProd
			(@userid int, @prodid int, @licitaval int)
as
SET NOCOUNT ON
BEGIN
	Insert into SchemaLicitacao.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax)
				values(@userid, @prodid,@licitaval)
END
Go




--Select * from SchemaUtilizador.Utilizador
--Go

--Inserção de coisas para razões tal.--
Insert into SchemaUtilizador.Utilizador(UtilizadorNome, UtilizadorSenha, UtilizadorEmail, UtilizadorDataNascimento, UtilizadorDataRegisto, UtilizadorTelefone) 
								values('Bruno Almeida','am1234br','almeida.bruno@live.com','1988-11-11','1995-04-25','965287167');										
								Go



--Coisa que acontece no momento que deviam acontecer coisas--
USE master
GO

IF (db_id('CBDLeiloes') is not null)
	Drop database CBDLeiloes;
Go

CREATE DATABASE CBDLeiloes;
Go

If DB_ID('CBDLeiloes') is null
	Raiserror('BD não criada',16,1)
	return
Go

Use CBDLeiloes
Go

Create Schema Schema1;
Go


--Criação de coisas onde se metem outras coisas--
Create table Schema1.Utilizador (
	UtilizadorNome varchar(50),
	UtilizadorSenha varchar(50) not null,
	UtilizadorId int identity(1,1) not null,
	UtilizadorEmail varchar(255) not null
	constraint mail_constraint
		check (UtilizadorEmail like '%@%.%') ,
	UtilizadorDataRegisto date,
	UtilizadorDataNascimento date,
	UtilizadorTelefone varchar(15)
	constraint uk_Telefone
		unique (UtilizadorTelefone )
	constraint CK_Telelfone
		check (UtilizadorTelefone like'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

Create table Schema1.Seguidor (
	SeguidorTableId  int identity(1,1) not null,
	SeguidorSeguidorID int not null,
	SeguidorSeguidoID int not null
);

Create table Schema1.Produto (
	ProdutoId int identity(1,1) not null,
	ProdutoNome varchar(50),
	ProdutoDescricao varchar(255),
	ProdutoValorMinVenda decimal(7, 2),
	ProdutoDataLimiteLeilao date,
	ProdutoUtilizadorID int not null
);

Create table Schema1.Licitacao (
	LicitacaoId int identity(1,1) not null,
	LicitacaoData date,
	LicitacaoProdutoID int not null,
	LicitacaoValorMax decimal(9,2),
	LicitacaoValorActual decimal(9,2),
	LicitacaoUtilizadorID int not null
);

Create table Schema1.Seguirproduto (
	SeguirprodutoTableId int identity(1,1) not null,
	SeguirprodutoProdutoId int not null,
	SeguirprodutoUtilizadorID int not null
);
Go

--Adicionadas restrições às coisas para não se armarem em espertas.--
Alter table Schema1.Utilizador add constraint pk_Utilizador primary key (UtilizadorId);

Alter table Schema1.Seguidor add constraint pk_Seguidor primary key (SeguidorTableId);

Alter table Schema1.Produto add constraint pk_Produto primary key (ProdutoId);

Alter table Schema1.Seguirproduto add constraint pk_Seguirproduto primary key (SeguirprodutoTableId);

Alter table Schema1.Licitacao add constraint pk_Licitacao primary key (LicitacaoId);

Go

--Adicionadas mais restrições porque restrições nunca são de mais.--
Alter table Schema1.Produto add constraint Produto_fk_Utilizador
            foreign key (ProdutoUtilizadorID) references Schema1.Utilizador(UtilizadorId) on delete cascade;

Alter table Schema1.Seguidor add constraint Seguidor_fk_Utilizador
            foreign key (SeguidorSeguidorID) references Schema1.Utilizador(UtilizadorId);

Alter table Schema1.Seguidor add constraint Seguido_fk_Utilizador
            foreign key (SeguidorSeguidoID) references Schema1.Utilizador(UtilizadorId);

Alter table Schema1.Seguirproduto add constraint Seguirproduto_fk_Produto
            foreign key (SeguirprodutoProdutoID) references Schema1.Produto(ProdutoId);

Alter table Schema1.Seguirproduto add constraint Seguirproduto_fk_Utilizador
            foreign key (SeguirprodutoUtilizadorID) references Schema1.Utilizador(UtilizadorId);

Alter table Schema1.Licitacao add constraint Licitacao_fk_Utilizador
            foreign key (LicitacaoUtilizadorID) references Schema1.Utilizador(UtilizadorId) on delete cascade;

Go

--Funções que devem funcionar.--
--Converte a password para uma hash--
CREATE FUNCTION Schema1.passToHash (@pass NVARCHAR)
RETURNS NVARCHAR
AS
BEGIN
	DECLARE @hash Nvarchar(500)
	SET NOCOUNT ON
	set @hash=HASHBYTES('SHA1', @pass);
	return @hash
END;
GO

--Calcular a idade a partir da data--
CREATE FUNCTION Schema1.idadeTens(@userId int)
RETURNS int
AS
BEGIN
	DECLARE @idade int
	SET NOCOUNT ON  
	select @idade = datediff(YYYY,UtilizadorDataNascimento, GETDATE()) 
	from Utilizador
	where @userId = UtilizadorId
	if(@idade is NULL)
		raiserror(50001,0,5,'Se estás a ver esta mensagem o utilizador provavelmente nao existe. OU FIZESTE MERDA!!!');

	return @idade
END;
GO


--Compara a pass do utilizador (usar em logins)--
CREATE FUNCTION Schema1.passConfirm (@user int, @pass NVARCHAR)
RETURNS int
AS
BEGIN
	DECLARE @returnVal int
	SET NOCOUNT ON  
	if exists(select  UtilizadorSenha from CBDLeiloes.Schema1.Utilizador 
	where UtilizadorId=@user and UtilizadorSenha=Schema1.passToHash(@pass))
  set @returnVal=1
  else
  set @returnVal=0
	return @returnVal
END;
GO

--Procedimentos que procedem.--

--Procedimento para registar o utilizador(Precisa ainda de uns retoques)--
create proc Schema1.procRegUser
		(@username varchar(40), @password varchar(50), @email varchar(50),
		@userDoB varchar(50),@userPhone varchar(50))
as
SET NOCOUNT ON
Insert into CBDLeiloes.Schema1.Utilizador (UtilizadorNome, UtilizadorSenha, UtilizadorEmail, UtilizadorDataNascimento, UtilizadorDataRegisto, UtilizadorTelefone)
		values (@username,Schema1.passToHash(@password),@email,@userDoB,GETDATE(),@userPhone)
Go
--Procedimento para colocar um produto à venda--
create proc Schema1.procVenderProd
			(@ProdDesc varchar(100), @ProdNome varchar(50), @ProdDataLimite varchar(50), @ProdValorMin int)
as
SET NOCOUNT ON
Insert into CBDLeiloes.Schema1.Produto (ProdutoDescricao, ProdutoNome, ProdutoDataLimiteLeilao, ProdutoValorMinVenda )
		values (@ProdDesc,@ProdNome, @ProdDataLimite, @ProdValorMin)
Go
--Procedimento para licitar num produto--
Create proc Schema1.procLicitarProd
			(@userid int, @prodid int, @licitaval int)
as
SET NOCOUNT ON
Insert into CBDLeiloes.Schema1.Licitacao(LicitacaoUtilizadorID,LicitacaoProdutoID,LicitacaoValorMax)
			values(@userid, @prodid,@licitaval)
Go

--Inserção de coisas para razões tal.--
Insert into CBDLeiloes.Schema1.Utilizador(UtilizadorNome, UtilizadorSenha, UtilizadorEmail, UtilizadorDataNascimento, UtilizadorDataRegisto, UtilizadorTelefone) 
								values('Rui','Pass','mail@io.at','1991-10-12','1991-10-12','919942285');

Go
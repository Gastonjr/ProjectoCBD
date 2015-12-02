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
Go

Use CBDLeiloes
Go

Create Schema Schema1;
Go


--Criação de coisas onde se metem outras coisas--
Create table Schema1.Utilizador (
	UtilizadorNome varchar(50),
	UtilizadorSenha varchar(50),
	UtilizadorId int identity(1,1) not null,
	UtilizadorEmail varchar(255)
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
--Inserção de coisas para razões tal.--
Insert into CBDLeiloes.Schema1.Utilizador(UtilizadorNome, UtilizadorSenha, UtilizadorEmail, UtilizadorDataNascimento, UtilizadorDataRegisto, UtilizadorTelefone) 
								values('Rui','Pass','mail@io.at','1991-10-12','1991-10-12','919942285');

Go
--Funções que devem funcionar.--
IF OBJECT_ID (N'CBDLeiloes.passToHash', N'TF') IS NOT NULL
    DROP FUNCTION CBDLeiloes.passToHash;
GO
CREATE FUNCTION Schema1.passToHash (@pass NVARCHAR)
RETURNS NVARCHAR
AS
BEGIN
	DECLARE @hash Nvarchar(500)
	set @hash=HASHBYTES('SHA1', @pass);
	return @hash
END;
GO


--Procedimentos que procedem.--

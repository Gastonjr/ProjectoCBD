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
Create table SchemaUtilizador.Utilizador (
	UtilizadorId int identity(1,1) not null,
	UtilizadorNome varchar(50),
	UtilizadorSenha varchar(32),	
	UtilizadorEmail varchar(255)
	constraint CK_Email
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
	ProdutoValorActual decimal(9,2),
	ProdutoValorMinVenda decimal(9,2),
	ProdutoDataLimiteLeilao dateTime,
	ProdutoUtilizadorID int not null
);

Create table SchemaLicitacao.Licitacao (
	LicitacaoId int identity(1,1) not null,
	LicitacaoData dateTime,
	LicitacaoValorActual decimal(9,2),
	LicitacaoValorMax decimal(9,2),
	LicitacaoProdutoID int not null,
	LicitacaoUtilizadorID int not null
);

Create table SchemaUtilizador.SeguirProduto (
	SeguirProdutoTableId int identity(1,1) not null,
	SeguirProdutoProdutoId int not null,
	SeguirProdutoUtilizadorID int not null
);

Create table SchemaUtilizador.Compra(
	CompraId int identity(1,1) not null,
	CompraClassificacao decimal(9,2),
	CompraLicitacaoID int not null,
	CompraProdutoID int not null
);

Go 


--Adicionadas restrições às coisas para não se armarem em espertas ou restrições de chaves primarias--

Alter table SchemaUtilizador.Utilizador add constraint pk_Utilizador primary key (UtilizadorId);

Alter table SchemaUtilizador.Seguidor add constraint pk_Seguidor primary key (SeguidorTableId);

Alter table SchemaProduto.Produto add constraint pk_Produto primary key (ProdutoId);

Alter table SchemaUtilizador.SeguirProduto add constraint pk_SeguirProduto primary key (SeguirProdutoTableId);

Alter table SchemaLicitacao.Licitacao add constraint pk_Licitacao primary key (LicitacaoId);

Alter table SchemaUtilizador.Compra add constraint pk_Compra primary key (CompraId);
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

Alter table SchemaUtilizador.Compra add constraint Compra_fk_Produto
            foreign key (CompraProdutoID ) references SchemaProduto.Produto(ProdutoId) ;

Alter table SchemaUtilizador.Compra  add constraint Compra_fk_Licitacao
            foreign key (CompraLicitacaoID) references SchemaLicitacao.Licitacao(LicitacaoId) on delete cascade;
Go







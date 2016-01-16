USE [CBDLeiloes]
GO
CREATE ROLE [Administrador]
GO
CREATE ROLE [Gestor Financeiro]
GO
CREATE ROLE [Utilizador]
GO

GRANT Select on SCHEMA::SchemaUtilizador to [Administrador]
GO
GRANT Select on SCHEMA::SchemaLicitacao to [Administrador]
GO
GRANT Select on SCHEMA::SchemaProduto to [Administrador]
GO
Grant Select on SchemaUtilizador.vUtililizadorLicitacaoCompra to [Gestor Financeiro]
GO

Grant Select on SchemaProduto.vUtilizadorProvendoAvenda to [Utilizador]
GO
Grant execute on SchemaLicitacao.procLicitarProd to [Utilizador]
GO
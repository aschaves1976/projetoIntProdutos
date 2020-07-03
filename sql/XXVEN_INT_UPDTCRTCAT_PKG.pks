CREATE OR REPLACE PACKAGE XXVEN_INT_UPDTCRTCAT_PKG AUTHID CURRENT_USER AS
  -- +=================================================================+
  -- |                 VENANCIO, RIO DE JANEIRO, BRASIL                |
  -- |                       ALL RIGHTS RESERVED.                      |
  -- +=================================================================+
  -- | FILENAME                                                        |
  -- |  XXVEN_INT_UPDTCRTCAT_PKG.pks                                   |
  -- | PURPOSE                                                         |
  -- |  Projeto de Integração (CMV)                                    |
  -- |                                                                 |
  -- | DESCRIPTION                                                     |
  -- |  Criar / Atualizar Categoria de Item na organizacao master      |
  -- |                                                                 |
  -- | PARAMETERS                                                      |
  -- |                                                                 |
  -- | CREATED BY   Alessandro Chaves   - (2020/07/03)                 |
  -- | UPDATED BY                                                      |
  -- |             <Developer's name> - <Date>                         |
  -- |              <Description>                                      |
  -- |                                                                 |
  -- +=================================================================+
  --  

  PROCEDURE set_log_p (p_msg IN VARCHAR2)
  ;

  PROCEDURE crtupd_item_categories_p
    (
        errbuf         OUT VARCHAR2
      , retcode        OUT NUMBER
      , p_item_id      IN NUMBER  DEFAULT NULL
    )
  ;
END XXVEN_INT_UPDTCRTCAT_PKG;
/
CREATE OR REPLACE PACKAGE XXVEN_INV_CST_UPDT_PKG AUTHID CURRENT_USER AS
  -- $Header: XXVEN_INV_CST_UPDT_PKG.pkb 120.1 2020/07/30 12:00:00 appldev $
  -- +=================================================================+
  -- |        Copyright (c) 2007 VENANCIO Rio de Janeiro, Brasil       |
  -- |                       All rights reserved.                      |
  -- +=================================================================+
  -- | FILENAME                                                        |
  -- |   XXVEN_INV_CST_UPDT_PKG.pkb                                    |
  -- |                                                                 |
  -- | PURPOSE                                                         |
  -- |   Atender as customizacoes do Inv referente a atualização do    |
  -- |   saldo de itens nos inventários                                |
  -- |                                                                 |
  -- | [DESCRIPTION]                                                   |
  -- |   DBLinks: Todos apontam para os dados contidos na producao do  |
  -- |    Procfit.                                                     |
  -- |      Homologacao: prochml                                       |
  -- |      Producao: PROCFIT                                          |
  -- |                                                                 |
  -- | [PARAMETERS]                                                    |
  -- |   [Parametro1: descricao do parametro]                          |
  -- |   [Parametro2: descricao do parametro]                          |
  -- |                                                                 |
  -- | CREATED BY                                                      |
  -- |   Alessandro Chaves      2020/07/30            v120.1           |
  -- |                                                                 |
  -- | ALTERED BY                                                      |
  -- |   ...                                                           |
  -- |   [nome]             [data alteracao]        [nova versao]      |
  -- |                                                                 |
  -- +=================================================================+
  --
  PROCEDURE main_p 
    (  errbuf   OUT VARCHAR2
     , retcode  OUT NUMBER
    )
  ;
  --
  -- Update Barramento
  PROCEDURE set_log_p
    (
       p_produto       IN NUMBER
     , p_empresa       IN NUMBER
     , p_envio_status  IN NUMBER
     , p_envio_erro    IN VARCHAR2
    )
  ;
  --
  -- Retorna quantidade em Estoque em Determinada Data
  FUNCTION get_stock_quantity_f
    (
       p_operating_unit    IN NUMBER
     , p_organization_id   IN NUMBER
     , p_inventory_item_id IN NUMBER
     , p_subinventory      IN VARCHAR2 DEFAULT NULL
     , p_dt_retroactive    IN DATE
     , p_error             OUT VARCHAR2
    )
  RETURN NUMBER
  ;
  -- Update Inventory Balance
  PROCEDURE update_balance_p
    (  errbuf   OUT VARCHAR2
     , retcode  OUT NUMBER
    )
  ;
  --
END XXVEN_INV_CST_UPDT_PKG;
/
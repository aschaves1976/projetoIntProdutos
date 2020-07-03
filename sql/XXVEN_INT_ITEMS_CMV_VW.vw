--------------------------------------------------------
--  Arquivo criado - Sexta-feira-Julho-03-2020   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for View XXVEN_INT_ITEMS_CMV_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."XXVEN_INT_ITEMS_CMV_VW" ("ID_SEQUENCIAL", "PRODUTO", "DESCRICAO") AS 
  SELECT DISTINCT
         id_sequencial
       , produto
       , descricao
  FROM xxven_carga_fullitems_tb
WHERE 1=1
;

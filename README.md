## Aplicar Recebimento aos Títulos de Cartões

Este desenvolvimento visa atender demandas pontuais do projeto CMV
Atualizar ou Criar novas categorias para Produtos.

## Table

 - XXVEN_CARGA_FULLITEMS_TB

## View

 - XXVEN_INT_ITEMS_CMV_VW
 
## Value Set

 - XXVEN_ITENS_CMV

## Concurrent

| Program Name | Short Name | Description | Executable | Short Name | Description | Execution File Name |
| -- | -- | -- | -- | -- | -- | -- |
|  XXVEN - INV Carga de Categorias de Produtos (CMV) | XXVEN_INT_UPDTCRTCAT | Carga de Categorias de Produtos |  XXVEN_INT_UPDTCRTCAT | XXVEN_INT_UPDTCRTCAT | Carga de Categorias de Produtos | XXVEN_AR_RCPTS_CREDITCARD_PKG.MAIN_P |

## Responsibility

| Concurrent |Responsibility|  Request Group| Application |
|--|--|--|--|
| XXVEN - INV Carga de Categorias de Produtos (CMV) | DV INV Super Usuario | All inclusive | Inventory |

## File

 - XXVEN_AR_RCPTS_CREDITCARD_PKG.pks
 - XXVEN_AR_RCPTS_CREDITCARD_PKG.pkb
 - XXVEN_CARGA_FULLITEMS_TB.tab
 - XXVEN_INT_ITEMS_CMV_VW.vw










VIEW

/******************************************************************************
 *
 * 
 * NAME
 *   testepkg.js
 *
 * DESCRIPTION
 *   Selecionar Itens para serem integrados nos Legados (Analisa, Procfit e Compliance).
 *
 *****************************************************************************/

'use strict'

// const oracledb = require('oracledb')
const moment   = require('moment')
const database = require('../services/database.js')
// const dbConfig = require('../config/database.js')


async function run() {
  let connection

  try {

    const date = moment().subtract(20, 'minutes').format('YYYY-MM-DD HH:mm:ss')
    let binds = {}

    // Create a PL/SQL package that uses a RECORD
    const stmts = [
    `
    create or replace PACKAGE xxven_int_itens_pkg AUTHID CURRENT_USER AS
    TYPE lt_prod_cab_tp IS RECORD
      (
          id_sequencial              NUMBER
        , produto                    VARCHAR2(240)
        , descricao                  VARCHAR2(240)  
        , unidade_medida             VARCHAR2(3)    
        , secao_produto              VARCHAR2(40)   
        , grupo_produto              VARCHAR2(40)   
        , subgrupo_produto           VARCHAR2(40)   
        , categoria_produto          VARCHAR2(40)   
        , sub_categoria              VARCHAR2(40)   
        , apresentacao               VARCHAR2(40)   
        , tipo_secao                 VARCHAR2(40)   
        , marca                      VARCHAR2(40)   
        , codigo_cest                VARCHAR2(150)  
        , data_inclusao              DATE           
        , data_fora_linha            DATE           
        , fabricante_cnpj            VARCHAR2(4000)   
        , status_compra              VARCHAR2(40)   
        , status_venda               VARCHAR2(40)   
        , ncm                        VARCHAR2(40)   
        , embalagem_industria        VARCHAR2(40)   
        , sazonalidade               VARCHAR2(40)   
        , data_hora_inclusao         DATE           
        , data_hora_ultima_alteracao DATE           
        , envio_status               NUMBER
        , envio_data_hora            TIMESTAMP(6)   
        , envio_erro                 VARCHAR2(4000) 
        , qtd_apresentacao           VARCHAR2(240)
        , status_item                VARCHAR2(30)   
        , tipo_medicamento           VARCHAR2(240)
        , comercializavel            CHAR(1)        
        , marca_gc                   VARCHAR2(40)   
        , pbm                        VARCHAR2(20)   
        , peso                       NUMBER
        , familia                    VARCHAR2(60)   
        , comprador                  VARCHAR2(60)   
        , tipo_reposicao             VARCHAR2(100)  
        , dimensao_uni_medida        VARCHAR2(60)   
        , dimensao_com               NUMBER
        , dimensao_lag               NUMBER
        , dimensao_alt               NUMBER
        , informacao_dun             VARCHAR2(240)
        , pacote_produto             VARCHAR2(240)
        , origem                     VARCHAR2(2)
        , unidade_medida_fracionado  VARCHAR2(40)
        , id_campanha                NUMBER
        , ean                        VARCHAR2(20)   
        , ean_quantidade_embalagem   VARCHAR2(240)
        , retencao_receita           VARCHAR2(25)   
        , venda_controlada           VARCHAR2(25)   
        , livro_portaria_344         VARCHAR2(25)   
        , registro_ms                VARCHAR2(240)  
        , tipo_receita               VARCHAR2(240)  
        , farmacia_popular           VARCHAR2(240)  
        , controle_rastreabilidade   VARCHAR2(240)  
        , principio_ativo            VARCHAR2(240)  
        , dosagem                    VARCHAR2(240)  
        , nome_comercial             VARCHAR2(80)   
        , requer_crm                 VARCHAR2(240)  
        , classe_terapeutica         VARCHAR2(240)  
        , termolabil                 VARCHAR2(40)   
        , produto_uso_continuo       VARCHAR2(25)   
        , lista_pnu                  VARCHAR2(240)  
        , uso_consumo                VARCHAR2(30)
        , ncm_icms                   VARCHAR2(240)
        , ncm_ipi                    VARCHAR2(240)
        , fabricacao_propria         VARCHAR2(240)
        , embalagem_padrao           VARCHAR2(240)
        , caixaria                   VARCHAR2(240)
        , minmultcompra              VARCHAR2(240)
        , icms_desonerado            VARCHAR2(240)
        , motivo_isencao_ms          VARCHAR2(240)
        , situacao_estadual          VARCHAR2(240)
        , indice_ibpt                VARCHAR2(240)    
      )
    ;  
    
    TYPE prod_cab        IS TABLE OF lt_prod_cab_tp;
    
    FUNCTION GET_ITENS_F( p_date IN VARCHAR2 ) RETURN prod_cab PIPELINED;
    
    END XXVEN_INT_ITENS_PKG;
    `,
    `
    create or replace PACKAGE BODY XXVEN_INT_ITENS_PKG AS
           
      FUNCTION GET_ITENS_F( p_date IN VARCHAR2) RETURN prod_cab PIPELINED
      IS
        retset    lt_prod_cab_tp;
        lv_date   VARCHAR2(40);
        ld_date   DATE;
      
        TYPE typ_rec IS RECORD (segment1    mtl_categories.segment1%TYPE
                               ,segment2    mtl_categories.segment2%TYPE
                               ,segment3    mtl_categories.segment3%TYPE 
                               ,segment4    mtl_categories.segment4%TYPE 
                               ,segment5    mtl_categories.segment5%TYPE 
                               ,segment6    mtl_categories.segment6%TYPE 
                               ,segment8    mtl_categories.segment8%TYPE
                               ,attribute1  mtl_categories.attribute1%TYPE
                               ,category_id mtl_categories.category_id%TYPE
                               ,description mtl_categories_tl.description%TYPE
                               )
        ;
        vretorno                   typ_rec;
        vclassif_fiscal            typ_rec;
        vcategory                  typ_rec;
        vfabricante                typ_rec;      
        vean                       typ_rec;        
        vmarca                     typ_rec;
        vpbm                       typ_rec;
        vclass_estoque             typ_rec;
        vcomprador                 typ_rec;
        vfamilia_prod	             typ_rec;
        vsazonalidade	             typ_rec;
        vtermolabil	               typ_rec;
        vrequer_CRM	               typ_rec;
        vvenda_controlada	         typ_rec;
        vretencao_receita	         typ_rec;
        vfarmacia_popular	         typ_rec;
        vlivro_344	               typ_rec;
        vclasse_teraupetica	       typ_rec;
        vcontrole_rastreabilidade  typ_rec;
        vpacote_produto	           typ_rec;
        vtipo_receita	             typ_rec;
        vtipo_medicamento          typ_rec;     
        vlista_pnu                 typ_rec;
        vuso_continuo              typ_rec;
        vusoeconsumo               typ_rec;  
        vpackprod                  typ_rec;
        vinfodun                   typ_rec;
        vusocontinuo               typ_rec;
        vembalagempadrao           typ_rec;
        vminmultcompra             typ_rec;
        vmarca_gc                  typ_rec;
        v_data_carga               DATE; 
      
        -- Retornar dados de categoria por item
        FUNCTION fnc_retorno
          (
              pcategory_set_name  mtl_category_sets.category_set_name%TYPE 
            , p_inventory_item_id NUMBER DEFAULT NULL 
            , p_organization_id   NUMBER DEFAULT NULL
          ) RETURN typ_rec
        IS
          --
          vretorno typ_rec;
        
        BEGIN
                         
          FOR r_seg in (SELECT 
                                  mc.segment1
                                , mc.segment2
                                , mc.segment3
                                , mc.segment4
                                , mc.segment5 
                                , mc.segment6
                                , mc.segment8
                                , mc.attribute1  -- ibpt
                                , mc.category_id -- id
                                , mct.description
                          FROM    mtl_category_sets   mcs
                                , mtl_categories      mc
                                , mtl_item_categories mic
                                , mtl_system_items_b  msi
                                , mtl_parameters      mp
                                , mtl_categories_tl   mct
                         WHERE 1=1
                           AND mct.language          = USERENV('LANG')
                           AND mct.category_id       = mc.category_id
                           AND mcs.category_set_name = pcategory_set_name
                           AND mcs.structure_id      = mc.structure_id
                           AND mc.category_id        = mic.category_id
                           AND mcs.category_set_id   = mic.category_set_id
                           AND mic.organization_id   = mp.organization_id
                           AND mic.organization_id   = msi.organization_id
                           AND mic.inventory_item_id = msi.inventory_item_id
                           AND mp.organization_id    = mp.master_organization_id
                           AND msi.organization_id   = p_organization_id
                           AND msi.inventory_item_id = p_inventory_item_id)
          LOOP
            vretorno.segment1    := r_seg.segment1;
            vretorno.segment2    := r_seg.segment2;
            vretorno.segment3    := r_seg.segment3;
            vretorno.segment4    := r_seg.segment4;
            vretorno.segment5    := r_seg.segment5;  -- criar campo na tabela
            vretorno.segment6    := r_seg.segment6;  -- criar campo na tabela
            vretorno.segment8    := r_seg.segment8;  -- criar campo na tabela 
            vretorno.attribute1  := r_seg.attribute1; 
            vretorno.category_id := r_seg.category_id;
            vretorno.description := r_seg.description;
          END LOOP;
        
          RETURN vretorno;
        
        END fnc_retorno;     
      -- Main Code --
      BEGIN         
        FOR c_itens IN
          (
            SELECT    
                      CAB.produto
                    , CAB.descricao
                    , CAB.unidade_medida
                    , CAB.codigo_cest
                    , CAB.origem
                    , CAB.eh_revenda
                    , CAB.data_inclusao
                    , CAB.data_fora_linha
                    , CAB.status_compra
                    , CAB.status_venda
                    , CAB.data_hora_inclusao
                    , MAX( CAB.data_hora_ultima_alteracao )  data_hora_ultima_alteracao
                    , CAB.rowversion 
                    , CAB.principio_ativo
                    , CAB.inventory_item_id
                    , CAB.organization_id
                    , CAB.registro_ms
                    , CAB.qtd_apresenta
                    , CAB.embal_indust
                    , CAB.peso_liquido
                    , CAB.dosagem
                    , CAB.nom_comercial
                    , CAB.peso
                    , CAB.dimensao_und_medida
                    , CAB.unidade_medida_fracionado
                    , CAB.comprimento
                    , CAB.largura 
                    , CAB.altura
                    , CAB.id_campanha
                    , CAB.status_item
                    , EAN.segment1  ean
                    , EAN.segment2  ean_quantidade_embalagem
                    , CAB.ncm_icms
                    , CAB.ncm_ipi
                    , CAB.fabricacao_propria
                    , CAB.icms_desonerado
                    , CAB.motivo_isencao_ms
                    , CAB.situacao_estadual      
              FROM
                      (
                        SELECT
                                  aa.segment1                    produto
                                , xx.description                 descricao
                                , aa.primary_uom_code            unidade_medida
                                , aa.global_attribute9           codigo_cest
                                , aa.global_attribute3           origem
                                , (
                                    CASE aa.global_attribute2
                                      WHEN 'REVENDA'    THEN 1
                                      WHEN 'REVENDA_ST' THEN 1
                                      ELSE  0
                                    END
                                  )                              eh_revenda
                                , aa.creation_date               data_inclusao
                                , aa.end_date_active             data_fora_linha
                                , aa.purchasing_enabled_flag     status_compra
                                , aa.invoiceable_item_flag       status_venda
                                , aa.creation_date               data_hora_inclusao
                                , aa.last_update_date            data_hora_ultima_alteracao
                                , aa.object_version_number       rowversion 
                                , aa.attribute1                  principio_ativo
                                , aa.inventory_item_id
                                , aa.organization_id
                                , aa.attribute6                  registro_ms
                                , aa.attribute9                  qtd_apresenta
                                , aa.attribute2                  embal_indust
                                , aa.attribute5                  peso_liquido
                                , aa.attribute7                  dosagem
                                , aa.attribute8                  nom_comercial
                                , aa.unit_weight                 peso
                                , (
                                    SELECT unit_of_measure
                                      FROM mtl_units_of_measure_tl
                                    WHERE 1=1
                                      AND uom_code = aa.dimension_uom_code
                                      AND  ROWNUM < 2
                                  )                              dimensao_und_medida
                               , (
                                   SELECT  uom_code
                                     FROM mtl_units_of_measure
                                   WHERE 1=1
                                     AND unit_of_measure = aa.attribute11
                                 )                              unidade_medida_fracionado
                                , aa.unit_length                 comprimento
                                , aa.unit_width                  largura 
                                , aa.unit_height                 altura
                                , TO_NUMBER(aa.attribute16)      id_campanha
                                , aa.inventory_item_status_code  status_item
                                , aa.attribute17                 NCM_ICMS
                                , aa.attribute18                 NCM_IPI
                                , aa.attribute19                 fabricacao_propria
                                , aa.attribute15                 icms_desonerado
                                , aa.attribute3                  motivo_isencao_ms
                                , aa.global_attribute3 || 
      						    aa.global_attribute6           situacao_estadual
                          FROM
                                  mtl_system_items_tl            xx
                                , mtl_system_items_b             aa
                                , mtl_parameters                 zz 
                                , (
                                    SELECT aa.inventory_item_id, MAX(aa.last_update_date) last_update_date -- capturar alteração na categoria do item
                                      FROM mtl_item_categories aa
                                    WHERE aa.organization_id = 174  
                                    GROUP BY aa.inventory_item_id
                                  )                              ss      
                        WHERE 1=1
                          AND xx.LANGUAGE          = 'PTB'
                          AND aa.inventory_item_id = xx.inventory_item_id
                          AND aa.organization_id   = xx.organization_id
                          AND aa.organization_id   = zz.organization_id
                          AND aa.inventory_item_id = ss.inventory_item_id
                          AND zz.organization_code = 'MST'
                          AND aa.inventory_item_flag  = 'Y'
                          AND aa.last_update_date <= SYSDATE
                          AND aa.last_update_date >=  FND_DATE.CANONICAL_TO_DATE(p_date) -- ld_date
                        UNION  
                        SELECT
                                  aa.segment1                    produto
                                , xx.description                 descricao
                                , aa.primary_uom_code            unidade_medida
                                , aa.global_attribute9           codigo_cest
                                , aa.global_attribute3           origem
                                , (
                                    CASE aa.global_attribute2
                                      WHEN 'REVENDA'    THEN 1
                                      WHEN 'REVENDA_ST' THEN 1
                                      ELSE  0
                                    END
                                  )                              eh_revenda
                                , aa.creation_date               data_inclusao
                                , aa.end_date_active             data_fora_linha
                                , aa.purchasing_enabled_flag     status_compra
                                , aa.invoiceable_item_flag       status_venda
                                , aa.creation_date               data_hora_inclusao
                                , ss.last_update_date            data_hora_ultima_alteracao
                                , aa.object_version_number       rowversion 
                                , aa.attribute1                  principio_ativo
                                , aa.inventory_item_id
                                , aa.organization_id
                                , aa.attribute6                  registro_ms
                                , aa.attribute9                  qtd_apresenta
                                , aa.attribute2                  embal_indust
                                , aa.attribute5                  peso_liquido
                                , aa.attribute7                  dosagem
                                , aa.attribute8                  nom_comercial
                                , aa.unit_weight                 peso
                                , (
                                    SELECT unit_of_measure
                                      FROM mtl_units_of_measure_tl
                                    WHERE 1=1
                                      AND uom_code = aa.dimension_uom_code
                                      AND  ROWNUM < 2
                                  )                              dimensao_und_medida
                               , (
                                   SELECT  uom_code
                                     FROM mtl_units_of_measure
                                   WHERE 1=1
                                     AND unit_of_measure = aa.attribute11
                                 )                              unidade_medida_fracionado
                                , aa.unit_length                 comprimento
                                , aa.unit_width                  largura 
                                , aa.unit_height                 altura
                                , TO_NUMBER(aa.attribute16)      id_campanha
                                , aa.inventory_item_status_code  status_item
                                , aa.attribute17                 NCM_ICMS
                                , aa.attribute18                 NCM_IPI
                                , aa.attribute19                 fabricacao_propria
                                , aa.attribute15                 icms_desonerado
                                , aa.attribute3                  motivo_isencao_ms
                                , aa.global_attribute3 || 
      						    aa.global_attribute6           situacao_estadual
                          FROM
                                  mtl_system_items_tl            xx
                                , mtl_system_items_b             aa
                                , mtl_parameters                 zz 
                                , (
                                    SELECT aa.inventory_item_id, MAX(aa.last_update_date) last_update_date -- capturar alteração na categoria do item
                                      FROM mtl_item_categories aa
                                    WHERE aa.organization_id = 174  
                                    GROUP BY aa.inventory_item_id
                                  )                              ss      
                        WHERE 1=1
                          AND xx.LANGUAGE          = 'PTB'
                          AND aa.inventory_item_id = xx.inventory_item_id
                          AND aa.organization_id   = xx.organization_id
                          AND aa.organization_id   = zz.organization_id
                          AND aa.inventory_item_id = ss.inventory_item_id
                          AND zz.organization_code = 'MST'
                          AND aa.inventory_item_flag  = 'Y'
                          AND ss.last_update_date <= SYSDATE
                          AND ss.last_update_date >=  FND_DATE.CANONICAL_TO_DATE(p_date) -- ld_date
                      )                                                                  CAB
                    , (  
                        SELECT
                                 mc.segment1
                               , mc.segment2
                               , mc.category_id
                               , msi.inventory_item_id
                          FROM   mtl_category_sets mcs
                               , mtl_categories  mc
                               , mtl_item_categories mic
                               , mtl_system_items_b msi
                               , mtl_parameters mp
                        WHERE 1=1
                          AND mcs.category_set_name = 'Informacoes Produtos x EAN' 
                          AND mcs.structure_id      = mc.structure_id
                          AND mc.category_id        = mic.category_id
                          AND mcs.category_set_id   = mic.category_set_id
                          AND mic.organization_id   = mp.organization_id
                          AND mic.organization_id   = msi.organization_id
                          AND mic.inventory_item_id = msi.inventory_item_id
                          AND mp.organization_id    = mp.master_organization_id
                          AND mp.organization_code  = 'MST'
                      )                                                                  EAN
            WHERE 1=1
              AND EAN.inventory_item_id(+) = CAB.inventory_item_id
            GROUP BY
                      CAB.produto
                    , CAB.descricao
                    , CAB.unidade_medida
                    , CAB.codigo_cest
                    , CAB.origem
                    , CAB.eh_revenda
                    , CAB.data_inclusao
                    , CAB.data_fora_linha
                    , CAB.status_compra
                    , CAB.status_venda
                    , CAB.data_hora_inclusao
                    , CAB.rowversion 
                    , CAB.principio_ativo
                    , CAB.inventory_item_id
                    , CAB.organization_id
                    , CAB.registro_ms
                    , CAB.qtd_apresenta
                    , CAB.embal_indust
                    , CAB.peso_liquido
                    , CAB.dosagem
                    , CAB.nom_comercial
                    , CAB.peso
                    , CAB.dimensao_und_medida
                    , CAB.unidade_medida_fracionado
                    , CAB.comprimento
                    , CAB.largura 
                    , CAB.altura
                    , CAB.id_campanha
                    , CAB.status_item
                    , EAN.segment1
                    , EAN.segment2
                    , CAB.ncm_icms
                    , CAB.ncm_ipi
                    , CAB.fabricacao_propria
                    , CAB.icms_desonerado
                    , CAB.motivo_isencao_ms
                    , CAB.situacao_estadual
          )
        LOOP
      
          vclassif_fiscal           := fnc_retorno(pcategory_set_name => 'FISCAL_CLASSIFICATION'      , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );  
          vcategory                 := fnc_retorno(pcategory_set_name => 'Categorias de Item'         , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );    
          vfabricante               := fnc_retorno(pcategory_set_name => 'Fabricante'                 , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vmarca_gc                 := fnc_retorno(pcategory_set_name => 'Marca GC'                   , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vean                      := fnc_retorno(pcategory_set_name => 'Informações EAN'            , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );  
          vmarca			               := fnc_retorno(pcategory_set_name => 'Marca'                      , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );  
          vfamilia_prod             := fnc_retorno(pcategory_set_name => 'Familia Produto'            , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vsazonalidade             := fnc_retorno(pcategory_set_name => 'Sazonalidade'               , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vtermolabil               := fnc_retorno(pcategory_set_name => 'Termolabil'                 , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vrequer_crm               := fnc_retorno(pcategory_set_name => 'Requer CRM'                 , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );    
          vvenda_controlada         := fnc_retorno(pcategory_set_name => 'Venda Controlada'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vretencao_receita         := fnc_retorno(pcategory_set_name => 'Retenção Receita'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vfarmacia_popular         := fnc_retorno(pcategory_set_name => 'Farmácia Popular'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vlivro_344                := fnc_retorno(pcategory_set_name => 'Livro Portaria 344'         , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vclasse_teraupetica       := fnc_retorno(pcategory_set_name => 'Classe Terapeutica'         , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vcontrole_rastreabilidade := fnc_retorno(pcategory_set_name => 'Controle de Rastreabilidade', p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vpacote_produto           := fnc_retorno(pcategory_set_name => 'Pacote de Produto'          , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vtipo_receita             := fnc_retorno(pcategory_set_name => 'Tipo Receita'               , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vtipo_medicamento         := fnc_retorno(pcategory_set_name => 'Tipo Medicamento'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id ); 
          vlista_pnu                := fnc_retorno(pcategory_set_name => 'Lista PNU'                  , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );	
          vpbm                      := fnc_retorno(pcategory_set_name => 'Parametro de PBM'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vclass_estoque            := fnc_retorno(pcategory_set_name => 'Classificação de Estoque'   , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vcomprador                := fnc_retorno(pcategory_set_name => 'Comprador'                  , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vpackprod                 := fnc_retorno(pcategory_set_name => 'Pacote de Produto'          , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vinfodun                  := fnc_retorno(pcategory_set_name => 'Informacoes DUN'            , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vuso_continuo             := fnc_retorno(pcategory_set_name => 'Uso Contínuo'               , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );
          vusoeconsumo              := fnc_retorno(pcategory_set_name => 'Uso e Consumo'              , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );	
          vembalagempadrao          := fnc_retorno(pcategory_set_name => 'Embalagem Padrão'           , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );	
          vminmultcompra            := fnc_retorno(pcategory_set_name => 'Mínimo múltiplo de compra'  , p_inventory_item_id => c_itens.inventory_item_id, p_organization_id => c_itens.organization_id );	
      
          IF c_itens.eh_revenda = 0 THEN         
            IF vmarca.segment1 IS NULL THEN
               vmarca.segment1 := 'SEM_MARCA';                
            END IF;           
            IF vfabricante.segment2 IS NULL THEN
               vfabricante.segment2 := 'SEM_FORN';
            END IF;           
            IF vfabricante.segment3 IS NULL THEN
               vfabricante.segment3 := 'SEM_FORN';
            END IF;           
            IF vcategory.segment4 IS NULL THEN
               vcategory.segment4 := 'DEFAULT';
            END IF;           
            IF vcategory.segment5 IS NULL THEN
               vcategory.segment5 := 'DEFAULT';
            END IF;
            IF vcategory.segment6 IS NULL THEN
               vcategory.segment6 := 'DEFAULT';
            END IF;         
          END IF; 
          -- Seta valor  para sazonalidade em null
          IF vsazonalidade.segment1 IS NULL THEN
             vsazonalidade.segment1 := 'NÃO É PRODUTO SAZONAL';       
          END IF;
      
          retset.id_sequencial               :=    c_itens.inventory_item_id;
          retset.produto                     :=    c_itens.produto;
          retset.descricao                   :=    c_itens.descricao;
          retset.unidade_medida              :=    c_itens.unidade_medida;
          retset.secao_produto               :=    vcategory.segment1;
          retset.grupo_produto               :=    vcategory.segment2;
          retset.subgrupo_produto            :=    vcategory.segment3;                    
          retset.categoria_produto           :=    vcategory.segment4;                    
          retset.sub_categoria               :=    vcategory.segment5;                    
          retset.apresentacao                :=    vcategory.segment6;                    
          retset.tipo_secao                  :=    vcategory.segment8;                    
          retset.marca                       :=    vmarca.segment1;                       
          retset.codigo_cest                 :=    c_itens.codigo_cest;
          retset.data_inclusao               :=    c_itens.data_inclusao;
          retset.data_fora_linha             :=    c_itens.data_fora_linha;
          retset.marca_gc                    :=    vmarca_gc.segment1;
          retset.fabricante_cnpj             :=    vfabricante.description;
          retset.status_compra               :=    c_itens.status_compra;
          retset.status_venda                :=    c_itens.status_venda;
          retset.ncm                         :=    SUBSTR(vclassif_fiscal.segment1, 1, 8);
          retset.embalagem_industria         :=    c_itens.embal_indust;
          retset.sazonalidade                :=    vsazonalidade.segment1;
          retset.tipo_medicamento            :=    vtipo_medicamento.segment1;
          retset.status_item                 :=    c_itens.status_item;
          retset.qtd_apresentacao            :=    c_itens.qtd_apresenta;
          retset.data_hora_inclusao          :=    c_itens.data_hora_inclusao;
          retset.data_hora_ultima_alteracao  :=    c_itens.data_hora_ultima_alteracao;
          retset.comercializavel             :=    c_itens.eh_revenda;
          retset.pbm                         :=    vpbm.segment1;
          retset.peso                        :=    c_itens.peso;
          retset.familia                     :=    vfamilia_prod.segment1;
          retset.comprador                   :=    vcomprador.segment1;
          retset.tipo_reposicao              :=    vpbm.segment2;
          retset.dimensao_uni_medida         :=    c_itens.dimensao_und_medida;
          retset.dimensao_com                :=    c_itens.comprimento;
          retset.dimensao_lag                :=    c_itens.largura;
          retset.dimensao_alt                :=    c_itens.altura;
          retset.informacao_dun              :=    vinfodun.segment1;   
          retset.pacote_produto              :=    vpackprod.segment1;
          retset.origem                      :=    c_itens.origem;
          retset.unidade_medida_fracionado   :=    c_itens.unidade_medida_fracionado;
          retset.id_campanha                 :=    c_itens.id_campanha;
          retset.ean                         :=    c_itens.ean;
          retset.ean_quantidade_embalagem    :=    c_itens.ean_quantidade_embalagem;
          retset.retencao_receita            :=    vretencao_receita.segment1;
          retset.venda_controlada            :=    vvenda_controlada.segment1;
          retset.livro_portaria_344          :=    vlivro_344.segment1;
          retset.registro_ms                 :=    c_itens.registro_ms;
          retset.tipo_receita                :=    vtipo_receita.segment1;
          retset.farmacia_popular            :=    vfarmacia_popular.segment1;
          retset.controle_rastreabilidade    :=    vcontrole_rastreabilidade.segment1;
          retset.principio_ativo             :=    c_itens.principio_ativo;
          retset.dosagem                     :=    c_itens.dosagem;
          retset.nome_comercial              :=    c_itens.nom_comercial;
          retset.requer_crm                  :=    vrequer_crm.segment1;
          retset.classe_terapeutica          :=    vclasse_teraupetica.segment1;
          retset.termolabil                  :=    vtermolabil.segment1;
          retset.produto_uso_continuo        :=    vuso_continuo.segment1;
          retset.lista_pnu                   :=    vlista_pnu.segment1;
          retset.uso_consumo                 :=    vusoeconsumo.segment1;
          retset.ncm_icms                    :=    c_itens.ncm_icms;
          retset.ncm_ipi                     :=    c_itens.ncm_ipi;
          retset.fabricacao_propria          :=    c_itens.fabricacao_propria;
          retset.embalagem_padrao            :=    vembalagempadrao.segment1;
          retset.caixaria                    :=    vinfodun.segment2;
          retset.minmultcompra               :=    vminmultcompra.segment1;
          retset.icms_desonerado             :=    c_itens.icms_desonerado;
          retset.motivo_isencao_ms           :=    c_itens.motivo_isencao_ms;
          retset.situacao_estadual           :=    c_itens.situacao_estadual;
          retset.indice_ibpt                 :=    vclassif_fiscal.attribute1;
          --retset.teste_Data                  :=    p_date;
          pipe ROW(retset);
        END LOOP;
        RETURN;
      
      END GET_ITENS_F;
      
    END XXVEN_INT_ITENS_PKG;
    `
]

 

    // Create Package 
    for (const s of stmts) {
        try {
          await database.connExecute(s)
        } catch(e) {
          console.error(e)
        }
    }

    const plsql = `SELECT
                      *            
                  FROM   TABLE(XXVEN_INT_ITENS_PKG.GET_ITENS_F('${date}'))
                  ORDER BY produto
                  `

    const result = await database.simpleExecute(plsql, binds)
    console.log(result)

    // for( const iten of result.rows){
    //     console.log(`Id do Produto: ${iten.ID_SEQUENCIAL}\n
    //     Produto: ${iten.PRODUTO}\n
    //     Descrição: ${iten.DESCRICAO}\n
    //     EAN: ${iten.EAN}\n
    //     Qtd Embalagem(EAN): ${iten.EAN_QUANTIDADE_EMBALAGEM}\n
    //     Entidade Inscrição Federal: ${iten.ENTIDADE_INSCRICAO_FEDERAL}\n
    //     Tipo Fornecedor: ${iten.TIPO_FORNECEDOR}\n
    //     Referência: ${iten.REFERENCIA}\n
    //     Qtd Embalagem(Suplier): ${iten.SUP_QUANTIDADE_EMBALAGEM}\n
    //     `)
    // }

  } catch (err) {
    console.error(err)
  } 
}

//run()
module.exports.run = run
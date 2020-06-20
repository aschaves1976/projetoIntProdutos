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
              , CAB.data_hora_ultima_alteracao
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
                    AND aa.inventory_item_flag = 'Y'
                    AND aa.last_update_date <= SYSDATE
                    AND aa.last_update_date >=  TO_DATE('17/06/2020 00:00:00', 'DD/MM/YYYY HH24:MI:SS') -- FND_DATE.CANONICAL_TO_DATE('17-JUN-20 00:00:00')  -- p_date) -- ld_date
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
                    AND aa.inventory_item_flag = 'Y'
                    AND ss.last_update_date <= SYSDATE
                    AND ss.last_update_date >=  TO_DATE('17/06/2020 00:00:00', 'DD/MM/YYYY HH24:MI:SS') -- FND_DATE.CANONICAL_TO_DATE('17-JUN-20 00:00:00')  -- p_date) -- ld_date
;                )                                                                  CAB
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

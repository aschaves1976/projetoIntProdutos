SET VERIFY OFF
REM WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
REM WHENEVER OSERROR EXIT FAILURE ROLLBACK;

set serveroutput on size unlimited;


set pagesize 100
set linesize 1000
clear columns
clear breaks
Ttitle off
set heading off
set newpage 0
set feedback on

CLEAR BUFFER;

DECLARE
  CURSOR c_item IS
    SELECT
      id_sequencial              
    , produto                    
    , descricao                  
    , unidade_medida             
    , secao_produto              
    , grupo_produto              
    , subgrupo_produto           
    , categoria_produto          
    , sub_categoria              
    , apresentacao               
    , tipo_secao                 
    , marca                      
    , codigo_cest                
    , data_inclusao              
    , data_fora_linha            
    , fabricante_cnpj            
    , status_compra              
    , status_venda               
    , ncm                        
    , embalagem_industria        
    , sazonalidade               
    , data_hora_inclusao         
    , data_hora_ultima_alteracao 
    , envio_status               
    , envio_data_hora            
    , envio_erro                 
    , qtd_apresentacao           
    , status_item                
    , tipo_medicamento           
    , comercializavel            
    , marca_gc                   
    , pbm                        
    , peso                       
    , familia                    
    , comprador                  
    , tipo_reposicao             
    , dimensao_uni_medida        
    , dimensao_com               
    , dimensao_lag               
    , dimensao_alt               
    , informacao_dun             
    , pacote_produto             
    , origem                     
    , unidade_medida_fracionado  
    , id_campanha                
    , ean                        
    , ean_quantidade_embalagem   
    , NVL(retencao_receita, 'NAO') retencao_receita           
    , NVL(venda_controlada, 'NAO') venda_controlada
    , livro_portaria_344         
    , NVL(registro_ms, 'ISENTO')   registro_ms
    , tipo_receita               
    , farmacia_popular           
    , controle_rastreabilidade   
    , principio_ativo            
    , dosagem                    
    , nome_comercial             
    , requer_crm                 
    , classe_terapeutica         
    , termolabil                 
    , NVL(produto_uso_continuo, 'NAO') produto_uso_continuo      
    , lista_pnu                  
    , uso_consumo                
    , ncm_icms                   
    , ncm_ipi                    
    , fabricacao_propria         
    , embalagem_padrao           
    , caixaria                   
    , minmultcompra              
    , icms_desonerado            
    , motivo_isencao_ms          
    , eh_revenda
      FROM xxven_carga_fullitems_tb cust
    WHERE 1=1
      -- AND id_sequencial IN
  ;

  TYPE lt_id_sequencial               IS TABLE OF xxven_carga_fullitems_tb.id_sequencial%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_produto                     IS TABLE OF xxven_carga_fullitems_tb.produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_descricao                   IS TABLE OF xxven_carga_fullitems_tb.descricao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_unidade_medida              IS TABLE OF xxven_carga_fullitems_tb.unidade_medida%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_secao_produto               IS TABLE OF xxven_carga_fullitems_tb.secao_produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_grupo_produto               IS TABLE OF xxven_carga_fullitems_tb.grupo_produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_subgrupo_produto            IS TABLE OF xxven_carga_fullitems_tb.subgrupo_produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_categoria_produto           IS TABLE OF xxven_carga_fullitems_tb.categoria_produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_sub_categoria               IS TABLE OF xxven_carga_fullitems_tb.sub_categoria%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_apresentacao                IS TABLE OF xxven_carga_fullitems_tb.apresentacao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_tipo_secao                  IS TABLE OF xxven_carga_fullitems_tb.tipo_secao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_marca                       IS TABLE OF xxven_carga_fullitems_tb.marca%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_codigo_cest                 IS TABLE OF xxven_carga_fullitems_tb.codigo_cest%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_data_inclusao               IS TABLE OF xxven_carga_fullitems_tb.data_inclusao             %TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_data_fora_linha             IS TABLE OF xxven_carga_fullitems_tb.data_fora_linha%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_fabricante_cnpj             IS TABLE OF xxven_carga_fullitems_tb.fabricante_cnpj%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_status_compra               IS TABLE OF xxven_carga_fullitems_tb.status_compra%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_status_venda                IS TABLE OF xxven_carga_fullitems_tb.status_venda%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_ncm                         IS TABLE OF xxven_carga_fullitems_tb.ncm%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_embalagem_industria         IS TABLE OF xxven_carga_fullitems_tb.embalagem_industria%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_sazonalidade                IS TABLE OF xxven_carga_fullitems_tb.sazonalidade%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_data_hora_inclusao          IS TABLE OF xxven_carga_fullitems_tb.data_hora_inclusao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_data_hora_ultima_alteracao  IS TABLE OF xxven_carga_fullitems_tb.data_hora_ultima_alteracao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_envio_status                IS TABLE OF xxven_carga_fullitems_tb.envio_status%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_envio_data_hora             IS TABLE OF xxven_carga_fullitems_tb.envio_data_hora%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_envio_erro                  IS TABLE OF xxven_carga_fullitems_tb.envio_erro%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_qtd_apresentacao            IS TABLE OF xxven_carga_fullitems_tb.qtd_apresentacao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_status_item                 IS TABLE OF xxven_carga_fullitems_tb.status_item%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_tipo_medicamento            IS TABLE OF xxven_carga_fullitems_tb.tipo_medicamento%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_comercializavel             IS TABLE OF xxven_carga_fullitems_tb.comercializavel%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_marca_gc                    IS TABLE OF xxven_carga_fullitems_tb.marca_gc%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_pbm                         IS TABLE OF xxven_carga_fullitems_tb.pbm%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_peso                        IS TABLE OF xxven_carga_fullitems_tb.peso%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_familia                     IS TABLE OF xxven_carga_fullitems_tb.familia%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_comprador                   IS TABLE OF xxven_carga_fullitems_tb.comprador%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_tipo_reposicao              IS TABLE OF xxven_carga_fullitems_tb.tipo_reposicao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_dimensao_uni_medida         IS TABLE OF xxven_carga_fullitems_tb.dimensao_uni_medida%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_dimensao_com                IS TABLE OF xxven_carga_fullitems_tb.dimensao_com%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_dimensao_lag                IS TABLE OF xxven_carga_fullitems_tb.dimensao_lag%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_dimensao_alt                IS TABLE OF xxven_carga_fullitems_tb.dimensao_alt%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_informacao_dun              IS TABLE OF xxven_carga_fullitems_tb.informacao_dun%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_pacote_produto              IS TABLE OF xxven_carga_fullitems_tb.pacote_produto%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_origem                      IS TABLE OF xxven_carga_fullitems_tb.origem%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_unidade_medida_fracionado   IS TABLE OF xxven_carga_fullitems_tb.unidade_medida_fracionado%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_id_campanha                 IS TABLE OF xxven_carga_fullitems_tb.id_campanha%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_ean                         IS TABLE OF xxven_carga_fullitems_tb.ean%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_ean_quantidade_embalagem    IS TABLE OF xxven_carga_fullitems_tb.ean_quantidade_embalagem%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_retencao_receita            IS TABLE OF xxven_carga_fullitems_tb.retencao_receita%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_venda_controlada            IS TABLE OF xxven_carga_fullitems_tb.venda_controlada%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_livro_portaria_344          IS TABLE OF xxven_carga_fullitems_tb.livro_portaria_344%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_registro_ms                 IS TABLE OF xxven_carga_fullitems_tb.registro_ms%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_tipo_receita                IS TABLE OF xxven_carga_fullitems_tb.tipo_receita%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_farmacia_popular            IS TABLE OF xxven_carga_fullitems_tb.farmacia_popular%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_controle_rastreabilidade    IS TABLE OF xxven_carga_fullitems_tb.controle_rastreabilidade%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_principio_ativo             IS TABLE OF xxven_carga_fullitems_tb.principio_ativo%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_dosagem                     IS TABLE OF xxven_carga_fullitems_tb.dosagem%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_nome_comercial              IS TABLE OF xxven_carga_fullitems_tb.nome_comercial%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_requer_crm                  IS TABLE OF xxven_carga_fullitems_tb.requer_crm%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_classe_terapeutica          IS TABLE OF xxven_carga_fullitems_tb.classe_terapeutica%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_termolabil                  IS TABLE OF xxven_carga_fullitems_tb.termolabil%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_produto_uso_continuo        IS TABLE OF xxven_carga_fullitems_tb.produto_uso_continuo%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_lista_pnu                   IS TABLE OF xxven_carga_fullitems_tb.lista_pnu%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_uso_consumo                 IS TABLE OF xxven_carga_fullitems_tb.uso_consumo%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_ncm_icms                    IS TABLE OF xxven_carga_fullitems_tb.ncm_icms%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_ncm_ipi                     IS TABLE OF xxven_carga_fullitems_tb.ncm_ipi%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_fabricacao_propria          IS TABLE OF xxven_carga_fullitems_tb.fabricacao_propria%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_embalagem_padrao            IS TABLE OF xxven_carga_fullitems_tb.embalagem_padrao%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_caixaria                    IS TABLE OF xxven_carga_fullitems_tb.caixaria%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_minmultcompra               IS TABLE OF xxven_carga_fullitems_tb.minmultcompra%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_icms_desonerado             IS TABLE OF xxven_carga_fullitems_tb.icms_desonerado%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_motivo_isencao_ms           IS TABLE OF xxven_carga_fullitems_tb.motivo_isencao_ms%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_eh_revenda                  IS TABLE OF xxven_carga_fullitems_tb.eh_revenda%TYPE   INDEX BY PLS_INTEGER;

  l_id_sequencial                 lt_id_sequencial;
  l_produto                       lt_produto;
  l_descricao                     lt_descricao;
  l_unidade_medida                lt_unidade_medida;
  l_secao_produto                 lt_secao_produto;
  l_grupo_produto                 lt_grupo_produto;
  l_subgrupo_produto              lt_subgrupo_produto;
  l_categoria_produto             lt_categoria_produto;
  l_sub_categoria                 lt_sub_categoria;
  l_apresentacao                  lt_apresentacao;
  l_tipo_secao                    lt_tipo_secao;
  l_marca                         lt_marca;
  l_codigo_cest                   lt_codigo_cest;
  l_data_inclusao                 lt_data_inclusao;
  l_data_fora_linha               lt_data_fora_linha;
  l_fabricante_cnpj               lt_fabricante_cnpj;
  l_status_compra                 lt_status_compra;
  l_status_venda                  lt_status_venda;
  l_ncm                           lt_ncm;
  l_embalagem_industria           lt_embalagem_industria;
  l_sazonalidade                  lt_sazonalidade;
  l_data_hora_inclusao            lt_data_hora_inclusao;
  l_data_hora_ultima_alteracao    lt_data_hora_ultima_alteracao;
  l_envio_status                  lt_envio_status;
  l_envio_data_hora               lt_envio_data_hora;
  l_envio_erro                    lt_envio_erro;
  l_qtd_apresentacao              lt_qtd_apresentacao;
  l_status_item                   lt_status_item;
  l_tipo_medicamento              lt_tipo_medicamento;
  l_comercializavel               lt_comercializavel;
  l_marca_gc                      lt_marca_gc;
  l_pbm                           lt_pbm;
  l_peso                          lt_peso;
  l_familia                       lt_familia;
  l_comprador                     lt_comprador;
  l_tipo_reposicao                lt_tipo_reposicao;
  l_dimensao_uni_medida           lt_dimensao_uni_medida;
  l_dimensao_com                  lt_dimensao_com;
  l_dimensao_lag                  lt_dimensao_lag;
  l_dimensao_alt                  lt_dimensao_alt;
  l_informacao_dun                lt_informacao_dun;
  l_pacote_produto                lt_pacote_produto;
  l_origem                        lt_origem;
  l_unidade_medida_fracionado     lt_unidade_medida_fracionado;
  l_id_campanha                   lt_id_campanha;
  l_ean                           lt_ean;
  l_ean_quantidade_embalagem      lt_ean_quantidade_embalagem;
  l_retencao_receita              lt_retencao_receita;
  l_venda_controlada              lt_venda_controlada;
  l_livro_portaria_344            lt_livro_portaria_344;
  l_registro_ms                   lt_registro_ms;
  l_tipo_receita                  lt_tipo_receita;
  l_farmacia_popular              lt_farmacia_popular;
  l_controle_rastreabilidade      lt_controle_rastreabilidade;
  l_principio_ativo               lt_principio_ativo;
  l_dosagem                       lt_dosagem;
  l_nome_comercial                lt_nome_comercial;
  l_requer_crm                    lt_requer_crm;
  l_classe_terapeutica            lt_classe_terapeutica;
  l_termolabil                    lt_termolabil;
  l_produto_uso_continuo          lt_produto_uso_continuo;
  l_lista_pnu                     lt_lista_pnu;
  l_uso_consumo                   lt_uso_consumo;
  l_ncm_icms                      lt_ncm_icms;
  l_ncm_ipi                       lt_ncm_ipi;
  l_fabricacao_propria            lt_fabricacao_propria;
  l_embalagem_padrao              lt_embalagem_padrao;
  l_caixaria                      lt_caixaria;
  l_minmultcompra                 lt_minmultcompra;
  l_icms_desonerado               lt_icms_desonerado;
  l_motivo_isencao_ms             lt_motivo_isencao_ms;
  l_eh_revenda                    lt_eh_revenda;
  
  ln_limit                        PLS_INTEGER := 100;
  ln_cnt                          PLS_INTEGER := 0;
  ln_counter                      PLS_INTEGER := 0;
							      
  ln_msg_count                    PLS_INTEGER;
  ln_time                         NUMBER;
  lv_error_msg                    VARCHAR2(32000);
							      
  ln_structure_id                 mtl_category_sets.structure_id%TYPE;
  ln_category_set_id              mtl_category_sets.category_set_id%TYPE;
  ln_category_id                  mtl_categories_b.category_id%TYPE;
							      
  lv_return_status                VARCHAR2(1) := NULL;
  ln_msg_count                    NUMBER := 0;
  lv_msg_data                     VARCHAR2(32000);
  ln_errorcode                    NUMBER;

  PROCEDURE create_log_p
    (
      p_inventory_item_id   IN NUMBER
    , p_category_id         IN NUMBER
    , p_category_set_id     IN NUMBER
    , p_structure_id        IN NUMBER
    , p_status              IN VARCHAR2
    , p_description         IN VARCHAR2
    )
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO xxven_carga_itemcat_log_tb
    VALUES
      (
          SYSDATE
        , p_inventory_item_id
        , p_category_id
        , p_category_set_id
        , p_structure_id
        , p_status
        , p_description
      )
    ;
    COMMIT;
  END create_log_p;
  --
  PROCEDURE category_p
    (
        p_category_id        OUT NUMBER
      , p_structure_id       OUT NUMBER
      , p_category_set_id    OUT NUMBER
      , p_inventory_item_id  IN NUMBER
      , p_organization_id    IN NUMBER
      , p_category_set_name  IN VARCHAR2  --> 'Fabricante' / 'Marca GC'
      , p_name_to_create     IN VARCHAR2  --> xxven_carga_fullitems_tb.FABRICANTE
    )
  IS
  
    l_category_rec           inv_item_category_pub.category_rec_type;
  
    lv_return_status         VARCHAR2(32000);
    ln_errorcode             NUMBER;
    ln_msg_count             PLS_INTEGER;
    lv_msg_data              PLS_INTEGER;
    ln_parent_category_id    NUMBER;
    ln_old_category_id       NUMBER;
	
  BEGIN
    --
    BEGIN
      SELECT structure_id,
             category_set_id
        INTO p_structure_id,
             p_category_set_id
        FROM mtl_category_sets mc
       WHERE mc.category_set_name = p_category_set_name
      ;
    EXCEPTION
      WHEN OTHERS THEN
        p_structure_id     := NULL;
        p_category_set_id  := NULL;
        create_log_p
          (
            p_inventory_item_id   => p_inventory_item_id
          , p_category_id         => p_category_id
          , p_category_set_id     => p_category_set_id
          , p_structure_id        => p_structure_id
          , p_status              => 'E'
          , p_description         => 'FAB_CATEGORY_P -> Unable to fetch the category set(' ||p_category_set_name || ') details :' || SQLERRM
          )
        ;
    END;
    -- looking for Item Category Assigment --
    BEGIN
      SELECT   mct.category_id
        INTO   ln_old_category_id
        FROM   mtl_item_categories mic
             , mtl_categories_tl   mct
             , mtl_categories_b    mcb
             , mtl_category_sets   mcs
      WHERE 1=1
        AND mcs.category_set_name = p_category_set_name
        AND mcs.structure_id      = mcb.structure_id
        AND mct.language          = 'PTB'
        AND mct.category_id       = mcb.category_id
        and mcs.category_set_id   = mic.category_set_id
        and mcb.category_id       = mic.category_id
        and mic.inventory_item_id = P_inventory_item_id
        and mic.organization_id   = p_organization_id
      ;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       ln_old_category_id := NULL;
    END;
    --
    -- LOOKING FOR CATEGORY --
    --
    BEGIN
      SELECT
               mct.category_id
             , mct.description
             , mcb.segment1,  mcb.segment2
             , mcb.segment3,  mcb.segment4
             , mcb.segment5,  mcb.segment6
             , mcb.segment7,  mcb.segment8
             , mcb.segment9,  mcb.segment10
             , mcb.segment11, mcb.segment12
             , mcb.segment13, mcb.segment14
             , mcb.segment15, mcb.segment16
             , mcb.segment17, mcb.segment18
             , mcb.segment19, mcb.segment20
        INTO
               p_category_id
             , l_category_rec.description
             , l_category_rec.segment1,  l_category_rec.segment2
             , l_category_rec.segment3,  l_category_rec.segment4
             , l_category_rec.segment5,  l_category_rec.segment6
             , l_category_rec.segment7,  l_category_rec.segment8
             , l_category_rec.segment9,  l_category_rec.segment10
             , l_category_rec.segment11, l_category_rec.segment12
             , l_category_rec.segment13, l_category_rec.segment14
             , l_category_rec.segment15, l_category_rec.segment16
             , l_category_rec.segment17, l_category_rec.segment18
             , l_category_rec.segment19, l_category_rec.segment20
        FROM   mtl_categories_tl   mct
             , mtl_categories_b    mcb
             , mtl_category_sets   mcs
      WHERE 1=1
        AND mcs.category_set_name = p_category_set_name
        AND mcs.structure_id      = mcb.structure_id
        AND mct.language          = 'PTB'
        AND mct.category_id       = mcb.category_id
        AND mct.description       = p_name_to_create
      ;
	  
      IF ln_old_category_id IS NOT NULL THEN
        inv_item_category_pub.update_category_assignment
          (
              p_api_version       => 1.0
            , p_init_msg_list     => fnd_api.g_true
            , p_commit            => fnd_api.g_true
            , p_category_id       => p_category_id
            , p_old_category_id   => ln_old_category_id
            , p_category_set_id   => p_category_set_id 
            , p_inventory_item_id => p_inventory_item_id
            , p_organization_id   => p_organization_id
            , x_return_status     => lv_return_status
            , x_errorcode         => ln_errorcode
            , x_msg_count         => ln_msg_count
            , x_msg_data          => lv_msg_data
          )
        ;  
        IF lv_return_status = fnd_api.g_ret_sts_success THEN
          create_log_p
            (
              p_inventory_item_id   => p_inventory_item_id
            , p_category_id         => p_category_id
            , p_category_set_id     => p_category_set_id
            , p_structure_id        => p_structure_id
            , p_status              => 'S'
            , p_description         => 'Item Category Assignment Updated'
            )
          ;
        ELSE
          create_log_p
            (
              p_inventory_item_id   => p_inventory_item_id
            , p_category_id         => p_category_id
            , p_category_set_id     => p_category_set_id
            , p_structure_id        => p_structure_id
            , p_status              => 'E'
            , p_description         => 'Item Category Assignment Update -' || p_category_id || ';' || p_category_set_id || ';' || p_inventory_item_id ||
                                       ' falied with the error '   || lv_msg_data
            )
          ;
          ROLLBACK;
          FOR i IN 1 .. ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(
                                           p_msg_index => i
                                         , p_encoded   => 'F'
                                        )
            ;
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'E'
              , p_description         => i || ') ' || lv_msg_data
              )
            ;
          END LOOP;			 
        END IF;	  
      ELSE
        -- create an item category assignment --
        inv_item_category_pub.create_category_assignment
          (
              p_api_version       => 1.0
            , p_init_msg_list     => fnd_api.g_true
            , p_commit            => fnd_api.g_true
            , x_return_status     => lv_return_status
            , x_errorcode         => ln_errorcode
            , x_msg_count         => ln_msg_count
            , x_msg_data          => lv_msg_data
            , p_category_id       => p_category_id
            , p_category_set_id   => p_category_set_id
            , p_inventory_item_id => p_inventory_item_id
            , p_organization_id   => p_organization_id
           );
        IF lv_return_status = fnd_api.g_ret_sts_success THEN
          create_log_p
            (
              p_inventory_item_id   => p_inventory_item_id
            , p_category_id         => p_category_id
            , p_category_set_id     => p_category_set_id
            , p_structure_id        => p_structure_id
            , p_status              => 'S'
            , p_description         => 'Item Category Assignment is sucessful'
            )
          ;
        ELSE
          create_log_p
            (
              p_inventory_item_id   => p_inventory_item_id
            , p_category_id         => p_category_id
            , p_category_set_id     => p_category_set_id
            , p_structure_id        => p_structure_id
            , p_status              => 'E'
            , p_description         => 'Item Category Assignment ' || p_category_id || ';' || p_category_set_id || ';' || p_inventory_item_id ||
                                       ' falied with the error '   || lv_msg_data
            )
          ;
          ROLLBACK;
          FOR i IN 1 .. ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get(
                                           p_msg_index => i
                                         , p_encoded   => 'F'
                                        )
            ;
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'E'
              , p_description         => i || ') ' || lv_msg_data
              )
            ;
          END LOOP;			 
        END IF;	  
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_category_rec              := NULL;
        l_category_rec.structure_id := p_structure_id;
        l_category_rec.summary_flag := 'N';
        l_category_rec.enabled_flag := 'Y';
        l_category_rec.segment1     := p_name_to_create;
        --
        -- Calling the api to create category --
        inv_item_category_pub.create_category
          (
              p_api_version   => 1.0
            , p_init_msg_list => fnd_api.g_true
            , p_commit        => fnd_api.g_true
            , x_return_status => lv_return_status
            , x_errorcode     => ln_errorcode
            , x_msg_count     => ln_msg_count
            , x_msg_data      => lv_msg_data
            , p_category_rec  => l_category_rec
            , x_category_id   => p_category_id
          )
        ;
        IF lv_return_status <> fnd_api.g_ret_sts_success THEN
          create_log_p
            (
              p_inventory_item_id   => p_inventory_item_id
            , p_category_id         => p_category_id
            , p_category_set_id     => p_category_set_id
            , p_structure_id        => p_structure_id
            , p_status              => 'E'
            , p_description         => 'Creation of Item Category Failed with the error :' || ln_errorcode
            )
          ;
          FOR i IN 1 .. ln_msg_count LOOP
            lv_msg_data := oe_msg_pub.get
              (
                 p_msg_index => i
               , p_encoded   => 'F'
              )
            ;
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'E'
              , p_description         => i || ') ' || lv_msg_data
              )
            ;
          END LOOP;
        ELSE
          BEGIN
		    SELECT category_id
              INTO p_category_id
              FROM mtl_categories_v
            WHERE 1=1
              AND structure_id         = p_structure_id
              AND category_concat_segs = p_name_to_create
            ;
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'S'
              , p_description         => 'Category Id: ' || p_category_id || 'Created.'
              )
            ;
          EXCEPTION
            WHEN OTHERS THEN
              NULL; -- dbms_output.put_line('Category Id: ' || p_category_id || 'não localizada. - ' || SQLERRM);
          END;
        END IF;	   
    
        IF p_category_id IS NOT NULL THEN
          -- Create Valid Category -> assigning a category to a category set
          inv_item_category_pub.create_valid_category
            (
               p_api_version        => 1.0
             , p_init_msg_list      => fnd_api.g_true
             , p_commit             => fnd_api.g_true
             , p_category_set_id    => p_category_set_id
             , p_category_id        => p_category_id
             , p_parent_category_id => ln_parent_category_id
             , x_return_status      => lv_return_status
             , x_errorcode          => ln_errorcode
             , x_msg_count          => ln_msg_count
             , x_msg_data           => lv_msg_data
            )
          ;
          IF lv_return_status = fnd_api.g_ret_sts_success THEN
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'S'
              , p_description         => 'Assignment of category is sucessful'
              )
            ;
            IF ln_old_category_id IS NOT NULL THEN
              inv_item_category_pub.update_category_assignment
                (
                    p_api_version       => 1.0
                  , p_init_msg_list     => fnd_api.g_true
                  , p_commit            => fnd_api.g_true
                  , p_category_id       => p_category_id
                  , p_old_category_id   => ln_old_category_id
                  , p_category_set_id   => p_category_set_id 
                  , p_inventory_item_id => p_inventory_item_id
                  , p_organization_id   => p_organization_id
                  , x_return_status     => lv_return_status
                  , x_errorcode         => ln_errorcode
                  , x_msg_count         => ln_msg_count
                  , x_msg_data          => lv_msg_data
                )
              ;  
              IF lv_return_status = fnd_api.g_ret_sts_success THEN
                create_log_p
                  (
                    p_inventory_item_id   => p_inventory_item_id
                  , p_category_id         => p_category_id
                  , p_category_set_id     => p_category_set_id
                  , p_structure_id        => p_structure_id
                  , p_status              => 'S'
                  , p_description         => 'Item Category Assignment Updated'
                  )
                ;
              ELSE
                create_log_p
                  (
                    p_inventory_item_id   => p_inventory_item_id
                  , p_category_id         => p_category_id
                  , p_category_set_id     => p_category_set_id
                  , p_structure_id        => p_structure_id
                  , p_status              => 'E'
                  , p_description         => 'Item Category Assignment Update -' || p_category_id || ';' || p_category_set_id || ';' || p_inventory_item_id ||
                                             ' falied with the error '   || lv_msg_data
                  )
                ;
                ROLLBACK;
                FOR i IN 1 .. ln_msg_count LOOP
                  lv_msg_data := oe_msg_pub.get(
                                                 p_msg_index => i
                                               , p_encoded   => 'F'
                                              )
                  ;
                  create_log_p
                    (
                      p_inventory_item_id   => p_inventory_item_id
                    , p_category_id         => p_category_id
                    , p_category_set_id     => p_category_set_id
                    , p_structure_id        => p_structure_id
                    , p_status              => 'E'
                    , p_description         => i || ') ' || lv_msg_data
                    )
                  ;
                END LOOP;			 
              END IF;	  
            ELSE
              -- create an item category assignment --
              inv_item_category_pub.create_category_assignment
                (
                    p_api_version       => 1.0
                  , p_init_msg_list     => fnd_api.g_true
                  , p_commit            => fnd_api.g_true
                  , x_return_status     => lv_return_status
                  , x_errorcode         => ln_errorcode
                  , x_msg_count         => ln_msg_count
                  , x_msg_data          => lv_msg_data
                  , p_category_id       => p_category_id
                  , p_category_set_id   => p_category_set_id
                  , p_inventory_item_id => p_inventory_item_id
                  , p_organization_id   => p_organization_id
                 );
              IF lv_return_status = fnd_api.g_ret_sts_success THEN
                create_log_p
                  (
                    p_inventory_item_id   => p_inventory_item_id
                  , p_category_id         => p_category_id
                  , p_category_set_id     => p_category_set_id
                  , p_structure_id        => p_structure_id
                  , p_status              => 'S'
                  , p_description         => 'Item Category Assignment is sucessful'
                  )
                ;
              ELSE
                create_log_p
                  (
                    p_inventory_item_id   => p_inventory_item_id
                  , p_category_id         => p_category_id
                  , p_category_set_id     => p_category_set_id
                  , p_structure_id        => p_structure_id
                  , p_status              => 'E'
                  , p_description         => 'Item Category Assignment ' || p_category_id || ';' || p_category_set_id || ';' || p_inventory_item_id ||
                                             ' falied with the error '   || lv_msg_data
                  )
                ;
                ROLLBACK;
                FOR i IN 1 .. ln_msg_count LOOP
                  lv_msg_data := oe_msg_pub.get(
                                                 p_msg_index => i
                                               , p_encoded   => 'F'
                                              )
                  ;
                  create_log_p
                    (
                      p_inventory_item_id   => p_inventory_item_id
                    , p_category_id         => p_category_id
                    , p_category_set_id     => p_category_set_id
                    , p_structure_id        => p_structure_id
                    , p_status              => 'E'
                    , p_description         => i || ') ' || lv_msg_data
                    )
                  ;
                END LOOP;			 
              END IF;	  
            END IF;
          ELSE
            create_log_p
              (
                p_inventory_item_id   => p_inventory_item_id
              , p_category_id         => p_category_id
              , p_category_set_id     => p_category_set_id
              , p_structure_id        => p_structure_id
              , p_status              => 'E'
              , p_description         => 'Assignment of category '  || p_name_to_create  || ' falied with the error ' || lv_msg_data
              )
            ;
            ROLLBACK;
            FOR i IN 1 .. ln_msg_count LOOP
              lv_msg_data := oe_msg_pub.get(   p_msg_index => i
          	                              , p_encoded   => 'F'
                                          )
              ;
              create_log_p
                (
                  p_inventory_item_id   => p_inventory_item_id
                , p_category_id         => p_category_id
                , p_category_set_id     => p_category_set_id
                , p_structure_id        => p_structure_id
                , p_status              => 'E'
                , p_description         => i || ') ' || lv_msg_data
                )
              ;
            END LOOP;  
          END IF;      
        END IF;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      create_log_p
        (
          p_inventory_item_id   => p_inventory_item_id
        , p_category_id         => p_category_id
        , p_category_set_id     => p_category_set_id
        , p_structure_id        => p_structure_id
        , p_status              => 'E'
        , p_description         => 'CATEGORY_P - ERRO SÚBITO: p_inventory_item_id: '||p_inventory_item_id||' p_category_id: '||p_category_id||' p_category_set_id: '||p_category_set_id
                   || ' p_structure_id: '||p_structure_id || ' - ' ||SQLERRM
        )
      ;
  END category_p;

--
-- START MAIN CODE --
--  
BEGIN
  BEGIN
    dbms_output.put_line( 'Start Time...........: ' || TO_CHAR( SYSDATE,'DD/MM/RR HH24:MI:SS' ) );    

    ln_time    := dbms_utility.get_time;
    ln_limit   := 100; 
    ln_counter := 0;
    ln_cnt     := 0;
    OPEN c_item;
      LOOP
       FETCH c_item
         BULK COLLECT INTO
              l_id_sequencial
            , l_produto
            , l_descricao
            , l_unidade_medida
            , l_secao_produto
            , l_grupo_produto
            , l_subgrupo_produto
            , l_categoria_produto
            , l_sub_categoria
            , l_apresentacao
            , l_tipo_secao
            , l_marca
            , l_codigo_cest
            , l_data_inclusao             
            , l_data_fora_linha
            , l_fabricante_cnpj
            , l_status_compra
            , l_status_venda
            , l_ncm
            , l_embalagem_industria
            , l_sazonalidade
            , l_data_hora_inclusao
            , l_data_hora_ultima_alteracao
            , l_envio_status
            , l_envio_data_hora
            , l_envio_erro
            , l_qtd_apresentacao
            , l_status_item
            , l_tipo_medicamento
            , l_comercializavel
            , l_marca_gc
            , l_pbm
            , l_peso
            , l_familia
            , l_comprador
            , l_tipo_reposicao
            , l_dimensao_uni_medida
            , l_dimensao_com
            , l_dimensao_lag
            , l_dimensao_alt
            , l_informacao_dun
            , l_pacote_produto
            , l_origem
            , l_unidade_medida_fracionado
            , l_id_campanha
            , l_ean
            , l_ean_quantidade_embalagem
            , l_retencao_receita
            , l_venda_controlada
            , l_livro_portaria_344
            , l_registro_ms
            , l_tipo_receita
            , l_farmacia_popular
            , l_controle_rastreabilidade
            , l_principio_ativo
            , l_dosagem
            , l_nome_comercial
            , l_requer_crm
            , l_classe_terapeutica
            , l_termolabil
            , l_produto_uso_continuo
            , l_lista_pnu
            , l_uso_consumo
            , l_ncm_icms
            , l_ncm_ipi
            , l_fabricacao_propria
            , l_embalagem_padrao
            , l_caixaria
            , l_minmultcompra
            , l_icms_desonerado
            , l_motivo_isencao_ms
            , l_eh_revenda
       LIMIT ln_limit
       ;
       ln_counter := l_id_sequencial.FIRST;
       WHILE ln_counter IS NOT NULL LOOP
         ln_cnt := ln_cnt + 1;
         SAVEPOINT INICIO;

         UPDATE   mtl_system_items_b   msib
           SET
                  msib.attribute18                = l_ncm_ipi(ln_counter)
                , msib.attribute17                = l_ncm_icms(ln_counter)
                , msib.attribute19                = l_fabricacao_propria(ln_counter)
                , msib.global_attribute9          = l_codigo_cest(ln_counter)
                , msib.attribute6                 = l_registro_ms(ln_counter)
				, msib.primary_uom_code           = l_unidade_medida(ln_counter)
                , msib.global_attribute3          = l_origem(ln_counter)
                , msib.global_attribute2          = l_eh_revenda(ln_counter)
                , msib.end_date_active            = l_data_fora_linha(ln_counter)
                , msib.purchasing_enabled_flag    = l_status_compra(ln_counter)
                , msib.invoiceable_item_flag      = l_status_venda(ln_counter)
                --, msib.creation_date              = l_data_hora_inclusao(ln_counter)
                , msib.attribute1                 = l_principio_ativo(ln_counter)
                , msib.attribute9                 = l_qtd_apresentacao(ln_counter)
                , msib.attribute2                 = l_embalagem_industria(ln_counter)
                , msib.unit_weight                = l_peso(ln_counter)
                , msib.attribute7                 = l_dosagem(ln_counter)
                , msib.attribute8                 = l_nome_comercial(ln_counter)
                , msib.unit_length                = l_dimensao_com(ln_counter)
                , msib.unit_width                 = l_dimensao_lag(ln_counter)
                , msib.unit_height                = l_dimensao_alt(ln_counter)
                , msib.attribute16                = l_id_campanha(ln_counter)
                , msib.inventory_item_status_code = l_status_item(ln_counter)
                , msib.attribute15                = l_icms_desonerado(ln_counter)
                , msib.attribute3                 = l_motivo_isencao_ms(ln_counter)
                , msib.last_update_date   = SYSDATE
         WHERE 1=1
           AND msib.inventory_item_id     = l_id_sequencial(ln_counter)
           AND msib.organization_id       = 174
         ;
         UPDATE   mtl_system_items_tl   msit
           SET
                  msit.description        = l_descricao(ln_counter)
                , msit.last_update_date   = SYSDATE
         WHERE 1=1
           AND msit.inventory_item_id     = l_id_sequencial(ln_counter)
           AND msit.organization_id       = 174
         ;
         -- 'FISCAL_CLASSIFICATION'
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'FISCAL_CLASSIFICATION'
             , p_name_to_create     => l_ncm(ln_counter)
           )
         ;
         --	 
         -- Fabricante --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Fabricante'
             , p_name_to_create     => l_fabricante_cnpj(ln_counter)
           )
         ;
         --
         -- Marca GC -- 
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Marca GC'
             , p_name_to_create     => l_marca_gc(ln_counter)
           )
         ;
		 --
         -- 'Marca' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Marca'
             , p_name_to_create     => l_marca(ln_counter)
           )
         ;
         -- 'Familia Produto' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Familia Produto'
             , p_name_to_create     => l_familia(ln_counter)
           )
         ;
         -- 'Sazonalidade' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Sazonalidade'
             , p_name_to_create     => l_sazonalidade(ln_counter)
           )
         ;
         -- 'Termolabil' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Termolabil'
             , p_name_to_create     => l_Termolabil(ln_counter)
           )
         ;
         -- 'Requer CRM' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Requer CRM'
             , p_name_to_create     => l_requer_crm(ln_counter)
           )
         ;
         -- 'Venda Controlada' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Venda Controlada'
             , p_name_to_create     => l_venda_controlada(ln_counter)
           )
         ;
        -- Retencao de Receita --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Retenção Receita'
             , p_name_to_create     => l_retencao_receita(ln_counter)
           )
         ;
         -- 'Farmácia Popular' --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Farmácia Popular'
             , p_name_to_create     => l_farmacia_popular(ln_counter)
           )
         ;
        -- Livro Portaria 344 --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Livro Portaria 344'
             , p_name_to_create     => l_livro_portaria_344(ln_counter)
           )
         ;
        -- Classe Terapeutica --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Classe Terapeutica'
             , p_name_to_create     => l_classe_terapeutica(ln_counter)
           )
         ;
        -- Controle de Rastreabilidade --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Controle de Rastreabilidade'
             , p_name_to_create     => l_controle_rastreabilidade(ln_counter)
           )
         ;
        -- Tipo Receita --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Tipo Receita'
             , p_name_to_create     => l_tipo_receita(ln_counter)
           )
         ;
        -- Tipo Medicamento --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Tipo Medicamento'
             , p_name_to_create     => l_tipo_medicamento(ln_counter)
           )
         ;
        -- Lista PNU --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Lista PNU'
             , p_name_to_create     => l_lista_pnu(ln_counter)
           )
         ;
        -- Parametro de PBM --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Parametro de PBM'
             , p_name_to_create     => l_pbm(ln_counter)
           )
         ;
        -- Comprador --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Comprador'
             , p_name_to_create     => l_comprador(ln_counter)
           )
         ;
        -- Pacote de Produto --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Pacote de Produto'
             , p_name_to_create     => l_pacote_produto(ln_counter)
           )
         ;
        -- Pacote de Produto --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Pacote de Produto'
             , p_name_to_create     => l_pacote_produto(ln_counter)
           )
         ;
         -- Informacoes DUN --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Informacoes DUN'
             , p_name_to_create     => l_informacao_dun(ln_counter)
           )
         ;
         -- Uso Contínuo --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Uso Contínuo'
             , p_name_to_create     => l_produto_uso_continuo(ln_counter)
           )
         ;
         -- Uso e Consumo --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Uso e Consumo'
             , p_name_to_create     => l_uso_consumo(ln_counter)
           )
         ;
         -- Embalagem Padrão --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Embalagem Padrão'
             , p_name_to_create     => l_embalagem_padrao(ln_counter)
           )
         ;
         -- Mínimo múltiplo de compra --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_id_sequencial(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Mínimo múltiplo de compra'
             , p_name_to_create     => l_minmultcompra(ln_counter)
           )
         ;
         --
		 COMMIT;
         <<PROXIMO>>
         ln_counter := l_id_sequencial.NEXT(ln_counter);
         NULL;
       END LOOP;
       EXIT WHEN l_id_sequencial.COUNT < ln_limit;
     END LOOP;
    CLOSE c_item;
    dbms_output.put_line( 'End Time...........: ' || TO_CHAR( SYSDATE,'DD/MM/RR HH24:MI:SS' ) || ' - ' || ((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
    dbms_output.put_line(' ');
  END;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(' ERRO SÚBITO: ' || SQLERRM); 
END;
--
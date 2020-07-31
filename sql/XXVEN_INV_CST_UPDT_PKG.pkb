CREATE OR REPLACE PACKAGE BODY XXVEN_INV_CST_UPDT_PKG AS
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
  PROCEDURE main_p (  errbuf   OUT VARCHAR2
                    , retcode  OUT NUMBER
                   )
  IS
 
  BEGIN
    update_balance_p
      (  errbuf   => errbuf
       , retcode  => retcode
      )
    ;
  END main_p;
  --
  -- Update Barramento
  PROCEDURE set_log_p
    (
       p_produto       IN NUMBER
     , p_empresa       IN NUMBER
     , p_envio_status  IN NUMBER
     , p_envio_erro    IN VARCHAR2
    )
  IS
  BEGIN
    UPDATE oracle_estoque_empresas@prochml
      SET
             envio_status     = p_envio_status
           , envio_data_hora  = TRUNC(CURRENT_TIMESTAMP)
           --, envio_erro       = p_envio_erro
    WHERE 1=1
      AND produto       = p_produto
      AND empresa       = p_empresa
    ;
    IF p_envio_erro IS NOT NULL THEN
      fnd_file.put_line(fnd_file.log,'ERROR:'||p_produto||' - '||p_empresa||' Error: '||p_envio_erro);
      dbms_output.put_line('ERROR:'||p_produto||' - '||p_empresa||' Error: '||p_envio_erro);
    END IF;
  END set_log_p;	
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
  IS
    ln_onhand_qty NUMBER;
    ln_last_qty   NUMBER;
    ln_target_qty NUMBER;

  BEGIN  
    -- onhand --
    SELECT
             NVL(SUM(moqd.transaction_quantity),0) on_hand
      INTO   ln_onhand_qty 
      FROM
             mtl_onhand_quantities_detail  moqd
           , mtl_system_items_b            msib
           , mtl_system_items_tl           msit
           , org_organization_definitions  ood
           , hr_all_organization_units     haou
    WHERE 1=1
      AND ood.organization_id    = haou.organization_id
      AND ood.organization_id    = moqd.organization_id
      AND msib.organization_id   = moqd.organization_id
      AND msit.language          = 'PTB'
      AND msib.organization_id   = msit.organization_id
      AND msib.inventory_item_id = msit.inventory_item_id
      AND moqd.inventory_item_id = msib.inventory_item_id
      AND ood.operating_unit     = p_operating_unit
      AND moqd.organization_id   = p_organization_id
      AND moqd.inventory_item_id = p_inventory_item_id 
      AND moqd.subinventory_code = NVL(p_subinventory, moqd.subinventory_code)
    ;
    -- TRANSACIONADOS --
    SELECT
           NVL(SUM(mmt.Transaction_quantity),0) last_qty
      INTO ln_last_qty 
      FROM
             mtl_material_transactions  mmt
    WHERE 1=1
      AND mmt.inventory_item_id       = p_inventory_item_id
      AND mmt.organization_id         = p_organization_id
      AND mmt.subinventory_code       = NVL(p_subinventory, mmt.subinventory_code)
      AND mmt.transaction_date       >= p_dt_retroactive
    ;
    ln_target_qty := (ln_onhand_qty)-(ln_last_qty);
    --
    RETURN( ln_target_qty);
  
  EXCEPTION
    WHEN OTHERS THEN
      p_error := 'XXVEN_INV_CST_UPDT_PKG.GET_STOCK_QUANTITY_F (p_operating_unit => '||p_operating_unit||
	             ' ,p_organization_id => '||p_organization_id||' ,p_inventory_item_id => '||p_inventory_item_id||
                 ' ,p_subinventory => '   ||p_subinventory||' ,p_dt_retroactive => '      ||p_dt_retroactive||' ERROR: '||SQLERRM;
      RETURN 0;
  END get_stock_quantity_f;

  -- Update Inventory Balance
  PROCEDURE update_balance_p
    (  errbuf   OUT VARCHAR2
     , retcode  OUT NUMBER
    )
  IS
    ln_cnt                    NUMBER := 0;
    ln_cnt_commit             NUMBER := 0;
    ln_cnt_error              NUMBER := 0;
    ln_aux                    NUMBER := 0;
    ln_user_id                fnd_user.user_id%TYPE;
    ln_resp_id                fnd_responsibility_tl.responsibility_id%TYPE;
    ln_resp_appl_id           fnd_responsibility_tl.application_id%TYPE;
    ln_limit                  PLS_INTEGER := 5000;
    ln_time                   NUMBER;


    lv_return_status           VARCHAR2(1);
    ln_msg_count               NUMBER;
    lv_msg_data                VARCHAR2(32000);
    lv_msg_erro                VARCHAR2(4000);
    lv_header                  VARCHAR2(32000);
    ln_qtd_total_nadata        NUMBER;
    ln_qtd_transacionada       NUMBER;
    ln_request_id              NUMBER;

    ln_transaction_interface_id  mtl_transactions_interface.transaction_interface_id%TYPE;
    lv_source_code               mtl_transactions_interface.source_code%TYPE;
    ln_distribution_account_id   mtl_transactions_interface.distribution_account_id%TYPE;
    lv_transaction_type_name     mtl_transaction_types.transaction_type_name%TYPE;  -- saldo para maior (Miscellaneous Entrada) ou para menor (Miscellaneous de saída)
    ln_transaction_type_id       mtl_transaction_types.transaction_type_id%TYPE;
    ln_organization_id           org_organization_definitions.organization_id%TYPE;
    ln_operating_unit            org_organization_definitions.operating_unit%TYPE;
    lv_subinventory_code         mtl_secondary_inventories.secondary_inventory_name%TYPE;
    ln_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;
    ln_transaction_cost          mtl_transactions_interface.transaction_cost%TYPE;
	
    CURSOR c_item IS
      SELECT *
        FROM oracle_estoque_empresas@prochml line
      WHERE 1=1
        AND NVL(envio_status, 0) = 0
    ;
    --
    TYPE lt_item                IS TABLE OF oracle_estoque_empresas@prochml%ROWTYPE INDEX BY PLS_INTEGER;
    l_item                      lt_item;
    -- COLUMNS --
    -- org_organization_definitions --
      -- organization_id
      TYPE organization_id_t     IS TABLE OF org_organization_definitions.organization_id%TYPE INDEX BY PLS_INTEGER; 
      l_organization_id          organization_id_t;
      -- operating_unit          
      TYPE operating_unit_t      IS TABLE OF org_organization_definitions.operating_unit%TYPE INDEX BY PLS_INTEGER; 
      l_operating_unit           operating_unit_t;
    --
    -- mtl_system_items_b --
      -- inventory_item_id 
      TYPE inventory_item_id_t   IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE INDEX BY PLS_INTEGER; 
      l_inventory_item_id        inventory_item_id_t;
      -- primary_uom_code
      TYPE primary_uom_code_t    IS TABLE OF mtl_system_items_b.primary_uom_code%TYPE INDEX BY PLS_INTEGER; 
      l_primary_uom_code         primary_uom_code_t;
    --
    -- oracle_estoque_empresas@prochml header --
      -- data
      TYPE data_t                IS TABLE OF tb_proc_ebs_saldo_inv_cab.data@intprd%TYPE INDEX BY PLS_INTEGER; 
      l_data                     data_t;

  BEGIN
	fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.log,CHR(13)||'    Início Atualização Custos ');

    EXECUTE IMMEDIATE (' alter session set nls_language  = '||CHR(39)||'AMERICAN'||CHR(39));
    -- Set the applications context
    BEGIN
      mo_global.init('INV');
      -- mo_global.set_policy_context(p_access_mode => 'S', p_org_id => fnd_global.org_id);
      fnd_global.APPS_INITIALIZE
        (   user_id      => fnd_global.user_id
          , resp_id      => fnd_global.resp_id
          , resp_appl_id => fnd_global.resp_appl_id
        )
      ;
    END;
    --
    ln_time := dbms_utility.get_time;
    OPEN c_item;
      LOOP
        FETCH c_item 
          BULK COLLECT INTO l_item LIMIT ln_limit
        ;
        FOR i IN 1 .. l_item.COUNT LOOP
          --
          SAVEPOINT INICIO;
          --
          lv_msg_erro := NULL;
          ln_qtd_transacionada := 0;
          ln_qtd_total_nadata  := 0;
          --
          -- Validate organization_id
          BEGIN
            SELECT
                     organization_id
                   , operating_unit
              INTO
                     ln_organization_id
                   , ln_operating_unit
              FROM org_organization_definitions  ood
            WHERE 1=1
              AND ood.organization_code = l_item(i).organizacao_oracle
              -- AND ood.operating_unit    = fnd_global.org_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_msg_erro := 'A Organização '||l_item(i).organizacao_oracle||' não foi localizada na Unidade Operacional '||fnd_global.org_id||' .';
              set_log_p
                (
                   p_produto           => l_item(i).produto
                 , p_empresa           => l_item(i).organizacao_oracle
                 , p_envio_status      => NULL
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação da Organização '||l_item(i).organizacao_oracle||' - Error: '|| SQLERRM;
              set_log_p
                (
                   p_produto           => l_item(i).produto
                 , p_empresa           => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
          END;
          -- Validate Subinventory --
          BEGIN
            SELECT secinv.secondary_inventory_name
              INTO lv_subinventory_code
              FROM mtl_secondary_inventories  secinv
            WHERE secinv.organization_id          = ln_organization_id
              AND secinv.secondary_inventory_name = l_item(i).sub_inventario
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_msg_erro := 'O Subinventário '||l_item(i).sub_inventario||' não foi localizado na Organização '||ln_organization_id||'.';
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação do Subinventário '||l_item(i).sub_inventario||' - Error: '|| SQLERRM;
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
          END;
          -- Check if item is assigned to organization --
          BEGIN
            SELECT
                     inventory_item_id
              INTO
                     ln_inventory_item_id
              FROM
                     mtl_system_items_b
            WHERE 1=1
              AND segment1          = l_item(i).produto
              AND organization_id   = ln_organization_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_msg_erro := 'O Item '||l_item(i).produto||' não foi localizado na Organização '||ln_organization_id||'.';
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação Item '||l_item(i).produto||' Associado a Organização '||ln_organization_id||' - Error: '|| SQLERRM;
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
          END;
          -- Validar se houve entrada ou saida --
		  -- Saldo para maior (Miscellaneous Entrada) ou Saldo para menor (Miscellaneous de Saída)
          ln_qtd_total_nadata := get_stock_quantity_f
            (
               p_operating_unit    => ln_operating_unit
             , p_organization_id   => ln_organization_id
             , p_inventory_item_id => ln_inventory_item_id
             , p_subinventory      => lv_subinventory_code
             , p_dt_retroactive    => l_item(i).data_base
             , p_error             => lv_msg_erro
            )
          ;
          IF lv_msg_erro IS NULL THEN
            -- Seleciona Tipo de Transacao --
            ln_qtd_transacionada := l_item(i).total_estoque_unidades - ln_qtd_total_nadata;
            IF ln_qtd_transacionada > 0 THEN
              BEGIN
                SELECT 
                         mtt.transaction_type_id
                       , mtt.transaction_type_name
                       , mtst.transaction_source_type_name
                  INTO
                         ln_transaction_type_id
                       , lv_transaction_type_name
                       , lv_source_code
                  FROM
                         mtl_transaction_types mtt
                       , mtl_txn_source_types  mtst
                WHERE 1=1
                  AND mtst.transaction_source_type_id = mtt.transaction_source_type_id
                  AND mtt.transaction_type_name        = 'Miscellaneous Entrada'
                ;
                ln_transaction_cost := l_item(i).custo_unitario;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_msg_erro := 'O Tipo de Transação "Miscellaneous Entrada" não foi localizado.';
                  set_log_p
                    (
                       p_produto     => l_item(i).produto
                     , p_empresa => l_item(i).organizacao_oracle
                     , p_envio_status      => 30
                     , p_envio_erro        => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
                WHEN OTHERS THEN
                  lv_msg_erro := 'Seleciona Tipo de Transacao (Miscellaneous Entrada) - Error: '||SQLERRM;
                  set_log_p
                    (
                       p_produto     => l_item(i).produto
                     , p_empresa => l_item(i).organizacao_oracle
                     , p_envio_status      => 30
                     , p_envio_erro        => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
              END;
            ELSE
              BEGIN
                SELECT 
                         mtt.transaction_type_id
                       , mtt.transaction_type_name
                       , mtst.transaction_source_type_name
                  INTO
                         ln_transaction_type_id
                       , lv_transaction_type_name
                       , lv_source_code
                  FROM
                         mtl_transaction_types mtt
                       , mtl_txn_source_types  mtst
                WHERE 1=1
                  AND mtst.transaction_source_type_id = mtt.transaction_source_type_id
                  AND mtt.transaction_type_name        = 'Miscellaneous de Saída'
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_msg_erro := 'O Tipo de Transação "Miscellaneous de Saída" não foi localizado.';
                  set_log_p
                    (
                       p_produto     => l_item(i).produto
                     , p_empresa => l_item(i).organizacao_oracle
                     , p_envio_status      => 30
                     , p_envio_erro        => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
                WHEN OTHERS THEN
                  lv_msg_erro := 'Seleciona Tipo de Transacao (Miscellaneous Saída) - Error: '||SQLERRM;
                  set_log_p
                    (
                       p_produto     => l_item(i).produto
                     , p_empresa => l_item(i).organizacao_oracle
                     , p_envio_status      => 30
                     , p_envio_erro        => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
              END;
            END IF;
          ELSE
            set_log_p
              (
                 p_produto     => l_item(i).produto
               , p_empresa => l_item(i).organizacao_oracle
               , p_envio_status      => 30
               , p_envio_erro        => lv_msg_erro
              )
            ;
            GOTO PROXIMO;
          END IF;
          -- Busca da Conta --
          BEGIN
            SELECT   gcc.code_combination_id
              INTO
                     ln_distribution_account_id
              FROM
                     mtl_parameters       mp
                   , gl_code_combinations gcc
            WHERE 1=1
              AND gcc.code_combination_id = mp.material_account
              AND mp.organization_id      = ln_organization_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_msg_erro := 'Conta não foi localizada na Organização '||ln_organization_id||'.';
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Busca da Conta (Organização '||ln_organization_id||') - Error: '||SQLERRM;
              set_log_p
                (
                   p_produto     => l_item(i).produto
                 , p_empresa => l_item(i).organizacao_oracle
                 , p_envio_status      => 30
                 , p_envio_erro        => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
          END;
          --
          SELECT mtl_material_transactions_s.NEXTVAL
            INTO ln_transaction_interface_id
            FROM dual
          ;
          --
          INSERT INTO mtl_transactions_interface    
                (
                   transaction_interface_id    
                 , transaction_header_id    
                 , source_code    
                 , source_line_id    
                 , source_header_id    
                 , process_flag    
                 , validation_required    
                 , transaction_mode    
                 , lock_flag    
                 , last_update_date    
                 , last_updated_by    
                 , creation_date    
                 , created_by    
                 , inventory_item_id    
                 , organization_id    
                 , transaction_quantity    
                 , transaction_uom    
                 , transaction_date    
                 , subinventory_code    
                 , distribution_account_id    
                 , transaction_type_id
                 , transaction_reference
                 , transaction_cost				 
                )    
          VALUES    
                ( 
                   ln_transaction_interface_id --  transaction_interface_id
                 , ln_transaction_interface_id --  transaction_header_id
                 , lv_source_code              --  source_code
                 , ln_transaction_interface_id --  source_line_id
                 , ln_transaction_interface_id --  source_header_id
                 , 1                           --  process_flag
                 , 1                           --  validation_required
                 , 2                           --  transaction_mode
                 , 2                           --  lock_flag
                 , SYSDATE                     --  last_update_date
                 , fnd_global.user_id          --  last_updated_by
                 , SYSDATE                     --  creation_date
                 , fnd_global.user_id          --  created_by
                 , ln_inventory_item_id        --  inventory_item_id
                 , ln_organization_id          --  organization_id
                 , ln_qtd_transacionada        --  transaction_quantity
                 , l_item(i).unidade_medida   --  transaction_uom
                 , l_item(i).data_base             --  transaction_date
                 , lv_subinventory_code        --  subinventory_code
                 , ln_distribution_account_id  --  distribution_account_id
                 , ln_transaction_type_id      --  transaction_type_id
                 , 'AJUSTE_prochml_' || TO_CHAR( SYSDATE, 'DD/MM/YYYY HH24:MI:SS' )
                 , ln_transaction_cost
                );

          BEGIN
             --
             -- 'Executando API para transacoes de materiais inv_txn_manager_pub.process_transactions';
             ln_request_id := inv_txn_manager_pub.process_transactions
               (
                 p_api_version   => 1.0                         -- IN
               , p_init_msg_list => fnd_api.g_true              -- IN
               , p_commit        => fnd_api.g_false             -- IN
               , x_return_status => lv_return_status            -- OUT
               , x_msg_count     => ln_msg_count                -- OUT
               , x_msg_data      => lv_msg_data                 -- OUT
               , x_trans_count   => ln_cnt                      -- OUT
               , p_table         => 1                           -- IN
               , p_header_id     => ln_transaction_interface_id -- IN
               )
             ;
             --
             IF lv_return_status IN ('S', 'W') THEN
                
               lv_msg_erro := 'Header - Lines: '||l_item(i).organizacao_oracle||' - '||l_item(i).produto||
                              ' - Movimentacao de material realizada com sucesso. ID da Solicitacao: ' || ln_request_id
               ;
               set_log_p
                 (
                    p_produto     => l_item(i).produto
                  , p_empresa => l_item(i).organizacao_oracle
                  , p_envio_status      => 40
                  , p_envio_erro        => NULL
                 )
               ;
               fnd_file.put_line(fnd_file.log,lv_msg_erro);
               dbms_output.put_line(lv_msg_erro);
               --
             ELSE
               --
               lv_msg_erro := 'Movimentacao de material realizada com erro - ';
               --
               FOR c_regerr IN 
                 (
                   SELECT   error_explanation
                     FROM   mtl_transactions_interface
                   WHERE 1=1
                     AND transaction_interface_id = ln_transaction_interface_id
                 )
               LOOP
                  lv_msg_erro := lv_msg_erro || c_regerr.error_explanation || ' ' || CHR(13) || CHR(10);
               END LOOP;
               --
               set_log_p
                 (
                    p_produto     => l_item(i).produto
                  , p_empresa => l_item(i).organizacao_oracle
                  , p_envio_status      => 30
                  , p_envio_erro        => lv_msg_erro
                 )
               ;
               GOTO PROXIMO;
               --
             END IF;
            --
          END;
          --
          COMMIT;
		  ln_cnt_commit := ln_cnt_commit + 1;
          <<PROXIMO>>
          NULL;
          --
        END LOOP;
        EXIT WHEN l_item.COUNT < ln_limit;
      END LOOP;
    CLOSE c_item;
    --
    COMMIT;
    ln_cnt_commit := ln_cnt_commit + 1;
    --
    -- Totalizar Processamentos com Erro --
    l_item.DELETE;
    OPEN c_item;
      LOOP
        FETCH c_item 
          BULK COLLECT INTO l_item LIMIT ln_limit
        ;
        FOR i IN 1 .. l_item.COUNT LOOP
          SELECT COUNT(*)
            INTO ln_aux
            FROM oracle_estoque_empresas@prochml line
          WHERE 1=1
            AND produto      = l_item(i).produto
            AND empresa  = l_item(i).organizacao_oracle
            AND envio_status       = '30'
          ;
          ln_cnt_error := ln_cnt_error + ln_aux;
        END LOOP;
        EXIT WHEN l_item.COUNT < ln_limit;
      END LOOP;
    CLOSE c_item;
    --
	fnd_file.put_line(fnd_file.log,CHR(13)||'-------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Registros (BARRAMENTO): '||l_item.COUNT); 
    fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Erros:     '||ln_cnt_error); 
    fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------------------'||CHR(13));

    --
    -- Processar os itens sem saldo --
    -- BEGIN
    --   lv_subinventory_code := NULL;
    --   lv_msg_erro          := NULL;
    --   lv_msg_data          := NULL;
    --   lv_header            :=   'transaction_interface_id;transaction_header_id;source_code;request_id;inventory_item_id;'
    --                           ||'organization_id;transaction_date;transaction_quantity;transaction_uom;acct_period_id;'
    --                           ||'subinventory_code;transaction_type_id;distribution_account_id;error_code;error_explanation'
    --   ;
    --   ln_qtd_total_nadata  := 0;
    --   ln_aux               := 0;
    --   ln_cnt               := 0;
    --   ln_cnt_commit        := 0;
    --   ln_msg_count         := 0;
    --   ln_cnt_error         := 0;
    --   SELECT
    --            ood.organization_id
    --          , ood.operating_unit
    --          , msib.inventory_item_id
    --          , msib.primary_uom_code
    --          , (
    --              SELECT data
    --                FROM oracle_estoque_empresas@prochml header
    --              WHERE 1=1
    --                AND ood.organization_code         = header.empresa
    --                AND header.envio_status           = '40'
    --                AND TRUNC(header.envio_data_hora) = TO_DATE('29/01/2019','DD/MM/YYYY')--TRUNC(SYSDATE)
    --            )data
    --     BULK COLLECT INTO
    --            l_organization_id
    --          , l_operating_unit
    --          , l_inventory_item_id
    --          , l_primary_uom_code
    --          , l_data
    --     FROM
    --            mtl_system_items_b               msib
    --          , org_organization_definitions     ood
    --          
    --   WHERE 1=1
    --     AND msib.organization_id          =  ood.organization_id
    --     AND NOT EXISTS
    --       (
    --         SELECT *
    --           FROM   oracle_estoque_empresas@prochml line
    --                , oracle_estoque_empresas@prochml header
    --         WHERE 1=1
    --           AND header.produto          = line.empresa
    --           AND line.empresa          = ood.organization_code
    --           AND line.produto                 = msib.segment1
    --           AND line.envio_status             = '40'
    --           AND header.envio_status           = '40'
    --           AND TRUNC(header.envio_data_hora) = TO_DATE('29/01/2019','DD/MM/YYYY')--TRUNC(SYSDATE)
    --           AND TRUNC(line.envio_data_hora)   = TO_DATE('29/01/2019','DD/MM/YYYY')--TRUNC(SYSDATE)
    --       )
    --     AND msib.inventory_item_id IN (24246, 24249, 473367, 12417)
    --     AND ood.organization_id = 153
    --   ;
    --   -- Seleciona Tipo Transacao --
    --   BEGIN
    --     SELECT 
    --              mtt.transaction_type_id
    --            , mtt.transaction_type_name
    --            , mtst.transaction_source_type_name
    --       INTO
    --              ln_transaction_type_id
    --            , lv_transaction_type_name
    --            , lv_source_code
    --       FROM
    --              mtl_transaction_types mtt
    --            , mtl_txn_source_types  mtst
    --     WHERE 1=1
    --       AND mtst.transaction_source_type_id = mtt.transaction_source_type_id
    --       AND mtt.transaction_type_name        = 'Miscellaneous de Saída'
    --     ;
    --   EXCEPTION
    --     WHEN NO_DATA_FOUND THEN
    --       ln_cnt_error := ln_cnt_error + 1;
    --       lv_msg_erro := 'O Tipo de Transação "Miscellaneous de Saída" não foi localizado. - '||SQLERRM;
    --       fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --       dbms_output.put_line(lv_msg_erro);
    --       RAISE_APPLICATION_ERROR(-20201,lv_msg_erro);
    --     WHEN OTHERS THEN
    --       ln_cnt_error := ln_cnt_error + 1;
    --       lv_msg_erro := 'Seleciona Tipo de Transacao (Miscellaneous Saída) - Error: '||SQLERRM;
    --       fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --       dbms_output.put_line(lv_msg_erro);
    --       RAISE_APPLICATION_ERROR(-20201,lv_msg_erro);
    --   END;
	-- 
    --   ln_aux := l_inventory_item_id.FIRST;
    --   WHILE ln_aux IS NOT NULL LOOP
    --     SAVEPOINT INICIO;
    --     -- Busca da Conta --
    --     BEGIN
    --       SELECT   gcc.code_combination_id
    --         INTO
    --                ln_distribution_account_id
    --         FROM
    --                mtl_parameters       mp
    --              , gl_code_combinations gcc
    --       WHERE 1=1
    --         AND gcc.code_combination_id = mp.material_account
    --         AND mp.organization_id      = l_organization_id(ln_aux)
    --       ;
    --     EXCEPTION
    --       WHEN NO_DATA_FOUND THEN
    --         ln_cnt_error := ln_cnt_error + 1;
    --         lv_msg_erro := 'Conta não foi localizada na Organização '||l_organization_id(ln_aux)||'.';
    --         fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --         dbms_output.put_line(lv_msg_erro);
    --         GOTO PROXIMO;
    --       WHEN OTHERS THEN
    --         ln_cnt_error := ln_cnt_error + 1;
    --         lv_msg_erro := 'Busca da Conta (Organização '||l_organization_id(ln_aux)||') - Error: '||SQLERRM;
    --         fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --         dbms_output.put_line(lv_msg_erro);
    --         GOTO PROXIMO;
    --     END;
    --     -- Indentificar o Saldo na Data Informada
    --     ln_qtd_total_nadata := xxven_inv_utils_pkg.get_stock_quantity_f
    --       (
    --          p_operating_unit    => l_operating_unit(ln_aux)
    --        , p_organization_id   => l_organization_id(ln_aux)
    --        , p_inventory_item_id => l_inventory_item_id(ln_aux)
    --        , p_subinventory      => lv_subinventory_code
    --        , p_dt_retroactive    => l_data(ln_aux)
    --        , p_error             => lv_msg_erro
    --       )
    --     ;
    --     ln_qtd_transacionada := ln_qtd_total_nadata * (-1);
    --     --
    --     IF lv_msg_erro IS NOT NULL THEN
    --       ln_cnt_error := ln_cnt_error + 1;
    --       fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --       dbms_output.put_line(lv_msg_erro);
    --       GOTO PROXIMO;
    --     END IF;
    --     --
    --     SELECT mtl_material_transactions_s.NEXTVAL
    --       INTO ln_transaction_interface_id
    --       FROM dual
    --     ;
    --     --
    --     INSERT INTO mtl_transactions_interface    
    --           (
    --              transaction_interface_id    
    --            , transaction_header_id    
    --            , source_code    
    --            , source_line_id    
    --            , source_header_id    
    --            , process_flag    
    --            , validation_required    
    --            , transaction_mode    
    --            , lock_flag    
    --            , last_update_date    
    --            , last_updated_by    
    --            , creation_date    
    --            , created_by    
    --            , inventory_item_id    
    --            , organization_id    
    --            , transaction_quantity    
    --            , transaction_uom    
    --            , transaction_date    
    --            , subinventory_code    
    --            , distribution_account_id    
    --            , transaction_type_id    
    --           )    
    --     VALUES    
    --           ( 
    --              ln_transaction_interface_id --  transaction_interface_id
    --            , ln_transaction_interface_id --  transaction_header_id
    --            , lv_source_code              --  source_code
    --            , ln_transaction_interface_id --  source_line_id
    --            , ln_transaction_interface_id --  source_header_id
    --            , 1                           --  process_flag
    --            , 1                           --  validation_required
    --            , 2                           --  transaction_mode
    --            , 2                           --  lock_flag
    --            , SYSDATE                     --  last_update_date
    --            , fnd_global.user_id          --  last_updated_by
    --            , SYSDATE                     --  creation_date
    --            , fnd_global.user_id          --  created_by
    --            , l_inventory_item_id(ln_aux) --  inventory_item_id
    --            , l_organization_id(ln_aux)   --  organization_id
    --            , ln_qtd_transacionada        --  transaction_quantity
    --            , l_primary_uom_code(ln_aux)  --  transaction_uom
    --            , l_data(ln_aux)              --  transaction_date
    --            , lv_subinventory_code        --  subinventory_code
    --            , ln_distribution_account_id  --  distribution_account_id
    --            , ln_transaction_type_id      --  transaction_type_id
    --           );
    --     
    --     BEGIN
    --        --
    --        -- 'Executando API para transacoes de materiais inv_txn_manager_pub.process_transactions';
    --        ln_request_id := inv_txn_manager_pub.process_transactions
    --          (
    --            p_api_version   => 1.0                         -- IN
    --          , p_init_msg_list => fnd_api.g_true              -- IN
    --          , p_commit        => fnd_api.g_false             -- IN
    --          , x_return_status => lv_return_status            -- OUT
    --          , x_msg_count     => ln_msg_count                -- OUT
    --          , x_msg_data      => lv_msg_data                 -- OUT
    --          , x_trans_count   => ln_cnt                      -- OUT
    --          , p_table         => 1                           -- IN
    --          , p_header_id     => ln_transaction_interface_id -- IN
    --          )
    --        ;
    --        --
    --        IF lv_return_status IN ('S', 'W') THEN
    --          INSERT INTO xxven_inv_bkpitem_nobalance
    --            SELECT   
    --                     mti.transaction_interface_id
    --                   , mti.transaction_header_id
    --                   , mti.source_code
    --                   , mti.request_id
    --                   , mti.inventory_item_id
    --                   , mti.organization_id
    --                   , mti.transaction_date
    --                   , mti.transaction_quantity
    --                   , mti.transaction_uom
    --                   , mti.acct_period_id
    --                   , mti.subinventory_code
    --                   , mti.transaction_type_id
    --                   , mti.distribution_account_id
    --                   , mti.error_code
    --                   , mti.error_explanation
    --                   , SYSDATE
    --                   , fnd_global.user_id
    --                   , SYSDATE
    --                   , fnd_global.user_id
    --              FROM   mtl_transactions_interface
    --            WHERE 1=1
    --              AND transaction_interface_id = ln_transaction_interface_id
    --          ;
    --          lv_msg_erro := 'Movimentacao de Material Realizada com Sucesso. ID da Solicitacao: ' || ln_request_id||
    --                         ' - Organização - Item:  '||l_organization_id(ln_aux)||' - '||l_inventory_item_id(ln_aux)||
    --                         'Quantidade Movimentada: '||ln_qtd_transacionada
    --                         
    --          ;
    --          fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --          dbms_output.put_line(lv_msg_erro);
    --          --
    --        ELSE
    --          ln_cnt_error := ln_cnt_error + 1;
    --          --
    --          lv_msg_erro := 'Movimentacao de material realizada com erro - transaction_interface_id: '||ln_transaction_interface_id;
    --          fnd_file.put_line(fnd_file.log, lv_msg_erro);
    --          dbms_output.put_line(lv_msg_erro);
    --          --             
    --          INSERT INTO xxven_inv_bkpitem_nobalance
    --            SELECT   
    --                     mti.transaction_interface_id
    --                   , mti.transaction_header_id
    --                   , mti.source_code
    --                   , mti.request_id
    --                   , mti.inventory_item_id
    --                   , mti.organization_id
    --                   , mti.transaction_date
    --                   , mti.transaction_quantity
    --                   , mti.transaction_uom
    --                   , mti.acct_period_id
    --                   , mti.subinventory_code
    --                   , mti.transaction_type_id
    --                   , mti.distribution_account_id
    --                   , mti.error_code
    --                   , mti.error_explanation
    --                   , SYSDATE
    --                   , fnd_global.user_id
    --                   , SYSDATE
    --                   , fnd_global.user_id
    --              FROM   mtl_transactions_interface mti
    --            WHERE 1=1
    --              AND transaction_interface_id = ln_transaction_interface_id
    --          ;
    --          COMMIT;
    --          GOTO PROXIMO;
    --          --
    --        END IF;
    --       --
    --     EXCEPTION
    --       WHEN OTHERS THEN
    --         ln_cnt_error := ln_cnt_error + 1;
    --         lv_msg_erro := 'Erro Inesperado no Bloco de Execução da API de Transações de Materiais! - ERROR: '||SQLERRM;
    --         fnd_file.put_line(fnd_file.log, lv_msg_erro ||CHR(13));
    --         dbms_output.put_line(lv_msg_erro ||CHR(13));
    --     END;
    --     --
    --     COMMIT;
    --     ln_cnt_commit := ln_cnt_commit + 1;
	--   
    --     <<PROXIMO>>
    --     ln_aux := l_inventory_item_id.NEXT(ln_aux);
    --     NULL;
    --   END LOOP;
	-- 
    -- EXCEPTION
    --   WHEN OTHERS THEN
    --     lv_msg_erro := 'Erro Inesperado Durante o Processamento do Bloco de Processamento dos Itens Sem Saldo! - ERROR: '||SQLERRM;
    --     RAISE_APPLICATION_ERROR(-20202, lv_msg_erro);
    -- END;
	
    dbms_output.put_line( 'Finalizado em: '||((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
    fnd_file.put_line (fnd_file.log, 'Finalizado em: '||((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
	-- fnd_file.put_line(fnd_file.log,CHR(13)||'-------------------------------------------------------------------------------');
    -- fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Registros - BARRAMENTO não Informou: '||l_inventory_item_id.COUNT); 
    -- fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Erros:     '||ln_cnt_error); 
    -- fnd_file.put_line(fnd_file.log,CHR(13)||'    Fim Atualização dos Estoques   ');
    fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------------------'||CHR(13));
  END UPDATE_BALANCE_P;
  --
END XXVEN_INV_CST_UPDT_PKG;
/
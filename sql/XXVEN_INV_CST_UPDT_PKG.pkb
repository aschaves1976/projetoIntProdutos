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
  -- |   ...                                                           |
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
     , p_status        IN VARCHAR2
     , p_description   IN VARCHAR2
    )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    lv_msg   VARCHAR2(32000);
  BEGIN
    BEGIN
      INSERT INTO XXVEN_INV_BALANCE_LOG_TB
      VALUES
        (p_produto, p_empresa, SYSDATE, p_status, p_description
        )
      ;
      COMMIT;
    END;
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
        AND PRODUTO            = '29088'
        AND ORGANIZACAO_ORACLE = '083'
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
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação da Organização '||l_item(i).organizacao_oracle||' - Error: '|| SQLERRM;
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
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
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação do Subinventário '||l_item(i).sub_inventario||' - Error: '|| SQLERRM;
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
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
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Validação Item '||l_item(i).produto||' Associado a Organização '||ln_organization_id||' - Error: '|| SQLERRM;
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
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
                  AND mtt.transaction_type_name        = 'Miscellaneous receipt'
                ;
                ln_transaction_cost := l_item(i).custo_unitario;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_msg_erro := 'O Tipo de Transação "Miscellaneous Entrada" não foi localizado.';
                  retcode := 1;
                  set_log_p
                    (
                       p_produto       => ln_inventory_item_id
                     , p_empresa       => ln_organization_id
                     , p_status        => 'E'
                     , p_description   => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
                WHEN OTHERS THEN
                  lv_msg_erro := 'Seleciona Tipo de Transacao (Miscellaneous Entrada) - Error: '||SQLERRM;
                  retcode := 1;
                  set_log_p
                    (
                       p_produto       => ln_inventory_item_id
                     , p_empresa       => ln_organization_id
                     , p_status        => 'E'
                     , p_description   => lv_msg_erro
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
                  AND mtt.transaction_type_name        = 'Miscellaneous issue'
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_msg_erro := 'O Tipo de Transação "Miscellaneous de Saída" não foi localizado.';
                  retcode := 1;
                  set_log_p
                    (
                       p_produto       => ln_inventory_item_id
                     , p_empresa       => ln_organization_id
                     , p_status        => 'E'
                     , p_description   => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
                WHEN OTHERS THEN
                  lv_msg_erro := 'Seleciona Tipo de Transacao (Miscellaneous Saída) - Error: '||SQLERRM;
                  retcode := 1;
                  set_log_p
                    (
                       p_produto       => ln_inventory_item_id
                     , p_empresa       => ln_organization_id
                     , p_status        => 'E'
                     , p_description   => lv_msg_erro
                    )
                  ;
                  GOTO PROXIMO;
              END;
            END IF;
          ELSE
            retcode := 1;
            set_log_p
              (
                 p_produto       => ln_inventory_item_id
               , p_empresa       => ln_organization_id
               , p_status        => 'E'
               , p_description   => lv_msg_erro
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
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
                )
              ;
              GOTO PROXIMO;
            WHEN OTHERS THEN
              lv_msg_erro := 'Busca da Conta (Organização '||ln_organization_id||') - Error: '||SQLERRM;
              retcode := 1;
              set_log_p
                (
                   p_produto       => ln_inventory_item_id
                 , p_empresa       => ln_organization_id
                 , p_status        => 'E'
                 , p_description   => lv_msg_erro
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
                 , 'AJUSTE_PROCFIT_' || TO_CHAR( SYSDATE, 'DD/MM/YYYY HH24:MI:SS' )
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

               lv_msg_erro := 'Organização: '||l_item(i).organizacao_oracle||' - Produto: '||l_item(i).produto||
                              ' - Movimentacao de material realizada com sucesso. ID da Solicitacao: ' || ln_request_id
               ;
               set_log_p
                 (
                    p_produto       => ln_inventory_item_id
                  , p_empresa       => ln_organization_id
                  , p_status        => 'S'
                  , p_description   => lv_msg_erro
                 )
               ;
               --
             ELSE
               --
               lv_msg_erro := 'Movimentacao de material realizada com erro - transaction_interface_id = '|| ln_transaction_interface_id || ' -> ';
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
               retcode := 1;
               set_log_p
                 (
                    p_produto       => ln_inventory_item_id
                  , p_empresa       => ln_organization_id
                  , p_status        => 'E'
                  , p_description   => lv_msg_erro
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
          IF ln_cnt_error > 0 THEN
            retcode := 1;
          END IF;
        END LOOP;
        EXIT WHEN l_item.COUNT < ln_limit;
      END LOOP;
    CLOSE c_item;
    --
    fnd_file.put_line(fnd_file.log,CHR(13)||'-------------------------------------------------------------------------------');
    fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Registros (BARRAMENTO): '||l_item.COUNT); 
    fnd_file.put_line(fnd_file.log,CHR(13)||' Total de Erros:     '||ln_cnt_error); 
    fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------------------'||CHR(13));

    dbms_output.put_line( 'Finalizado em: '||((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
    fnd_file.put_line (fnd_file.log, 'Finalizado em: '||((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
    fnd_file.put_line(fnd_file.log,'-------------------------------------------------------------------------------'||CHR(13));
  END UPDATE_BALANCE_P;
  --
END XXVEN_INV_CST_UPDT_PKG;
/
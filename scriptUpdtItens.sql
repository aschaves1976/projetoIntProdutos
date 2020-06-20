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
  CURSOR c_sup IS
    SELECT
             inventory_item_id
           , item
           , ncm
           , ipi
           , icms
           , cest
           , fabrica_propria
           , fabricante
           , marca_gc
      FROM xxven_carga_items_tb cust
    WHERE 1=1
      --AND inventory_item_id = 11521
	  AND TRUNC(creation_date) = TRUNC(SYSDATE)
  ;

  TYPE lt_inventory_item_id            IS TABLE OF xxven_carga_items_tb.inventory_item_id%TYPE   INDEX BY PLS_INTEGER;
  TYPE lt_item                         IS TABLE OF xxven_carga_items_tb.item%TYPE                INDEX BY PLS_INTEGER;
  TYPE lt_ncm                          IS TABLE OF xxven_carga_items_tb.ncm%TYPE                 INDEX BY PLS_INTEGER;
  TYPE lt_ipi                          IS TABLE OF xxven_carga_items_tb.ipi%TYPE                 INDEX BY PLS_INTEGER;
  TYPE lt_icms                         IS TABLE OF xxven_carga_items_tb.icms%TYPE                INDEX BY PLS_INTEGER;
  TYPE lt_cest                         IS TABLE OF xxven_carga_items_tb.cest%TYPE                INDEX BY PLS_INTEGER;
  TYPE lt_fabrica_propria              IS TABLE OF xxven_carga_items_tb.fabrica_propria%TYPE     INDEX BY PLS_INTEGER;
  TYPE lt_fabricante                   IS TABLE OF xxven_carga_items_tb.fabricante%TYPE          INDEX BY PLS_INTEGER;
  TYPE lt_marca_gc                     IS TABLE OF xxven_carga_items_tb.marca_gc%TYPE            INDEX BY PLS_INTEGER;

  l_inventory_item_id                  lt_inventory_item_id;
  l_item                               lt_item;
  l_ncm                                lt_ncm;
  l_ipi                                lt_ipi;
  l_icms                               lt_icms;
  l_cest                               lt_cest;
  l_fabrica_propria                    lt_fabrica_propria;
  l_fabricante                         lt_fabricante;
  l_marca_gc                           lt_marca_gc;
  l_retencao_receita                   lt_fabricante;
  l_venda_controlada                   lt_fabricante;
  l_uso_contínuo                       lt_fabricante;
  l_registro_ms                        lt_fabricante;

  
  ln_limit                  PLS_INTEGER := 100;
  ln_cnt                    PLS_INTEGER := 0;
  ln_counter                PLS_INTEGER := 0;

  ln_msg_count              PLS_INTEGER;
  ln_time                   NUMBER;
  lv_error_msg              VARCHAR2(32000);

  ln_structure_id           mtl_category_sets.structure_id%TYPE;
  ln_category_set_id        mtl_category_sets.category_set_id%TYPE;
  ln_category_id            mtl_categories_b.category_id%TYPE;
  
  lv_return_status VARCHAR2(1) := NULL;
  ln_msg_count     NUMBER := 0;
  lv_msg_data      VARCHAR2(32000);
  ln_errorcode     NUMBER;

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
    --l_category_updt_rec      inv_item_category_pub.category_rec_type;
  
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
              dbms_output.put_line('Category Id: ' || p_category_id || 'não localizada. - ' || SQLERRM);
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
      DBMS_OUTPUT.PUT_LINE(   'CATEGORY_P - ERRO SÚBITO: p_inventory_item_id: '||p_inventory_item_id||' p_category_id: '||p_category_id||' p_category_set_id: '||p_category_set_id
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
    OPEN c_sup;
      LOOP
       FETCH c_sup
         BULK COLLECT INTO
              l_inventory_item_id
            , l_item
            , l_ncm
            , l_ipi
            , l_icms
            , l_cest
            , l_fabrica_propria
            , l_fabricante
            , l_marca_gc
       LIMIT ln_limit
       ;
       ln_counter := l_inventory_item_id.FIRST;
       WHILE ln_counter IS NOT NULL LOOP
         ln_cnt := ln_cnt + 1;
         SAVEPOINT INICIO;

         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - UPDATE   mtl_system_items_b   msib
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   SET
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -          msib.attribute18        = l_ipi(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -        , msib.attribute17        = l_icms(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -        , msib.attribute19        = l_fabrica_propria(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -        , msib.global_attribute9  = l_cest(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -        , msib.attribute6         = l_registro_ms(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -        , msib.last_update_date   = SYSDATE
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - WHERE 1=1
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   AND msib.inventory_item_id     = l_inventory_item_id(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   AND msib.organization_id       = 174
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - ;
         --
         -- Marca GC -- 
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_inventory_item_id(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Marca GC'
             , p_name_to_create     => l_marca_gc(ln_counter)
           )
         ;
         --
         -- Fabricante --
         category_p
           (
               p_category_id        => ln_category_id
             , p_structure_id       => ln_structure_id
             , p_category_set_id    => ln_category_set_id
             , p_inventory_item_id  => l_inventory_item_id(ln_counter)
             , p_organization_id    => 174
             , p_category_set_name  => 'Fabricante'
             , p_name_to_create     => l_fabricante(ln_counter)
           )
         ;
         --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - -- Retencao de Receita --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - category_p
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   (
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -       p_category_id        => ln_category_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_structure_id       => ln_structure_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_id    => ln_category_set_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_inventory_item_id  => l_inventory_item_id(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_organization_id    => 174
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_name  => 'Retenção Receita'
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_name_to_create     => l_retencao_receita(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   )
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - ;
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - -- Venda Controlada --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - category_p
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   (
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -       p_category_id        => ln_category_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_structure_id       => ln_structure_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_id    => ln_category_set_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_inventory_item_id  => l_inventory_item_id(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_organization_id    => 174
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_name  => 'Venda Controlada'
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_name_to_create     => l_venda_controlada(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   )
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - ;
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - -- Uso Contínuo --
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - category_p
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   (
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -       p_category_id        => ln_category_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_structure_id       => ln_structure_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_id    => ln_category_set_id
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_inventory_item_id  => l_inventory_item_id(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_organization_id    => 174
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_category_set_name  => 'Uso Contínuo'
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -     , p_name_to_create     => l_uso_contínuo(ln_counter)
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC -   )
         -- ASChaves - 20200620 - Esta carga é somente para Fabricante e Marca GC - ;
         --
		 COMMIT;
         <<PROXIMO>>
         ln_counter := l_inventory_item_id.NEXT(ln_counter);
         NULL;
       END LOOP;
       EXIT WHEN l_inventory_item_id.COUNT < ln_limit;
     END LOOP;
    CLOSE c_sup;
    dbms_output.put_line( 'End Time...........: ' || TO_CHAR( SYSDATE,'DD/MM/RR HH24:MI:SS' ) || ' - ' || ((dbms_utility.get_time - ln_time)/100) || ' seconds....' );
    dbms_output.put_line(' ');
  END;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(' ERRO SÚBITO: ' || SQLERRM); 
END;
--
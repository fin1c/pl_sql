
CREATE OR REPLACE PROCEDURE copy_table(
                                        p_source_scheme IN VARCHAR2,
                                        p_target_scheme IN VARCHAR2 DEFAULT USER,
                                        p_list_table    IN VARCHAR2,
                                        p_copy_data     IN BOOLEAN DEFAULT FALSE,
                                        po_result       OUT VARCHAR2
                                    ) AS


    v_sql_code             VARCHAR2(4000);
    v_proc_name            VARCHAR2(20) := 'copy_table';
    v_count_exist_table    NUMBER;

  
    CURSOR cursor_table IS
        SELECT table_name,
               'CREATE TABLE ' || p_target_scheme || '.' || table_name || ' (' ||
                       LISTAGG(column_name || ' ' || data_type || count_symbol, ', ')
                       WITHIN GROUP (ORDER BY column_id) || ')' AS ddl_code
        FROM (
             SELECT  table_name,
                     column_name,
                     data_type,
                     CASE
                         WHEN data_type IN ('VARCHAR2', 'CHAR') THEN '(' || data_length || ')'
                         WHEN data_type = 'DATE' THEN NULL
                         WHEN data_type = 'NUMBER' THEN REPLACE('(' || data_precision || ',' || data_scale || ')', '(,)', NULL)
                     END AS count_symbol,
                     column_id
              FROM all_tab_columns
              WHERE owner = UPPER(p_source_scheme) 
              AND table_name IN (
                                 SELECT UPPER(value_list) 
                                 FROM TABLE(util.table_from_list(p_list_val => p_list_table)))
              )
        GROUP BY table_name;
        
        
        PROCEDURE do_create_table(p_sql_code IN VARCHAR2) IS
                  PRAGMA AUTONOMOUS_TRANSACTION;
              BEGIN
                  EXECUTE IMMEDIATE p_sql_code;
                  COMMIT;
              EXCEPTION
                  WHEN OTHERS THEN
                      log_util.log_error(v_proc_name, SQLERRM, 'Помилка при створенні таблиці');
                  ROLLBACK;
        END do_create_table;
        
BEGIN

    log_util.log_start(v_proc_name, 'Початок копіювання таблиці та даних.');


    FOR cc IN cursor_table LOOP

        SELECT COUNT(*) 
        INTO v_count_exist_table
        FROM all_tables
        WHERE owner = p_target_scheme 
              AND table_name = cc.table_name;

        IF v_count_exist_table = 0 THEN
            BEGIN

                do_create_table(p_sql_code => cc.ddl_code);
                
                log_util.log_finish(v_proc_name, 'Створена таблиця: ' || cc.table_name);


                IF p_copy_data THEN
                    v_sql_code := 'INSERT INTO ' || p_target_scheme || '.' || cc.table_name ||
                                  ' SELECT * FROM ' || p_source_scheme || '.' || cc.table_name;
                    EXECUTE IMMEDIATE v_sql_code;
                    log_util.log_finish(v_proc_name, 'Дані скопіювалися: ' || cc.table_name);
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    log_util.log_error(v_proc_name, SQLERRM, 'Помилка при процесі копіюванні таблиці: ' || cc.table_name);
                    CONTINUE;
            END;
        ELSE
            log_util.log_finish(v_proc_name, 'Таблиця вже існує: ' || cc.table_name);
        END IF;
    END LOOP;


    log_util.log_finish(v_proc_name, 'Процедура завершена');
    po_result := 'Копіювання завершено';
EXCEPTION
    WHEN OTHERS THEN
        po_result := 'Помилка: ' || SQLERRM;
        log_util.log_error(v_proc_name, SQLERRM, 'Помилка в процедурі (не зазначена)');


END copy_table;

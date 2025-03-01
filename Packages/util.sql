--------SPECIFICATION


CREATE OR REPLACE PACKAGE util AS


      --FUNCTION

    TYPE rec_value_list IS RECORD (value_list VARCHAR2(100));
    TYPE tab_value_list IS TABLE OF rec_value_list;



    FUNCTION table_from_list (p_list_val IN VARCHAR2,
                                  p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED;

----------------------------------------------------------------------------

=====================================================
======================================================

      --PROCEDURE

      PROCEDURE api_nbu_sync;


--------------------------------------------------------------------     

     PROCEDURE change_attribute_employee (p_employee_id IN NUMBER,
                                        p_first_name IN VARCHAR2 DEFAULT NULL,
                                        p_last_name IN VARCHAR2 DEFAULT NULL,
                                        p_email IN VARCHAR2 DEFAULT NULL,
                                        p_phone_number IN VARCHAR2 DEFAULT NULL,
                                        p_job_id IN VARCHAR2 DEFAULT NULL,
                                        p_salary IN NUMBER DEFAULT NULL,
                                        p_commission_pct IN NUMBER DEFAULT NULL,
                                        p_manager_id IN NUMBER DEFAULT NULL,
                                        p_department_id IN NUMBER DEFAULT NULL
                                        );
----------------------------------------------------------------

     PROCEDURE fire_an_employee (p_employee_id IN NUMBER); 

-----------------------------------------------------------    

    PROCEDURE add_employee (p_first_name IN VARCHAR2,
                            p_last_name IN VARCHAR2,
                            p_email IN VARCHAR2,
                            p_phone_number IN VARCHAR2,
                            p_hire_date IN DATE DEFAULT TRUNC(SYSDATE, 'DD'),
                            p_job_id IN VARCHAR2,
                            p_salary IN NUMBER,
                            p_commission_pct IN NUMBER DEFAULT NULL,
                            p_manager_id IN NUMBER DEFAULT 100,
                            p_department_id IN NUMBER);                                               
                                          

END util;



===========
============
=======-BODY


CREATE OR REPLACE PACKAGE BODY util AS

 --FUNCTION

        FUNCTION table_from_list (p_list_val IN VARCHAR2,
                                  p_separator IN VARCHAR2 DEFAULT ',') RETURN tab_value_list PIPELINED IS
                                  
                out_rec  tab_value_list := tab_value_list(); -- ініцілізація змінної   
                l_cur SYS_REFCURSOR;
        BEGIN
        
            OPEN  l_cur FOR
            
                SELECT TRIM(REGEXP_SUBSTR(p_list_val, '[^'||p_separator||']+', 1, LEVEL)) AS cur_value
                FROM dual
                CONNECT BY LEVEL <= REGEXP_COUNT(p_list_val, p_separator) + 1;
                
                BEGIN
                
                    LOOP                                           
                        EXIT WHEN l_cur%NOTFOUND;
                        FETCH l_cur BULK COLLECT
                            INTO out_rec;
                        FOR i IN 1.. out_rec.count LOOP
                            PIPE ROW(out_rec(i));
                        END LOOP;    
                    END LOOP;
                    CLOSE l_cur;
                
                EXCEPTION WHEN OTHERS THEN
                    IF (l_cur%ISOPEN) THEN 
                        CLOSE l_cur;
                        RAISE;
                    ELSE
                        RAISE;
                    END IF;    
                END;
            
        
        END table_from_list;
     
===============================================================        
==============================================================-
        
--PROCEDURE  

    PROCEDURE api_nbu_sync IS
               
                v_list_currencies  VARCHAR2(1000);
                
                
             CURSOR cursor_val IS   
                    SELECT value_list AS curr 
                    FROM TABLE(util.table_from_list(p_list_val => v_list_currencies));
                    
             BEGIN
                  BEGIN
                    SELECT value_text
                    INTO v_list_currencies
                    FROM andriyi_9wd.sys_params
                    WHERE param_name = 'list_currencies';
                    
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                           andriyi_9wd.log_util.log_error(p_proc_name => 'api_nbu_sync', 
                                                          p_sqlerrm => SQLERRM, 
                                                          p_text => 'Список валют не знайдено');
                           raise_application_error(-20001, 'Список валют не знайдено: ' || SQLERRM);
                           
                     WHEN OTHERS THEN
                           andriyi_9wd.log_util.log_error(p_proc_name => 'api_nbu_sync', 
                                                          p_sqlerrm => SQLERRM, 
                                                          p_text => 'Помилка при при отриманні даних з таблиці');
                           raise_application_error(-20001, 'Помилка при при отриманні даних з таблиці: ' || SQLERRM);
                  END;    
              
              FOR c IN cursor_val LOOP
                   BEGIN
                        INSERT INTO andriyi_9wd.cur_exchange (r030, txt, rate, cur, exchangedate)
                        SELECT r030, txt, rate, cur, exchangedate
                        FROM TABLE(util.get_currency(p_currency => c.curr));
                 
                   EXCEPTION
                    WHEN OTHERS THEN
                         andriyi_9wd.log_util.log_error(p_proc_name => 'api_nbu_sync', 
                                                        p_sqlerrm => SQLERRM, 
                                                        p_text =>  'Помилка додавання даних ');
                         raise_application_error(-20001, 'Помилка додавання даних : ' || SQLERRM);
                  END;
              END LOOP;

             log_util.log_finish('Оновлення крсу валют завершено');
          

             EXCEPTION
               WHEN OTHERS THEN
                  andriyi_9wd.log_util.log_error(p_proc_name => 'api_nbu_sync', 
                                                 p_sqlerrm => SQLERRM, 
                                                 p_text =>  'Помилка в процедурі api_nbu_sync : ');
                  raise_application_error(-20001, 'Помилка в процедурі api_nbu_sync : ' || SQLERRM);           
             
             
             END api_nbu_sync;


     
----------------------------------------------------------------------
   PROCEDURE change_attribute_employee (p_employee_id IN NUMBER,
                                        p_first_name IN VARCHAR2 DEFAULT NULL,
                                        p_last_name IN VARCHAR2 DEFAULT NULL,
                                        p_email IN VARCHAR2 DEFAULT NULL,
                                        p_phone_number IN VARCHAR2 DEFAULT NULL,
                                        p_job_id IN VARCHAR2 DEFAULT NULL,
                                        p_salary IN NUMBER DEFAULT NULL,
                                        p_commission_pct IN NUMBER DEFAULT NULL,
                                        p_manager_id IN NUMBER DEFAULT NULL,
                                        p_department_id IN NUMBER DEFAULT NULL) IS
                                        
                 
                 v_request_update_parametr  VARCHAR2(2000);
                                                         
                 BEGIN
                 -- Викликати  процедуру log_util.log_start
             
                    andriyi_9wd.log_util.log_start (p_proc_name => 'change_attribute_employee', 
                                                    p_text => 'Оновлення даних по співробітнику');
                    
                 -- Перевірити, що мінімум в одному параметрі (окрім p_employee_id) є значення НЕ NULL,
                 -- інакше помилка і виклик процедури log_util.log_finish.  
                      
                    IF p_first_name IS NULL AND
                       p_last_name IS NULL AND
                       p_email IS NULL AND
                       p_phone_number  IS NULL AND
                       p_job_id  IS NULL AND
                       p_salary  IS NULL AND
                       p_commission_pct  IS NULL AND
                       p_manager_id  IS NULL AND
                       p_department_id  IS NULL THEN
                       
                    log_util.log_finish (p_proc_name => 'change_attribute_employee',
                                         p_text => 'Немає жодного параметру для оновлення атрибутів.');  
                    raise_application_error(-20001, 'Немає жодного параметру для оновлення атрибутів.');
                    
                    END IF;   
                    
                 -- Перевіряти який з вхідних параметрів не пустий і для такого параметра зробити UPDATE в таблиці employees.
                 -- Механізм продумати самостійно. Бажано зробити через дінамічний SQL. Але для першого варіанта цієї процедуру підійде варіант через IF..ELSIF..END IF на кожний вхідний параметр. 
                    
                     v_request_update_parametr := 'UPDATE andriyi_9wd.employees SET '; 
                 
                     IF p_first_name IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'first_name = ''' || p_first_name || ''', ';
                     END IF;
                     
                     IF p_last_name IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'last_name = ''' || p_last_name || ''', ';
                     END IF;
                     
                     IF p_email IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'email = ''' || p_email || ''', ';
                     END IF; 
                     
                     IF p_phone_number IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'phone_number = ''' || p_phone_number || ''', ';
                     END IF;                    
                     
                     IF p_job_id IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'job_id = ''' || p_job_id || ''', ';
                     END IF; 
                     
                     IF p_salary IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'salary = ' || p_salary || ', ';
                     END IF;
                     
                     IF p_commission_pct IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'commission_pct = ' || p_commission_pct || ', ';
                     END IF;  
                     
                     IF p_manager_id IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'manager_id = ' || p_manager_id || ', ';
                     END IF; 
                     
                     IF p_department_id IS NOT NULL THEN
                        v_request_update_parametr := v_request_update_parametr || 'department_id = ' || p_department_id || ', ';
                     END IF;                   
                     
                     v_request_update_parametr := RTRIM(v_request_update_parametr, ', ') || ' WHERE employee_id = ' || p_employee_id;
                 
             
                    
                     BEGIN
                        EXECUTE IMMEDIATE v_request_update_parametr;
                        
                        IF SQL%ROWCOUNT > 0 THEN
                          dbms_output.put_line('У співробітника ' || p_employee_id || ' успішно оновлені артібути.');
                          ELSE
                          raise_application_error(-20001, 'Немає даних для оновлення атрибутів співробітника' || p_employee_id) ;
                          log_util.log_finish (p_proc_name => 'change_attribute_employee',
                                         p_text => 'Немає жодного параметру для оновлення атрибутів.');
                        END IF;
                        
                        EXCEPTION
                           WHEN OTHERS THEN
                           andriyi_9wd.log_util.log_error(p_proc_name => 'change_attribute_employee', 
                                                          p_sqlerrm => SQLERRM, 
                                                          p_text => 'Помилка при оновленні атрибутів');
                           raise_application_error(-20001, 'Помилка при оновленні атрибутів: ' || SQLERRM);
                      END;

                 END change_attribute_employee;

----------------------------------------------------------------------------------------------------------------------------------

        PROCEDURE work_day_time IS
             -- Процедура перевіряє день та час при додаванні чи видаленні працівника. 
             -- Не можна додаввати чи видаляти співробітника у суботу та неділю, а також з 18:01 до 07:59.   
             
             work_day VARCHAR2(10);
             work_time VARCHAR2(10);
             
        BEGIN
             
             work_day  := TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN');
             work_time := TO_CHAR(SYSDATE, 'HH24:MI:SS');
             
                        
             IF work_day IN ('SAT', 'SUN') OR
                work_time NOT BETWEEN '08:00:00' AND '18:00:00' THEN
                raise_application_error (-20001, 'Ви можете додавати чи видаляти співробітника лише в робочий час');
             END IF; 
             
        END work_day_time;

-----------------------------------------------------------------------------------------------    

      PROCEDURE fire_an_employee (p_employee_id IN NUMBER) IS
         
       
             v_text_log_finish       VARCHAR(200);
             v_first_name      andriyi_9wd.employees.first_name%TYPE;
             v_last_name       andriyi_9wd.employees.last_name%TYPE;
             v_job_id          andriyi_9wd.employees.job_id%TYPE;
             v_department_id   andriyi_9wd.employees.department_id%TYPE;
             v_hire_date       andriyi_9wd.employees.hire_date%TYPE;
             v_salary          andriyi_9wd.employees.salary%TYPE;
         
       BEGIN 
         
       -- Викликати  процедуру log_util.log_start
             
             andriyi_9wd.log_util.log_start (p_proc_name => 'fire_an_employee');
             
      -- Процедура перевіряє день та час при додаванні чи видаленні працівника. 
      -- Не можна додаввати чи видаляти співробітника у суботу та неділю, а також з 18:00 до 08:00.     
        
             work_day_time; 
         
         -- Перевіряти чи існує p_employee_id, що передається в таблиці EMPLOYEES. 
         -- Якщо передали не існуючий ід співробітника, тоді помилка - RAISE_APPLICATION_ERROR(-20001,'Переданий співробітник не існує ')
            
             BEGIN
                 SELECT em.first_name,
                        em.last_name,
                        em.job_id,
                        em.department_id,
                        em.hire_date,
                        em.salary
                 INTO v_first_name,
                      v_last_name,
                      v_job_id,
                      v_department_id,
                      v_hire_date,
                      v_salary
                 FROM andriyi_9wd.employees em
                 WHERE em.employee_id = p_employee_id; 
                 
                 EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                        raise_application_error (-20001, 'Переданий співробітник не існує');
             END;
                   
         -- Блок видалення спвробітника   
             BEGIN            
             
                 DELETE FROM andriyi_9wd.employees em
                        WHERE em.employee_id = p_employee_id;
                                                         
                 EXCEPTION
                 WHEN OTHERS THEN
                    
                    andriyi_9wd.log_util.log_error(p_proc_name => 'fire_an_employee',
                                                   p_sqlerrm => SQLERRM);
              END;  
                                                 
              v_text_log_finish := 'Співробітник ' || v_first_name || ', ' || v_last_name || 
                                    ', ' || v_job_id || ', ' || v_department_id || ' успішно звільнений із системи';
              
          -- Записати дані в історичну таблицю employees_history.
              BEGIN            
          
                 INSERT INTO andriyi_9wd.employees_history (
                                         employee_id, first_name, last_name, hire_date, job_id, salary, department_id, dismissal_date
                                         ) 
                                  VALUES (
                                          p_employee_id, v_first_name, v_last_name,
                                          v_hire_date, v_job_id, v_salary, v_department_id, TO_DATE(SYSDATE, 'DD.MM.YYYY')
                                          );
                                 
                 EXCEPTION
                 WHEN OTHERS THEN
                    
                    andriyi_9wd.log_util.log_error(p_proc_name => 'fire_an_employee',
                                                   p_sqlerrm => SQLERRM);
              
              END;            
              
              
              
              
              andriyi_9wd.log_util.log_finish(p_proc_name => 'fire_an_employee',
                                              p_text => v_text_log_finish);
              
              COMMIT;
                                             
             
       END fire_an_employee; 

---------------------------------------------------------------------------------------------------


PROCEDURE add_employee (p_first_name IN VARCHAR2,
                               p_last_name IN VARCHAR2,
                               p_email IN VARCHAR2,
                               p_phone_number IN VARCHAR2,
                               p_hire_date IN DATE DEFAULT TRUNC(SYSDATE, 'DD'),
                               p_job_id IN VARCHAR2,
                               p_salary IN NUMBER,
                               p_commission_pct IN NUMBER DEFAULT NULL,
                               p_manager_id IN NUMBER DEFAULT 100,
                               p_department_id IN NUMBER) IS
                               
               PRAGMA autonomous_transaction; --EMPLOYEE_ID + 1 (за рахунок сіквенса)

        
               v_count_jobs_id         NUMBER;
               v_count_department_id   NUMBER;
               v_count_jobs_salary     NUMBER;
               v_text_log_finish       VARCHAR(200);
      

         BEGIN
           
         -- Викликати  процедуру log_util.log_start
             
             andriyi_9wd.log_util.log_start (p_proc_name => 'add_employee');
         
         -- Перевірити день і час при вставці. Неможливо додавати нового співробітника у суботу і неділю, а також з 18:01 до 07:59. 
         -- Якщо нового співробітника додають у недозволений час, викликати помилку - RAISE_APPLICATION_ERROR(-20001,'Ви можете додавати нового співробітника лише в робочий час').
             
             IF TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN') IN ('SAT', 'SUN') OR
                TO_CHAR(SYSDATE, 'HH24:MI:SS') NOT BETWEEN '08:00:00' AND '18:00:00' THEN
                raise_application_error (-20001, 'Ви можете додавати нового співробітника лише в робочий час');
             END IF;
             
         -- Перевірити, чи існує переданий код посади (P_JOB_ID) в таблиці JOBS. 
         -- Якщо передано неіснуючий код, викликати помилку - RAISE_APPLICATION_ERROR(-20001,'Введено неіснуючий код посади').
            
             SELECT COUNT(*)
             INTO v_count_jobs_id
             FROM andriyi_9wd.jobs j
             WHERE j.job_id = p_job_id; 
             
             IF v_count_jobs_id = 0 THEN
                        raise_application_error (-20001, 'Введено неіснуючий код посади');
             END IF;
             
         -- Перевірити, чи існує переданий ідентифікатор відділу (P_DEPARTMENT_ID) в таблиці DEPARTMENTS. 
         -- Якщо передано неіснуючий ідентифікатор, викликати помилку - RAISE_APPLICATION_ERROR(-20001,'Введено неіснуючий ідентифікатор відділу').
            
             SELECT COUNT(*)
             INTO v_count_department_id
             FROM andriyi_9wd.departments dep
             WHERE dep.department_id = p_department_id; 
             
             IF v_count_department_id = 0 THEN
                        raise_application_error (-20001, 'Введено неіснуючий ідентифікатор відділу');
             END IF;
             
         -- Перевірити передану заробітну плату на коректність за кодом посади (P_JOB_ID) в таблиці JOBS. 
         -- Якщо передана заробітна плата не входить у діапазон заробітних плат для даного коду посади (P_JOB_ID), викликати помилку - RAISE_APPLICATION_ERROR(-20001,'Введено неприпустиму заробітну плату для даного коду посади').
            
             SELECT COUNT(*)
             INTO v_count_jobs_salary
             FROM andriyi_9wd.jobs j
             WHERE j.job_id = p_job_id
                   AND p_salary BETWEEN j.min_salary AND j.max_salary ; 
             
             IF v_count_jobs_salary = 0 THEN
                        raise_application_error (-20001, 'Введено неприпустиму заробітну плату для даного коду посади');
             END IF; 
             
             BEGIN            
          
                 INSERT INTO andriyi_9wd.employees (
                                         employee_id, first_name, last_name, email, phone_number,
                                         hire_date, job_id, salary, commission_pct, manager_id, department_id
                                         ) 
                                  VALUES (
                                          emp_seq.NEXTVAL, p_first_name, p_last_name, p_email, p_phone_number,
                                          p_hire_date, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id
                                          );
                
                  
                /* DBMS_OUTPUT.PUT_LINE('Співробітник ' || p_first_name || ', ' || p_last_name || 
                               ', ' || p_job_id || ', ' || p_department_id || ' успішно додано до системи'); */
                                 
                 EXCEPTION
                 WHEN OTHERS THEN
                    
                    andriyi_9wd.log_util.log_error(p_proc_name => 'add_employee',
                                                   p_sqlerrm => SQLERRM);
              
              END;
              
              v_text_log_finish := 'Співробітник ' || p_first_name || ', ' || p_last_name || 
                                    ', ' || p_job_id || ', ' || p_department_id || ' успішно додано до системи';
              
              andriyi_9wd.log_util.log_finish(p_proc_name => 'add_employee',
                                              p_text => v_text_log_finish);
              
              COMMIT;
        
        
        END add_employee;

END util;

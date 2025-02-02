--------SPECIFICATION


CREATE OR REPLACE PACKAGE util AS

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



-------------
--------BODY


CREATE OR REPLACE PACKAGE BODY util AS
  
------------------------------------------------------------------------        
------------------------------------------------------------------------
        
--PROCEDURE  


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
                TO_CHAR(SYSDATE, 'HH24:MI:SS') NOT BETWEEN '08:00:00' AND '24:00:00' THEN
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

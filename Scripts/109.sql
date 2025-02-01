SELECT *
FROM andriyi_9wd.employees;

DELETE FROM andriyi_9wd.employees em
WHERE em.first_name IN ('Andrii');

SELECT to_char(SYSDATE+2, 'DY')
FROM dual;

SELECT *--, COUNT(*)
FROM andriyi_9wd.jobs j;
        
DECLARE 
     v_count_jobs_id andriyi_9wd.jobs.job_id%TYPE;

 BEGIN
         SELECT COUNT(*)
             INTO v_count_jobs_id
             FROM andriyi_9wd.jobs j
             WHERE j.job_id = 'IT_PROG'; 
             
    dbms_output.put_line (v_count_jobs_id);
 END;

BEGIN
  util.add_employee(           p_first_name => 'Andrii3',
                               p_last_name => 'Andrii3',
                               p_email => 'AAndrii',
                               p_phone_number => '505.505.050',
                               p_hire_date => to_date('20.01.2025', 'DD.MM.YYYY'),
                               p_job_id => 'IT_PROG',
                               p_salary => 5000,
                               p_commission_pct => 0.1,
                               p_manager_id => 103,
                               p_department_id => 200);

 --    commit;  
END;
/

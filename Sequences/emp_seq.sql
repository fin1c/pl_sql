--Створення послідовної нумерації для таблиці employees стовбця id

DECLARE
    v_max_dep_id NUMBER;
BEGIN
    
    SELECT NVL(MAX(em.employee_id), 0) 
    INTO v_max_dep_id 
    FROM andriyi_9wd.employees em;

    EXECUTE IMMEDIATE 'CREATE SEQUENCE emp_seq
                       MINVALUE 1
                       START WITH ' || (v_max_dep_id + 1) || ' INCREMENT BY 1 
                       CACHE 20';
END;
/

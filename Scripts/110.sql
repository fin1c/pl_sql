SELECT *
FROM andriyi_9wd.employees;


SELECT *
FROM andriyi_9wd.employees_history;

SELECT *
FROM andriyi_9wd.logs l
order by l.log_date desc;

 DELETE FROM andriyi_9wd.employees em
                        WHERE em.employee_id = 207;



BEGIN
  util.fire_an_employee(p_employee_id => 208);

 --    commit;  
END;
/

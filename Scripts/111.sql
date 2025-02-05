SELECT *
FROM andriyi_9wd.employees;








BEGIN
  util.change_attribute_employee(p_employee_id => 231,
                                 p_first_name => 'Andrii232');

 --    commit;  
END;
/


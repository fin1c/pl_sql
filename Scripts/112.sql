
DECLARE
    v_po_result VARCHAR2(200);
BEGIN 
    copy_table(p_source_scheme => 'hr',
               p_target_scheme => 'andriyi_9wd',
               p_list_table => 'countries',
               p_copy_data => TRUE,
               po_result => v_po_result);
    dbms_output.put_line(v_po_result);
END;
/

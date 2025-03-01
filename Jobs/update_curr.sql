
BEGIN
    sys.dbms_scheduler.create_job(job_name => 'update_curr',
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => 'BEGIN andriyi_9wd.util.api_nbu_sync(); end;',
                                  start_date => SYSDATE,
                                  repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=00',
                                  end_date => TO_DATE(NULL),
                                  job_class => 'DEFAULT_JOB_CLASS',
                                  enabled => TRUE,
                                  auto_drop => FALSE,
                                  comments => 'Оновлення курсу валют');
END;
/

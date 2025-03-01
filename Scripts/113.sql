
CREATE TABLE andriyi_9wd.sys_params(
                                    param_name   VARCHAR2(150),
                                    value_date   DATE,
                                    value_text   VARCHAR2(2000), 
                                    value_number NUMBER,
                                    param_descr  VARCHAR2(200)
                                    );
                                    
SELECT *
FROM sys_params;    
                                     


INSERT INTO andriyi_9wd.sys_params (param_name, value_text, param_descr)
VALUES ('list_currencies', 'USD,EUR,KZT,AMD,GBP,ILS', 'Список валют для синхронізації в процедурі util.api_nbu_sync');                               
COMMIT;


CREATE TABLE andriyi_9wd.cur_exchange(
                                    r030          NUMBER,
                                    txt           VARCHAR2(100),
                                    rate          NUMBER, 
                                    cur           VARCHAR2(10),
                                    exchangedate  DATE,
                                    change_date   DATE
                                    );
                                    
SELECT *
FROM cur_exchange;


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

--Вимкнути шедулер
BEGIN
dbms_scheduler.disable(name=>'update_curr', force => TRUE);
END;
/

--Вмикнути шедулер
BEGIN
dbms_scheduler.enable(name=>'update_curr');
END;
/

BEGIN
DBMS_SCHEDULER.RUN_JOB(job_name => 'update_curr');
END;
/

SELECT *
FROM all_scheduler_jobs sj;

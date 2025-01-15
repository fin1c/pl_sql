--Створення послідовної нумерації для таблиці logs стовбця id

CREATE SEQUENCE log_seq
    MINVALUE 1 MAXVALUE 99999999999999999   
    START WITH 1 INCREMENT BY 1
    CACHE 20;

CREATE TABLE logfile2db.perf_file (
    id                 NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL,
    customer_ticket_id VARCHAR2(4000),
    created            TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    file_path          VARCHAR2(4000),
    CONSTRAINT pk_perf_file PRIMARY KEY (id)
);
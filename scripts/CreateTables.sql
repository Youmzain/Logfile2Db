/*
drop TABLE perf_file;
drop TABLE perf_row;
*/

CREATE TABLE perf_file (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY
                        CONSTRAINT pk_perf_file PRIMARY KEY,
    customer_ticket_id  VARCHAR2(100),
    created             TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    file_path           VARCHAR2(1000)
);

CREATE TABLE perf_row (
    id                  NUMBER GENERATED ALWAYS AS IDENTITY
                        CONSTRAINT pk_perf_row PRIMARY KEY,
    perf_file_id        NUMBER NOT NULL,
	row_type			VARCHAR2(1 CHAR)
    row_number          NUMBER NOT NULL,
    file_row            CLOB NOT NULL,
	rows_fetched		NUMBER,			-- 10 	aus '10 rows fetched in 5 ms' oder 50 aus '50 rows fetched in 2 parts'
	fetched_in_ms		NUMBER,			-- 5 	aus '10 rows fetched in 5 ms'
	fetched_in_parts	NUMBER, 		-- 2	aus '50 rows fetched in 2 parts'
    CONSTRAINT fk_perf_row__perf_file
        FOREIGN KEY (perf_file_id)
        REFERENCES perf_file (id)
        ON DELETE CASCADE,
    CONSTRAINT uk_perf_file_id__row_number 
        UNIQUE (perf_file_id, row_number)
);

CREATE INDEX ix_perf_row__perf_file_id ON perf_row (perf_file_id);







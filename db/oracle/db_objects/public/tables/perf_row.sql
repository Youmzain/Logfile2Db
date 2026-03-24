CREATE TABLE logfile2db.perf_row (
    id                        NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL,
    perf_file_id              NUMBER NOT NULL,
    row_number                NUMBER NOT NULL,
    lower_row                 CLOB NOT NULL,
    row_type                  VARCHAR2(1 CHAR),
    first4k                   VARCHAR2(4000 CHAR),
    lower_sql4k               VARCHAR2(4000 CHAR),
    lower_sql4k_neutralized   VARCHAR2(4000 CHAR),
    CONSTRAINT pk_perf_row                  PRIMARY KEY (id),
    CONSTRAINT uk_perf_file_id__row_number  UNIQUE (perf_file_id, row_number),
    CONSTRAINT fk_perf_row__perf_file       FOREIGN KEY (perf_file_id) REFERENCES logfile2db.perf_file (id) ON DELETE CASCADE
);

CREATE INDEX ix_perf_row__perf_file_id ON logfile2db.perf_row (perf_file_id);
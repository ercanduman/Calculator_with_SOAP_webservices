create table EDUMAN.CALCULATIONS (
   Calculation_id  NUMBER PRIMARY KEY,
   Number_A        NUMBER,
   Number_B        NUMBER,
   Operand_id      NUMBER,
   Result          VARCHAR (50),
   Remark          VARCHAR (1000),
   Status          VARCHAR (1) DEFAULT 'N',
   Retry_count     NUMBER,
   Xml_Request     VARCHAR (4000),
   Xml_Response    VARCHAR (4000),
   process_time    DATE,
   http_host    VARCHAR2 (2000)
);

--table comment
comment on table EDUMAN.CALCULATIONS  is 'Stores all operations which are executed or need to executed.';

--column comments
comment on column EDUMAN.CALCULATIONS.calculation_id is 'CALCULATION_ID attribute defines unique identifier of CALCULATIONS.';
comment on column EDUMAN.CALCULATIONS.Number_A is 'Number_A attribute defines the first number that is executed.';
comment on column EDUMAN.CALCULATIONS.Number_B is 'Number_B attribute defines the second number that is executed.';
comment on column EDUMAN.CALCULATIONS.Operand_id is 'Operand_id attribute defines unique identifier of operands on CALCULATIONS_OPERAND_CONFIG table.';
comment on column EDUMAN.CALCULATIONS.Result is 'Result attribute defines the result value of calculations.';
comment on column EDUMAN.CALCULATIONS.Remark is 'Remark attribute defines the remark value of operation result.';
comment on column EDUMAN.CALCULATIONS.status is 'Status attribute defines the status of operation for execution: not processed(N), processed but fail(F), success(S).';
comment on column EDUMAN.CALCULATIONS.Retry_count is 'Retry_count attribute defines the number of times that the calculations should be retried in any case of failure.';
comment on column EDUMAN.CALCULATIONS.Xml_Request is 'Xml_Request attribute defines the XML with given parameters for webservice request.';
comment on column EDUMAN.CALCULATIONS.Xml_Response is 'Xml_Response attribute defines the XML with the values from webservice response.';
comment on column EDUMAN.CALCULATIONS.process_time is 'process_time attribute defines time that the calculations done.';
comment on column EDUMAN.CALCULATIONS.http_host is 'http_host attribute defines webservice host address.';

--instead of writing Operand_id values one by one, a sequence created
CREATE sequence EDUMAN.seq_calculations_id start with 1 increment by 1 cache 10 order nocycle;

-- CONSTRAINT
ALTER TABLE EDUMAN.CALCULATIONS ADD CONSTRAINT CK_CALCULATIONS_STATUS CHECK ( STATUS IN ('N', 'F', 'S') );
ALTER TABLE EDUMAN.CALCULATIONS ADD CONSTRAINT FK_CALCULATIONS__OPID FOREIGN KEY (Operand_id) REFERENCES EDUMAN.CALCULATIONS_OPERAND_CONFIG (Operand_id) ENABLE NOVALIDATE;

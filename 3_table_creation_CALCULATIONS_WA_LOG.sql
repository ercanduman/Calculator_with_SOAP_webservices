create table EDUMAN.CALCULATIONS_WA_LOG (
               log_id                     NUMBER primary key,
               process_start_date         DATE,
               process_end_date           DATE,
               processed_operations_count NUMBER,
               Status                     VARCHAR2(1),
							 Remark                     VARCHAR2(30000)
);

--table comment
comment on table EDUMAN.CALCULATIONS_WA_LOG  is 'Stores all operations which are executed or need to executed.';

--column comments
comment on column EDUMAN.CALCULATIONS_WA_LOG.log_id is 'log_id attribute defines unique identifier and primary key of CALCULATIONS_WA_LOG.';
comment on column EDUMAN.CALCULATIONS_WA_LOG.process_start_date is 'process_start_date attribute defines execution start time.';
comment on column EDUMAN.CALCULATIONS_WA_LOG.process_end_date is 'process_end_date attribute defines execution end time.';
comment on column EDUMAN.CALCULATIONS_WA_LOG.processed_operations_count is 'This attribute defines number of operations handled between execution start and end times.';
comment on column EDUMAN.CALCULATIONS_WA_LOG.Status is 'Status attribute defines the status of execution: fail(F), success(S).';
comment on column EDUMAN.CALCULATIONS_WA_LOG.Remark is 'Remark attribute defines the remark value of execution result.';

--index
create index EDUMAN.i_CALCULATIONS_WA_LOG_id on CALCULATIONS_WA_LOG(log_id);

--instead of writing Operand_id values one by one, a sequence created
CREATE sequence EDUMAN.seq_CALCULATIONS_WA_LOG_id start with 1 increment by 1 cache 10 order nocycle;

-- CONSTRAINT
ALTER TABLE EDUMAN.CALCULATIONS_WA_LOG ADD CONSTRAINT CK_CALCULATIONS_WA_STATUS CHECK ( STATUS IN ('F', 'S') );

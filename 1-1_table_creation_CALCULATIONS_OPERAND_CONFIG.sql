create table EDUMAN.CALCULATIONS_OPERAND_CONFIG (
      Operand_id number primary key,
      Operand_Name varchar2(10) not null, 
      Operand_Symbol  varchar2(1) not null
);

--table comment
comment on table EDUMAN.CALCULATIONS_OPERAND_CONFIG  is 'Stores all operation variables such as operand unique id, operand name and operand symbol.';

--column comments
comment on column EDUMAN.CALCULATIONS_OPERAND_CONFIG.Operand_id is 'Operand_id attribute defines unique identifier of operands.';
comment on column EDUMAN.CALCULATIONS_OPERAND_CONFIG.Operand_Name is 'Operand_Name attribute defines name of operands.';
comment on column EDUMAN.CALCULATIONS_OPERAND_CONFIG.Operand_Symbol is 'Operand_Symbol attribute defines symbol of operands such as +(add), /(divide) etc';

--instead of writing Operand_id values one by one, a sequence created
CREATE sequence EDUMAN.seq_operand_id start with 1 increment by 1 cache 10 order nocycle;



insert into eduman.calculations_operand_config (operand_id, operand_name, operand_symbol) values (eduman.seq_operand_id.nextval, 'Add', '+');
insert into eduman.calculations_operand_config (operand_id, operand_name, operand_symbol) values (eduman.seq_operand_id.nextval, 'Subtract', '-');
insert into eduman.calculations_operand_config (operand_id, operand_name, operand_symbol) values (eduman.seq_operand_id.nextval, 'Multiply', '*');
insert into eduman.calculations_operand_config (operand_id, operand_name, operand_symbol) values (eduman.seq_operand_id.nextval, 'Divide', '/');
commit;

--SELECT * FROM eduman.calculations_operand_config;

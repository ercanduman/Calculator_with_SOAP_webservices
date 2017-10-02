INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 15, 56, 1);-- 71
INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 15, 8, 2); -- 7
INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 5, 25, 3); -- 125
INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 32, 4, 4); -- 8
INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 15, 22, 5); -- fail (invalid operand_id)
INSERT INTO eduman.calculations (calculation_id, number_a, number_b, operand_id) VALUEs (eduman.seq_calculations_id.nextval, 32, 0, 4); -- error (server cannnot do the calculation)
commit;
--SELECT * FROM eduman.calculations;
--SELECT * FROM  eduman.calculations_operand_config;

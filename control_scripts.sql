-- the operands and their names
SELECT * FROM eduman.calculations_operand_config;
-- 1 Add        +
-- 2 Subtract   -
-- 3 Multiply   *
-- 4 Divide     /
;

-- configurations for operation of packaged
SELECT ROWID, a.* FROM eduman.calculations_config a;

-- All operations
SELECT * FROM eduman.calculations ORDER BY calculation_id DESC;

-- The executions log 
SELECT * FROM eduman.calculations_wa_log ORDER BY log_id DESC;

-- the operations that need to be executed 
SELECT cal.calculation_id,
			 cal.number_a,
			 cal.number_b,
			 NVL(cal.retry_count, 0) AS retry_count,
			 conf.operand_name
	FROM eduman.calculations cal, eduman.calculations_operand_config conf
 WHERE cal.operand_id = conf.operand_id
	 AND (cal.status <> 'S' OR cal.status IS NULL)
	 AND (cal.retry_count < 3 OR cal.retry_count IS NULL);

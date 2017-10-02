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
			 (CASE
				 WHEN cal.retry_count IS NULL THEN
					(SELECT operation_retry_count FROM eduman.calculations_config)
				 WHEN cal.retry_count IS NOT NULL THEN
					cal.retry_count
			 END) AS retry_count,
			 (SELECT operand_name
					FROM eduman.calculations_operand_config
				 WHERE operand_id = cal.operand_id) AS operand_name
--  BULK COLLECT
--  INTO vt_Operations
	FROM eduman.calculations cal
 WHERE (cal.status <> 'S' OR status IS NULL)
	 AND (retry_count IS NULL OR retry_count > 0)
		OR (retry_count > 0 AND xml_response IS NULL)
--AND cal.calculation_id = 10
;
AND(retry_count IS NULL) OR(retry_count > 0 AND xml_response IS NULL) OR xml_response LIKE '%NETWROK_ERROR%'


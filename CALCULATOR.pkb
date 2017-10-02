-- body
CREATE OR REPLACE PACKAGE BODY EDUMAN.CALCULATOR IS

	/**************************************************************************************
  * Purpose    : Doing calculations and executing Web Services from PL/SQL language. 
  * Notes      : 
  * -------------------------------------------------------------------------------------
  * History    :
   | Author        | Date                 | Purpose
   |-------        |-----------           |----------------------------------------------
   | Ercan Duman   | 22-Sept-2017         | Package creation.
  **************************************************************************************/

	PROCEDURE EXECUTE_WEBSERVICE(pic_RequestXML   IN CLOB,
															 pin_Timeout      IN NUMBER DEFAULT 60,
															 pis_HttpHost     IN VARCHAR2,
															 poc_ResponseXML  OUT CLOB,
															 pos_ErrorMessage OUT VARCHAR2) IS
	
		vn_RunningLength       NUMBER;
		vs_Varchar2Chunk       VARCHAR2(32767);
		vn_ChunkSize           PLS_INTEGER;
		vt_HttpRequest         utl_http.REQ;
		vt_HttpResponse        utl_http.RESP;
		vs_HeaderName          VARCHAR2(1024);
		vs_HeaderValue         VARCHAR2(1024);
		vn_ResponseHeaderCount PLS_INTEGER;
		vs_DetailSQLCode       VARCHAR2(64);
		vs_DetailSQLMessage    VARCHAR2(1024);
		vn_RequestXMLength     NUMBER;
		vn_DefaultChunkSize    PLS_INTEGER;
	BEGIN
		poc_ResponseXML     := NULL;
		pos_ErrorMessage    := NULL;
		vn_DefaultChunkSize := 3000;
		dbms_lob.createtemporary(poc_ResponseXML, FALSE);
	
		utl_http.set_body_charset('UTF-8');
		utl_http.set_detailed_excp_support(TRUE);
		IF pin_Timeout IS NOT NULL
		THEN
			utl_http.set_transfer_timeout(pin_Timeout);
		END IF;
		vt_HttpRequest := utl_http.begin_request(pis_HttpHost, --'www.dneonline.com/calculator.asmx',
																						 'POST',
																						 'HTTP/1.1');
	
		utl_http.set_header(vt_HttpRequest,
												'Content-Type',
												'application/soap+xml;charset=UTF-8');
	
		vn_RequestXMLength := dbms_lob.getlength(pic_RequestXML);
		utl_http.set_header(vt_HttpRequest,
												'Content-Length',
												vn_RequestXMLength);
	
		vn_RunningLength := 1;
		vs_Varchar2Chunk := NULL;
		vn_ChunkSize     := vn_DefaultChunkSize;
	
		BEGIN
			LOOP
				vs_Varchar2Chunk := NULL;
			
				dbms_lob.read(pic_RequestXML,
											vn_ChunkSize,
											vn_RunningLength,
											vs_Varchar2Chunk);
				utl_http.write_text(vt_HttpRequest, vs_Varchar2Chunk);
			
				vn_RunningLength := vn_RunningLength + vn_ChunkSize;
				vn_ChunkSize     := vn_DefaultChunkSize;
			END LOOP;
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;
	
		vt_HttpResponse        := utl_http.get_response(vt_HttpRequest);
		vn_ResponseHeaderCount := utl_http.get_header_count(vt_HttpResponse);
		FOR i IN 1 .. vn_ResponseHeaderCount
		LOOP
			utl_http.get_header(vt_HttpResponse,
													i,
													vs_HeaderName,
													vs_HeaderValue);
		END LOOP;
	
		vs_Varchar2Chunk := NULL;
		vn_ChunkSize     := vn_DefaultChunkSize;
	
		BEGIN
			LOOP
				utl_http.read_text(vt_HttpResponse, vs_Varchar2Chunk, vn_ChunkSize);
				dbms_lob.writeappend(poc_ResponseXML,
														 LENGTH(vs_Varchar2Chunk),
														 vs_Varchar2Chunk);
				vn_ChunkSize := vn_DefaultChunkSize;
			END LOOP;
		EXCEPTION
			WHEN utl_http.end_of_body THEN
				NULL;
		END;
		utl_http.end_response(vt_HttpResponse);
	
	EXCEPTION
		WHEN OTHERS THEN
		
			vs_DetailSQLCode    := utl_http.get_detailed_sqlcode();
			vs_DetailSQLMessage := utl_http.get_detailed_sqlerrm();
		
			BEGIN
				utl_http.end_response(vt_HttpResponse);
			EXCEPTION
				WHEN OTHERS THEN
					NULL;
			END;
		
			IF pos_ErrorMessage IS NULL
			THEN
				pos_ErrorMessage := 'Error:ExecuteWebService:' || SQLERRM;
				pos_ErrorMessage := pos_ErrorMessage || CHR(10) ||
														dbms_utility.format_error_backtrace;
				pos_ErrorMessage := pos_ErrorMessage || CHR(10) ||
														'UTL_HTTP Detail SQL Code = ' ||
														vs_DetailSQLCode;
				pos_ErrorMessage := pos_ErrorMessage || CHR(10) ||
														'UTL_HTTP Detail SQL Message = ' ||
														vs_DetailSQLMessage;
			
			END IF;
		
	END EXECUTE_WEBSERVICE;

	PROCEDURE HANDLE_OPERATION(pin_NumberA       IN NUMBER,
														 pin_NumberB       IN NUMBER,
														 pis_OperationName IN VARCHAR,
														 pos_Remark        OUT VARCHAR,
														 pos_XMLRequest    OUT VARCHAR,
														 pos_XMLResponse   OUT VARCHAR,
														 pos_Result        OUT VARCHAR) IS
	
		vs_ErrorMessage            VARCHAR2(32000);
		vc_SOAPEnvelopeRequestXML  CLOB;
		vc_SOAPEnvelopeResponseXML CLOB;
		vs_StringPiece             VARCHAR2(32000);
		vs_Varchar2Chunk           VARCHAR2(4000);
		vn_RunningLength           INTEGER;
		vn_ChunkSize               INTEGER;
		vx_ResponseXML             XMLTYPE;
		vs_HttpHost                eduman.calculations_config.http_request_host%TYPE;
	
	BEGIN
		dbms_lob.createtemporary(vc_SOAPEnvelopeRequestXML, FALSE);
	
		--Construct SOAP Request XML  
		SELECT soap_base_request_xml, http_request_host
			INTO vs_StringPiece, vs_HttpHost
			FROM eduman.calculations_config;
	
		vs_StringPiece := REPLACE(vs_StringPiece, '$NUMBERA$', pin_NumberA);
		vs_StringPiece := REPLACE(vs_StringPiece, '$NUMBERB$', pin_NumberB);
		vs_StringPiece := REPLACE(vs_StringPiece,
															'$OPERATIONNAME$',
															pis_OperationName);
	
		pos_XMLRequest := vs_StringPiece;
	
		dbms_lob.writeappend(vc_SOAPEnvelopeRequestXML,
												 LENGTH(vs_StringPiece),
												 vs_StringPiece);
	
		--execute web service
		EXECUTE_WEBSERVICE(vc_SOAPEnvelopeRequestXML,
											 NULL,
											 vs_HttpHost,
											 vc_SOAPEnvelopeResponseXML,
											 vs_ErrorMessage);
	
		--check results...
		IF vs_ErrorMessage IS NULL
		THEN
			pos_Remark := 'Execution SUCCESSFUL!';
		ELSE
			pos_Remark := 'Execution FAILED!!!!' || 'ErrorMessage : ' ||
										vs_ErrorMessage;
		END IF;
	
		--read response
		vn_RunningLength := 1;
		BEGIN
			LOOP
				vn_ChunkSize := 9000;
				dbms_lob.read(vc_SOAPEnvelopeResponseXML,
											vn_ChunkSize,
											vn_RunningLength,
											vs_Varchar2Chunk);
			
				pos_XMLResponse  := vs_Varchar2Chunk;
				vn_RunningLength := vn_RunningLength + vn_ChunkSize;
				vx_ResponseXML   := xmltype(vc_SOAPEnvelopeResponseXML);
			
				IF vx_ResponseXML IS NOT NULL
				THEN
					pos_Result := vx_ResponseXML.Extract('//' || pis_OperationName ||'Result/text()','xmlns="http://tempuri.org/"')
												.GetStringVal();
				END IF;
			END LOOP;
		
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN OTHERS THEN
				pos_Remark := 'Execution FAILED!!!!' ||
											'ErrorMessage : Server was unable to process request.' ||
											SQLERRM;
		END;
	
	END HANDLE_OPERATION;

	PROCEDURE CALCULATIONS_APPLY IS
		-- operation variables
		vn_Result      eduman.calculations.result%TYPE;
		vs_Remark      eduman.calculations.remark%TYPE;
		vs_Status      eduman.calculations.status%TYPE;
		vs_XmlRequest  eduman.calculations.xml_request%TYPE;
		vs_XmlResponse eduman.calculations.xml_response%TYPE;
	
		TYPE t_Operation IS RECORD(
			id            eduman.calculations.calculation_id%TYPE,
			numbera       eduman.calculations.number_a%TYPE,
			numberb       eduman.calculations.number_a%TYPE,
			retry_count   eduman.calculations.retry_count%TYPE,
			operationname eduman.calculations_operand_config.operand_name%TYPE);
	
		TYPE t_TypeList IS TABLE OF t_Operation;
		vt_Operations t_TypeList;
	
		-- wa_log variables
		vd_exec_start_date     eduman.calculations_wa_log.process_start_date%TYPE;
		vs_exec_status         eduman.calculations_wa_log.status%TYPE := 'S';
		vs_exec_remark         eduman.calculations_wa_log.remark%TYPE;
		vn_ExecOperationsCount eduman.calculations_wa_log.processed_operations_count%TYPE;
	
		vn_validOperationsCount NUMBER;
		vn_InvalidOperandsCount NUMBER := 0;
		vn_ExceedsRetriesCount  NUMBER := 0;
		vn_NetworkErrorCount    NUMBER := 0;
	
		NO_OPERATION_FOUND EXCEPTION;
		INVALID_OPERAND_ID EXCEPTION;
		EXCEEDS_RETRIES    EXCEPTION;
		NETWROK_ERROR      EXCEPTION;
	BEGIN
		vd_exec_start_date := SYSDATE;
		vt_Operations      := t_TypeList();
	
		BEGIN
		
			-- Get all operations which are not handled or not succeeded yet
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
				BULK COLLECT
				INTO vt_Operations
				FROM eduman.calculations cal
			 WHERE (cal.status <> 'S' OR status IS NULL)
				 AND (retry_count IS NULL OR retry_count > 0)
					OR (retry_count > 0 AND xml_response IS NULL);
		
			IF vt_Operations.count = 0
			THEN
				RAISE NO_OPERATION_FOUND;
			ELSE
				vn_ExecOperationsCount := vt_Operations.count;
			END IF;
		
		EXCEPTION
			WHEN NO_OPERATION_FOUND THEN
				vs_exec_remark := 'ERROR> No unhandled operations found in EDUMAN.CALCULATIONS table ';
			
			WHEN OTHERS THEN
				vs_exec_status := 'F';
				vs_exec_remark := 'ERROR> ' || dbms_utility.format_error_backtrace ||
													SQLERRM;
		END;
	
		FOR i IN 1 .. vt_Operations.count
		LOOP
			vs_XmlRequest  := NULL;
			vs_XmlResponse := NULL;
			vs_Status      := 'S';
			vs_remark      := NULL;
		
			BEGIN
			
				IF vt_Operations(i).retry_count = 0
				THEN
					RAISE EXCEEDS_RETRIES;
				END IF;
			
				-- reduce retry_count    
				vt_Operations(i).retry_count := vt_Operations(i).retry_count - 1;
			
				IF vt_Operations(i).operationname IS NULL
				THEN
					RAISE INVALID_OPERAND_ID;
				END IF;
			
				handle_operation(pin_NumberA => vt_Operations(i).numbera,
												 
												 pin_NumberB       => vt_Operations(i).numberb,
												 pis_OperationName => vt_Operations(i).operationname,
												 pos_Remark        => vs_remark,
												 pos_XMLRequest    => vs_XmlRequest,
												 pos_XMLResponse   => vs_XmlResponse,
												 pos_Result        => vn_result);
			
				IF vs_Remark LIKE '%ErrorMessage%'
					 OR length(vs_Remark) > 50
					 OR vs_XmlResponse IS NULL
				THEN
					RAISE NETWROK_ERROR;
				END IF;
			
				--handle  all possible errors
			EXCEPTION
			
				WHEN EXCEEDS_RETRIES THEN
					vn_ExceedsRetriesCount := vn_ExceedsRetriesCount + 1;
					vs_status              := 'F';
					vs_remark              := 'Execution FAILED! EXCEEDS_RETRIES';
				
				WHEN INVALID_OPERAND_ID THEN
					vn_InvalidOperandsCount := vn_InvalidOperandsCount + 1;
					vs_status               := 'F';
					vs_remark               := 'Execution FAILED! INVALID_OPERAND_ID';
				
				WHEN NETWROK_ERROR THEN
					vn_NetworkErrorCount := vn_NetworkErrorCount + 1;
					vs_status            := 'F';
					vs_exec_status       := 'F';
					vs_exec_remark       := vs_remark ||
																	dbms_utility.format_error_backtrace ||
																	SQLERRM || ' ... ';
				
				WHEN OTHERS THEN
					vs_status      := 'F';
					vs_exec_status := 'F';
					vs_exec_remark := vs_remark ||
														'ERROR> OPERATION_ERROR: web service cannot do the calculations. ' ||
														dbms_utility.format_error_backtrace || SQLERRM;
				
			END;
		
			UPDATE eduman.calculations cal
				 SET RESULT       = TO_NUMBER(vn_result, '99999'),
						 remark       = vs_remark,
						 status       = vs_status,
						 retry_count  = vt_Operations(i).retry_count,
						 xml_request  = vs_XmlRequest,
						 xml_response = vs_XmlResponse,
						 process_time = SYSDATE
			 WHERE calculation_id = vt_Operations(i).id;
		
			COMMIT;
		END LOOP;
	
		IF vn_ExecOperationsCount IS NOT NULL
		THEN
			vn_ValidOperationsCount := vn_ExecOperationsCount;
			vn_ExecOperationsCount  := vn_ExecOperationsCount -
																 (vn_InvalidOperandsCount +
																 vn_ExceedsRetriesCount +
																 vn_NetworkErrorCount);
			IF vn_ExecOperationsCount > 0
			THEN
				vs_exec_remark := '' || vn_ExecOperationsCount ||
													' Operations SUCCESSFUL. ';
			END IF;
			IF vn_InvalidOperandsCount > 0
			THEN
				vs_exec_remark := vs_exec_remark || '' || vn_InvalidOperandsCount ||
													' Operations INVALID_OPERAND_ID. ';
			END IF;
			IF vn_ExceedsRetriesCount > 0
			THEN
				vs_exec_remark := vs_exec_remark || '' || vn_ExceedsRetriesCount ||
													' Operations EXCEEDS_RETRIES. ';
			END IF;
		
			IF vn_NetworkErrorCount > 0
			THEN
				IF vn_ExecOperationsCount <= 0
				THEN
					vs_exec_remark := vn_NetworkErrorCount ||
														' Operations NETWROK_ERROR. ' || '' ||
														vs_exec_remark;
				ELSE
					vs_exec_remark := vs_exec_remark || '' || vn_NetworkErrorCount ||
														' Operations NETWROK_ERROR. ';
				END IF;
			END IF;
		END IF;
	
		-- logging execution results
		INSERT INTO eduman.calculations_wa_log
			(log_id,
			 process_start_date,
			 process_end_date,
			 processed_operations_count,
			 status,
			 remark)
		VALUES
			(eduman.seq_calculations_wa_log_id.nextval,
			 vd_exec_start_date,
			 SYSDATE,
			 vn_ValidOperationsCount,
			 vs_exec_status,
			 vs_exec_remark);
	
		COMMIT;
	END CALCULATIONS_APPLY;

END CALCULATOR;
/

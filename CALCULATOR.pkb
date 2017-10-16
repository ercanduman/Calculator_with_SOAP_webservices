CREATE OR REPLACE PACKAGE BODY EDUMAN.CALCULATOR IS
/**************************************************************************************
  * Purpose    :  Handling the numbers in EDUMAN.CALCULATIONS table and doing calculation via execution of SOAP Web Services with PL/SQL language.
  * Notes      : 
  * -------------------------------------------------------------------------------------
  * Parameters : N/A
  * Return     : N/A
  * Exceptions : N/A
  * -------------------------------------------------------------------------------------
  * History    :        
   | Author         | Date                 | Purpose
   |-------         |-----------           |-----------------------------------
   | Ercan DUMAN    | 22-Sept-2017         | Procedure creation.
  **************************************************************************************/

  gs_HttpHost         eduman.calculations_config.http_request_host%TYPE;
  gs_base_request_xml eduman.calculations_config.soap_base_request_xml%TYPE;
  gn_retry_count      eduman.calculations_config.operation_retry_count%TYPE;

  gs_LogSuccessRemark        eduman.calculations.remark%TYPE := 'Execution SUCCESSFUL! ';
  gs_LogFailureRemark        eduman.calculations.remark%TYPE := 'Execution FAILED! ';
  gs_LogExecutionRemark      eduman.calculations_wa_log.remark%TYPE := NULL;
  gn_ExecutedOperationsCount NUMBER := 0;

 TYPE t_Operation IS RECORD(
    id            eduman.calculations.calculation_id%TYPE,
    numbera       eduman.calculations.number_a%TYPE,
    numberb       eduman.calculations.number_a%TYPE,
    retry_count   eduman.calculations.retry_count%TYPE,
    operationname eduman.calculations_operand_config.operand_name%TYPE);

  TYPE gt_TypeList IS TABLE OF t_Operation;
  gt_Operations gt_TypeList;

PROCEDURE get_Calculations
/**************************************************************************************
* Purpose    : Get all operations which are not handled or succeeded yet.
    * Notes      : 
    * -------------------------------------------------------------------------------------
    * Parameters : 
      - gt_Operations   : A TYPE variable of TypeList for global configuration
    * Return     : N/A
    * Exceptions : 
      - NO_OPERATION_FOUND: Checks the value of BULK COLLECT's count
    * -------------------------------------------------------------------------------------
    * History    :        
     | Author         | Date                 | Purpose
     |-------         |-----------           |-----------------------------------
     | Ercan DUMAN    | 13-Oct-2017          | Procedure creation.
    **************************************************************************************/
	 IS
		NO_OPERATION_FOUND EXCEPTION;
 BEGIN
	gt_Operations := gt_TypeList();

	SELECT cal.calculation_id,
		cal.number_a,
		cal.number_b,
		NVL(cal.retry_count, 0) AS retry_count,
		conf.operand_name
		BULK COLLECT
		INTO gt_Operations
		FROM eduman.calculations cal, eduman.calculations_operand_config conf
	 WHERE cal.operand_id = conf.operand_id
		 AND (cal.status <> 'S' OR cal.status IS NULL)
		 AND (cal.retry_count < gn_retry_count OR cal.retry_count IS NULL);

	IF gt_Operations.count = 0
	THEN
		RAISE NO_OPERATION_FOUND;
	ELSE
		gn_ExecutedOperationsCount := gt_Operations.count;
	END IF;
	
	EXCEPTION
	  WHEN NO_OPERATION_FOUND THEN
		gs_LogExecutionRemark := 'ERROR> No operations were found!';
	
	WHEN OTHERS THEN
	 	gs_LogExecutionRemark := 'ERROR> ' || dbms_utility.format_error_backtrace || SQLERRM;

END get_Calculations;

PROCEDURE get_GlobalConfigurations
/**************************************************************************************
* Purpose    : Get all global configurations from EDUMAN.CALCULATIONS_CONFIG table. 
* Notes      : 
* -------------------------------------------------------------------------------------
* Parameters : N/A
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 12-Oct-2017          | Procedure creation.
**************************************************************************************/
	 IS
	BEGIN
		-- SOAP Request XML  
	SELECT soap_base_request_xml, http_request_host, operation_retry_count
		INTO gs_base_request_xml, gs_HttpHost, gn_retry_count
		FROM eduman.calculations_config;

END get_GlobalConfigurations;

PROCEDURE ExecuteWebService(pic_RequestXML   IN CLOB,
			poc_ResponseXML  OUT CLOB,
			pos_ErrorMessage OUT VARCHAR2)
/**************************************************************************************
* Purpose    : Execution of webservice, creates http_request and gets data from http_response.
* Notes      : 
1) This procedure uses UTL_HTTP in order to execute web services.
* -------------------------------------------------------------------------------------
* Parameters : 
- pic_RequestXML  : Web service request XML.
- poc_ResponseXML : Web service response XML.
- pos_ErrorMessage: Web Service output with error message in case of failure!
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 22-Sept-2017         | Procedure creation.
**************************************************************************************/
 IS
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
	vt_HttpRequest := utl_http.begin_request(gs_HttpHost,
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
	pos_ErrorMessage := pos_ErrorMessage || CHR(10) || 'UTL_HTTP Detail SQL Code = ' || vs_DetailSQLCode;
			pos_ErrorMessage := pos_ErrorMessage || CHR(10) || 'UTL_HTTP Detail SQL Message = ' ||
			vs_DetailSQLMessage;
	END IF;

END ExecuteWebService;

PROCEDURE HandleOperation(pin_NumberA       IN eduman.calculations.number_a %TYPE,
			pin_NumberB       IN eduman.calculations.number_b%TYPE,
			pis_OperationName IN eduman.calculations_operand_config.operand_name%TYPE,
			pos_Remark        OUT eduman.calculations.remark%TYPE,
			pos_XMLRequest    OUT eduman.calculations.xml_request%TYPE,
			pos_XMLResponse   OUT eduman.calculations.xml_response%TYPE,
			pos_Result        OUT eduman.calculations.result%TYPE)
/**************************************************************************************
* Purpose    : Handle all operations which not successfully processed yet.
* Notes      : N/A
* -------------------------------------------------------------------------------------
* Parameters : 
- pin_NumberA       : First number of operation from eduman.calculations.
- pin_NumberB       : Second number of operation from eduman.calculations.
- pis_OperationName : Name of operation which can be Add, Divide, etc from eduman.calculations_operand_config.
- pos_Remark        : Output status message for each operation which can be Execution SUCCESSFUL! or Execution FAILED! etc.
- pos_XMLRequest    : Web service request XML.
- pos_XMLResponse   : Web service response XML.
- pos_Result        : The result value of operation.
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 12-Oct-2017          | Procedure creation.
**************************************************************************************/
 IS
	vs_ErrorMessage            VARCHAR2(32000);
	vc_SOAPEnvelopeRequestXML  CLOB;
	vc_SOAPEnvelopeResponseXML CLOB;
	vs_Varchar2Chunk           VARCHAR2(4000);
	vn_RunningLength           INTEGER;
	vn_ChunkSize               INTEGER;
	vx_ResponseXML             XMLTYPE;
	vs_request_xml             eduman.calculations_config.soap_base_request_xml%TYPE;
BEGIN
	dbms_lob.createtemporary(vc_SOAPEnvelopeRequestXML, FALSE);

	vs_request_xml := gs_base_request_xml;
	vs_request_xml := REPLACE(vs_request_xml, '$NUMBERA$', pin_NumberA);
	vs_request_xml := REPLACE(vs_request_xml, '$NUMBERB$', pin_NumberB);
	vs_request_xml := REPLACE(vs_request_xml, '$OPERATIONNAME$', pis_OperationName);

	pos_XMLRequest := vs_request_xml;

	dbms_lob.writeappend(vc_SOAPEnvelopeRequestXML,
			LENGTH(vs_request_xml),
			vs_request_xml);

	ExecuteWebService(vc_SOAPEnvelopeRequestXML,
		vc_SOAPEnvelopeResponseXML,
		vs_ErrorMessage);

	IF vs_ErrorMessage IS NULL
	THEN
		pos_Remark := gs_LogSuccessRemark;
	ELSE
		pos_Remark := gs_LogFailureRemark || 'ErrorMessage : ' || vs_ErrorMessage;
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
		-- Extract the result value
		pos_Result := vx_ResponseXML.Extract('//' || pis_OperationName ||'Result/text()','xmlns="http://tempuri.org/"').GetStringVal();
		END IF;
	END LOOP;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			pos_Remark := gs_LogFailureRemark ||'ErrorMessage : Server was unable to process request.' || SQLERRM;
	END;
END HandleOperation;

PROCEDURE i_CalculationsWaLog(vd_exec_start_date    IN OUT eduman.calculations_wa_log.process_start_date%TYPE,
			vs_exec_status        IN OUT eduman.calculations_wa_log.status%TYPE,
			vs_LOGEXECUTIONREMARK IN OUT eduman.calculations_wa_log.remark%TYPE)
/**************************************************************************************
* Purpose    : To insert all log data to EDUMAN.CALCULATIONS_WA_LOG table
* Notes      : N/A
* -------------------------------------------------------------------------------------
* Parameters :  
- vd_exec_start_date    : Execution start time.
- vs_exec_status        : Status of exection process.
- gs_LogExecutionRemark : Output message for exection.
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 12-Oct-2017          | Procedure creation.
**************************************************************************************/
 IS
BEGIN

	INSERT INTO eduman.calculations_wa_log
		(log_id, process_start_date, process_end_date, status, remark)
	VALUES
		(eduman.seq_calculations_wa_log_id.nextval,
		 vd_exec_start_date,
		 systimestamp,
		 vs_exec_status,
		 vs_LOGEXECUTIONREMARK);

	COMMIT;
END i_CalculationsWaLog;

PROCEDURE u_CalculationsTable(vn_Result         IN OUT eduman.calculations.result%TYPE,
			vs_Remark         IN OUT eduman.calculations.remark%TYPE,
			vs_Status         IN OUT eduman.calculations.status%TYPE,
			vn_retry_count    IN OUT eduman.calculations.retry_count%TYPE,
			vs_XmlRequest     IN OUT eduman.calculations.xml_request%TYPE,
			vs_XmlResponse    IN OUT eduman.calculations.xml_response%TYPE,
			vn_calculation_id IN OUT eduman.calculations.calculation_id%TYPE)
/**************************************************************************************
* Purpose    : Update data for each operation in EDUMAN.CALCULATIONS table
* Notes      : N/A
* -------------------------------------------------------------------------------------
* Parameters :  
- vn_Result         : The result value of operation.
- vs_Status         : Status of operaiton when handled.
- vs_Remark         : Output message of operation.
- vn_retry_count    : The value for retry in any case of failure.
- vs_XmlRequest     : Web service request XML.
- vs_XmlResponse    : Web service response XML.
- vn_calculation_id : The index identifier of effected operation.
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 10-Oct-2017          | Procedure creation.
**************************************************************************************/
 IS
BEGIN

	UPDATE eduman.calculations cal
		 SET RESULT = TO_NUMBER(vn_result, '99999'),
				 remark        = vs_remark,
				 status        = vs_status,
				 retry_count   = vn_retry_count,
				 xml_request   = vs_XmlRequest,
				 xml_response  = vs_XmlResponse,
				 process_time  = SYSDATE,
				 cal.http_host = gs_HttpHost
	 WHERE calculation_id = vn_calculation_id;

END u_CalculationsTable;

PROCEDURE CALCULATIONS_APPLY
/**************************************************************************************
* Purpose    : The main procedure which apply all configurations and execute all unprocessed operations.
* Notes      : 
* -------------------------------------------------------------------------------------
* Parameters : N/A
* Return     : N/A
* Exceptions : N/A
* -------------------------------------------------------------------------------------
* History    :        
| Author         | Date                 | Purpose
|-------         |-----------           |-----------------------------------
| Ercan DUMAN    | 23-Sept-2017         | Procedure creation.
**************************************************************************************/
 IS
	-- operation variables
	vn_Result      eduman.calculations.result%TYPE;
	vs_Remark      eduman.calculations.remark%TYPE;
	vs_Status      eduman.calculations.status%TYPE;
	vs_XmlRequest  eduman.calculations.xml_request%TYPE;
	vs_XmlResponse eduman.calculations.xml_response%TYPE;

	-- wa_log variables
	vd_exec_start_date eduman.calculations_wa_log.process_start_date%TYPE;
	vs_exec_status     eduman.calculations_wa_log.status%TYPE;

	vn_ExceedsRetriesCount NUMBER := 0;
	vn_NetworkErrorCount   NUMBER := 0;

	EXCEEDS_RETRIES EXCEPTION;
	NETWORK_ERROR   EXCEPTION;
BEGIN
	vd_exec_start_date    := systimestamp;
	vs_exec_status        := 'S';
	gs_LogExecutionRemark := NULL;

	get_Calculations;

	FOR i IN 1 .. gt_Operations.count
	LOOP
		vs_XmlRequest  := NULL;
		vs_XmlResponse := NULL;
		vs_Status      := 'S';
		vs_remark      := NULL;
		vn_Result      := NULL;

	BEGIN
		-- increase retry_count    
		gt_Operations(i).retry_count := gt_Operations(i).retry_count + 1;

		HandleOperation(gt_Operations (i).numbera,
				gt_Operations (i).numberb,
				gt_Operations (i).operationname,
				vs_remark,
				vs_XmlRequest,
				vs_XmlResponse,
				vn_result);

		IF vs_Remark LIKE '%ErrorMessage%'
			 OR vs_XmlResponse IS NULL
		THEN
			dbms_output.put_line('ERROR> ' || vs_Remark);

			IF gt_Operations(i).retry_count = gn_retry_count
			THEN
			RAISE EXCEEDS_RETRIES;
			ELSE
			RAISE NETWORK_ERROR;
			END IF;
		ELSE
		dbms_output.put_line('INFO> ' || gs_LogSuccessRemark);
		END IF;

	-- Handle all possible errors
	EXCEPTION
		WHEN EXCEEDS_RETRIES THEN
			vn_ExceedsRetriesCount := vn_ExceedsRetriesCount + 1;
			vs_status              := 'F';
			vs_remark              := gs_LogFailureRemark || 'EXCEEDS_RETRIES';

		WHEN NETWORK_ERROR THEN
			vn_NetworkErrorCount := vn_NetworkErrorCount + 1;
			vs_status            := 'F';
			vs_exec_status       := 'F';

		WHEN OTHERS THEN
			vs_status      := 'F';
			vs_exec_status := 'F';
	END;

	u_CalculationsTable(vn_Result,
			vs_Remark,
			vs_Status,
			gt_Operations (i).retry_count,
			vs_XmlRequest,
			vs_XmlResponse,
			gt_Operations (i).id);
		COMMIT;
	END LOOP;

	IF gn_ExecutedOperationsCount IS NOT NULL
	THEN
		gn_ExecutedOperationsCount := gn_ExecutedOperationsCount - (vn_ExceedsRetriesCount + vn_NetworkErrorCount);
		IF gn_ExecutedOperationsCount > 0
		THEN
		   gs_LogExecutionRemark := '' || gn_ExecutedOperationsCount ||' SUCCESSFUL. ';
		END IF;
		IF vn_ExceedsRetriesCount > 0
		THEN
		  gs_LogExecutionRemark := gs_LogExecutionRemark || '' ||vn_ExceedsRetriesCount ||' EXCEEDS_RETRIES. ';
		END IF;

		IF vn_NetworkErrorCount > 0
		THEN
		  gs_LogExecutionRemark := gs_LogExecutionRemark || '' ||vn_NetworkErrorCount || ' NETWORK_ERROR. ';
		END IF;
	END IF;
	
	i_CalculationsWaLog(vd_exec_start_date,
			vs_exec_status,
			gs_LogExecutionRemark);

	dbms_output.put_line('INFO> ' || gs_LogSuccessRemark);
END CALCULATIONS_APPLY;

BEGIN
	get_GlobalConfigurations;
	dbms_output.put_line('INFO> ' || gs_LogSuccessRemark);
END CALCULATOR;

INSERT INTO eduman.calculations_config
	(operation_retry_count, http_request_host, soap_base_request_xml)
VALUES
	(3,
	 'www.dneonline.com/calculator.asmx',
	 '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
	<soap12:Body>
		<' || '$OPERATIONNAME$' || ' xmlns="http://tempuri.org/">
			<intA>$NUMBERA$</intA> 
			<intB>' || '$NUMBERB$' || '</intB>
		</' || '$OPERATIONNAME$' || '>
	</soap12:Body>
</soap12:Envelope>');

COMMIT;
--SELECT * FROM eduman.calculations_config;

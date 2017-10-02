create table EDUMAN.CALCULATIONS_CONFIG (
						operation_retry_count number default 5,
						http_request_host  VARCHAR2(200),
						SOAP_base_request_xml      VARCHAR2(4000)
);

--table comment
comment on table EDUMAN.CALCULATIONS_CONFIG  is 'Stores all configürations for package execution.';

--column comments
comment on column EDUMAN.CALCULATIONS_CONFIG.operation_retry_count is 'operation_retry_count attribute defines the number of times that the calculations should be retried in any case of failure.';
comment on column EDUMAN.CALCULATIONS_CONFIG.http_request_host is 'http_request_host attribute defines webservice host address.';
comment on column EDUMAN.CALCULATIONS_CONFIG.SOAP_base_request_xml is 'SOAP_base_request_xml attribute defines execution end time.';

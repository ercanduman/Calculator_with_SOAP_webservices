# Calculator package with SOAP webservices

This is a workaround (**WA**) type project that can execute SOAP web services and do calculations from web service.

There is a table (`eduman.calculations`) with columns of _NumberA, NumberB, Operand,_ and _Result_. The main purpose with this project is handling the numbers in eduman.calculations table and doing calculation with calling web service.

There is a nice website which provides SOAP services for doing simple calculations such as:  Add (+), Subtract (-), Multiply (*) and Divide (/);
For WSDL information please check the web page itself here: http://www.dneonline.com/calculator.asmx
  
### Try and run project 
Please run all scripts with given file names order.

>  1-1_table_creation,
>  1-2_table_insertion,
>  2-1_table_creation,
>  ... etc


The` eduman.calculator `package Simple can be called simply as below:
```
-- Call the package
BEGIN
  EDUMAN.CALCULATOR.CALCULATIONS_APPLY;
END;
```
This package also categorizes the execution results in` eduman.calculations_wa_log` table. For different operations, different results/outputs will be written in the table. 
For example:
> "4 Operations SUCCESSFUL. 1 Operations INVALID_OPERAND_ID. 1 Operations NETWROK_ERROR.”



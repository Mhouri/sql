  --|----------------------------------------------|
  --| Date    : October 2023                       |
  --| Author  : Mohamed Houri                      |
  --| Purpose : Alter a SPM baseline property      |
  --|           a) attribute_name                  |
  --|              'ENABLED',                      |
  --|              'FIXED',                        |
  --|              'AUTOPURGE',                    |
  --|              'PLAN_NAME',                    |
  --|              'DESCRIPTION'                   |
  --|                                              |
  --|          b) attribute_value                  |
  --|               'YES'                          |
  --|               'NO'                           |
  --|----------------------------------------------|

declare
   spm_op pls_integer;
begin
  spm_op := dbms_spm.alter_sql_plan_baseline 
                        (plan_name       => '&plan_name'
						,attribute_name  => '&attribute_name'
						,attribute_value => '&attribute_value'
						);
end;
/


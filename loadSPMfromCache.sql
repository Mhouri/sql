   --|-------------------------------------------------------------|
   --| Author 		: Mohamed Houri                              --|
   --| Date   		: 08/06/2022                                 --|
   --| Scope        : Create a SPM baseline from a cursor cache  --|
   --| Usage        : @loadSPMfromCache                          --|
   --| Remarks      :                                            --|                          
   --|-------------------------------------------------------------|
set serveroutput on
declare
   spm_op pls_integer;
begin
  spm_op := dbms_spm.load_plans_from_cursor_cache (sql_id => '&sqlid'
                                                 ,plan_hash_value => to_number(trim('&plan_hash_value'))
												);
  dbms_output.put_line('Plans Loaded into SPB :'||spm_op);												
end;
/
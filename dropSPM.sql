declare
spm_op pls_integer;
begin
spm_op := dbms_spm.drop_sql_plan_baseline (sql_handle => NULL, plan_name  => '&plan_name');
end;
/


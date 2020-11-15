DECLARE
  l_plans_altered  PLS_INTEGER;
BEGIN
  l_plans_altered := DBMS_SPM.alter_sql_plan_baseline(
    sql_handle      => '&SQL_HANDLE',
    plan_name       => '&plan_name',
    attribute_name  => 'enabled',
    attribute_value => 'NO');

END;
/
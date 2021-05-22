SELECT report_id, key1 sql_id, key2 sql_exec_id, key3 sql_exec_start
  FROM dba_hist_reports
 WHERE component_name = 'sqlmonitor'
and key1 = '';


SELECT DBMS_AUTO_REPORT.REPORT_REPOSITORY_DETAIL(RID => 1022, TYPE => 'text')
       FROM dual;
	   
-- another way to do this

SELECT 
    report_id,
    EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/@sql_id') sql_id,
    EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_id') sql_exec_id,
    EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/@sql_exec_start') sql_exec_start
FROM 
    dba_hist_reports
WHERE 
     component_name = 'sqlmonitor'
 and EXTRACTVALUE(XMLType(report_summary),'/report_repository_summary/sql/@sql_id')='6qkdybw3ruwtx'
;
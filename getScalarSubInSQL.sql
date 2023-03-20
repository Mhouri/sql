--|-------------------------------------------------------------------|
--|Author : Mhouri                                                    |
--|Date   : mars 2023                                                 |
--|Scope  : find all SQL statments calling scalar subquery function   |
--|         -- from memory 	                                          |
--|         -- from AWR                                               |
--|        UNION ALL is used instead of UNION because of distinct     |
--|        on CLOB (sql_text)                                         |
--| Update : 20-03-2023                                               |
--|         I workarround the distinct on CLOB by using               |
--|         dbms_lob.substr                                           |
--|-------------------------------------------------------------------|
select 
    gv.sql_id
   ,gv.force_matching_signature as force_match_sign
   ,dbms_lob.substr(gv.sql_fulltext,32767)
from   
     gv$sql gv
where  
    gv.plsql_exec_time > 0
-- Exclude non applicative schemas
and gv.parsing_schema_name not in
   (select 
         db.username
	 from 
	     dba_users db
	 where
	    db.oracle_maintained ='Y'
	)
-- Exclude INSERT/UPDATE/DELETE
-- exclude PL/SQL blocks
and gv.command_type not in ('2','6','7','47')
--exclude automatic tasks (stats, space, tuning)
and
   gv.module != 'DBMS_SCHEDULER' 
UNION ALL
select 
    st.sql_id
   ,st.force_matching_signature as force_match_sign
   ,dbms_lob.substr(qt.sql_text,32767)
from   
    dba_hist_sqlstat st
   ,dba_hist_sqltext qt	 
where  
   st.sql_id = qt.sql_id
and
   st.plsexec_time_delta > 0
-- Exclude non applicative schemas
and st.parsing_schema_name not in
   (select 
         db.username
	 from 
	     dba_users db
	 where
	    db.oracle_maintained ='Y'
	)
-- Exclude INSERT/UPDATE/DELETE/CREATE
-- Exclude PL/SQL blocks
and qt.command_type not in ('1','2','6','7','47')
--exclude automatic tasks (stats, space, tuning)
and
   st.module != 'DBMS_SCHEDULER' 
 order by 2;

/* ----------------------------------------------------------------------------------|
|Author : Mohamed Houri                                                              |
|Date   : 03/07/2020                                                                 |
|Scope  : This script gives historical column histogram values                       |
|          -- I am using sys.WRI$_OPTSTAT_HISTHEAD_HISTORY for this purpose			 |		
|          -- I am only able to say whether, previously, there was HISTOGRAM or not  |
|          -- I can't show the historical type of Histogram 				         |
|																					 |
|Usage  :  SQL> @h_hist1                                                             |
|			Enter value for table_name: t1                                           |
|			Enter value for owner: test                                              |
|			Enter value for col_name: n2     				                         |
-------------------------------------------------------------------------------------|*/
col object_name   	    format a20
col column_name  		format a12
col last_analyzed 		format a20
col prev_last_analyzed  format a20
col histogram           format a16
col prev_histogram      format a16
WITH sq AS 
    (
     SELECT
	      object_id
		 ,object_name
		 ,subobject_name
	 FROM
	     dba_objects
	 WHERE
	     object_name    = upper ('&&table_name')
	 AND owner          = upper('&&owner')
	 AND subobject_name IS NULL
	 )
SELECT
	 object_name
	,column_name
	,lead(prev_histogram,1,histogram) over (order by last_analyzed) histogram
	,last_analyzed
	,prev_histogram
	,prev_last_analyzed
FROM
   (
     SELECT
	     object_name
		,column_name
		,(select histogram from all_tab_col_statistics where owner = upper('&&owner') 
		  and table_name = upper('&&table_name') and column_name = upper('&&col_name')) histogram
		,last_analyzed
		,stat_time prev_last_analyzed
		,row_number() over (order by last_analyzed) rn
		,case when round(derivedDensity,9)= round(density,9) then 'NONE' else 'HISTOGRAM' end prev_histogram
	 FROM
	    (
		 SELECT
		     object_name
			,column_name
			,to_char(savtime ,'dd/mm/yyyy hh24:mi:ss')     last_analyzed
			,to_char(timestamp# ,'dd/mm/yyyy hh24:mi:ss') stat_time
			,density
			,1/distcnt derivedDensity
			,row_number() over (order by savtime) rn
			,lag(case when round(1/distcnt,9) = round(density,9) then 'NONE' else 'HISTOGRAM' end) over(order by savtime) hist_histogram
		 FROM
		    sys.WRI$_OPTSTAT_HISTHEAD_HISTORY
			INNER JOIN sq ON object_id = obj#
			INNER JOIN (SELECT 
			                column_id
						   ,column_name
						FROM
						    dba_tab_columns
						WHERE
						    column_name = upper('&&col_name')
						AND table_name  = upper('&&table_name') 
			            AND owner       = upper('&&owner')
						) ON intcol# = column_id
	)
WHERE
   rn >= 1 --exlcude/include the very first dbms_stat
   )
ORDER BY
    last_analyzed;
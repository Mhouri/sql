/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Author : Mohamed Houri
Date   : 03/08/2016
Scope : This is an updated version of an existing script (over the web)
         in which I have  taken into account the following points:
		
          -- Superfluous executions and not used plan_hash_value are excluded.
                Superfluous plan_hash_value are inserted into dba_hist_sqlstat 
                because they were present in gv$sql at the AWR capture time. 
                This generally happens when a SQL_ID has several child cursors  
                in gv$sql. All these child cursors will be captured regardless
                of their activity (used or not used). These superfluous executions
                are excluded using the following where clause: 
				
		                WHERE avg_lio != 0
						
                But a "lock table" for example doesn't consume any logical I/O. This
                is why I added the following extra where clause:
				
                    OR  (avg_lio =0 AND avg_etime > 0)
                    
		  -- When a query is run in PARALLEL the avg_etime represents the time
               spent by all parallel servers concurrently. So if avg_px is not null then 
               avg_etime represents the cumulated time of all PX servers. To have
               the approximate wall clock time of the query I have divided the
               avg_time by the avg_px to obtain avg_px_time.
               
               Warning : avg_px_time do not include the Query Coordinator time 
               I still have not figured out how to get the QC time from a historical
               table. I have a script QCelaps.sql which gives the QC time but it
               is based on gv$sql_monitor. This is obviously not reliable when 
               dealing with historical executions. 
               
               Investigation : may be I have to investigate the new 12c RTSM
                               historical tables : dba_hist_reports
                                                   dba_hist_reports_details	
Update : 28-09-2016 : add end_of_fetch column
                         if end_of_fetch = 0 and exec = 1 then 
						      this means that the query not finished during the snapshot
						  end if
						When you see avg_rows = 0 this doesnt' necessarily means that 
						the query has not finished during the snapshot
                            						 
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
col snap_begin  format a25
col sql_profile format a20
col execs format 9999999
SELECT 
       snap_begin
      ,plan_hash_value
	  --sql_profile
      ,execs
	  ,end_of_fetch
      ,avg_etime 
      ,avg_px
	  ,trunc(avg_etime/decode(avg_px,0,1,avg_px) ,2) avg_px_time
      ,avg_pio
      ,avg_lio     
      ,avg_rows
    FROM
     (SELECT
           sn.begin_interval_time snap_begin
          ,plan_hash_value
		  ,st.sql_profile
          ,executions_delta execs
		  ,end_of_fetch_count_delta end_of_fetch
          ,trunc(elapsed_time_delta/1e6/decode(executions_delta, 0, 1, executions_delta)) avg_etime
          ,round(disk_reads_delta/decode(executions_delta,0,1, executions_delta),1) avg_pio
          ,round(buffer_gets_delta/decode(executions_delta,0,1, executions_delta), 1) avg_lio
          ,round(px_servers_execs_delta/decode(executions_delta,0,1, executions_delta), 1) avg_px
          ,round(rows_processed_delta/decode(executions_delta,0, 1, executions_delta), 1) avg_rows
      FROM 
           dba_hist_sqlstat st,
           dba_hist_snapshot sn
     WHERE st.snap_id = sn.snap_id
     AND   sql_id     = '&sql_id'
     AND   begin_interval_time > to_date('&from_date','ddmmyyyy')
     )
   WHERE avg_lio != 0                  
    OR  (avg_lio =0 AND avg_etime > 0) 
   ORDER by 1 asc;

 
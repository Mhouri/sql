-----  ./MohamedUndoHist.sql ------------------------
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Author : Mohamed Houri
Date   : 02/03/2020
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
						When you see avg_rows = 0 this doesn't' necessarily means that 
						the query has not finished during the snapshot
      -- https://blog.oracle48.nl/oracle-database-undo-space-explained/                      						 
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
col snap_begin  	    format a25
col maxquerysqlid 	    format a15
col maxquerylen         format 9999999
col txncount            format 9999999
col ora_01555  	        format 99
col undoblks 	        format 9999999
col undoConsump         format 9999999
col tuned_undoretention format 9999999
col activeblks          format 9999999
col unexpiredblks       format 9999999
col expiredblks         format 9999999

compute sum label 'Total Unexpired' of unexpiredblks on report
break   on report
SELECT 
       snap_begin
      ,maxquerysqlid
      ,maxquerylen
      ,txncount
      ,unxpstealcnt
      ,unxpblkrelcnt
      ,unxpblkreucnt
      ,expstealcnt
      ,expblkrelcnt
      ,expblkreucnt
      ,nospaceerrcnt
      ,ssolderrcnt ora_01555
      ,round(undoblks * 8 / 1024) undo_mb
	  ,tuned_undoretention
      ,activeblks
      ,unexpiredblks
      ,expiredblks      
    FROM
     (SELECT
           sn.begin_interval_time snap_begin
		  ,sn.instance_number inst
          ,st.maxquerylen
          ,st.maxquerysqlid
          ,st.unxpstealcnt
          ,st.unxpblkrelcnt
          ,st.unxpblkreucnt
          ,st.expstealcnt
          ,st.expblkrelcnt
          ,st.expblkreucnt
          ,st.ssolderrcnt
          ,st.nospaceerrcnt
		  ,st.txncount
          ,st.undoblks
		  ,st.tuned_undoretention
          ,st.activeblks
          ,st.unexpiredblks
          ,st.expiredblks            
      FROM 
           dba_hist_undostat st,
           dba_hist_snapshot sn
     WHERE st.snap_id = sn.snap_id    
     AND   begin_interval_time between to_date('06032020 04:00:00','ddmmyyyy hh24:mi:ss')
                               and     to_date('09032020 07:00:00','ddmmyyyy hh24:mi:ss')
     )  
   ORDER by 1 asc, 3 desc;
 

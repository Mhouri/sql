-----  ./MohamedUndoHist.sql ------------------------
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
|Author : Mohamed Houri                                             |
|Date   : 02/03/2020                                                |
|Scope  : comments to be added here                                 |
|       : check historical undo, particularly ORA-01555             |
|       : input dates have to be changed as a subtition parameters  |
|++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
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
     AND   begin_interval_time between to_date('&from_date','ddmmyyyy hh24:mi:ss')
                               and     to_date('&to_date','ddmmyyyy hh24:mi:ss')
     )  
   ORDER by 1 asc, 3 desc;
 

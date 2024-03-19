select
    a.dbid
   ,a.name
   ,extract( day from b.snap_interval) *24*60 + extract(hour from b.snap_interval) snap_hour
   ,extract( day from b.retention) ret_days
from
   dba_hist_wr_control b
join
   gv$database a
 on a.dbid=b.dbid;
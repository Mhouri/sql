with got_my_sid as
(select
      sid  
     ,inst_id
     ,event             
     ,total_waits   
   from
     gv$session_event 
   where 
    event = 'SQL*Net break/reset to client'
   and sid = (select sid from v$mystat where rownum = 1)
   )
select
   a.inst_id
  ,a.sid
  ,a.event
  ,a.total_waits
 -- ,s.schema#
 -- ,s.schemaname
 -- ,s.top_level_call#
  ,(select l.top_level_call_name from v$toplevelcall l
    where l.top_level_call# = s.top_level_call#
   ) top_level_call
  ,s.osuser
  ,s.username sess_user
  ,p.username proc_user
  ,p.tracefile
from
   gv$process p
  ,gv$session s
  ,got_my_sid a
where
    p.addr       = s.paddr
and a.sid = s.sid
and a.inst_id    = s.inst_id;


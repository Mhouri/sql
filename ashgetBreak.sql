--|-----------------------------------------------------------|
--|Author : Mhouri                                            |
--|scope  : get Origin of the SQL*Netbreak/reset to client    |
--|                                                           |
--|-----------------------------------------------------------|
col top_level_call for a25
col osuser for a20
col osuser for a20
col osuser for a20
with got_my_sid
as(select
      session_id
	 ,inst_id
     ,count(1) cnt
   from
     gv$active_session_history
   where 
       sample_time between to_date('10072015 11:00:00', 'ddmmyyyy hh24:mi:ss')
                   and     to_date('10072015 12:00:00', 'ddmmyyyy hh24:mi:ss')
   and event = 'SQL*Net break/reset to client'
   group by session_id, inst_id
   having count(1) > 10
   )
select
   a.inst_id
  ,a.session_id
  ,a.cnt elaps
  ,s.schema#
  ,s.schemaname
  ,s.top_level_call#
  ,(select l.top_level_call_name from v$toplevelcall l
    where l.top_level_call# = s.top_level_call#
   ) top_level_call
  ,s.osuser
  ,s.username sess_user
  ,p.username proc_user
  ,p.tracefile
 --,p.pga_used_mem
--  ,p.pga_alloc_mem
from
   gv$process p
  ,gv$session s
  ,got_my_sid a
where
    p.addr       =  s.paddr
and a.session_id = s.sid
and a.inst_id    = s.inst_id;

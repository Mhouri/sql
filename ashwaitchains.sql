------  ./ashwaitchains.sql ------------------------
--@ash_wait_chains2 inst_id||':'||session_id||':'||NVL(sql_id,'{sql_id}')||':'||sql_opname||':'||program2||event2 session_type='FOREGROUND' &from &to
@ash_wait_chains2 inst_id||':'||session_id||':'||NVL(sql_id,'{sql_id}')||':'||sql_opname||':'||program2||event2 1=1 "timestamp'2022-&from'" "timestamp'2022-&to'"

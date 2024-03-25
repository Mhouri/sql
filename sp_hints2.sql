set lines 155
col hint for a150
select attr_val hint
from dba_sql_profiles p, sqlprof$attr h
where p.signature = h.signature
and name like ('&profile_name')
order by attr#;

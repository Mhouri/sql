column REDOLOG_FILE_NAME format a60

compute sum label 'Total size' of size_GB on report

break on report
 select
	a.group#,
	a.thread#,
	a.sequence#,
	a.archived,
	a.status,
	b.member as redolog_file_name,
	trunc(a.bytes/power(1024,3),3) as size_gb
from gv$log a
join gv$logfile b on a.group#=b.group#
order by a.group# ;
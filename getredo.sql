--|--------------------------------------------------------------------------------------|
--|MHouri                                                                                |
--|thread#		: représente le numéro du groupe dans lequel se trouve le redo log       |
--|members 		: indique si le redo log est multiplexé (>1) ou pas(=1)                  |
--|redo_size_mb : la taille de chaque redo log file                                      |
--|Total size   : représente la taille réellement disponible pour gérer les transactions |
--|             : cette taille ne prend pas en compte les redos log multiplexés.         |
--|---------------------------------------------------------------------------------------|

column REDOLOG_FILE_NAME format a50

compute sum label 'Total size' of size_MB on report

break on report
 select
        a.group#,
        a.thread#,
        a.members,
        a.sequence#,
        a.archived,
        a.status,
        b.member as redolog_file_name,
        trunc(a.bytes/power(1024,2),3) as redo_size_mb,
        case when a.thread# = 1 then
              trunc(a.bytes/power(1024,2),3)
        else null end as size_MB
from gv$log a
join gv$logfile b on a.group#=b.group#
order by a.group# ;
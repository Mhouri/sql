-- check whether we are in archive mode log or not
archive log list

SELECT LOG_MODE from v$database;

show parameter recovery
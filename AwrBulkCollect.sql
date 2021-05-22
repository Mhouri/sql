-- +----------------------------------------------------------------------------+
-- | Author : Mohamed Houri                                                     |
-- |----------------------------------------------------------------------------|
-- | DATABASE : 12cR1                                                           |
-- | Name     : AwrBulkcollect.sql                                              |
-- | PURPOSE  : Dynamically create a SQL script to generate a list of AWR       |
-- |            reports between two snapshots dates.                            |
-- | NOTE     : As with any code, ensure to test this script in a development   |
-- |            environment before attempting to run it in production.          |
-- | Remarks : CHR(10) new line is mandatory. Unfortunately                     |
-- |           SET termout off so that AWR content will not be displayed        |
-- |           For RAC configuration consider the instance number               |       
-- |          Enter input date in this format :'mmddyyyy hh24:mi:ss'            |
-- |                                                                            |
-- ------------------------------------------------------------------------------
set termout off
set head off
set define off
set linesize 120
spool collectAWRs.sql

SELECT
    'spool awr_XYZ_inst_1_'
    || t.si
    || '_'
    || t.se
    || '.text '
    || CHR(10)
  --  || ' alter session set nls_language=''AMERICAN'';'
  --  || CHR(13)
    || 'SELECT * FROM TABLE(dbms_workload_repository.awr_report_text('
    || t.dbid
    || ','
    || t.instance_number
    || ','
    || t.si
    || ','
    || t.se
    || '));'
    || CHR(10)
    || ' spool off;'
FROM
    (
        SELECT
            dbid,
            snap_id si,
            snap_id + 1 se,
            instance_number
        FROM
            dba_hist_snapshot
        WHERE
            begin_interval_time >   TO_DATE('28102019 04:00:00', 'ddmmyyyy hh24:mi:ss')
        AND end_interval_time   <=  TO_DATE('28102019 12:30:00', 'ddmmyyyy hh24:mi:ss')
        AND  instance_number = 1
    ) t;
	
spool off;
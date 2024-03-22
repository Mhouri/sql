-- This will magnify the XML column for a RTSM history
-- for a given rid
-- report_summary is a column from dba_hist_reports
SELECT
    XMLSERIALIZE(CONTENT xmltype(a.report_summary) AS CLOB INDENT SIZE = 1) pretty_xml
FROM
    dba_hist_reports a
WHERE
    report_id = 5182;
--Mhouri
SELECT
    cfk.owner   
   ,cfk.table_name        fk_table
   ,cfk.constraint_name   fk_name
   ,cfk.constraint_type   fk_type
   ,cfk.status            fk_status
   ,cfk.r_constraint_name referenced_pk
   ,cpk.constraint_type   pk_type
   ,cpk.table_name        pk_table
   ,cpk.status            pk_status
FROM
    dba_constraints cfk
JOIN 
   dba_constraints cpk
     ON cfk.r_constraint_name = cpk.constraint_name
WHERE
    cpk.owner = upper('c##mhouri')
--  AND cpk.table_name = &table_name
AND cpk.constraint_type = 'P';

-- https://forums.oracle.com/ords/apexds/post/find-parent-and-child-hierarchy-of-foreign-keys-2779
WITH    descendants    AS
(
	SELECT  
    c.owner		    as child_owner
	,c.table_name	as child_table
	,p.owner		    as parent_owner
	,p.table_name	as parent_table
	FROM	
        all_constraints  c
	JOIN	all_constraints  p   ON  p.constraint_name  = c.r_constraint_name
)
SELECT    parent_table
,	  child_table
,	  LEVEL					   AS hierarchy_level
,	  CONNECT_BY_ROOT parent_table
       || sys_connect_by_path ( child_table, '\')  AS hierarchy_diagram
FROM	  descendants
START WITH  
   parent_owner = 'C##MHOURI'
CONNECT BY NOCYCLE   parent_owner  = PRIOR child_owner
	AND  	     parent_table  = PRIOR child_table
ORDER BY  parent_table	-- or whatever you want
;
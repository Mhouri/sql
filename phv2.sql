/* -----------------------------------------------------------------------------|
|Author : Mohamed Houri                                                         |
|Date   : 03/07/2017                                                            |
|Scope  : gives plan_hash_value and phv2 that includes the predicate part       |        
|							                                                    |
--------------------------------------------------------------------------------|*/
SELECT
               p.sql_id
              ,p.plan_hash_value
              ,p.child_number
              ,t.phv2
        FROM   v$sql_plan p
              ,xmltable('for $i in /other_xml/info
                        where $i/@type eq "plan_hash_2"
                        return $i'
                        passing xmltype(p.other_xml)
                        columns phv2 number path '/') t
          WHERE p.sql_id = '&1'
          and   p.other_xml is not null;
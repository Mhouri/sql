--*******************************************************************
-- Name   : CurSelCubeHybridNonPopWithoutEndPoint
-- Date   : October 2017
-- Author : Mohamed Houri
-- Purpose: gives the selectivity low and high value range of a Hybrid 
--          non-popular histogram bind variable which has not been
--          captured by the histogram gathering program.
--          This low-high value range corresponds to the low-high
--          selectivity range of a bind aware cursor using this
--          bind variable value
--*****************************************************************|
var num_rows    number
var new_density number

begin
 select num_rows into :num_rows from all_tables where table_name = 'ACS_TEST_TAB';
end;
/

begin
     SELECT
        trunc(((BktCnt-PopBktCnt)/BktCnt)/(NDV-PopValCnt),10) 
		into :new_density
     FROM
        (SELECT
           COUNT(1) PopValCnt,
           SUM(endpoint_repeat_count) PopBktCnt,
           ndv,
           BktCnt,
           pop_bucketSize
         FROM
          (SELECT
            (sample_size - num_nulls) BktCnt,
            num_distinct ndv,
            num_buckets,
            density OldDensity,
            (sample_size-num_nulls)/num_buckets pop_bucketSize
          FROM user_tab_col_statistics
          WHERE
              table_name  = 'ACS_TEST_TAB'
          AND column_name = 'RECORD_TYPE'
          ),
          user_histograms
        WHERE table_name         = 'ACS_TEST_TAB'
        AND column_name          = 'RECORD_TYPE'
        AND endpoint_repeat_count> pop_bucketSize
        GROUP BY ndv,
          BktCnt,
          pop_bucketSize
        );
end;
/

col bind format a10
select
    &&bind
   ,round((sel_of_bind - offset),6) low
   ,round((sel_of_bind + offset),6) high
from
   (select
      &bind
     ,:new_density       sel_of_bind
	 ,0.1*(:new_density) offset
    from dual
	);
     


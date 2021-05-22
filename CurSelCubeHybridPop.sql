--************************************************************************
-- Name   : CurSelCubeHybridNonPop
-- Date   : October 2017
-- Author : Mohamed Houri
-- Purpose: gives the selectivity low and high value range of a Hybrid 
--          non-popular histogram bind variable having an endpoint number
--          when this bind variable is used in a bind aware cursor
--***********************************************************************
var num_rows    number
var new_density number

begin
 select num_rows into :num_rows from all_tables where table_name = upper ('&table_name');
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
              table_name  = upper ('&table_name')
          AND column_name = upper ('&column_name')
          ),
          user_histograms
        WHERE table_name         = upper ('&table_name')
        AND column_name          = upper ('&column_name')
        AND endpoint_repeat_count> pop_bucketSize
        GROUP BY ndv,
          BktCnt,
          pop_bucketSize
        );
end;
/
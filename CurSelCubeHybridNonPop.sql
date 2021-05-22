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

col bind format a10
select
    bind
   ,round((sel_of_bind - offset),6) low
   ,round((sel_of_bind + offset),6) high
from
   (select
      bind
     ,value_count/:num_rows       sel_of_bind
	 ,0.1*(value_count/:num_rows) offset
    from
     (select 
	      endpoint_actual_value bind
	    ,(:num_rows*greatest(:new_density,endpoint_repeat_count/sample_size)) value_count
	  from
	     (select
           sample_size
		  ,endpoint_actual_value 
          ,endpoint_repeat_count
         from (select
				 ucs.sample_size 
				,uth.endpoint_actual_value
				,uth.endpoint_repeat_count
			   from
				user_tab_histograms uth
			   ,user_tab_col_statistics ucs
		      where
				uth.table_name   = ucs.table_name
			  and uth.column_name   = ucs.column_name
			  and uth.table_name    = upper ('&table_name')
			  and uth.column_name   = upper ('&column_name')
			   )
	       )
	  )
	)
where bind = &bind; 
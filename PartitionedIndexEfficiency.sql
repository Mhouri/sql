rem
rem     Script:     index_est_proc_2.sql
rem     Author:     Jonathan Lewis
rem     Dated:      August 2005 (updated Apr 2009)
rem     Purpose:    Fast analysis of indexes to help identify
rem                 extreme degeneration.
rem
rem     Last tested
rem             11.1.0.7
rem             10.2.0.3
rem             10.1.0.4
rem              9.2.0.8
rem              8.1.7.4
rem     Not tested
rem             11.2.0.1
rem             10.2.0.4
rem
rem     Usage:
rem     Set the values in the "define" section
rem     Log on with the privilege to see the "dba_" views
rem     using SQL*Plus and run the script.
rem
rem     Notes:
rem     This script assumes that statistics have been collected in
rem     the fairly recent past, and uses some approximations to
rem     compare the number of leaf blocks with the number of leaf
rem     blocks that ought to be needed to hold the data.
rem
rem     There are various little oddities with the way that
rem         (a) Oracle calculates average column lenght and
rem         (b) I use the available data
rem     that mean that at small sizes and in extreme cases the
rem     numbers I produce can be wrong.  In particular, for indexes
rem     where a lot of the table data has nulls (so no entry in the
rem     index), the estimated size can be significantly larger than
rem     they finally turn out to be.
rem
rem
rem     Targets
rem     =======
rem     Where the estimate is very much smaller than the actual, then
rem     you may be looking at a "FIFO" index, emptying out in the past
rem     and filling in the future. This type of index is a candidate for
rem     a regular "coalesce" - although you may want to rebuild it once
rem     to get it to the right starting size and release excess space
rem     back to the tablespace.
rem
rem     See https://jonathanlewis.wordpress.com/2008/09/26/index-analysis/
rem     for an example and discussion on this type of index.
rem
rem     Where the estimate is about half the size of the actual, then
rem     it is worth checking whether there is any special treatment of
rem     the data that is making this happen. 50% utilisation is fairly
rem     common in RAC for indexes based on a sequence with a large cache
rem     size, so it may be best to leave the indexes at that level. 
rem     However, you may find that rebuilding (perhaps just once) with
rem     a pctfree in the region of 30% may give you a slightly more efficient
rem     index in non-RAC systems.
rem
rem     If your index is running at 50% and is not strongly sequence based
rem     then you may be suffering from the concurrency/ITL bug and may want
rem     to rebuild the index and force a maxtrans setting into the index.
rem
rem     If the index is running at a fairly uniform 25%, it may be subject
rem     to side effects of both sequencing and the concurrency effects.
rem
rem     Usage:
rem     ======
rem     This script takes a username (table owner), percent usage, and
rem     scaling factor.  It reports the estimated leaf block count of
rem     all simple indexes for that schema where the size of the index
rem     would be smaller than the supplied fraction of the current size
rem     when rebuilt at the supplied percentage utilisation. Current settings
rem     are 90% (which equates to the default pctfree 10) and 0.6 which means
rem     the index would be running at about 50% empty wastage - which is the
rem     point at which it begins to be a possible target for investigation.
rem     The script does not report any index smaller than 10,000 leaf blocks,
rem     and assumes an 8KB block size.
rem
rem     Technical notes:
rem     ================
rem     Don't need to add a length byte after using dbms_stats
rem     Don't need a 'descending' byte because it's automatically included
rem     Don't need to adjust for num_nulls because it's automatically included
rem     Reverse key indexes don't affect column lengths
rem
rem     Need to worry about COMPRESSED indexes. At present compression
rem     may reduce the size of an index so that I don't notice it should
rem     still be smaller than it is.
rem
rem     Index types that can be used (with partitioned = 'NO')
rem         NORMAL
rem         NORMAL/REV
rem         FUNCTION-BASED NORMAL
rem
rem     Still needs enhancing for partitioned and subpartitioned indexes
rem     Check dba_part_indexes for locality, partitioning_type, subpartitioning_type
rem     But does handle global indexes on partitioned tables.
rem
rem     To investigate
rem         LOB
rem         IOT - TOP
rem         IOT - NESTED
rem         SECONDARY
rem         BITMAP  (and BITMAP JOIN)
rem         FUNCTION-BASED BITMAP
rem         CLUSTER
rem         ANSI ?
rem
rem     Probably not possible
rem         DOMAIN
rem         FUNCTION-BASED DOMAIN
rem
rem     Need to avoid partitioned, temporary, unusable and dropped indexes
rem
rem
rem    Update : December 2016 by Mohamed Houri to consider Locally 
rem             Partitioned and SUB-Partitioned indexes
rem           : Any error is this script is mine. 
rem           : This script has been tested on running systems and seems giving
rem             acceptable results. But still I have not enough feedback. So use it
rem             carefully.
rem
set serveroutput on size 1000000 format wrapped
 
define  m_owner         = '&m_schemaname'
define m_blocksize = 8192
define  m_target_use    = 90 -- equates to pctfree 10
define  m_scale_factor  = 0.6
define m_minimum = 1000
define m_overhead = 192 -- leaf block "lost" space in index_stats

set verify off
set serveroutput on size 1000000 format wrapped

declare
    m_leaf_estimate number;
    ln_size         number;
begin
    for r in 
    (
       select
            ww.table_owner,
            ww.table_name,
            ww.index_owner,
            ww.index_name,
            ww.partition_name,
            ww.leaf_blocks,
            ww.status,
            ww.part_level
       from -- top level partitioned index
           (
        	select
            	a.table_owner,
            	a.table_name,
            	b.index_owner,
            	b.index_name,
            	b.partition_name,
            	b.leaf_blocks,
            	b.status,
            	'TOP' part_level
        	from
            	dba_indexes        a
               ,dba_ind_partitions b
        	where
            	a.owner       = b.index_owner
            and a.index_name  = b.index_name
            and a.owner       = upper('&m_owner')
        	and a.partitioned = 'YES'
        	and a.temporary   = 'N'
        	and a.dropped     = 'NO'
        	and b.status     != 'UNUSABLE'
        	and a.last_analyzed is not null
           union all
              -- sub partitioned indexes
           	select
            	a.table_owner,
            	a.table_name,
            	c.index_owner,
            	c.index_name,
            	c.subpartition_name,
            	c.leaf_blocks,
            	c.status,
            	'SUB' part_level
        	from
            	dba_indexes           a
               ,dba_ind_subpartitions c
        	where
            	a.owner       = c.index_owner
            and a.index_name  = c.index_name
            and a.owner       = upper('&m_owner')
        	and a.partitioned = 'YES'
        	and a.temporary   = 'N'
        	and a.dropped     = 'NO'
        	and c.status     != 'UNUSABLE'
        	and a.last_analyzed is not null
        	)ww
     order by
            ww.index_owner, ww.table_name, ww.index_name,ww.partition_name
    ) loop
        if r.leaf_blocks > &m_minimum then
            select
                round( 100 / &m_target_use * (ind.num_rows * (tab.rowid_length + ind.uniq_ind + 4) + sum((tc.avg_col_len) *(tab.num_rows)) ) /(&m_blocksize - &m_overhead)
         )               index_leaf_estimate
                into    m_leaf_estimate
            from
                (
                select  /*+ no_merge */
                    a.partition_name,
                    a.num_rows,
                    10 rowid_length
                from
                    dba_ind_partitions a
                where
                    a.index_owner    = r.index_owner
                and a.index_name     = r.index_name
                and a.partition_name = r.partition_name
                union all
                select  /*+ no_merge */
                    a.subpartition_name,
                    a.num_rows,
                    10 rowid_length
                from
                    dba_ind_subpartitions a
                where
                    a.index_owner       = r.index_owner
                and a.index_name        = r.index_name
                and a.subpartition_name = r.partition_name
                )               tab,
                (
                select  /*+ no_merge */
                    a.index_name,
                    a.num_rows,
                    decode(uniqueness,'UNIQUE',0,1) uniq_ind
                from
                    dba_ind_partitions a
                   ,dba_indexes        b
                where
                    a.index_name     = b.index_name
                and a.index_owner    = r.index_owner
                and b.table_name     = r.table_name
                and b.owner          = r.index_owner
                and a.index_name     = r.index_name
                and a.partition_name = r.partition_name
                union all
                select  /*+ no_merge */
                    c.index_name,
                    c.num_rows,
                    decode(uniqueness,'UNIQUE',0,1) uniq_ind
                from
                    dba_ind_subpartitions c
                   ,dba_indexes           b
                where
                    c.index_name        = b.index_name
                and c.index_owner       = r.index_owner
                and b.table_name        = r.table_name
                and b.owner             = r.index_owner
                and c.index_name        = r.index_name
                and c.subpartition_name = r.partition_name
                )               ind,
                (
                select  /*+ no_merge */
                    column_name
                from
                    dba_ind_columns
                where
                    table_owner = r.table_owner
                and index_owner = r.index_owner
                and table_name  = r.table_name
                and index_name  = r.index_name
                )               ic,
                (
                select  /*+ no_merge */
                    column_name,
                    avg_col_len
                from
                    dba_tab_cols
                where
                    owner       = r.table_owner
                and table_name  = r.table_name
                )               tc
            where
                tc.column_name = ic.column_name
            group by
                ind.num_rows,
                ind.uniq_ind,
                tab.rowid_length
            ;
            if m_leaf_estimate < &m_scale_factor * r.leaf_blocks then
 
              select sum(round(bytes/1024/1024,2)) into ln_size
              from dba_segments a
              where segment_name = r.index_name
              and partition_name = r.partition_name;
              
              if ln_size is not null 
              then
                 dbms_output.new_line;
                dbms_output.put_line
                (
                    'table name ' || ': ' || trim(r.table_name) || ' - ' ||
                    'index name ' || ': ' || trim(r.index_name) || 
					' - Partition Name :' || trim(r.partition_name) || 
					' - Partition Level:' || r.part_level
                );
 
                dbms_output.put_line
                (
                    '--> Current partition index size (MB): ' ||
                    round(ln_size,2) ||
                    '         Expected Partition index size (MB): ' ||
                    round(ln_size * (m_leaf_estimate/r.leaf_blocks),2)
                );
 
                dbms_output.new_line;
 
            end if;
        end if;
      end if;
    end loop;
end;
/
set verify on
 
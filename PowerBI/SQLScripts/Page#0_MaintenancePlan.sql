-- https://techcommunity.microsoft.com/t5/azure-database-support-blog/bg-p/AzureDBSupport
-- https://github.com/JMNetwalker/PerfCollector

--OutOfDate Estadísticas
SELECT sp.stats_id, stat.name, o.name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter,  DATEDIFF(DAY, last_updated , getdate()) AS Diff, schema_name(o.schema_id) as SchemaName
                           FROM sys.stats AS stat   
                           Inner join sys.objects o on stat.object_id=o.object_id
                           CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
                           WHERE o.type = 'U' AND stat.auto_created ='1' or stat.user_created='1' order by o.name, stat.name

--Recomendations 
select COUNT(1) from sys.dm_db_tuning_recommendations Where Execute_action_initiated_time = '1900-01-01 00:00:00.0000000'

--Timeouts 
SELECT
qst.query_sql_text,
qrs.execution_type,
qrs.execution_type_desc,
qpx.query_plan_xml,
qrs.count_executions,
qrs.last_execution_time
FROM sys.query_store_query AS qsq
JOIN sys.query_store_plan AS qsp on qsq.query_id=qsp.query_id
JOIN sys.query_store_query_text AS qst on qsq.query_text_id=qst.query_text_id
OUTER APPLY (SELECT TRY_CONVERT(XML, qsp.query_plan) AS query_plan_xml) AS qpx
JOIN sys.query_store_runtime_stats qrs on qsp.plan_id = qrs.plan_id
WHERE qrs.execution_type in (3,4)
ORDER BY qrs.last_execution_time DESC;

---Missing indexes
SELECT CONVERT (varchar, getdate(), 126) AS runtime,
                           CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact *
                           (migs.user_seeks + migs.user_scans)) AS improvement_measure,
                           REPLACE(REPLACE('CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' +
                           CONVERT (varchar, mid.index_handle) + ' ON ' + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(mid.statement,CHAR(10), ' '), CHAR(13), ' '),'  ',''))) + 
                           '(' + ISNULL (mid.equality_columns,'')
                           + CASE WHEN mid.equality_columns IS NOT NULL
                              AND mid.inequality_columns IS NOT NULL
                           THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
                           + ')'
                           + ISNULL (' INCLUDE (' + mid.included_columns + ')', ''), CHAR(10), ' '), CHAR(13), ' ') AS create_index_statement,
                           migs.avg_user_impact
                           FROM sys.dm_db_missing_index_groups AS mig
                           INNER JOIN sys.dm_db_missing_index_group_stats AS migs
                           ON migs.group_handle = mig.index_group_handle
                           INNER JOIN sys.dm_db_missing_index_details AS mid
                           ON mig.index_handle = mid.index_handle
                           ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

---
select 
ObjectSchema = OBJECT_SCHEMA_NAME(idxs.object_id)
,ObjectName = object_name(idxs.object_id) 
,IndexName = idxs.name
,i.avg_fragmentation_in_percent
from sys.indexes idxs
inner join sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,'LIMITED') i  on i.object_id = idxs.object_id and i.index_id = idxs.index_id
where idxs.type in (0 /*HEAP*/,1/*CLUSTERED*/,2/*NONCLUSTERED*/,5/*CLUSTERED COLUMNSTORE*/,6/*NONCLUSTERED COLUMNSTORE*/) 
and (alloc_unit_type_desc = 'IN_ROW_DATA' /*avoid LOB_DATA or ROW_OVERFLOW_DATA*/ or alloc_unit_type_desc is null /*for ColumnStore indexes*/)
and OBJECT_SCHEMA_NAME(idxs.object_id) != 'sys'
and idxs.is_disabled=0
and not idxs.name is null
order by ObjectName, IndexName


-- How we fix the problem ? 

ALTER INDEX ALL ON [Dimension].[City] rebuild
ALTER INDEX ALL ON [Dimension].[Customer] rebuild
ALTER INDEX ALL ON [Dimension].[Date] rebuild
ALTER INDEX ALL ON [Dimension].[Employee] rebuild
ALTER INDEX ALL ON [Dimension].[Stock Item] rebuild
ALTER INDEX ALL ON [Fact].[Sale] rebuild
ALTER INDEX ALL ON [Fact].[SaleColumnStoreIndex] rebuild

UPDATE STATISTICS [Dimension].[City] WITH FULLSCAN
UPDATE STATISTICS [Dimension].[Customer] WITH FULLSCAN
UPDATE STATISTICS [Dimension].[Date] WITH FULLSCAN
UPDATE STATISTICS [Dimension].[Employee] WITH FULLSCAN
UPDATE STATISTICS [Dimension].[Stock Item] WITH FULLSCAN
UPDATE STATISTICS [Fact].[Sale] WITH FULLSCAN
UPDATE STATISTICS [Fact].[SaleColumnStoreIndex] WITH FULLSCAN


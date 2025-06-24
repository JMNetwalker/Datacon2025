--------------------------------------
-- Number of different plans
--------------------------------------
SELECT
    q.query_id,
    qt.query_sql_text,
    q.query_hash,
    COUNT(DISTINCT p.plan_id) AS num_plans,
    STRING_AGG(CAST(p.plan_id AS VARCHAR), ', ') AS plan_ids
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
GROUP BY q.query_id, qt.query_sql_text, q.query_hash
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY num_plans DESC;

--------------------------------------
-- ForcedPlan?
--------------------------------------
SELECT plan_id, is_forced_plan
FROM sys.query_store_plan
WHERE query_id = 1;

--------------------------------------
-- Number of different plans and their execution details
--------------------------------------

SELECT
    rs.execution_type_desc,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.last_duration,
	rs.count_executions,
    rs.first_execution_time,
    rs.last_execution_time
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
WHERE p.query_id = 1
ORDER BY rs.last_execution_time DESC;

SELECT
    rs.execution_type_desc,              
    rs.avg_duration / 1000 AS avg_ms,    
    rs.avg_cpu_time / 1000 AS avg_cpu_ms,
    rs.last_duration / 1000 AS last_ms,  
    rs.count_executions,                 
    rs.first_execution_time,
    rs.last_execution_time,
    p.plan_id,
    p.is_forced_plan                     
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
WHERE p.query_id = 2
ORDER BY rs.last_execution_time DESC;

SELECT
    rs.execution_type_desc,                    
    rs.avg_duration / 1000 AS avg_duration_ms, 
    rs.avg_cpu_time / 1000 AS avg_cpu_ms,      
    rs.last_duration / 1000 AS last_duration_ms,
    rs.count_executions,
    rs.first_execution_time,
    rs.last_execution_time,
    p.plan_id,
    p.is_forced_plan,
    TRY_CONVERT(XML, p.query_plan) AS execution_plan_xml
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
WHERE p.query_id = 2
ORDER BY rs.last_execution_time DESC;

--------------------------------------
-- Statistics changed?
--------------------------------------
;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
    p.plan_id,
    stat.value('@Statistics', 'VARCHAR(200)') AS stats_name,
    stat.value('@LastUpdate', 'DATETIME') AS stats_last_updated,
    stat.value('@SamplingPercent', 'FLOAT') AS stats_sampling_percent
FROM sys.query_store_plan AS p
CROSS APPLY (
    SELECT CAST(p.query_plan AS XML) AS xml_plan
) AS x
OUTER APPLY  x.xml_plan.nodes('
    /ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/OptimizerStatsUsage/StatisticsInfo'
) AS t(stat)
WHERE p.query_id = 2;

--------------------------------------
-- Statistics changed? When?
--------------------------------------

SELECT 
    name AS stats_name,
    last_updated,
    modification_counter,
    [rows], rows_sampled
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id)
WHERE s.object_id = OBJECT_ID('dbo.Notes');

--------------------------------------
-- Resource Consumption
--------------------------------------
select * from sys.dm_db_resource_stats
------------------------
-- Total Executions vs CPU Time
------------------------
SELECT TOP 10
    qsq.query_id,
    qsp.plan_id,
    qs.avg_duration AS avg_cpu_time, 
    qs.last_execution_time,
    qs.count_executions,
    qt.query_sql_text
FROM
    sys.query_store_runtime_stats qs
JOIN
    sys.query_store_plan qsp ON qs.plan_id = qsp.plan_id
JOIN
    sys.query_store_query qsq ON qsp.query_id = qsq.query_id
JOIN
    sys.query_store_query_text qt ON qsq.query_text_id = qt.query_text_id
ORDER BY
    qs.avg_duration DESC; 


SELECT 
    qsqt.query_sql_text AS QueryText,
    qsq.query_id,
    COUNT(qrs.count_executions) AS TotalExecutions,
    SUM(qrs.count_executions) AS TotalExecutionCount,
    MIN(qrs.first_execution_time) AS FirstExecutionTime,
    MAX(qrs.last_execution_time) AS LastExecutionTime,
    MIN(qrs.avg_duration / 1000.0) AS MinDurationMs,  -- Convert to milliseconds
    MAX(qrs.avg_duration / 1000.0) AS MaxDurationMs,  -- Convert to milliseconds
    AVG(qrs.avg_duration / 1000.0) AS AvgDurationMs   -- Convert to milliseconds
FROM 
    sys.query_store_query_text AS qsqt
INNER JOIN 
    sys.query_store_query AS qsq
    ON qsqt.query_text_id = qsq.query_text_id
INNER JOIN 
    sys.query_store_plan AS qsp
    ON qsq.query_id = qsp.query_id
INNER JOIN 
    sys.query_store_runtime_stats AS qrs
    ON qsp.plan_id = qrs.plan_id
--WHERE 
 --   qsqt.query_sql_text LIKE '%notes%'
GROUP BY 
    qsqt.query_sql_text, qsq.query_id
ORDER BY 
    TotalExecutionCount DESC;

------------------------
-- Process running - https://github.com/amachanic/sp_whoisactive/releases
------------------------
WHILE 1 = 1
BEGIN
    EXEC sp_whoisactive @get_locks = 1, @get_task_info = 2;
    WAITFOR DELAY '00:00:01';
END

select * from sys.dm_db_resource_stats

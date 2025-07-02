-- ==============================================
-- Query Store - Understanding DMVs and Relationships
-- ==============================================

-- This script demonstrates how to explore query performance data in SQL Server Query Store
-- by joining key DMVs: sys.query_store_query, sys.query_store_query_text,
-- sys.query_context_settings, sys.query_store_plan, sys.query_store_runtime_stats,
-- and sys.query_store_runtime_stats_interval.

-- ==============================================
-- 1. Retrieve metadata: Query text, context settings, and plans
-- ==============================================

SELECT
    qsq.query_id,
    qsqqt.query_text_id,
    qsqqt.query_sql_text,
    qsq.context_settings_id,
    qcs.set_options,
    qsp.plan_id,
    qsp.is_forced_plan,
    qsp.last_compile_start_time,
    qsp.last_execution_time
FROM sys.query_store_query AS qsq
JOIN sys.query_store_query_text AS qsqqt
    ON qsq.query_text_id = qsqqt.query_text_id
JOIN sys.query_context_settings AS qcs
    ON qsq.context_settings_id = qcs.context_settings_id
JOIN sys.query_store_plan AS qsp
    ON qsq.query_id = qsp.query_id
ORDER BY qsp.last_execution_time DESC;

-- ==============================================
-- 2. Retrieve runtime statistics per plan and time interval
-- ==============================================

SELECT
    qsp.plan_id,
    qsrs.runtime_stats_interval_id,
    qsrs.count_executions,
    qsrs.avg_duration,          -- in microseconds
    qsrs.avg_cpu_time,         -- in microseconds
    qsrs.avg_logical_io_reads,
    qsrs.avg_logical_io_writes,
    qsrs.avg_num_physical_io_reads,
    qsrsrs.start_time,
    qsrsrs.end_time
FROM sys.query_store_plan AS qsp
JOIN sys.query_store_runtime_stats AS qsrs
    ON qsp.plan_id = qsrs.plan_id
JOIN sys.query_store_runtime_stats_interval AS qsrsrs
    ON qsrs.runtime_stats_interval_id = qsrsrs.runtime_stats_interval_id
ORDER BY qsrsrs.start_time DESC;

-- ==============================================
-- 3. Full joined view: From query text to runtime statistics
-- ==============================================

SELECT
    qsq.query_id,
    qsqqt.query_sql_text,
    qcs.set_options,
    qsp.plan_id,
    qsp.is_forced_plan,
    qsp.last_execution_time,
    qsrs.count_executions,
    qsrs.avg_duration,
    qsrs.avg_cpu_time,
    qsrsrs.start_time,
    qsrsrs.end_time
FROM sys.query_store_query AS qsq
JOIN sys.query_store_query_text AS qsqqt
    ON qsq.query_text_id = qsqqt.query_text_id
JOIN sys.query_context_settings AS qcs
    ON qsq.context_settings_id = qcs.context_settings_id
JOIN sys.query_store_plan AS qsp
    ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats AS qsrs
    ON qsp.plan_id = qsrs.plan_id
JOIN sys.query_store_runtime_stats_interval AS qsrsrs
    ON qsrs.runtime_stats_interval_id = qsrsrs.runtime_stats_interval_id
ORDER BY qsrsrs.start_time DESC;
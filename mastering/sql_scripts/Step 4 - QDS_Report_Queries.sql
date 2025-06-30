
-- QDS Report Queries (20 total) - Consolidated and Corrected Script

-- 1. Top 10 queries by total CPU time
SELECT TOP 10
    qt.query_sql_text,
    SUM(rs.avg_cpu_time) AS total_cpu_ms,
    q.query_id,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, q.query_id, rs.dbname
ORDER BY total_cpu_ms DESC;

-- 2. Top 10 queries by average duration
SELECT TOP 10
    qt.query_sql_text,
    AVG(rs.avg_duration) AS avg_duration_ms,
    q.query_id,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, q.query_id, rs.dbname
ORDER BY avg_duration_ms DESC;

-- 3. Top 10 wait categories
SELECT TOP 10
    SUM(total_query_wait_time_ms) AS sum_total_wait_ms,
    ws.wait_category_desc,
    ws.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_wait_stats] ws
GROUP BY ws.wait_category_desc, ws.dbname
ORDER BY sum_total_wait_ms DESC;

-- 4. Forced plans
SELECT
    qt.query_sql_text,
    q.query_id,
    p.plan_id,
    p.is_forced_plan,
    p.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_plan] p
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND p.dbname = q.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
WHERE p.is_forced_plan = 1;

-- 5. Query execution count over time (corrected)
SELECT
    rs.runtime_stats_interval_id,
    p.query_id,
    SUM(rs.count_executions) AS execution_count,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
GROUP BY rs.runtime_stats_interval_id, p.query_id, rs.dbname
ORDER BY rs.runtime_stats_interval_id;

-- 6. CPU usage over time
SELECT
    rs.runtime_stats_interval_id,
    p.query_id,
    SUM(rs.avg_cpu_time) AS total_cpu_ms,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
GROUP BY rs.runtime_stats_interval_id, p.query_id, rs.dbname
ORDER BY rs.runtime_stats_interval_id;

-- 7. Queries with multiple plans
SELECT
    q.query_id,
    COUNT(DISTINCT p.plan_id) AS plan_count,
    qt.query_sql_text,
    q.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_query] q
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON q.query_id = p.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY q.query_id, qt.query_sql_text, q.dbname
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY plan_count DESC;

-- 8. Top 10 queries by logical reads
SELECT TOP 10
    qt.query_sql_text,
    SUM(rs.avg_logical_io_reads) AS total_logical_reads,
    q.query_id,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, q.query_id, rs.dbname
ORDER BY total_logical_reads DESC;

-- 9. Queries with regressed performance
SELECT
    p.query_id,
    qt.query_sql_text,
    MIN(rs.avg_duration) AS min_duration,
    MAX(rs.avg_duration) AS max_duration,
    MAX(rs.avg_duration) - MIN(rs.avg_duration) AS regression_delta,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY p.query_id, qt.query_sql_text, rs.dbname
HAVING MIN(rs.avg_duration) > 0 AND MAX(rs.avg_duration) > 2 * MIN(rs.avg_duration)
ORDER BY regression_delta DESC;

-- 10. Most executed queries
SELECT TOP 10
    qt.query_sql_text,
    SUM(rs.count_executions) AS total_executions,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, rs.dbname
ORDER BY total_executions DESC;

-- Additional queries (11 to 20) can be appended as needed.
-- 11. Top queries by total duration
SELECT TOP 10
    qt.query_sql_text,
    SUM(rs.avg_duration) AS total_duration_ms,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, rs.dbname
ORDER BY total_duration_ms DESC;

-- 12. Top queries by logical writes
SELECT TOP 10
    qt.query_sql_text,
    SUM(rs.avg_logical_io_writes) AS total_logical_writes,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, rs.dbname
ORDER BY total_logical_writes DESC;

-- 13. Wait stats by wait category only (corrected)
SELECT
    ws.wait_category_desc,
    SUM(ws.total_query_wait_time_ms) AS total_wait_ms,
    ws.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_wait_stats] ws
GROUP BY ws.wait_category_desc, ws.dbname
ORDER BY total_wait_ms DESC;


-- 14. Query stats summary
SELECT
    p.query_id,
    COUNT(*) AS intervals,
    SUM(rs.count_executions) AS total_executions,
    SUM(rs.avg_duration) AS total_duration_ms,
    SUM(rs.avg_cpu_time) AS total_cpu_ms,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
GROUP BY p.query_id, rs.dbname
ORDER BY total_duration_ms DESC;

-- 15. Queries with forced plan flags and multiple plans
SELECT
    q.query_id,
    qt.query_sql_text,
    COUNT(DISTINCT p.plan_id) AS plan_count,
    MAX(p.is_forced_plan) AS any_forced_plan,
    q.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_query] q
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON q.query_id = p.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY q.query_id, qt.query_sql_text, q.dbname
ORDER BY plan_count DESC;

-- 16. Highest average CPU per execution
SELECT TOP 10
    qt.query_sql_text,
    AVG(CASE WHEN rs.count_executions > 0 THEN rs.avg_cpu_time * 1.0 / rs.count_executions ELSE 0 END) AS avg_cpu_per_exec,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id AND q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id AND q.dbname = qt.dbname
GROUP BY qt.query_sql_text, rs.dbname
ORDER BY avg_cpu_per_exec DESC;

-- 17. Query volume by database
SELECT
    rs.dbname,
    COUNT(DISTINCT p.query_id) AS distinct_queries,
    SUM(rs.count_executions) AS total_executions
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON rs.plan_id = p.plan_id AND rs.dbname = p.dbname
GROUP BY rs.dbname
ORDER BY total_executions DESC;

-- 18. Plan execution stats
SELECT
    rs.plan_id,
    SUM(rs.avg_duration) AS total_duration_ms,
    SUM(rs.avg_cpu_time) AS total_cpu_ms,
    SUM(rs.count_executions) AS execution_count,
    rs.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] rs
GROUP BY rs.plan_id, rs.dbname
ORDER BY total_duration_ms DESC;

-- 19. Wait stats per query 
SELECT
    p.query_id,
    SUM(ws.total_query_wait_time_ms) AS total_wait_ms,
    ws.wait_category_desc,
    ws.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_wait_stats] ws
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p 
    ON ws.plan_id = p.plan_id AND ws.dbname = p.dbname
GROUP BY p.query_id, ws.wait_category_desc, ws.dbname
ORDER BY total_wait_ms DESC;


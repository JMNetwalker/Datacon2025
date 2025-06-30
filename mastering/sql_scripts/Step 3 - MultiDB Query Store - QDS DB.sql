SELECT TOP 10
    sum(total_query_wait_time_ms) AS sum_total_wait_ms, 
	 ws.[wait_category_desc]
FROM [_xTotalxAcummulatedx_xQDSx_query_store_wait_stats] ws
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON ws.plan_id = p.plan_id and ws.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id and p.dbname = q.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id and q.dbname = qt.dbname
GROUP BY ws.[wait_category_desc]
ORDER BY sum_total_wait_ms DESC;

SELECT TOP 100
    sum(total_query_wait_time_ms) AS sum_total_wait_ms, 
	 ws.[wait_category_desc], 
	 q.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_wait_stats] ws
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] p ON ws.plan_id = p.plan_id and ws.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] q ON p.query_id = q.query_id and p.dbname = q.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query_text] qt ON q.query_text_id = qt.query_text_id and q.dbname = qt.dbname
GROUP BY q.dbname , ws.[wait_category_desc]
ORDER BY q.dbname, sum_total_wait_ms DESC;

SELECT TOP 10 rs.avg_duration, qt.query_sql_text, q.query_id,
    qt.query_text_id, p.plan_id, GETUTCDATE() AS CurrentUTCTime,
    rs.last_execution_time, p.dbname
FROM [_xTotalxAcummulatedx_xQDSx_query_store_query_text] AS qt
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_query] AS q
    ON qt.query_text_id = q.query_text_id and qt.dbname = q.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_plan] AS p
    ON q.query_id = p.query_id and q.dbname = p.dbname
JOIN [_xTotalxAcummulatedx_xQDSx_query_store_runtime_stats] AS rs
    ON p.plan_id = rs.plan_id and p.dbname = rs.dbname
WHERE rs.last_execution_time > DATEADD(DAY, -10, GETUTCDATE())
ORDER BY rs.avg_duration DESC;

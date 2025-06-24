--Prompt #1: I have a problem with database, I don't know the process that is running and what are the command that are executing. Could you give the TSQL to find this information?

SELECT 
    s.session_id,
    s.login_name,
    r.status,
    r.command,
    r.cpu_time,
    r.total_elapsed_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.blocking_session_id,
    t.text AS sql_text
FROM 
    sys.dm_exec_requests r
JOIN 
    sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    s.is_user_process = 1
ORDER BY 
    r.total_elapsed_time DESC;
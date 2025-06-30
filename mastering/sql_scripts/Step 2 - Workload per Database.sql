----------------------------------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual CPU usage max per database 
----------------------------------------------------------------------------------------
SELECT 
    tasks.session_id,
    req.status,
    req.database_id,
    masterdata.name AS database_name,
    req.cpu_time,
    req.command,
    req.last_wait_type,
    req.wait_type,
    req.wait_time,
    sched.status AS scheduler_status,
    substring(
        REPLACE(REPLACE(
            SUBSTRING(ST.text,
                (req.statement_start_offset / 2) + 1,
                (
                    (CASE req.statement_end_offset
                        WHEN -1 THEN DATALENGTH(ST.text)
                        ELSE req.statement_end_offset
                    END - req.statement_start_offset) / 2
                ) + 1),
            CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
FROM sys.dm_exec_requests AS req
JOIN dbo.master_data AS masterdata ON req.database_id = masterdata.database_id
JOIN sys.dm_os_workers AS work ON req.task_address = work.task_address
JOIN sys.dm_os_tasks AS tasks ON req.session_id = tasks.session_id
JOIN sys.dm_os_schedulers AS sched ON sched.scheduler_id = tasks.scheduler_id
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST
WHERE req.status <> 'background'
  AND req.session_id <> @@SPID
  and masterdata.name = 'jmjuradotestdb1'
ORDER BY req.cpu_time DESC;


----------------------------------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual CPU usage max per database and who is.
----------------------------------------------------------------------------------------
SELECT 
    tasks.session_id,
    req.status,
    req.database_id,
    masterdata.name AS database_name,
    s.login_name,
    s.host_name,
    s.program_name,
    c.client_net_address,
    req.cpu_time,
    req.command,
    req.last_wait_type,
    req.wait_type,
    req.wait_time,
    sched.status AS scheduler_status,
    SUBSTRING(
        REPLACE(REPLACE(
            SUBSTRING(ST.text,
                (req.statement_start_offset / 2) + 1,
                (
                    (CASE req.statement_end_offset
                        WHEN -1 THEN DATALENGTH(ST.text)
                        ELSE req.statement_end_offset
                    END - req.statement_start_offset) / 2
                ) + 1),
            CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
FROM sys.dm_exec_requests AS req
JOIN dbo.master_data AS masterdata ON req.database_id = masterdata.database_id
JOIN sys.dm_os_workers AS work ON req.task_address = work.task_address
JOIN sys.dm_os_tasks AS tasks ON req.session_id = tasks.session_id
JOIN sys.dm_os_schedulers AS sched ON sched.scheduler_id = tasks.scheduler_id
JOIN sys.dm_exec_sessions AS s ON req.session_id = s.session_id
JOIN sys.dm_exec_connections AS c ON req.session_id = c.session_id
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST
WHERE req.status <> 'background'
  AND req.session_id <> @@SPID
  AND masterdata.name = 'jmjuradotestdb1'
ORDER BY req.cpu_time DESC;

----------------------------------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual CPU usage max per database and showing who is
----------------------------------------------------------------------------------------
SELECT 
    r.session_id,
    r.status AS request_status,
    r.database_id,
    md.name AS database_name,
    s.login_name,
    s.host_name,
    s.program_name,
    c.client_net_address,
    r.cpu_time,
    r.command,
    wt.wait_type,
    wt.wait_duration_ms,
    wt.resource_description,
    r.last_wait_type,
    r.wait_type AS current_wait_type,
    r.wait_time AS current_wait_time,
    sched.status AS scheduler_status,
    SUBSTRING(
        REPLACE(REPLACE(
            SUBSTRING(st.text,
                (r.statement_start_offset / 2) + 1,
                (
                    (CASE r.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE r.statement_end_offset
                    END - r.statement_start_offset) / 2
                ) + 1),
            CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
FROM sys.dm_exec_requests AS r
LEFT JOIN sys.dm_os_waiting_tasks AS wt ON r.session_id = wt.session_id
JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
JOIN sys.dm_exec_connections AS c ON r.session_id = c.session_id
JOIN sys.dm_os_tasks AS t ON r.session_id = t.session_id
JOIN sys.dm_os_workers AS w ON r.task_address = w.task_address
JOIN sys.dm_os_schedulers AS sched ON t.scheduler_id = sched.scheduler_id
JOIN dbo.master_data AS md ON r.database_id = md.database_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.status <> 'background'
  AND r.session_id <> @@SPID
   AND md.name = 'jmjuradotestdb1'
ORDER BY r.cpu_time DESC;

----------------------------------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual memory usage.
----------------------------------------------------------------------------------------
SELECT bf.database_id, page_type,
    COUNT(*) * 8 / 1024 AS buffer_pool_usage_MB
FROM sys.dm_os_buffer_descriptors bf
JOIN dbo.master_data AS md ON bf.database_id = md.database_id
where bf.database_id<32000 and bf.database_id >4
group by bf.database_id, page_type
order by bf.database_id, page_type
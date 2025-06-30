--------------------------------------------------------------
-- Execute in master database to retrieve the actual workload
--------------------------------------------------------------
select * from sys.elastic_pool_resource_stats where elastic_pool_name ='EPoolDataCon' ORDER BY end_time DESC;
select * from sys.sysdatabases
----------------------------------------------------------------
-- Run this from any database in the Elastic Pool
-- You'll see the same tempdb files across all databases, proving tempdb is shared.
----------------------------------------------------------------
SELECT file_id, type, type_desc, name, physical_name, state, size * 8 / 1024 AS size_MB
from tempdb.sys.database_files;

----------------------------------------------------------------
-- Run this inside each user database
-- Shows how much space is used by data and log files
SELECT * FROM sys.database_files
----------------------------------------------------------------


--------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual workload per database.
--------------------------------------------------------------
SELECT * FROM SYS.DM_DB_RESOURCE_STATS

select req.status, tasks.session_id,  task_state, req.database_id, masterdata.name
wait_type, wait_time, req.last_wait_type, cpu_time, dop,
req.command, 
blocking_session_id,  
substring
(REPLACE
(REPLACE
(SUBSTRING
(ST.text
, (req.statement_start_offset/2) + 1
, (
(CASE statement_end_offset
WHEN -1
THEN DATALENGTH(ST.text)
ELSE req.statement_end_offset
END
- req.statement_start_offset)/2) + 1)
, CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text,
sched.status,
 * from sys.dm_exec_requests req
join dbo.master_data masterdata on req.database_id = masterdata.database_id
join sys.dm_os_workers work on req.task_address = work.task_address 
join sys.dm_os_tasks tasks on req.session_id = tasks.session_id 
join sys.dm_os_schedulers sched on sched.scheduler_id = tasks.scheduler_id
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) as ST
where req.status <> 'background' and req.session_id<> @@spid
order by wait_resource,req.session_id, req.status

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
ORDER BY req.cpu_time DESC;

----------------------------------------------------------------------------------------
-- Execute in jmjuradotestdb1 database to retrieve the actual CPU usage percentage
----------------------------------------------------------------------------------------
WITH cpu_per_db AS (
    SELECT 
        req.database_id,
        masterdata.name AS database_name,
        SUM(req.cpu_time) AS total_cpu_time_ms,
        COUNT(*) AS active_requests
    FROM sys.dm_exec_requests AS req
    JOIN dbo.master_data AS masterdata ON req.database_id = masterdata.database_id
    WHERE req.status <> 'background'
      AND req.session_id <> @@SPID
    GROUP BY req.database_id, masterdata.name
),
total_cpu AS (
    SELECT SUM(total_cpu_time_ms) AS total_cpu_ms FROM cpu_per_db
)
SELECT 
    c.database_id,
    c.database_name,
    c.total_cpu_time_ms,
    t.total_cpu_ms,
    ROUND(100.0 * c.total_cpu_time_ms / NULLIF(t.total_cpu_ms, 0), 2) AS cpu_usage_percent,
    c.active_requests
FROM cpu_per_db c
CROSS JOIN total_cpu t
ORDER BY cpu_usage_percent DESC;


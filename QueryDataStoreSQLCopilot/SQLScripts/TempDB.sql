-------------------------------------------------------------------
----- Data to know Allocation Contention or Metadata Contention
--------------------------------------------------------------------
SELECT
 substring(REPLACE(REPLACE(SUBSTRING(ST.text, (req.statement_start_offset/2) + 1, (
(CASE statement_end_offset WHEN -1 THEN DATALENGTH(ST.text) ELSE req.statement_end_offset END
- req.statement_start_offset)/2) + 1) , CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
,req.database_id
,CASE
      WHEN CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT)
           % 8088 = 0 OR CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT) = 1 THEN 'Is PFS Page'
      WHEN CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT)
           % 511232 = 0 OR CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT) = 2 THEN 'Is GAM Page'
      WHEN (CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT)
           - 1) % 511232 = 0 OR CAST(RIGHT(req.wait_resource,
                      LEN(req.wait_resource)
                      - CHARINDEX(':', req.wait_resource, 3)) AS INT) = 3 THEN 'Is SGAM Page'
      ELSE 'Is Not PFS, GAM, or SGAM page'
    END resourcetype
,sess.program_name
,req.session_id
, sysproc.ecid
,sysproc.status
,sysproc.waittime
,sysproc.lastwaittype
, sysproc.cpu
, sysproc.sql_handle
, req.cpu_time 'cpu_time_ms'
, req.status
, wait_time
, wait_resource
, wait_type
, last_wait_type
, req.total_elapsed_time
, total_scheduled_time
, req.row_count as [Row Count]
, command
, scheduler_id
, memory_usage
, req.writes
, req.reads
, req.logical_reads, blocking_session_id

FROM sys.dm_exec_requests AS req
inner join sys.dm_exec_sessions as sess on sess.session_id = req.session_id
inner join sys.sysprocesses as sysproc on sess.session_id = sysproc.spid
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) as ST
where req.session_id <> @@SPID and sysproc.status <> 'background'
and req.wait_type LIKE 'PAGE%LATCH_%'
    AND req.wait_resource LIKE '2:%'
order by sess.session_id, sysproc.ecid

----------------------------
--Run the Query to obtain the current process.
--------------------------
SELECT
 substring(REPLACE(REPLACE(SUBSTRING(ST.text, (req.statement_start_offset/2) + 1, (
(CASE statement_end_offset WHEN -1 THEN DATALENGTH(ST.text) ELSE req.statement_end_offset END
- req.statement_start_offset)/2) + 1) , CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
,req.database_id
,sess.program_name
,req.session_id
, sysproc.ecid
,sysproc.status
,sysproc.waittime
,sysproc.lastwaittype
, sysproc.cpu
, sysproc.sql_handle
, req.cpu_time 'cpu_time_ms'
, req.status
, wait_time
, wait_resource
, wait_type
, last_wait_type
, req.total_elapsed_time
, total_scheduled_time
, req.row_count as [Row Count]
, command
, scheduler_id
, memory_usage
, req.writes
, req.reads
, req.logical_reads, blocking_session_id

FROM sys.dm_exec_requests AS req
inner join sys.dm_exec_sessions as sess on sess.session_id = req.session_id
inner join sys.sysprocesses as sysproc on sess.session_id = sysproc.spid
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) as ST
where req.session_id <> @@SPID and sysproc.status <> 'background'
order by sess.session_id, sysproc.ecid


---------------
--Space used
----------------
SELECT sys.dm_exec_sessions.session_id AS [SESSION ID],
DB_NAME(2) AS [DATABASE Name],
HOST_NAME AS [System Name],
program_name AS [Program Name],
login_name AS [USER Name],
status,
cpu_time AS [CPU TIME (in milisec)],
total_scheduled_time AS [Total Scheduled TIME (in milisec)],
total_elapsed_time AS    [Elapsed TIME (in milisec)],
(memory_usage * 8)      AS [Memory USAGE (in KB)],
(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
CASE is_user_process
WHEN 1      THEN 'user session'
WHEN 0      THEN 'system session'
END AS [SESSION Type], row_count AS [ROW COUNT]
FROM sys.dm_db_session_space_usage
INNER join
sys.dm_exec_sessions
ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id

--select * from sys.sysprocesses
--DBCC DROPCLEANBUFFERS
--DBCC FREEPROCCACHE
--DBCC procedurecache

--Know database files
select * from tempdb.sys.database_files

--- Know the Page ID and object.
SELECT object_name(object_id), page_info.* 
FROM sys.dm_exec_requests AS d  
CROSS APPLY sys.fn_PageResCracker (d.page_resource) AS r  
CROSS APPLY sys.dm_db_page_info(r.db_id, r.file_id, r.page_id, 'DETAILED') AS page_info
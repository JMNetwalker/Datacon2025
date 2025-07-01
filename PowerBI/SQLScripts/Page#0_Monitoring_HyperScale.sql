DECLARE @SPID AS INT = 109
--Connections
select conn.session_id, net_transport,connect_time, connection_id, protocol_version,sess.host_name, 
sess.PROGRAM_NAME, client_net_address, client_interface_name  from sys.dm_exec_connections conn 
  inner join sys.dm_exec_sessions sess on conn.session_id = sess.session_id
  WHERE CONN.session_id=@SPID
  order by sess.session_id


-- Requests with sysprocess.

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
where req.session_id = @SPID and sysproc.status <> 'background'
order by sess.session_id, sysproc.ecid


select * from sys.sysprocesses WHERE SPID=@SPID

--Perf at DB Level
select TOP 10 * from sys.dm_db_resource_stats order by end_time desc

select * from sys.dm_exec_session_wait_stats WHERE SESSION_ID=@SPID order by session_id, max_wait_time_ms desc
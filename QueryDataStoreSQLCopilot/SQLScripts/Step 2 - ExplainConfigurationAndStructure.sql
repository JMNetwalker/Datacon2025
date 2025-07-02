
---
-- Configuration and structure 
---
SELECT 
    s.name AS [Schema],
    t.name AS [Table]
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
ORDER BY 
    s.name, t.name;

----
-- Special Query Store Data & Clean DB
----
ALTER DATABASE [PerfTroubleshootingDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, 
                                           CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 1), 
                                           DATA_FLUSH_INTERVAL_SECONDS = 60, 
                                           INTERVAL_LENGTH_MINUTES = 1, 
                                           QUERY_CAPTURE_MODE = ALL)
GO
ALTER DATABASE PerfTroubleshootingDB SET QUERY_STORE CLEAR;

----
-- Clean Buffer pool and proc cache
-----
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS

select * from sys.dm_db_resource_stats

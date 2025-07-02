DROP TABLE IF EXISTS dbo.SniffingTest;
GO

CREATE TABLE dbo.SniffingTest (
    Id INT IDENTITY,
    Category INT,
    Padding CHAR(4000) -- To generate noticeable CPU/memory load
);
GO

-- Insert 100,000 rows for Category = 1
INSERT INTO dbo.SniffingTest (Category)
SELECT TOP (100000) 1
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

-- Insert only 100 rows for Category = 2
INSERT INTO dbo.SniffingTest (Category)
SELECT TOP (100) 2
FROM sys.all_objects;
GO

-- Create a supporting index
CREATE NONCLUSTERED INDEX IX_Sniffing_Category ON dbo.SniffingTest(Category);
GO


-- Clear the plan cache to force plan compilation
DBCC FREEPROCCACHE;
GO
ALTER DATABASE PerfTroubleshootingDB SET QUERY_STORE CLEAR;

-- First execution with Category = 2 (very selective)
EXEC sp_executesql N'
    SELECT * FROM dbo.SniffingTest WHERE Category = @cat OPTION (recompile)',
    N'@cat INT',
    @cat = 2;
GO 10

WAITFOR DELAY '00:02:00'
GO
-- Second execution with Category = 1 (returns many rows)
EXEC sp_executesql N'
    SELECT * FROM dbo.SniffingTest WHERE Category = @cat OPTION (recompile)',
    N'@cat INT',
    @cat = 1;
GO 10


EXEC sp_query_store_flush_db
GO

SELECT 
    q.query_id,
    qt.query_sql_text,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.stdev_duration / 1000.0 AS stdev_duration_ms,
    rs.count_executions,
    p.plan_id,
    p.is_forced_plan, 
    qt.query_text_id
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE qt.query_sql_text LIKE '%SniffingTest%'
ORDER BY rs.avg_duration DESC;

-------------------------------------------------
-- Different Execution plans due to:
----- auto-created statistics by SQL.
----- Force Plan 
----- An Index 
-------------------------------------------------
DROP TABLE IF EXISTS [dbo].[Notes]

CREATE TABLE [dbo].[Notes](
	[ID] [int] NULL,
	[NAME] [varchar](200) NULL,
	[id2] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_Notes] PRIMARY KEY CLUSTERED ([id2] ASC))

 ALTER DATABASE PerfTroubleshootingDB SET QUERY_STORE CLEAR;
 DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS

-------------------------------------------------
-- Create the store procedure
--------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.GiveNotes
   @N AS INT = null
AS 
SELECT count(Name),name FROM Notes where ID<@n group by Name

-- Prompt #1: Find the queries in Query Store that were executed by the stored procedure dbo.GiveNotes or that reference the notes table
-- Prompt #2: Great! how many times has been executed the query id #1
-- Prompt #3: do you find any performance issue with the query id #1?
--------------------------------------------------
-- Insert data
--------------------------------------------------
INSERT INTO Notes (ID,Name) SELECT RAND()*(100000 - 1) + 1, 'Info:'+convert(varchar(200),RAND()*(100000 - 1) + 1) 
INSERT INTO Notes (ID,Name) SELECT RAND()*(100000 - 1) + 1, 'Info:'+convert(varchar(200),RAND()*(100000 - 1) + 1) FROM Notes

-- Prompt #4: could you please compare the two execution plans for the query id #1?
-- Prompt #5: Provide the different execution times for each execution plan for the query #1 and the number of executions
-- Prompt #6: Give me a detailed explanation about query_id, plan_id, runtime stats, wait stats
--------------------------------------------------
-- Count the rows
--------------------------------------------------
select count(*) from notes

--------------------------------------------------
-- See what is happening 
-------------------------------------------------- 
declare @n as int = 0
set @n=RAND()*(100000 - 1) + 1
EXEC dbo.GiveNotes @n

--------------------------------------------------
-- Clean buffer pool
-------------------------------------------------- 
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS

CREATE NONCLUSTERED INDEX [NOTES_IX1] ON [dbo].[Notes] ([ID] ASC) include (name)
EXEC dbo.GiveNotes 2 

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
DROP  INDEX [NOTES_IX1] ON [dbo].[Notes]
EXEC dbo.GiveNotes 3

ALTER INDEX [PK_Notes] ON [DBO].[Notes] REBUILD
ALTER INDEX [NOTES_IX1] ON [dbo].[Notes] REBUILD
DROP STATISTICS NOTES.[_WA_Sys_00000001_7EF6D905]
DROP STATISTICS NOTES.[_WA_Sys_00000002_7EF6D905]

UPDATE STATISTICS NOTES([_WA_Sys_00000001_6E01572D]) WITH FULLSCAN
UPDATE STATISTICS NOTES([_WA_Sys_00000002_6E01572D]) WITH FULLSCAN

EXEC sp_query_store_flush_db


----
-------
-- Questions for SQL Copilot
-----------
/*
-- Which queries are consuming the most CPU in the database in the last hour?
-- How can I optimize the query with ID 4?
-- How can I identify and add missing indexes for my database?
-- Are there any missing index suggestions for the high CPU-consuming queries?
-- Which queries are being canceled due to timeouts?
-- Which queries are exhibiting common performance antipatterns?
-- What is the average and maximum duration of the queries canceled by timeouts?
-- Which queries are using inefficient joins or subqueries?
-- Can you provide a list of missing indexes in my database?
-- What are the most common wait times in my database?
-- Which queries are using forced execution plans?
-- Is there any command timeout in the database?
-- Is there any query with different execution plans?
-- What are the reasons for multiple execution plans being generated for the same query?
-- Is parameter sniffing causing performance issues with queries that have multiple execution plans?
-- Are there any queries using unnecessary SELECT * operations?
-- Can you provide a detailed list of wait times and their deltas?
-- Can you provide the text of the queries that are consuming the most CPU?
-- Do you have any recomendation to improve the query id 1?
-- Provide the queries list that are consuming the most of CPU?

Which is the query consuming the CPU?
Is there any command timeout in the database?
Is there any query with different execution plans?
*/

/* Additional text 
Which is the query with major total duration
give me the duration in seconds
Add to the output the object
Please add the number of executions
Add the number of execution plans for this query
*/


---------------------------
-- Others
-----------------------------
-- Tell me the name of the database
-- Tell me the SQL Server version
-- Which Cumulative Update (CU) am I on?
-- I want to create an index for the history table that includes the columns k and a1, where k must be a unique key
-- Create a table to store my employees
-- I’m in Spain, I need the column names in Spanish and include two last names
-- This script creates a table named Empleados in the dbo schema with columns in Spanish and two last names
-- It must include a primary key as a unique index and an index on first name and last names


---------------------------
-- General Performance Troubleshooting
---------------------------
-- Show me the top regressed queries from Query Store in the last 7 days.
-- Which queries have the highest average CPU usage over the past week?
-- Identify the most executed query today.
-- List queries with increasing execution time trends over the past 30 days.
-- What queries are consuming the most memory grant?
-- Show the queries with the most variation in execution plans.
-- What queries have recently changed execution plans?
-- Identify the longest-running query in the last 24 hours.
-- Which queries have had more than 3 different execution plans recently?
-- What is the top query by total logical reads?
-- find queries that stopped using an index only for user tables belongs to dbo.schema
-- Identify the most executed 5 queries today.
-- Give me the query to analyze resource comsuption in Azure SQL Database?

---------------------------
-- Performance Regression Detection
---------------------------
-- Which query had a performance regression last week?
-- Show queries that used to run in less than 1 second but now exceed 5 seconds.
-- Identify queries where duration has doubled in the last week.
-- Show query regressions caused by plan changes.
-- What regressed queries are associated with new indexes?

---------------------------
-- Execution Statistics
---------------------------
-- List queries with the highest total duration.
-- What are the top 5 queries by average duration?
-- Which query has the highest std deviation in execution time?
-- What queries have more than 1000 executions per hour?
-- Identify queries with high max duration compared to their avg.

---------------------------
-- Plan Changes and Forcing
---------------------------
-- What queries have had more than 5 plans in the last month?
-- Show queries where plan forcing was successful.
-- Show me forced plans that are now underperforming.
-- Which plans have been automatically forced by SQL Server?
-- Show queries where plan forcing failed.

---------------------------
-- Resource Usage
---------------------------
-- Show top queries by CPU time.
-- Identify queries consuming the most logical reads.
-- What are the most IO-heavy queries?
-- Which queries have the highest tempdb usage?
-- Show top queries by wait time.

---------------------------
-- Waits and Bottlenecks
---------------------------
-- Which queries experience the most PAGEIOLATCH waits?
-- Identify queries with high CXPACKET waits.
-- Show queries that often wait on RESOURCE_SEMAPHORE.
-- What are the top wait types for my regressed queries?
-- Which queries have high ASYNC_NETWORK_IO waits?

---------------------------
-- Query Text and Patterns
---------------------------
-- Show the query text of the top 10 slowest queries.
-- Which queries use cursors?
-- Identify ad hoc queries with similar execution patterns.
-- What parameterized queries are suffering from plan cache pollution?
-- Find queries using scalar UDFs.

---------------------------
-- Time-Based Analysis
---------------------------
-- What are the busiest hours in terms of query execution?
-- Show query execution patterns over the past week.
-- What time of day do slow queries typically occur?
-- Identify queries with degraded performance only during peak hours.
-- Show execution count for queries per day.

---------------------------
-- Plan and Index Analysis
---------------------------
-- Which queries would benefit from missing indexes?
-- Identify queries affected by parameter sniffing.
-- Show execution plans with key lookups.
-- What plans use full table scans?
-- List plans that use nested loops on large datasets.

---------------------------
-- Object-Level Insights
---------------------------
-- What queries target table Sales.Orders?
-- Which stored procedures are most expensive?
-- Show all queries accessing indexed view vw_FactSales.
-- What queries access the Customers table with high logical reads?
-- Identify queries updating the Inventory table.

---------------------------
-- Plan Comparison
---------------------------
-- Compare two plans of the same query with different performance.
-- What are the plan differences for Query ID 12345?
-- Why did a query switch from hash join to nested loop?
-- Analyze regressions caused by cardinality estimation changes.
-- Show missing statistics for plans with poor performance.

---------------------------
-- Index & Stats Impact
---------------------------
-- What queries are affected by stale statistics?
-- Which queries have degraded after recent index changes?
-- Find queries that stopped using an index.
-- What queries use outdated execution plans due to missing statistics?
-- Show impact of index rebuilds on plan choice.

---------------------------
-- Optimization Opportunities
---------------------------
-- Recommend indexes based on Query Store data.
-- Suggest plan forcing for stable performance.
-- Identify implicit conversion issues in queries.
-- Show queries that could benefit from parameterization.
-- Identify queries using OPTION (RECOMPILE).

---------------------------
-- Security & Blocking
---------------------------
-- Show queries causing blocking.
-- Identify queries waiting for locks frequently.
-- What queries are blocked most often?
-- What blocking chains involve regressed queries?
-- Show average blocking duration per query.

---------------------------
-- Trends and Forecast
---------------------------
-- Forecast query duration trends for next week.
-- Predict if query performance will degrade based on current trend.
-- Show CPU usage trend for Query ID 20001.
-- Show execution count trend for top 10 queries.
-- Identify new queries added in the last 7 days.

---------------------------
-- TempDB and Memory Pressure
---------------------------
-- What queries use large memory grants?
-- Show spill-to-disk operations from sort or hash.
-- Identify tempdb-intensive queries.
-- Which queries cause memory grant waits?
-- Show queries requiring excessive workspace memory.

---------------------------
-- Query Store Configuration
---------------------------
-- What is the current Query Store capture mode?
-- Are any databases close to max Query Store size?
-- When was the last Query Store cleanup?
-- Show QDS size growth over time.
-- What is the oldest captured execution in QDS?

---------------------------
-- Testing and Validation
---------------------------
-- Did query performance improve after plan forcing?
-- What was the performance before and after index creation?
-- Show metrics before and after applying a query hint.
-- What queries got faster after the last update statistics job?
-- Validate if a regressed query is now stable.

---------------------------
-- Housekeeping and Cleanup
---------------------------
-- What queries haven’t executed in the last 30 days?
-- Identify unused forced plans.
-- Show queries with obsolete data in Query Store.
-- What plans should be evicted to free up space?
-- Identify rarely-used stored procedures with high resource cost.


---------------------------
-- Detecting SELECT * usage
---------------------------
Find queries in Query Store that contain SELECT *.
Show queries using SELECT * with the highest average duration.
List queries with SELECT * grouped by client application name.
Which users are executing SELECT * queries most frequently?
What is the total resource usage of queries using SELECT *?

---------------------------
-- Missing Indexes and Scan Patterns
---------------------------
Show top queries by logical reads with no supporting indexes.
Find regressed queries that could benefit from index creation.
Identify queries with large table scans in their execution plans.
Which queries access heap tables or tables with no clustered index?
List queries showing scan count > 1000 without a WHERE clause.

---------------------------
--Wait Stats Analysis
---------------------------
Show queries with the highest CXPACKET waits in Query Store.
List queries with RESOURCE_SEMAPHORE waits and large memory grants.
Identify queries with high ASYNC_NETWORK_IO waits.
Which wait types are most common across top resource-consuming queries?
Show total wait time by wait category for all regressed queries.

---------------------------
--Parallelism Issues
----------------------------
List queries using parallel plans with high CPU cost.
Show plans with degree of parallelism greater than 1.
Identify queries regressed due to switching from serial to parallel plans.
Find queries using high DOP and causing CXCONSUMER waits.
Show execution plans where parallelism leads to regressions.

---------------------------
--User and Client-Specific Patterns
------------------------------
Show total CPU by client application name using Query Store.
List queries by username with the highest execution count.
What users are executing the most expensive queries?
Show performance trends per user or application over time.
Identify apps consistently running inefficient or regressed queries.

---------------------------
--Query Plan Antipatterns
---------------------------
Find queries with key lookups in their execution plans.
List queries performing table scans on large tables.
Identify plans using nested loops with high row count.
Show plans containing table spools or lazy/eager spools.
Find queries with scalar UDFs in SELECT or WHERE clauses.

---------------------------
--Common T-SQL Antipatterns
---------------------------
List queries using LIKE '%term%' in WHERE conditions.
Find queries with non-SARGable predicates (e.g. functions on indexed columns).
Identify queries using implicit data type conversions.
Show queries using cursors or WHILE loops.
List queries using OPTION (RECOMPILE) excessively.

---------------------------
--Regressed Queries and Plan Changes
---------------------------

Show queries that regressed after a plan change.
Find queries with increasing average duration over time.
Which queries have more than 3 plans with large performance variation?
Show differences between the last good plan and the current regressed plan.
List regressed queries by total impact (duration × execution count).

---------------------------
--Cleanup and Optimization Candidates
---------------------------
Find queries in Query Store not executed in the last 30 days.
Show forced plans no longer performing well.
Suggest queries where plan forcing may help stabilize performance.
List unused stored procedures with high resource consumption.
Identify queries that should be rewritten due to inefficiency.

---------------------------
-- Index & Statistics Health
---------------------------
Show queries running against tables with outdated statistics.
Identify queries using filtered indexes with mismatched predicates.
List queries impacted by missing column statistics.
Which queries access large tables with no recent index maintenance?
Show queries using indexes with high fragmentation and low usage.

--------------------------------
-- HyperScale PowerBI scenario
-- Analysis Phase
--------------------------------
-- List all tables in the 'Fact' and 'Dimension' schemas with space usage en MB and number of rows
-- List all tables in the 'Fact' and 'Dimension' schemas with their structure, including data types, primary keys, foreign keys and indexes. Then provide optimization suggestions for DirectQuery scenarios in Power BI.
-- the name of the tables a their relation among them
-- Provide the table names including number of rows and space usage per each
-- Please, provided textual representation for all relations
-- List all foreign key relationships between tables in the 'Fact' and 'Dimension' schemas, showing the cardinality and referenced columns.
-- Could you please let me know what is the meaning of every table?
-- Describe all schemas in this database, listing the number of tables and views per schema.
-- Create a textual data model (ER-style) representation showing how all Fact and Dimension tables are connected.
-- List all tables with the number of rows, total size, and index size, sorted by total size descending.

--------------------------------
-- HyperScale PowerBI scenario
-- Maintenance Phase
--------------------------------
-- List all statistics in the database that have not been updated in the last 7 days, showing table name, number of rows, and last update date.
-- List all indexes in the database with fragmentation higher than 30%, including table name, index name, and page count.
-- Please, provide the TSQL to rebuild all tables in ONLINE mode and UPDATE STATISTICS for all tables that are an automatic statistics
-- Please, provide the TSQL statement to rebuild each table that is part of schema Dimension and Fact  in ONLINE mode and another TSQL statement for UPDATE STATISTICS for all tables that are an automatic statistics
-- Perform a maintenance and data quality health check of this database. Include outdated statistics, index fragmentation, partition distribution, dominant values in key columns, unused space, orphaned rows, and identify any high-cost or unoptimized queries.
-- List all tables with allocated space but zero rows, or with excessive reserved space not used by actual data.
-- Check for fact table rows that reference dimension keys which no longer exist (broken foreign key integrity).
-- Find queries that perform table scans on large tables where no indexes are used, based on recent execution plans.
-- For each key dimension column (e.g. ProductID, RegionID), show the most frequent value and its percentage of total rows.
-- For Fact.Sale table show the most frequent value and its percentage of total rows. using the column [Tax Rate]

--------------------------------
-- HyperScale PowerBI scenario
-- Performance Troubleshooting Phase
--------------------------------
-- I have this query, what are the improves for a better performance that we could apply?
-- Step #1: please simplify the query
-- Step #1: explain me the query
-- Explain in plain language what the following SQL query does, including the purpose of each subquery and the final WHERE clause.
-- Show a histogram of data distribution for key columns used in joins or filters, such as SaleDate, ProductCategory, or Region.
-- Can this query be transformed into a schemabound indexed view that pre-aggregates the sales by [Fiscal Month Label] to improve DirectQuery performance?

---------------
Analyze the following SQL query and provide a detailed performance review tailored for Azure SQL Database Hyperscale and Power BI DirectQuery scenarios. For each recommendation, estimate the potential performance improvement as a percentage (e.g. query runtime reduction, I/O savings, etc.).

1. Could this query benefit from a schemabound indexed view or a materialized view? Estimate the performance gain if implemented.
2. Is there any missing index on the involved tables that would improve join or filter efficiency? Include the suggested index definition and expected benefit.
3. Would using a clustered or nonclustered columnstore index on the main fact table improve performance? Estimate the potential gain in query time or storage.
4. Could partitioning the fact table improve performance by enabling partition elimination? If so, suggest the partition key and scheme, and estimate improvement.
5. Are current statistics sufficient for optimal execution plans? Recommend updates if needed and estimate impact.
6. Does this query preserve query folding when used with Power BI DirectQuery? If not, identify what breaks folding and suggest how to fix it.
7. Recommend any query rewrites or schema redesigns, along with estimated performance improvements for each.

Query:
[PASTE YOUR SQL QUERY HERE]



---------------

-- List all views in the database, indicating whether they are materialized or not, and whether they use schemabinding.
-- For each table in schema 'Fact', show its partitioning configuration, including the partition function and scheme used.
-- List all tables with the number of rows, total size, and index size, sorted by total size descending.


retrieve the details of jmjuradotestdb2
show resource stats of jmjuradotestdv2

--------------------------------
-- Elastic Database Pool
-- Informative
--------------------------------
Show the details of the Azure SQL Elastic Database Pool named GlobalAzureEP, including:
- Elastic pool name
- Edition (e.g., GeneralPurpose)
- Number of vCores
- Maximum storage in GB
- Zone redundancy status
- Minimum and maximum vCores per database
- Current state
- List of databases in the pool

How many Azure SQL Elastic Database Pools do I have in my subscription?
List all Elastic Pools in my subscription with their names, editions, and current state.
Which Elastic Database Pool is using the most CPU right now?
What is the average CPU usage of the Elastic Pool named GlobalAzureEP in the last hour?
What is the DTU or vCore limit of the Elastic Pool named GlobalAzureEP?

What is the edition, vCore count, and max storage size of the Elastic Pool GlobalAzureEP?
Is zone redundancy enabled in the Elastic Pool GlobalAzureEP?
What are the min and max vCore limits per database in GlobalAzureEP?

--------------------------------
-- Elastic Database Pool
-- Informative GlobalAzureEP
--------------------------------
Which database in the Elastic Pool GlobalAzureEP is consuming the most CPU?
List all databases in the Elastic Pool GlobalAzureEP with their current status and resource usage.
How many databases are assigned to the Elastic Pool GlobalAzureEP?
Which database has the highest average log write usage in the last 30 minutes?

--------------------------------
-- Elastic Database Pool
-- Performance GlobalAzureEP
--------------------------------
Show the historical CPU usage for the Elastic Pool GlobalAzureEP over the last 24 hours.
Has any database in the Elastic Pool GlobalAzureEP reached 100% CPU usage recently?
What was the highest CPU usage recorded for GlobalAzureEP this week?

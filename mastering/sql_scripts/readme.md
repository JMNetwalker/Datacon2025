# 📘 Elastic Database Pools Performance Analysis Toolkit

This repository contains a full set of SQL scripts used to simulate, collect, and analyze performance data across multiple databases using **Query Store (QDS)** in Azure SQL Elastic Pools.

## 📂 Files Summary

### 🔹 `step 0 - Clean QDS and Memory.sql`
Cleans Query Store and clears memory across all databases involved in the workload simulation. 
Use this step to start from a clean state before running performance tests.

### 🔹 `Step 1 - Workload Master and DBs.sql`
Creates the workload environment:
- Master control database
- Multiple target databases simulating an Elastic Pool scenario
- Shared procedures to simulate workload execution

### 🔹 `Step 2 - Workload per Database.sql`
Simulates workload against each database:
- Inserts queries with varied complexity
- Ensures Query Store captures realistic usage patterns
- Can be run in parallel to simulate load distribution across pool

### 🔹 `Step 3 - MultiDB Query Store - QDS DB.sql`
Creates a centralized **Query Store data collector**:
- Extracts data from multiple databases in the pool
- Inserts results into a centralized QDS_DB for cross-database analysis
- Enables performance insights at pool level

### 🔹 `Step 4 - QDS_Report_Queries.sql`
Generates detailed reports from the centralized QDS database:
- Shows top resource-consuming queries
- Breaks down CPU, reads, writes, duration, and execution counts
- Identifies problematic queries across the Elastic Pool

### 🔹 `Step 5 - QDS_Report_Views.sql`
Creates reusable **views** to analyze and filter QDS data:
- Filter by query text, wait stats, resource usage
- Simplifies reporting and dashboards
- Ideal for integration with tools like Power BI or Copilot

---

## 🚀 How to Use

1. **Start with Step 0** to clean the environment.
2. **Run Step 1** to set up the workload and databases.
3. **Use Step 2** to simulate workload across databases.
4. **Run Step 3** to collect and consolidate Query Store data.
5. **Generate reports** using Step 4.
6. **(Optional)** Create views with Step 5 to facilitate long-term analysis.

---

## 💡 Notes

- Designed for **Azure SQL Elastic Pools**, but adaptable to any SQL Server environment using Query Store.
- You can scale the number of databases and query executions to simulate real-world workloads.
- Useful for **troubleshooting**, **performance reviews**, and **pool resource planning**.





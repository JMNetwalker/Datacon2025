# 📊 PerfCollector & Analyzer – Consolidated Query Store Analysis Toolkit

This repository provides a complete solution to **collect**, **centralize**, and **analyze** performance data from multiple databases in Azure SQL using Query Store (QDS). It is especially useful for Elastic Database Pools or environments with many independent databases.

---

## 📦 Toolkit Components

### 🔹 `PerfCollector.ps1` – Data Collection Script

This script gathers extensive performance metadata and diagnostics from each individual database.

#### ✅ What It Collects
- **Query Store data**:
  - Query performance history
  - Wait stats
  - Execution timeouts
- **Statistics** status and age
- **Auto-tuning recommendations**
- **Index fragmentation**
- **Missing indexes**
- **MAXDOP checks**
- **Resource usage per database**
- **Table and system table size**

#### 📤 Output
- Each database's data is exported to:
  - `.bcp` and `.xml` files (for QDS-related tables)
  - `PerfChecker.Log` – Summary of findings
- All files are saved to a configurable folder (`$Folder`)

---

### 🔹 `PerfCollectorAnalyzer.ps1` – Data Consolidation Script

This script reads the previously exported `.bcp`/`.xml` files and **imports the data into a central analysis database**.

#### 🧠 Purpose
- Unifies QDS and performance metadata from all databases
- Enables global, cross-database reporting

#### 🛠️ Configuration Parameters
- `Folder`: Path where PerfCollector output was saved
- `server`: Target SQL Server (e.g., Azure SQL logical server)
- `user` / `passwordSecure`: SQL authentication credentials
- `Db`: Name of the **centralized database** where data is stored (must be created beforehand)

---

### 🔹 `GenerateTableFromXMLFormatFile.sql`
SQL helper script to dynamically create tables in the analysis database using the format of exported `.xml` files.

---

### 🔹 `Step 4 - QDS_Report_Queries.sql` & `Step 5 - QDS_Report_Views.sql`
These SQL scripts provide ready-to-use queries and views to analyze the imported data:

#### Sample Reports
- Top queries by CPU, duration, reads/writes
- Wait statistics per database
- Cross-database performance trends
- Normalized views for Power BI or Excel dashboards

---

## 🧪 End-to-End Workflow

1. **Run `PerfCollector.ps1`** in each database (or pool) environment.
2. The script will save `.bcp`, `.xml`, and `.log` files in the specified folder.
3. **Create a centralized empty database** in your target server.
4. Use `GenerateTableFromXMLFormatFile.sql` if needed to generate table structures.
5. **Run `PerfCollectorAnalyzer.ps1`** to import all the collected files into the central database.
6. **Run `QDS_Report_Queries.sql` and `QDS_Report_Views.sql`** to start analyzing the data.

---

## 📚 Additional Resources

📖 Official blog post:  
👉 [Lesson Learned #224 - Hands-on Labs: Checking the performance with PerfCollector & Analyzer](https://techcommunity.microsoft.com/blog/azuredbsupport/lesson-learned-224hands-on-labs-checking-the-performance-with-perf-collector-ana/3574602)

📹 Video guide (YouTube):  
👉 `https://www.youtube.com/watch?v=pfnSdhk4Za0`

---

## 🎯 Ideal For

- Performance tuning across many Azure SQL Databases
- Elastic Pool analysis and right-sizing
- Consolidated QDS investigation
- Managed Instance troubleshooting
- Power BI dashboards based on historical performance

# 📚 Mastering Elastic Database Pools – Performance Toolkit

This repository contains all the resources used in the session **"Mastering Elastic Database Pools: Best Practices and Troubleshooting from Microsoft Support"**. It includes real-world PowerShell tools, SQL scripts, and lab content to simulate, analyze, and optimize performance across Azure SQL Databases, especially when using Elastic Database Pools.

---

## 📁 Folder Overview

### 📂 `PPT/` – Slide Decks and Presentation Materials
- Session slides presented during the hands-on lab or conference.
- Contains speaker bios, agenda, demo architecture, and summary.
- Useful for training sessions, internal workshops, or onboarding teams.

### 📂 `SQL_Scripts/` – Query Store & Workload Simulation Scripts

Includes tools and structured scripts to:
- Simulate workloads across one or multiple databases
- Collect and analyze Query Store (QDS) data
- Build consolidated performance databases

**Highlighted files:**
- `Step 1-3`: Create test databases, inject workloads
- `Step 4`: Generate reports using QDS data
- `Step 5`: Create views for cross-database analysis
- `GenerateTableFromXMLFormatFile.sql`: Create tables from XML for consolidated QDS imports

### 📂 `PowerShell/` – Diagnostic and Simulation Tools

Powerful PowerShell scripts to simulate load and analyze performance:

#### 🔸 **`PerfCollector.ps1`**
- Collects Query Store, index, statistics, and resource usage info from multiple databases
- Saves data in `.bcp` and `.xml` files for offline analysis

#### 🔸 **`PerfCollectorAnalyzer.ps1`**
- Imports all data from `PerfCollector` into a centralized SQL database
- Enables consolidated dashboards and advanced analysis

#### 🔸 **`DoneThreads.ps1` + `ExecutionConnectionTimeSpent.ps1`**
- Simulate real-world workloads (HighCPU, I/O, Locks, TempDB contention, etc.)
- Designed for concurrency, stress testing, retry logic, and telemetry capture

#### 🔸 **`KillAllProcess.ps1`**
- Terminates all test sessions launched during simulation

#### 🔸 `Config.txt` + `Secrets.txt`
- Configuration files used to control workload settings and authentication

---

## 📘 Related Blog Article

👉 **Lesson Learned #224 – Checking performance with PerfCollector & Analyzer**  
📎 https://techcommunity.microsoft.com/blog/azuredbsupport/lesson-learned-224hands-on-labs-checking-the-performance-with-perf-collector-ana/3574602

---

## 🎯 Ideal Use Cases

- Training engineers on troubleshooting and tuning
- Simulating performance scenarios in Azure SQL Elastic Pools
- Consolidated performance analytics using Query Store
- Building performance dashboards across multiple databases

---

## 🛠 Requirements

- Azure SQL Database / Elastic Pools / Managed Instance
- PowerShell 5+ (Windows), ODBC/SQL Client Tools
- Permissions to execute queries, create tables, and connect via SQL Authentication

---

## 🧪 Recommended Workflow

1. Simulate workloads using `DoneThreads.ps1`
2. Collect telemetry using `PerfCollector.ps1`
3. Import into a central database with `PerfCollectorAnalyzer.ps1`
4. Run SQL reports from `SQL_Scripts` folder to analyze results

---

## 📬 Contact

For questions, contributions, or enhancements, visit the [Azure Database Support Blog](https://techcommunity.microsoft.com/t5/azure-database-support-blog/bg-p/AzureDatabaseSupportBlog).


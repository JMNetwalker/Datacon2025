# 🧠 Query Store and Azure SQL Copilot – Who is the fairest in the land?

This hands-on workshop presented at **DataCon Seattle – June 2025** is focused on identifying and resolving common performance issues in **Azure SQL Database** using **Query Store**, **SSMS Copilot**, and a simulated Python application.

---

## 🎯 Goals

- Detect real-world performance issues: high CPU, CXPACKET, command timeouts, deadlocks, etc.
- Use **Query Data Store (QDS)** for diagnosing regressions and performance anomalies.
- Leverage **SSMS Copilot** to receive actionable insights and resolve issues faster.
- Apply best coding practices for retry logic, concurrency, and SQL efficiency.
- Promote collaboration between developers and DBAs for proactive issue resolution.

---

## 🧪 Hands-On Labs

Using a Python app with simulated workloads, participants experience and troubleshoot scenarios such as:

- High CPU & CXPACKET queries  
- Execution plan regressions (parameter sniffing)  
- Command timeout vs connection timeout  
- Inefficient bulk inserts  
- High concurrency and blocking  
- Real-time diagnostics using QDS and Copilot  
- Cross-database query analysis in Elastic Pools

---

## 🛠️ Technologies Used

- **Azure SQL Database** (Serverless, Gen5, 4 vCores)
- **Query Store**
- **SSMS Copilot**
- **ODBC + Python (Driver 18)**
- Simulation of bad practices and inefficiencies
- **PowerShell** scripts for bulk insert and data analysis

---

## 🧩 Tables Simulated

Includes specific tables to simulate:

- High CPU load
- Network latency
- Inefficient joins
- High concurrency and blocking
- Deadlocks
- `tempdb` contention

---

## 💬 Copilot Prompt Examples

Here are some prompts used during the workshop with **SSMS Copilot**:

- `Which queries are consuming the most CPU in the last hour?`
- `Are there any missing index suggestions?`
- `Is parameter sniffing causing performance issues?`
- `Show me the execution plan for query ID 4`
- `Which queries are being canceled due to timeouts?`

---

## 📁 Folder Structure

- `PPT/`  
  Contains the PowerPoint presentation used in the session.

- `Backup/`  
  Backup of the demo **Azure SQL Database** used during the simulation.

- `PowerShell/`  
  Scripts for:
  - `dbTestProject.ps1` – Launches multi-scenario tests from the shell.
  - `PerfAnalyzer.ps1` – Analyzes query performance collected across databases.

- `SQLScripts/`  
  Contains SQL scripts for:
  - Understanding Query Store structure.
  - Capturing execution times.
  - Diagnosing regressions and timeouts.
  - Extracting query plans in XML.
  - Practicing with real QDS queries.

# 🧠 Query Store and Azure SQL Copilot – Who is the fairest in the land?

This hands-on workshop presented at **Datacon Seattle June 2025** is focused on identifying and resolving common performance issues in **Azure SQL Database** using **Query Store**, **SSMS Copilot**, and a simulated Python application.

## 🎯 Goals

- Detect real-world performance issues: high CPU, CXPACKET, command timeouts, deadlocks, etc.
- Use **Query Data Store (QDS)** for diagnosing regressions and performance anomalies.
- Leverage **SSMS Copilot** to receive actionable insights and resolve issues faster.
- Apply best coding practices for retry logic, concurrency, and SQL efficiency.
- Promote collaboration between developers and DBAs for proactive issue resolution.

## 🧪 Hands-On Labs

Using a Python app with simulated workloads, participants experience and troubleshoot scenarios such as:

1. High CPU & CXPACKET queries  
2. Execution plan regressions (parameter sniffing)  
3. Command timeout vs connection timeout  
4. Inefficient bulk inserts  
5. High concurrency and blocking  
6. Real-time diagnostics using QDS and Copilot  
7. Cross-database query analysis in Elastic Pools  

## 🛠️ Technologies Used

- **Azure SQL Database** (Serverless, Gen5, 4 vCores)
- **Query Store**
- **SSMS Copilot**
- **ODBC + Python (Driver 18)**
- Simulation of bad practices and inefficiencies
- PowerShell scripts for bulk insert

## 🧩 Tables Simulated

Includes specific tables to simulate high CPU, network latency, inefficient joins, concurrency, deadlocks, tempdb contention, and more.

## 💬 Copilot Prompt Examples

Examples of Copilot prompts used during the session:

- `Which queries are consuming the most CPU in the last hour?`
- `Are there any missing index suggestions?`
- `Is parameter sniffing causing performance issues?`
- `Show me the execution plan for query ID 4`
- `Which queries are being canceled due to timeouts?`

> _Empower yourself to detect, diagnose and solve performance problems before your users even notice them._

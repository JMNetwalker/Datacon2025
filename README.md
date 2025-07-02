# 🧠 DataCon 2025 Workshop Projects

Welcome to the **DataCon 2025 Collection**, featuring three advanced technical workshops led by the Microsoft Support Escalation Engineering team. Each folder contains a full environment including PowerPoint decks, SQL scripts, source code (Python/PowerShell), and configuration files to help you master complex performance and analytics scenarios with Azure SQL and Power BI.

---

## 📁 1. Query Store and Azure SQL Copilot – Who is the fairest in the land?

**Focus:** Reproduce and troubleshoot performance issues using Python simulations, Query Store, and SSMS Copilot.

**Key Topics:**
- High CPU, CXPACKET, command timeouts, deadlocks
- Query regressions and plan analysis
- Connection vs execution timeouts
- Copilot diagnostics and natural language troubleshooting

**Components:**
- `PPT/`: Workshop slide deck  
- `SQLScripts/`: Scripts to analyze Query Store performance and regressions  
- `PowerShell/`: Tools like `PerfAnalyzer` and `dbTestProject.ps1`  
- `PythonApp/`: Python simulation engine for generating workloads  
- `Backup/`: Azure SQL DB backup for reproducibility

---

## 📁 2. Mastering Elastic Database Pools: Best Practices and Troubleshooting from Microsoft Support

**Focus:** Best practices and diagnostics in Elastic Pools, resource governance, and multi-tenant troubleshooting using Query Store and telemetry.

**Key Topics:**
- Elastic Pool resource management
- Scaling strategies
- Cross-database analysis using `PerfCollector` and `PerfAnalyzer`
- Query Store consolidation and tuning

**Components:**
- `PPT/`: Presentation with real-world customer cases  
- `SQLScripts/`: Elastic Pool diagnostics, tuning, and governance scripts  
- `PowerShell/`: `PerfCollector` and analysis tools  
- `Demos/`: Consolidated telemetry and resource pattern examples  

---

## 📁 3. Power BI, DirectQuery & SQL Server – Is It a Good Choice?

**Focus:** Understanding performance, bottlenecks, and best practices using DirectQuery in production environments with SQL Server (On-Prem, IaaS, MI, Azure SQL DB).

**Key Topics:**
- DirectQuery latency and CPU overhead
- Real-time vs cached model comparison
- Query folding, timeouts, and visual optimization
- Indexing and partitioning impact in Power BI

**Components:**
- `PPT/`: Comparative results between optimized and unoptimized workloads  
- `SQLScripts/`: Queries used in real dashboards with/without improvements  
- `PowerBIReports/`: PBIX examples with connected datasets  
- `DemoDB/`: Azure SQL Hyperscale demo databases (v1 and v2)

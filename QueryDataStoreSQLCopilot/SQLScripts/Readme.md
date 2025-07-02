# 📁 SQL Scripts for Query Store & Azure SQL Copilot Workshop

This folder contains all the SQL scripts used during the workshop **“Query Store and Azure SQL Copilot, who is the fairest in the land?”**. Each script is designed to support demonstrations of real-world performance issues and how **Query Store** and **SSMS Copilot** can help diagnose, analyze, and solve them.

---

## 🗂️ Script Overview

### ✅ `Step 0 - Prompts.sql`
- Includes a curated list of **Copilot prompts** used during the workshop.
- Helps participants quickly analyze CPU usage, query regressions, timeouts, and missing indexes using natural language.

### 🧠 `Step 2 - ExplainConfigurationAndStructure.sql`
- Explains the configuration of **Query Store**.
- Shows which tables and views are critical to monitor query performance internally.

### ⏱️ `Step 3 - Execution time.sql`
- Focuses on collecting **execution time statistics** from Query Store.
- Helps identify which queries are consuming more resources over time.

### 🧪 `Step 4 - Play with QDS.sql`
- Interactive script for practicing different **Query Store diagnostics**.
- Includes scenarios to identify **plan regressions**, high resource-consuming queries, and forced plans.

### 🔍 `Step 5 - Identify the PlanID and Extract XML.sql`
- Queries to identify **plan_id**, extract the **execution plan in XML**, and analyze plan choices.
- Supports root cause analysis in degraded performance scenarios.

### 🚨 `Step 6 - Executions and Timeouts.sql`
- Focused on detecting queries **canceled due to timeout**.
- Retrieves **query_id**, frequency of timeouts, and associated patterns.

### 📈 `Step7 - Bulk Insert and High DataIO.sql`
- Diagnoses **bulk insert operations** and queries with **high Data IO**.
- Demonstrates how QDS helps detect inefficient write patterns and storage bottlenecks.

### 🧊 `TempDB.sql`
- Analyzes usage of **tempdb** in the workload.
- Identifies contention and potential misuses, correlating with session-level activity.

---

## 🎓 Bonus Scripts

### `QDS_Introduction_Understanding.sql`
- A guided walkthrough of **Query Store concepts**.
- Explains how runtime stats, wait stats, and query plans are tracked.

### `QDS_Introduction_Regresion.sql`
- Focuses on **plan regressions**.
- Shows how changes in execution plans can affect performance and how to detect them.

---

## 💡 Use Cases

These scripts were used alongside a **Python simulation application** that generated typical performance issues. Attendees used these scripts to:

- Monitor queries in real time using **Query Store views**.
- Ask questions directly to **SSMS Copilot** to solve problems faster.
- Validate **root causes**, **plan stability**, and **performance degradations**.

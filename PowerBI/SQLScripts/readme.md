# 📁 SQLScripts – Technical Demonstrations for Performance Optimization

This folder contains all the SQL scripts used during the live session **"Power BI, DirectQuery and SQL Server – Is it a good choice?"**. Each script represents a step in a real-world performance troubleshooting journey for Power BI DirectQuery scenarios against an Azure SQL Hyperscale database.

---

## 🔧 Configuration and Monitoring Scripts

### `Page#0_InitialConfiguration.sql`
Initializes the session environment: sets compatibility levels, enables Query Store, and prepares session-level configuration settings to support monitoring and tuning.

### `Page#0_MaintenancePlan.sql`
Implements a basic maintenance plan including index rebuild/reorganize and statistics update to simulate a healthy operational environment.

### `Page#0_Monitoring_HyperScale.sql`
Provides a monitoring snapshot of the Azure SQL Hyperscale environment:
- Current vCore usage
- DTU limits
- Active sessions
- Elastic pool diagnostics (if applicable)

---

## 📊 Performance Scenarios and Solutions

Each “Page” corresponds to a Power BI visual and related SQL query. Scripts ending with `_Solution.sql` show the optimized version of the query or schema.

---

### 🧮 Page 1: Total Sales per Fiscal Month Label

#### `Page#1_TotalPerFiscalMonthLabel.sql`
Query for total sales grouped by fiscal month. Initial execution time: 4 minutes.

#### `Page#1_TotalPerFiscalMonthLabel_Solution.sql`
Optimized using a **pre-aggregated indexed view**, execution time reduced to 0 seconds.

---

### 🏙️ Page 2: Total Sales per Fiscal Month Label and City

#### `Page#2_TotalPerFiscalMonthLabel_City.sql`
Expands the grouping to include city-level granularity. Initial execution time: 4 minutes.

#### `Page#2_TotalPerFiscalMonthLabel_City_Solution.sql`
Improved using an **indexed view** that covers both month and city. Final execution time: ~15 seconds.

---

### 🧾 Page 3: Sales per Month, Stock Item and Date Filters

#### `Page#3_TotalPerFiscalMonthLabel_Stock_Filter.sql`
Adds complexity with filtering by month and grouping by stock items. Initial time: 4 minutes.

#### `Page#3_TotalPerFiscalMonthLabel_Stock_Filter_Solution.sql`
Optimized using **table partitioning** and **clustered columnstore index**. Execution time reduced to ~3 seconds.

---

### 🧑 Page 4: Sales Count per Month and Salesperson

#### `Page#4_TotalPerFiscalMonthLabel_SalesPerson.sql`
Reports total sales per fiscal month and salesperson. Initial time: 4 minutes.

#### `Page#4_TotalPerFiscalMonthLabel_SalesPerson_Solution.sql`
Uses **partitioning and columnstore indexing** to drop execution time to ~20 seconds.

---

### 🧱 Page 5: Creating the Columnstore Index

#### `Page#5_SaleColumnStoreIndex_Creation.sql`
Script to create a **Clustered Columnstore Index** on `Fact.Sale`. This supports scenarios from pages 3, 4, and 5.

---

### 💡 Page 6: Full Columnstore Scenario and SQLDW Compatibility

#### `Page#6_TotalColumnStoreIndex.sql`
Simulates a Power BI report that relies entirely on columnstore indexing for efficient scan-based access over the full fact table.

#### `Page#6_SQLDWDefinition.sql`
Outlines how the same solution could be implemented in **Azure Synapse (SQL Data Warehouse)**. Demonstrates scalability of the pattern in larger environments.

---

## 🧠 Summary

These scripts demonstrate how thoughtful indexing, partitioning, and pre-aggregation dramatically improve performance in DirectQuery workloads against large datasets in SQL Server and Azure SQL.

You can run each pair of scripts (base + solution) to compare query plans and performance.

---

## 🧪 Tip: Use Query Store

All examples leverage **Query Store** to:
- Capture execution statistics
- Visualize regressions and improvements
- Understand the effect of schema changes on performance

# 🚀 Power BI, DirectQuery & SQL Server – Is It a Good Choice?

This repository showcases advanced performance optimization techniques for Power BI reports running in **DirectQuery mode** against large datasets hosted in **Azure SQL Database – Hyperscale**. It supports educational workshops and practical sessions where different real-world problems were solved using various SQL Server strategies.

---

## 🗂️ Repository Structure

### 📁 `/SQLScripts/`
A collection of T-SQL scripts used to simulate Power BI-generated queries and their optimized versions. These scripts demonstrate techniques such as:
- Materialized Indexed Views
- Columnstore Indexing
- Partitioning
- SQL DW Patterns

Each `Page#X` file represents a specific scenario, and `*_Solution.sql` files contain the optimized fixes.

---

## 📖 Session Summary

This session was built around a workshop format where each page (scenario) simulated a common Power BI DirectQuery bottleneck. The performance issues and solutions are supported by real blog posts from Microsoft’s Azure Database Support team.

---

## 🧪 Scenario Overview

| Page | Description                                             | Optimization                        | Result              |
|------|---------------------------------------------------------|-------------------------------------|---------------------|
| 1    | Grouping by Fiscal Month Label                          | Indexed View                        | ~4 min → < 1 sec    |
| 2    | Fiscal Month Label + City                               | Indexed View                        | ~4 min → ~15 sec    |
| 3    | Month + Stock Filtering                                  | Partitioning + Columnstore          | ~4 min → ~3 sec     |
| 4    | Sales by SalesPerson                                     | Columnstore + Partitioning          | ~4 min → ~20 sec    |
| 5    | SaleColumnStoreIndex Creation                            | Clustered Columnstore Index         | Highly efficient    |
| 6    | SQL DW Pattern + Columnstore Table                       | Synapse-style design (partitioned)  | Subsecond, scalable |

Support scripts include:
- `Page#0_InitialConfiguration.sql`: Compatibility level, Query Store setup
- `Page#0_MaintenancePlan.sql`: Index/statistics maintenance routines
- `Page#0_Monitoring_HyperScale.sql`: Monitors Hyperscale resources and sessions

---

## 🔎 Deep Dive – Script Logic

### Indexed Views – Page 1 & 2
Aggregates by `FiscalMonthLabel` using a materialized view created with `SCHEMABINDING`. Indexes are applied to the join key (`DeliveryDateKey`) and aggregated column for optimizer reuse.

### Partitioning & Filtering – Page 3
Improves filtering on `Fact.Sale` using a partition function based on `DeliveryDateKey`, reducing scanned data and execution time.

### Columnstore Optimization – Page 4, 5, 6
Combines horizontal partitioning and clustered columnstore indexing on `Fact.SaleColumnStoreIndex`, ideal for large-scale aggregation queries.

---

## 📚 Lessons Learned – "All started with the phrase…"

These blog posts from Microsoft Azure DB Support directly inspired the implementation scenarios.

### ✅ Lesson Learned #247: *"Indexed Views"*
- Context: Slow aggregation by month in Power BI DirectQuery on 234M rows.
- Fix: Materialized indexed view on `FiscalMonthLabel`.
- Result: From ~4 min → instant.

🔗 [Read Article](https://techcommunity.microsoft.com/blog/azuredbsupport/lesson-learned-247-all-started-with-the-phrase-in-powerbi-direct-query-is-slow--/3695858)

---

### ✅ Lesson Learned #249: *"Partitioned Table"*
- Context: Slow queries when filtering by month + stock item.
- Fix: Partitioned table on `DeliveryDateKey`.
- Result: Major performance gain with selective scans.

🔗 [Read Article](https://techcommunity.microsoft.com/blog/azuredbsupport/lesson-learned-249-all-started-with-the-phrase-in-powerbi-direct-query-is-slow-p/3696955)

---

### ✅ Lesson Learned #250: *"Columnstore Index"*
- Context: Complex filtering on city, month, and stock data.
- Fix: Partitioned table + clustered columnstore index.
- Result: Performance 10× improvement; reduced table size.

🔗 [Read Article](https://techcommunity.microsoft.com/blog/azuredbsupport/lesson-learned-250-all-started-with-the-phrase-in-powerbi-direct-query-is-slow-c/3697879)

---

## 🧭 Mapping Scenarios to Lessons

| Scenario                                 | Optimization Technique        | Blog Post       |
|------------------------------------------|-------------------------------|-----------------|
| Page 1 – Fiscal Month Aggregations       | Indexed Views                 | LL #247         |
| Page 2 - Fiscal Month & Label Filtering  | Indexes                       |                 | 
| Page 3 – Stock Filtering                 | Partitioning                  | LL #249         |
| Page 4 – Sales by SalesPerson            | Filtered Indexes              |                 |
| Page 5 - Adhoc queries                   | Clustered Columnstore Index   | LL #250         |
| Page 6 - SQLDW                           | Clustered Columnstore Index   | LL #250         |

---

## 🔗 Additional References

- Azure SQL DB Support Blog: [https://techcommunity.microsoft.com/blog/azuredbsupport](https://techcommunity.microsoft.com/blog/azuredbsupport)
- Indexed Views in Azure SQL DB: [Docs](https://learn.microsoft.com/sql/relational-databases/views/create-indexed-views)
- Columnstore Index Overview: [Docs](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-overview)




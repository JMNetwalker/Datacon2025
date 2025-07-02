# 🗄️ PerfTroubleshootingDB.7z.001

This file is the **split 7-Zip archive** containing the backup file `PerfTroubleshootingDB.bak`.

---

## 🧩 What’s Inside?

- `PerfTroubleshootingDB.bak`  
  A full **SQL Server backup** used as the **sample database** for the Python simulation app in the workshop *"Query Store and Azure SQL Copilot – Who is the fairest in the land?"*

---

## 🛠️ How to Use

1. Ensure you have **7-Zip** installed.
2. Download all parts of the archive (e.g., `.7z.001`, `.7z.002`, ... if split).
3. Right-click on `PerfTroubleshootingDB.7z.001` and select **Extract here**.
4. You will get `PerfTroubleshootingDB.bak`.
5. Restore it using SQL Server Management Studio or `RESTORE DATABASE` command:
```sql
RESTORE DATABASE PerfTroubleshootingDB FROM DISK = 'C:\Path\PerfTroubleshootingDB.bak' WITH MOVE ...
```

---

## 🧪 Purpose

Used to simulate:
- High CPU queries
- Plan regressions
- Blocking and deadlocks
- Chatty apps and timeouts


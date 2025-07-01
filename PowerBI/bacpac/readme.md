## 🗃️ `bacpacs/` Folder – Importable Database Versions

The `bacpacs/` folder contains two compressed `.bacpac` files representing the full state of the database in different stages:

| File Name                        | Description                                                                 |
|----------------------------------|-----------------------------------------------------------------------------|
| `PowerBIHyperScaleDemo.bacpac`   | ✅ Optimized version with all performance enhancements implemented.         |
| `PowerBIHyperScaleDemo_v1.bacpac`| 🐌 Original version with no improvements, showing slow performance.         |

> ⚠️ **Important**: Due to file size (~1.5 GB each), the `.bacpac` files are split using **7-Zip**. To reconstruct the full file:
> 1. Download all `.7z.001`, `.7z.002`, ... parts.
> 2. Use [7-Zip](https://www.7-zip.org/) to extract the `.bacpac` file.

---

### 🛠️ Importing the `.bacpac` Files into Azure SQL

These files can be imported into any **Azure SQL Database** (preferably Hyperscale Gen5) or even into **SQL Server On-Premises**.

Use the following command with `sqlpackage.exe`:

```bash
"sqlpackage.exe" ^
  /Action:Import ^
  /SourceFile:"PowerBIHyperScaleDemo.bacpac" ^
  /TargetServerName:"yourserver.database.windows.net" ^
  /TargetDatabaseName:"PowerBIHyperScaleDemo" ^
  /TargetUser:"yourusername" ^
  /TargetPassword:"yourpassword"


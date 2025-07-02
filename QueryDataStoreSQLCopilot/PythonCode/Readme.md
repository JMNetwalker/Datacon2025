# GiveNotesPerformance.py - Performance Simulation for Azure SQL

This Python application simulates **real-world performance issues** in Azure SQL Database using various techniques such as high CPU load, command timeouts, execution plan variations, deadlocks, and concurrency. It is designed for **educational and diagnostic purposes**, complementing the "Query Store and Azure SQL Copilot" workshop.

---

## 📂 credentials.txt

This file contains the database connection parameters in the following format:

```ini
username=username
password=pwd
dbname=dbname
servername=servername
appName=TEST-DataCon
dbnameadditional1=
dbnameadditional2=
sufix=.database.windows.net
port=1433
```

> 📌 The file is securely read from `C:\MyDocs\Save\credentials.txt` and is essential for authentication and routing.

---

## 🧪 Main Features

The script allows simulating and analyzing the following scenarios:

| Scenario ID | Description |
|-------------|-------------|
| 1           | High CPU (single-threaded) |
| 2           | High CPU (multi-threaded) |
| 3           | Command timeout with retry logic |
| 4           | Different execution plans (parameter sniffing) |
| 5           | High network latency |
| 6           | Concurrency issues |
| 7           | CXPACKET contention (parallelism) |
| 8           | Deadlock simulation |
| 9           | ODBC connection reuse after error |
| 10          | Chatty application pattern |
| 11          | TempDB object contention |
| 12          | TempDB data contention |
| 13          | Connection benchmark stress test |
| 14          | Execution loop benchmark with statistics |
| 15          | Extreme data inefficiency |
| 16          | Query Store Read-Only scenario |

---

## 🧠 Architecture & Modules

- `ConnectToTheDB()`: Central function for connecting to Azure SQL with retry logic.
- `RunHighCPU()`, `RunCommandTimeout()`, `RunHighNetworkIO()`: Simulate specific performance patterns.
- `simulate_deadlock()`, `simulate_concurrency()`: Stress concurrency & locking.
- `RunChattyApplication()`: Simulates frequent, inefficient queries with/without caching.
- `run_connection_benchmark()`: Evaluates connection overhead at different levels of concurrency.
- `create_gui()`: A Tkinter GUI to select and launch scenarios interactively.

---

## 📊 Observability & Diagnostics

- Uses `Query Store` for monitoring queries.
- Enables colorful console output for better UX.
- Records logs in `C:\MyDocs\Save\error_log.log`
- Supports `matplotlib` charts for performance stats.
- Tracks retry attempts and execution times per thread.

---

## 🚀 How to Run

1. Prepare a valid `credentials.txt` file.
2. Ensure Python 3.x and required packages (`pyodbc`, `matplotlib`, `tkinter`) are installed.
3. Launch the script:
```bash
python GiveNotesPerformance.py
```
4. Select the scenario from the GUI and observe metrics/logs/output.

---

## 📘 Use Case

This tool is ideal for:

- Reproducing performance problems.
- Observing how Query Store captures patterns.
- Validating Copilot diagnostics.
- Testing application resiliency and retry mechanisms.

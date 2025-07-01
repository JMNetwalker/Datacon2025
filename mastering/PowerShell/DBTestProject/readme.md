
# 📘 Elastic Database Pools Performance & Workload Simulation Toolkit

This repository contains key components to **simulate, test, and analyze workloads in Azure SQL Elastic Database Pools**:

**PowerShell Toolkit** – Designed to simulate customizable SQL workload patterns (CPU, I/O, locks, etc.) across a single DB, multiple DBs, or an entire Elastic Pool.

## ⚙️ PowerShell Workload Simulation Toolkit

### 🔹 `DoneThreads.ps1` – Orchestrator Script

This is the **main launcher** that coordinates workload simulations using multiple threads (PowerShell jobs). Each thread runs the `ExecutionConnectionTimeSpent.ps1` script in parallel to simulate different workload types.

**Main Responsibilities:**
- Accepts input parameters:
  - `NumberOfConcurrentTasks`: Number of threads to simulate parallel users.
  - `ScenarioType`: Workload scenario (e.g., HighCPU, HighLocks, HighDataIO).
  - `HowManyOperations`: Number of executions per thread.
  - `PowerShellLocationToExecute`: Path to execution script.
- Launches child PowerShell jobs using `Start-Job` or parallel execution
- Includes a `logMsgParallel` function with timestamped, color-coded output to provide real-time tracking

**Advanced Behavior:**
- Dynamically constructs the command line for each thread
- Ensures even distribution of operations across threads
- Designed to simulate concurrency and contention in Elastic Pools
- Can run thousands of operations in minutes under configurable retry/timeout rules

---

### 🔹 `ExecutionConnectionTimeSpent.ps1` – Execution Engine

This is the **workhorse script** responsible for:
- Connecting to SQL databases using parameters from `Config.txt` and `Secrets.txt`
- Creating schema dynamically for specific test cases (e.g., wide tables for network IO)
- Executing DML operations under load
- Simulating errors, retries, timeouts, delays, and pool behavior

**Scenarios Simulated:**
- `HighCPU`: Intensive insert operations into large tables
- `HighDATAIO`, `HighDATAIOBlocks`: Read/write-heavy queries with wide schemas
- `HighTempDB`: Temp table and metadata pressure
- `HighLocks`: Locking/blocking with SERIALIZABLE isolation
- `HighCXPacket`: Degree of parallelism contention
- `HighAsyncNetworkIO`: Emulates chatty applications and slow clients

**Built-In Logic:**
- Reads parameters from `Config.txt` for retries, timeouts, delays, batching, and connection settings
- Dynamically creates tables based on scenario and schema width
- Generates SQL commands with appropriate isolation levels
- Includes error handling and retry logic per execution
- Logs timings, successes, and failures for detailed telemetry

---

### 🔹 `KillAllProcess.ps1`
Terminates all currently running PowerShell jobs or sessions initiated by the simulation. Useful for aborting load tests or resetting the environment.

---

### 🔹 `Config.txt`
Fully customizable configuration file for connection settings, retry behavior, execution options, and workload definitions.

**Key Sections:**
- **Connectivity**: server name, databases list, connection pooling, timeouts, retry attempts
- **Execution**: command timeout, retry logic, number of executions, bulk copy settings
- **Workload Definitions**: Tables and schema used in each scenario
- **Advanced Options**: Network visibility, connection diagnostics, isolation levels

---

### 🔹 `Secrets.txt`
Stores credentials in plain text (use cautiously):
```
user=username
password=pwd
```
> ⚠️ Make sure this file is excluded via `.gitignore` and not committed to version control.

---

## 🚀 Example Usage

```powershell
# Launch 10 threads simulating HighCPU workload with 500 executions each
.\DoneThreads.ps1 -NumberOfConcurrentTasks 10 `
                  -ScenarioType "HighCPU" `
                  -HowManyOperations 500 `
                  -PowerShellLocationToExecute ".\ExecutionConnectionTimeSpent.ps1"
```

```powershell
# Stop all background processes (optional)
.\KillAllProcess.ps1
```

---

## 🧪 Use Cases

- Stress-test Elastic Database Pools
- Simulate high CPU, IO, lock contention, async network IO, and tempdb pressure
- Validate Elastic Pool scaling behavior under concurrency
- Test connection pooling, retry logic, and timeout handling
- Combine with QDS collection to analyze degraded queries
- Reproduce customer performance incidents in a controlled lab

---

## 🧰 Designed For

- Azure SQL Database (Single & Elastic Pools)
- Performance engineering teams
- Cloud DBAs
- Product support simulation labs
- Developers testing retry/connection logic

---

## 📬 Contact

Created by engineers at Microsoft. For feedback or contributions, feel free to open an issue or pull request.

import os
import pyodbc
import time
import random
import logging
import sys
import threading
import matplotlib.pyplot as plt
import cProfile
import pstats
from datetime import datetime, timedelta
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
from tkinter import simpledialog
import concurrent.futures
import statistics
import queue
import math

#os.environ['TDSDUMP'] = 'stdout'
#os.environ['TDSDUMPCONFIG'] = 'Yes'       # Para mostrar las configuraciones en el dump
#os.environ['TDSDUMPLEVEL'] = '5'  

# Constants for different use cases about performance issues
HIGH_CPU_SINGLE_THREAD = 1
HIGH_CPU_MULTI_THREAD = 2
COMMAND_TIMEOUT_RETRY = 3
DIFFERENT_EXECUTION_PLAN = 4
HIGH_NETWORK_LATENCY = 5
HIGH_CONCURRENCY = 6
HIGH_CXPACKET = 7
DEADLOCK_SIMULATION = 8
ODBC_ERROR_REUSE_CONNECTION = 9
CHATTY_APPLICATION =10
TEMPDB_ALLOCATION=11
TEMPDB_ALLOCATION_DATA=12
CONNECTION_BENCHMARK = 13
NUMBER_OF_EXECUTIONS = 14
EXTREME_DATA_INEFFICIENCY = 15 
READ_ONLY_QDS = 16

# Set CURRENT_SCENARIO to the desired use case
CURRENT_SCENARIO =TEMPDB_ALLOCATION_DATA
# Use multiple database in HIGH CPU
USE_MULTIPLE_DB_IN_HIGH_CPU_MULTI_THREAD=False
# Decide on the data type to use in queries to demonstrate how different data types can affect CPU usage
USE_SETINPUTSIZES_SQL_WCHAR=1
USE_SETINPUTSIZES_SQL_VARCHAR=2
USE_SETINPUTSIZES=USE_SETINPUTSIZES_SQL_VARCHAR
# Path to the file containing database credentials
FILE_CREDENTIALS= "C:\MyDocs\Save\credentials.txt"
# Path of File Log
LOG_FILE = 'C:\MyDocs\Save\error_log.log'
log_lock = threading.Lock()
# Constants for table names used in the deadlock scenario
TABLE_A_NAME = "dbo.MS_TableA_MS"
TABLE_B_NAME = "dbo.MS_TableB_MS"
TABLE_A_COLUMN = "ValueA"
TABLE_B_COLUMN = "ValueB"
ITEM_ID = 1
TABLE_A_INITIAL_VALUE = 'Value A1'
TABLE_B_INITIAL_VALUE = 'Value B1'

cache = {}
stop_threads = False  # Global variable to signal threads to stop

# Unexpected number of executions - Constants for retry policy
MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds between retries
# Unexpected number of executions - Global variables for counting errors
execution_errors = 0
connection_errors = 0
# Queue for communicating between threads
update_queue = queue.Queue()

logging.basicConfig(level=logging.INFO)

def clear_screen():
    # Clears the terminal screen to make the output readable
    os.system('cls' if os.name == 'nt' else 'clear')

def get_credentials_from_file(filename):
    """
    Obtain the credentials for the database. 

    Parameters:
    - filename: Name of the credentials file.

    Returns:
    - credentials: A dictionary containing the credentials.
    """
    try:
        if not os.path.exists(filename):
            print(f"The credentials file {filename} doesn't exists.")
            sys.exit(1)  
        credentials = {}
        with open(filename, 'r') as f:
            for line in f:
                key, value = line.strip().split('=')
                credentials[key] = value
        return credentials
    except Exception as e:
        print(f"Issue reading the credentials file {filename}.")
        sys.exit(1)

def ConnectToTheDB(Conntimeout=30, max_attempts=3, delay=5,querytimeout=30,dbName=""):

    """
    Establishes a connection to the database, showcasing error handling and retry logic in database connections.

    Parameters:
    - Conntimeout: Connection timeout in seconds.
    - max_attempts: Maximum number of connection attempts.
    - delay: Delay between retries.
    - querytimeout: Query execution timeout in seconds.
    - dbName: Optional specific database name to connect to.

    Returns:
    - conn: The database connection object.
    - dbNameToConnect: The name of the database connected to.
    """

    credentials = get_credentials_from_file(FILE_CREDENTIALS)

    if len(credentials) <4:
        print('No available data for credentials or configuration issue...')
        sys.exit(1)  

    dbName = dbName.lstrip().rstrip()
    username = credentials.get('username')
    password = credentials.get('password')
    servername = credentials.get('servername')
    appName = credentials.get('appName')

    if dbName == "" or dbName is None:
        dbNameToConnect = credentials.get('dbname')
    else:
        dbNameToConnect = dbName                

    if username is None or username == '':
        print("The username is not defined or is empty.")
        sys.exit(1)

    if appName is None or appName == '':
        print("The appName is not defined or is empty.")
        sys.exit(1)

    if password is None or password == '':
        print("The password is not defined or is empty.")
        sys.exit(1)

    if servername is None or servername == '':
        print("The servername is not defined or is empty.")
        sys.exit(1)        

    SQL_ATTR_CONNECTION_TIMEOUT = 113
    connection_string =f"DRIVER={{ODBC Driver 18 for SQL Server}};server=tcp:{servername}.database.windows.net,1433;UID={username};PWD={password};database={dbNameToConnect};APP={appName}"
    #connection_string =f"DSN=NUNO1;server=tcp:{servername}.database.windows.net,1433;UID={username};PWD={password};database={dbNameToConnect};APP={appName}"
    for attempt in range(max_attempts):
        try:
            thread_id = threading.get_ident()
            set_text_color("blue")
            logging.info(f'Connecting to the DB {dbNameToConnect} - Thread id {thread_id} - (Attempt {attempt + 1}/{max_attempts})')
            start_time = time.time()    
            conn = pyodbc.connect(connection_string, attrs_before={SQL_ATTR_CONNECTION_TIMEOUT: Conntimeout})
            conn.timeout = querytimeout
            set_text_color("green")
            logging.info(f"Connected to the Database in {dbNameToConnect} - Thread id {thread_id} - {time.time() - start_time:.4f} seconds ---")
            reset_text_color()
            return conn, dbNameToConnect
        except pyodbc.OperationalError as e:
            # If an error occurs and we have not reached the max number of attempts
            # then wait for the specified delay and then retry
            if attempt < max_attempts - 1:
                logging.info("Error occurred while connecting to the DB - {}. Retrying in {} seconds...".format(e, delay*(attempt+1)))
                time.sleep(delay*(attempt+1))
            else:
                # If we've reached the max number of attempts, print an error message and return None
                logging.info("Error occurred while connecting to the DB - {}. All retry attempts failed.".format(e))
                return None, dbNameToConnect

def RunHighCPU(data_type=USE_SETINPUTSIZES_SQL_WCHAR, loop_count=10000,timeout=30,dbName='',bShowStatistics=False):

    """
    Executes a high CPU consuming query on the database.

    Parameters:
    - data_type (int): USE_SETINPUTSIZES_SQL_WCHAR for SQL_WCHAR, USE_SETINPUTSIZES_SQL_VARCHAR for SQL_VARCHAR.
    - loop_count (int): Number of times the query will be executed.

    Returns:
    None
    """
    dbNameParam = dbName
    thread_id = threading.get_ident()
    aValues= []
    aNames = []
    conn, dbNameReturn = ConnectToTheDB(Conntimeout=30,querytimeout=30,dbName=dbNameParam)

    # If connection is None, exit the function
    if conn is None:
        logging.info(f'(RunHighCPU) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
        return

    cursor = conn.cursor()
    logging.info(f"(RunHighCPU) - Thread: {thread_id} - RunHighCPU starting up....")

    # Set input size based on data_type parameter
    if data_type == USE_SETINPUTSIZES_SQL_WCHAR:
        set_text_color("green")
        print(f"(RunHighCPU) - Thread: {thread_id} - Using pyodbc.SQL_WCHAR data type.")
        cursor.setinputsizes([(pyodbc.SQL_WCHAR, 200, 0)])
        reset_text_color()
    else:
        set_text_color("green")
        print(f"(RunHighCPU) - Thread: {thread_id} - Using pyodbc.SQL_VARCHAR data type.")
        cursor.setinputsizes([(pyodbc.SQL_VARCHAR, 200, 0)])
        reset_text_color()

    total_start_time = time.time()  # Start the timer for the entire process

    try:
        for i in range(1, loop_count + 1):
            start_time = time.time()    
            cursor.execute("select count(*) from [MSxyzTest].[_x_y_z_MS_HighCPU] WHERE TextToSearch = ?", "Value:" + str(i))
            row = cursor.fetchone() 
            execution_time = time.time() - start_time

            # Calculate elapsed time up to this point
            elapsed_time = time.time() - total_start_time

            # Calculate the average executions per second up to this point
            if elapsed_time > 0:  # Avoid division by zero
                average_executions_per_second = i / elapsed_time
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: {average_executions_per_second:.2f} executions/second - DB: {dbNameReturn}")
                if bShowStatistics==True:
                    aValues.append(execution_time)
                    aNames.append(i)
            else:
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: Calculating...- Database {dbNameReturn}")
                if bShowStatistics==True:
                    aValues.append(execution_time)
                    aNames.append(i)
        if bShowStatistics==True:
            fetch_max_resource_usage(dbNameReturn,thread_id)
            show_bar_chart(aNames, aValues, title='Execution Times - Testing App', xlabel='Attempts', ylabel='Execution Time', color='skyblue')
        conn.close()
        set_text_color("green")
        print(f"(RunHighCPU) - Thread: {thread_id} - RunHighCPU finished....")
        reset_text_color()

    except Exception as e:
        print(f"(RunHighCPU) - Thread: {thread_id} - An error occurred:", e)
        conn.close()

def run_in_threads(thread_count, use_random_db, *args, **kwargs):
    """
    Starts multiple threads to run a specified function.

    Parameters:
    - thread_count (int): Number of threads to start.
    - *args: Variable length argument list to pass to the function.
    - **kwargs: Arbitrary keyword arguments to pass to the function.
    """
    db_names = ['jmjuradotestdb1', 'mybc']
    if use_random_db == False:
        kwargs['dbName'] = db_names[0] 

    threads = []
    for _ in range(thread_count):
        # Create a thread to run RunHighCPU function
        if use_random_db == True:
            dbName = random.choice(db_names) if use_random_db else ''
            kwargs['dbName'] = dbName
                           
        thread = threading.Thread(target=RunHighCPU, args=args, kwargs=kwargs)
        threads.append(thread)
        thread.start()  # Start the thread

    for thread in threads:
        thread.join()  # Wait for all threads to complete

def RunCommandTimeout(initial_timeout=1, loop_count=1000, retry=True, retry_count=3, retry_increment=2):
    """
    Executes a database command with a specified timeout and retry mechanism.
    """
    try:
        thread_id = threading.get_ident()
        conn, dbNameReturn = ConnectToTheDB(querytimeout=initial_timeout)
       
        if conn is None:
            logging.info(f'(RunCommandTimeout) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
            return

        cursor = conn.cursor()
        logging.info(f'(RunCommandTimeout) - Thread: {thread_id} - Run Command Timeout starting up....')
        
        for i in range(1, loop_count + 1):
            successful_execution = False
            timeout=initial_timeout
            attempts = 0

            while not successful_execution and (attempts < retry_count or not retry):
                try:
                    start_time = time.time()    
                    cursor.execute("Select * from [MSxyzTest].[_x_y_z_MS_HighCXPacket] order by newid() desc")
                    print(f"(RunCommandTimeout) - Thread: {thread_id} - Loop:{i}/{loop_count} Execution Time: {time.time() - start_time:.4f} seconds - Database {dbNameReturn}")
                    successful_execution = True

                except Exception as e:
                    if retry:
                        attempts += 1
                        timeout += retry_increment
                        conn, dbNameReturn = ConnectToTheDB(querytimeout=timeout)
                        
                        if conn is None:
                            set_text_color("red")
                            logging.info(f'(RunCommandTimeout) - Thread: {thread_id} - Error re-establishing connection to the database {dbNameReturn}. Exiting...')
                            reset_text_color()                            
                            return
                        
                        cursor = conn.cursor()
                        set_text_color("red")
                        print(f"(RunCommandTimeout) - Thread: {thread_id} - Error executing command, retrying in {timeout} seconds. Attempt {attempts} of {retry_count} with new timeout {timeout}. Error: {e}")
                        reset_text_color()
                        time.sleep(timeout)
                    else:
                        raise

        conn.close()

    except Exception as e:
        set_text_color("red")
        print(f"(RunCommandTimeout) - Thread: {thread_id} - An error executing the command - {e}")
        reset_text_color()

    finally:
        set_text_color("green")
        print(f'(RunCommandTimeout) - Thread: {thread_id} - Run Command Timeout finished....')
        reset_text_color()

def RunDifferentExecutionPlan(nLoop=100000):
    """
    Executes the stored procedure dbo.GiveNotes with random numbers.
    
    Parameters:
    - nLoop (int): Number of times the procedure will be executed. Default is 100,000.
    
    Returns:
    None. It prints the execution time for each run.
    """
    try:
        initial_timeout = 30  
        thread_id = threading.get_ident()
        conn, dbNameReturn  = ConnectToTheDB(querytimeout=initial_timeout)

        if conn is None:
            logging.info(f'(RunDifferentExecutionPlan) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
            return
        
        max_retries = 3  
        retry_delay = 2 

        logging.info(f'(RunDifferentExecutionPlan) - Thread: {thread_id} - starting up.... - Database: {dbNameReturn}' )
        for _ in range(nLoop):
            numero = random.randint(1, 100000)        
            for attempt in range(1, max_retries + 1):
                cursor = conn.cursor()
                start_time = time.time()   
                try:
                    cursor.execute("EXEC dbo.GiveNotes ?", numero)
                    print(f'---- Filtering by ID: {numero:010} - Attempt {attempt}/{max_retries} - Execution Time: {time.time() - start_time:.2f} seconds')
                    break
                except Exception as retry_e:
                    print(f"-------- Failed: {retry_e} - After: {time.time() - start_time:.2f} seconds")
                    if attempt == max_retries:
                        print("-------- Maximum retries reached for this execution.")
                        break
                conn, dbNameReturn  = ConnectToTheDB(querytimeout=((initial_timeout + (attempt - 1))* retry_delay))
                if conn is None:
                    logging.info(f'-------- Error establishing connection to the database {dbNameReturn}. Exiting...')
                    break
        
        conn.close()
        
    except Exception as e:
        print(f"(RunDifferentExecutionPlan) - Thread: {thread_id} - An error executing the command: {e}")
        
    finally:
        print(f'(RunDifferentExecutionPlan) - Thread: {thread_id} - Run Different Execution Plan finished....')

def RunReadonly_QDS(nLoop=100000):
    """
    Executes the stored procedure dbo.RandomSelects with random numbers.
    
    Parameters:
    - nLoop (int): Number of times the procedure will be executed. Default is 100,000.
    
    Returns:
    None. It prints the execution time for each run.
    """
    try:
        initial_timeout = 30  
        thread_id = threading.get_ident()
        conn, dbNameReturn  = ConnectToTheDB(querytimeout=initial_timeout)

        if conn is None:
            logging.info(f'(RunReadonly_QDS) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
            return
        
        max_retries = 3  
        retry_delay = 2 

        logging.info(f'(RunReadonly_QDS) - Thread: {thread_id} - starting up.... - Database: {dbNameReturn}' )
        for _ in range(nLoop):
            numero = random.randint(5000, 50000)        
            for attempt in range(1, max_retries + 1):
                cursor = conn.cursor()
                start_time = time.time()   
                try:
                    cursor.execute("EXEC dbo.RandomSelects ?", numero)
                    print(f'---- Executing by ID: {numero:010} - Thread: {thread_id} - Attempt {attempt}/{max_retries} - Execution Time: {time.time() - start_time:.2f} seconds')
                    break
                except Exception as retry_e:
                    print(f"-------- Failed: {retry_e} - Thread: {thread_id} - After: {time.time() - start_time:.2f} seconds")
                    if attempt == max_retries:
                        print("-------- Maximum retries reached for this execution.")
                        break
                conn, dbNameReturn  = ConnectToTheDB(querytimeout=((initial_timeout + (attempt - 1))* retry_delay))
                if conn is None:
                    logging.info(f'-------- Error establishing connection to the database {dbNameReturn}. Exiting...')
                    break
        
        conn.close()
        
    except Exception as e:
        print(f"(RunReadonly_QDS) - Thread: {thread_id} - An error executing the command: {e}")
        
    finally:
        print(f'(RunReadonly_QDS) - Thread: {thread_id} - Run Different Execution Plan finished....')

def RunHighNetworkIO(TopCount=1000, loop_count=100,timeout=30,dbName=''):
    """
    Run a query causing high network latency. 
    
    Parameters:
    - nLoop_count (int): Number of times the procedure will be executed. Default is 100.
    - TopCount (int): How many rows will be returned.
    
    Returns:
    None. It prints the execution time for each run.
    """
    dbNameParam = dbName
    thread_id = threading.get_ident()
    conn, dbNameReturn = ConnectToTheDB(Conntimeout=30,querytimeout=30,dbName=dbNameParam)

    # If connection is None, exit the function
    if conn is None:
        logging.info(f'(RunHighNetworkIO) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
        return

    cursor = conn.cursor()
    set_text_color("green")
    logging.info(f"(RunHighNetworkIO) - Thread: {thread_id} - RunHighNetworkIO starting up....TOP:{TopCount}")
    reset_text_color()
    total_start_time = time.time()  # Start the timer for the entire process

    try:
        for i in range(1, loop_count + 1):
            start_time = time.time()    
            cursor.execute(f"select TOP {TopCount} * from [MSxyzTest].[_x_y_z_MS_HighAsyncNetworkIO]")
            row = cursor.fetchall() 
            execution_time = time.time() - start_time

            # Calculate elapsed time up to this point
            elapsed_time = time.time() - total_start_time

            # Calculate the average executions per second up to this point
            if elapsed_time > 0:  # Avoid division by zero
                average_executions_per_second = i / elapsed_time
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: {average_executions_per_second:.2f} executions/second - DB {dbNameReturn}")
            else:
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: Calculating...- Database {dbNameReturn}")


        conn.close()
        set_text_color("green")
        print(f"(RunHighNetworkIO) - Thread: {thread_id} - RunHighNetworkIO finished....")
        reset_text_color()

    except Exception as e:
        print(f"(RunHighNetworkIO) - Thread: {thread_id} - An error occurred:", e)
        conn.close()

def update_inventory(item_id, decrement_amount, thread_id):
    """
    Updates the inventory for a given item by decrementing its quantity.
    This function is meant to be called by multiple threads to simulate concurrency.

    Parameters:
    - item_id: The ID of the item to update.
    - decrement_amount: The amount by which to decrement the item's quantity.
    - thread_id: Identifier for the thread, used for logging.
    """
    try:
        conn, dbNameReturn = ConnectToTheDB()
        if conn is None:
           logging.info(f'(RunLockingIssues) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
           return

        cursor = conn.cursor()
        start_time = time.time()

        set_text_color("green")
        logging.info(f"(RunLockingIssues) - Thread: {thread_id} - RunLockingIssues starting up....")
        reset_text_color()
        # Update statement wrapped in a transaction
        cursor.execute("BEGIN TRANSACTION;")
        cursor.execute("SELECT Quantity FROM Inventory WITH (UPDLOCK) WHERE ItemID = ?;", (item_id,))
        quantity = cursor.fetchone()[0]
        if quantity >= decrement_amount:
            cursor.execute("UPDATE Inventory SET Quantity = Quantity - ? WHERE ItemID = ?;", (decrement_amount, item_id))
            cursor.execute("COMMIT;")
            print(f"- Thread {thread_id}: Successfully decremented item {item_id} by {decrement_amount}. Time taken: {time.time() - start_time:.4f} seconds - DB {dbNameReturn}")
        else:
            cursor.execute("ROLLBACK;")
            print(f"- Thread {thread_id}: Not enough inventory for item {item_id}. Rolling back. Time taken: {time.time() - start_time:.4f} seconds - DB {dbNameReturn}")

        conn.close()
        set_text_color("green")
        print(f"(RunLockingIssues) - Thread: {thread_id} - RunLockingIssues finished....")
        reset_text_color()
    except Exception as e:
        print(f"(RunLockingIssues) - Thread {thread_id}: An error occurred - {e}")

def simulate_concurrency(item_id, decrement_amount, thread_count):
    """
    Simulates concurrent updates to the inventory for a given item.

    Parameters:
    - item_id: The ID of the item to update.
    - decrement_amount: The amount by which to decrement the item's quantity for each thread.
    - thread_count: The number of concurrent threads to simulate.
    """
    threads = []
    for i in range(thread_count):
        thread = threading.Thread(target=update_inventory, args=(item_id, decrement_amount, i+1))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

def RunHighCXPacket(loop_count=100,timeout=30,dbName=''):
    """
    Run a query causing high CX Packet latency. 
    
    Parameters:
    - nLoop_count (int): Number of times the procedure will be executed. Default is 100.
    - TopCount (int): How many rows will be returned.
    
    Returns:
    None. It prints the execution time for each run.
    """
    dbNameParam = dbName
    thread_id = threading.get_ident()
    conn, dbNameReturn = ConnectToTheDB(Conntimeout=30,querytimeout=30,dbName=dbNameParam)

    # If connection is None, exit the function
    if conn is None:
        logging.info(f'(RunHighCXPacket) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
        return

    cursor = conn.cursor()
    set_text_color("green")
    logging.info(f"(RunHighCXPacket) - Thread: {thread_id} - RunHighCXPacket starting up....")
    reset_text_color()
    total_start_time = time.time()  # Start the timer for the entire process

    try:
        for i in range(1, loop_count + 1):
            start_time = time.time()   
            iSubString= random.randint(1, 200)  
            sSubString= f"Where SubString(Name,1,{iSubString})"
            sText= "#"
            sText= sText.rjust(iSubString,"#")
            sSubString = sSubString + "='" + sText + "'"

            iSort= random.randint(1, 200)  
            sSort= f"Order By SubString(Name,1,{iSort})"

            db_sort = ['asc', 'desc']
            dbSort = random.choice(db_sort) 

            cursor.execute(f"select * from [MSxyzTest].[_x_y_z_MS_HighCXPacket] {sSubString} {sSort} {dbSort}")
            row = cursor.fetchone() 
            execution_time = time.time() - start_time

            # Calculate elapsed time up to this point
            elapsed_time = time.time() - total_start_time

            # Calculate the average executions per second up to this point
            if elapsed_time > 0:  # Avoid division by zero
                average_executions_per_second = i / elapsed_time
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: {average_executions_per_second:.2f} executions/second - DB {dbNameReturn}")
            else:
                print(f"- Loop:{i}/{loop_count} - Thread: {thread_id} - Execution Time: {execution_time:.4f} seconds - Average: Calculating...- Database {dbNameReturn}")


        conn.close()
        set_text_color("green")
        print(f"(RunHighCXPacket) - Thread: {thread_id} - RunHighCXPacket finished....")
        reset_text_color()

    except Exception as e:
        print(f"(RunHighCXPacket) - Thread: {thread_id} - An error occurred:", e)
        conn.close()

def set_text_color(color_name):
    """
    Sets the text color for all future output in the terminal until the color is changed again or reset.

    Parameters:
    - color_name: The name of the color in text. (e.g., "red", "green", "blue")
    """
    # Dictionary of colors with color names as keys and ANSI codes as values
    colors = {
        "black": "\033[30m",
        "red": "\033[31m",
        "green": "\033[32m",
        "yellow": "\033[33m",
        "blue": "\033[34m",
        "magenta": "\033[35m",
        "cyan": "\033[36m",
        "white": "\033[37m"
    }
    color_code = colors.get(color_name.lower(), "\033[0m")  # Use default color if color name is not found

    sys.stdout.write(color_code)
    sys.stdout.flush()  # Ensure the color change is applied immediately

def reset_text_color():
    """
    Resets the text color to its default value.
    """
    sys.stdout.write('\033[0m')
    sys.stdout.flush()

def show_bar_chart(names, values, title='Bar Chart', xlabel='Categories', ylabel='Values', color='skyblue'):
    """
    Displays a simple bar chart with the provided names and values.

    Parameters:
    - names (list): List of names/categories for the bars.
    - values (list): List of values corresponding to each bar.
    - title (str): Title of the chart.
    - xlabel (str): Label for the X-axis.
    - ylabel (str): Label for the Y-axis.
    - color (str): Color of the bars.
    """
    plt.figure(figsize=(10, 6))  # Adjust the size of the chart

    # Create the bar chart
    plt.bar(names, values, color=color)

    plt.xlabel(xlabel)  # X-axis label
    plt.ylabel(ylabel)  # Y-axis label
    plt.title(title)  # Chart title

    plt.show()  # Display the chart

def fetch_max_resource_usage(dbName='',thread_id=0):
    """
    Fetches and prints the maximum values of CPU usage, log bytes used, data IO percent, and max workers count
    from the last 3 records in sys.dm_db_resource_stats, if the view exists.
    """

    dbNameParam = dbName
    conn, dbNameReturn = ConnectToTheDB(Conntimeout=30,querytimeout=30,dbName=dbNameParam)

    if conn is None:
        logging.info(f'(MaxResourceUsage) - Thread: {thread_id} - Error establishing connection to the database {dbNameReturn}. Exiting...')
        return

    try:
        cursor = conn.cursor()
        # Check if the view exists
        cursor.execute("SELECT COUNT(*) FROM sys.all_views WHERE name = 'dm_db_resource_stats'")
        if cursor.fetchone()[0] == 0:
            print(f"(MaxResourceUsage) - Thread: {thread_id} - The view 'sys.dm_db_resource_stats' does not exist in this SQL Server instance.")
            return

        # If the view exists, proceed with the main query
        query = """
        SELECT 
            MAX(avg_cpu_percent) AS Max_CPU_Usage,
            MAX(avg_log_write_percent) AS Max_Log_Usage,
            MAX(avg_data_io_percent) AS Max_Data_IO,
            MAX(max_worker_percent) AS Max_Workers
        FROM (
            SELECT TOP 3
                avg_cpu_percent,
                avg_log_write_percent,
                avg_data_io_percent,
                max_worker_percent
            FROM sys.dm_db_resource_stats
            ORDER BY end_time DESC
        ) AS Last3Records;
        """
        cursor.execute(query)
        result = cursor.fetchone()
        if result:
            print(f"Maximum CPU Usage: {result[0]} %")
            print("Maximum Log Usage:", result[1], "%")
            print("Maximum Data IO:", result[2], "%")
            print("Maximum Workers Count:", result[3])
        else:
            print("(MaxResourceUsage) - Thread: {thread_id} - No data available.")
    except Exception as e:
        logging.error(f'(MaxResourceUsage) - Thread: {thread_id} - An error occurred while fetching resource usage stats: {e}')
    finally:
        conn.close()

# Function to simulate deadlock
def simulate_deadlock(retry=False, retry_attempts=3):
    """
    Simulates a deadlock by running two transactions in parallel that lock resources in opposite order.
    If retry is enabled, the transactions will attempt to retry up to a specified number of attempts upon failure.

    Parameters:
    - retry (bool): Whether to retry the transaction in case of a deadlock. Default is False.
    - retry_attempts (int): The maximum number of retry attempts if retry is enabled.
    """
    setup_deadlock_tables()

    # Create threads for the two transactions with retry logic
    thread1 = threading.Thread(target=run_transaction_with_retry, args=(deadlock_transaction1, retry_attempts,retry))
    thread2 = threading.Thread(target=run_transaction_with_retry, args=(deadlock_transaction2, retry_attempts,retry))

    # Start the threads
    thread1.start()
    thread2.start()

    # Wait for both threads to finish
    thread1.join()
    thread2.join()

def run_transaction_with_retry(transaction_func, attempt_limit,retry):
   attempt = 0
   while attempt < attempt_limit:
     try:
        transaction_func(retry)
        break
     except pyodbc.Error as e:
        if 'deadlock' in str(e).lower() and retry:
           attempt += 1
           logging.warning(f"Deadlock detected. Retrying transaction... Attempt {attempt}/{attempt_limit}")
           time.sleep(1)  # Brief pause before retrying
        else:
           logging.error(f"Transaction failed: {e}")
           break

def setup_deadlock_tables():
    """
    Sets up the tables required for the deadlock simulation, using constants for table and column names.
    """
    conn, dbNameReturn = ConnectToTheDB()
    if conn is None:
        logging.info('Error establishing connection to the database. Exiting setup.')
        return
    cursor = conn.cursor()
    try:
        cursor.execute(f"""
        IF OBJECT_ID('{TABLE_A_NAME}', 'U') IS NULL
        CREATE TABLE {TABLE_A_NAME} (
            ID INT PRIMARY KEY,
            {TABLE_A_COLUMN} VARCHAR(100)
        );
        """)
        
        cursor.execute(f"""
        IF OBJECT_ID('{TABLE_B_NAME}', 'U') IS NULL
        CREATE TABLE {TABLE_B_NAME} (
            ID INT PRIMARY KEY,
            {TABLE_B_COLUMN} VARCHAR(100)
        );
        """)
        
        cursor.execute(f"SELECT COUNT(*) FROM {TABLE_A_NAME}")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"INSERT INTO {TABLE_A_NAME} (ID, {TABLE_A_COLUMN}) VALUES ({ITEM_ID}, '{TABLE_A_INITIAL_VALUE}');")
        
        cursor.execute(f"SELECT COUNT(*) FROM {TABLE_B_NAME}")
        if cursor.fetchone()[0] == 0:
            cursor.execute(f"INSERT INTO {TABLE_B_NAME} (ID, {TABLE_B_COLUMN}) VALUES ({ITEM_ID}, '{TABLE_B_INITIAL_VALUE}');")
        
        conn.commit()
        logging.info("Tables prepared successfully.")
    except Exception as e:
        logging.error(f"An error occurred in setup_deadlock_tables: {e}")
        conn.rollback()
    finally:
        conn.close()

def deadlock_transaction1(retry=False):
    """
    First transaction that participates in the deadlock, using constants for table and column names.
    """
    conn, dbNameReturn = ConnectToTheDB()
    if conn is None:
        logging.info('Error establishing connection to the database. Exiting transaction 1.')
        return
    cursor = conn.cursor()
    try:
        cursor.execute("BEGIN TRANSACTION;")
        cursor.execute(f"UPDATE {TABLE_A_NAME} SET {TABLE_A_COLUMN} = 'Transaction 1' WHERE ID = {ITEM_ID};")
        time.sleep(2)  # Wait to allow the other transaction to lock the other table
        cursor.execute(f"UPDATE {TABLE_B_NAME} SET {TABLE_B_COLUMN} = 'Transaction 1' WHERE ID = {ITEM_ID};")
        conn.commit()
        logging.info("Transaction 1 completed successfully.")
    except pyodbc.Error as e:
        logging.error(f"Transaction 1 failed: {e}")
        conn.rollback()
        if 'deadlock' in str(e).lower() and retry:
            raise e  # Rethrow the exception to trigger retry in run_transaction_with_retry
    finally:
        conn.close()

def deadlock_transaction2(retry=False):
    """
    Second transaction that participates in the deadlock, using constants for table and column names.
    """
    conn, dbNameReturn = ConnectToTheDB()
    if conn is None:
        logging.info('Error establishing connection to the database. Exiting transaction 2.')
        return
    cursor = conn.cursor()
    try:
        cursor.execute("BEGIN TRANSACTION;")
        cursor.execute(f"UPDATE {TABLE_B_NAME} SET {TABLE_B_COLUMN} = 'Transaction 2' WHERE ID = {ITEM_ID};")
        time.sleep(2)  # Wait to allow the other transaction to lock the other table
        cursor.execute(f"UPDATE {TABLE_A_NAME} SET {TABLE_A_COLUMN} = 'Transaction 2' WHERE ID = {ITEM_ID};")
        conn.commit()
        logging.info("Transaction 2 completed successfully.")
    except pyodbc.Error as e:
        logging.error(f"Transaction 2 failed: {e}")
        conn.rollback()
        if 'deadlock' in str(e).lower() and retry:
            raise e  # Rethrow the exception to trigger retry in run_transaction_with_retry
    finally:
        conn.close()

def TestConnectionErrorReuse():
    """
    Connects to the database, runs a query that causes an error, and then attempts to run another query
    to demonstrate the state of the connection after a critical error.
    """
    try:
        thread_id = threading.get_ident()
        conn, db_name = ConnectToTheDB(querytimeout=10)
        
        if conn is None:
            logging.info(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Failed to establish initial connection. Exiting...')
            return

        cursor = conn.cursor()
        
        # Step 1: Execute a query that will cause an error (division by zero)
        try:
            logging.info(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Executing a query that will cause an error (SELECT 1/0)...')
            cursor.execute("SELECT 1/0")  # This should trigger a division by zero error
        except pyodbc.Error as e:
            logging.error(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Error during query execution: {e}')

        # Step 2: Attempt to reuse the connection by running another query
        try:
            logging.info(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Attempting to execute a follow-up query after error...')
            cursor.execute("SELECT 1")  # Simple query to test reuse of connection
            row = cursor.fetchone()
            print(f"(TestConnectionErrorReuse) - Thread: {thread_id} - Follow-up query result: {row[0]}")
        except pyodbc.Error as e:
            logging.error(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Error reusing connection after previous failure: {e}')
        
    except Exception as e:
        logging.error(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Unexpected error occurred: {e}')
    
    finally:
        if conn:
            conn.close()
            logging.info(f'(TestConnectionErrorReuse) - Thread: {thread_id} - Connection closed.')

def fetch_product_from_db(product_id, use_cache=False, cache_validity=20):
    """
    Retrieves product details from the database or from cache if `use_cache` is True.
    
    Parameters:
    - product_id (int): ID of the product to query.
    - use_cache (bool): If True, uses cache to store and reuse results.
    - cache_validity (int): Time in minutes for cache validity.

    Returns:
    - result: The query result of the product.
    """
    # Current time
    current_time = datetime.now()

    # If using cache and product is already cached
    if use_cache and product_id in cache:
        cached_result, cache_timestamp = cache[product_id]
        # Check if the cached value is still valid
        if current_time - cache_timestamp < timedelta(minutes=cache_validity):
            logging.info(f"Cache hit for ProductID {product_id}")
            return cached_result
        else:
            logging.info(f"Cache expired for ProductID {product_id}")

    # If the value is not cached or has expired, connect to the database and execute the query
    conn, dbname = ConnectToTheDB(querytimeout=10)
    cursor = conn.cursor()
    cursor.execute("SELECT ProductID, ProductName FROM Products2 WHERE ProductID = ?", product_id)
    result = cursor.fetchone()
    conn.close()

    # Store the result in cache if `use_cache` is True, with the current timestamp
    if use_cache:
        cache[product_id] = (result, current_time)

    return result

def RunChattyApplication(thread_count=5, iterations=10000, use_cache=False, cache_validity=20):
    """
    Runs the chatty application simulation in multiple threads.

    Parameters:
    - thread_count (int): Number of threads to run the simulation.
    - iterations (int): Total number of iterations for all requests.
    - use_cache (bool): If True, uses cache to store and reuse results.
    - cache_validity (int): Time in minutes for cache validity.
    """
    def task():
        global stop_threads
        for _ in range(iterations // thread_count):
            if stop_threads:  # Check if stop signal has been set
                logging.info("Thread received stop signal.")
                break
            # Generate a random ProductID between 500 and 1000
            product_id = random.randint(500, 1000)
            # Execute the query, optionally using cache
            result = fetch_product_from_db(product_id, use_cache=use_cache, cache_validity=cache_validity)
            logging.info(f"Fetched ProductID {product_id}: {result}")

    # Create and start threads
    threads = []
    for _ in range(thread_count):
        thread = threading.Thread(target=task)
        threads.append(thread)
        thread.start()

    try:
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
    except KeyboardInterrupt:
        global stop_threads
        stop_threads = True  # Signal all threads to stop
        logging.info("Interrupt received. Stopping threads...")

        # Wait for threads to acknowledge the stop signal
        for thread in threads:
            thread.join()

    logging.info("Chatty application simulation completed.")

def simulate_tempdb_object_contention_parallel(thread_count=10, loop_count=100):
    """
    Simulates contention in tempdb by frequently creating and dropping temporary objects in parallel threads.

    Parameters:
    - thread_count (int): Number of threads performing the simulation.
    - loop_count (int): Number of iterations per thread for creating and dropping temporary tables.

    Returns:
    None
    """
    def task():
        conn, dbNameReturn = ConnectToTheDB()
        if conn is None:
            logging.info("Error establishing connection to the database. Exiting simulate_tempdb_object_contention_parallel.")
            return
        
        cursor = conn.cursor()
        thread_id = threading.get_ident()
        logging.info(f"(TempDB Object Contention) - Thread {thread_id} - Starting object contention simulation in tempdb...")

        try:
            for i in range(loop_count):
                cursor.execute("CREATE TABLE #TempTable (ID INT, Data VARCHAR(100))")
                cursor.execute("INSERT INTO #TempTable (ID, Data) VALUES (?, ?)", i, f"Data_{i}")
                cursor.execute("DROP TABLE #TempTable")

                if i % 10 == 0:
                    logging.info(f"(TempDB Object Contention) - Thread {thread_id} - Iteration {i}/{loop_count}")
            
            logging.info(f"(TempDB Object Contention) - Thread {thread_id} - Finished object contention simulation.")

        except Exception as e:
            logging.error(f"(TempDB Object Contention) - Thread {thread_id} - An error occurred: {e}")
        finally:
            conn.close()

    threads = [threading.Thread(target=task) for _ in range(thread_count)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

def simulate_tempdb_data_contention_parallel(thread_count=10, row_count=10000, loop_count=100):
    """
    Simulates contention in tempdb by performing data operations in a temporary table in parallel threads.

    Parameters:
    - thread_count (int): Number of threads performing the simulation.
    - row_count (int): Number of rows to insert into the temporary table.
    - loop_count (int): Number of iterations per thread for performing operations on the temporary table.

    Returns:
    None
    """
    def task():
        conn, dbNameReturn = ConnectToTheDB()
        if conn is None:
            logging.info("Error establishing connection to the database. Exiting simulate_tempdb_data_contention_parallel.")
            return
        
        cursor = conn.cursor()
        thread_id = threading.get_ident()
        logging.info(f"(TempDB Data Contention) - Thread {thread_id} - Starting data contention simulation in tempdb...")

        try:
            # Create a temporary table to persist across all iterations in the thread
            cursor.execute("CREATE TABLE #TempDataTable (ID INT, Data VARCHAR(100))")
            for i in range(row_count):
                cursor.execute("INSERT INTO #TempDataTable (ID, Data) VALUES (?, ?)", i, f"Data_{i}")

            for i in range(loop_count):
                cursor.execute("SELECT COUNT(*) FROM #TempDataTable WHERE ID < ?", random.randint(1, row_count))
                cursor.execute("UPDATE #TempDataTable SET Data = CONCAT(Data, '_updated') WHERE ID = ?", random.randint(1, row_count))

                if i % 10 == 0:
                    logging.info(f"(TempDB Data Contention) - Thread {thread_id} - Iteration {i}/{loop_count}")

            # Drop the temporary table
            cursor.execute("DROP TABLE #TempDataTable")
            logging.info(f"(TempDB Data Contention) - Thread {thread_id} - Finished data contention simulation.")

        except Exception as e:
            logging.error(f"(TempDB Data Contention) - Thread {thread_id} - An error occurred: {e}")
        finally:
            conn.close()

    threads = [threading.Thread(target=task) for _ in range(thread_count)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

def run_connection_benchmark():
    """
    Performs a benchmark by creating parallel connections to the database in batches,
    increasing from 10 to 100 in steps of 10. For each batch, records the number of
    successful connections, errors, and connection times.
    """
    results = []  # To store results for each batch
    dbNameParam = ''  # Use default database or specify if needed

    for connection_count in range(10, 201, 10):
        logging.info('BenchMark Connections using {connection_count}.')
        successful_connections = 0
        failed_connections = 0
        connection_times = []

        threads = []
        lock = threading.Lock()

        def connect_thread():
            nonlocal successful_connections, failed_connections
            start_time = time.time()
            conn, dbNameReturn = ConnectToTheDB(dbName=dbNameParam)
            end_time = time.time()
            time_taken = end_time - start_time
            with lock:
                if conn:
                    successful_connections += 1
                    connection_times.append(time_taken)
                    conn.close()
                else:
                    failed_connections += 1
                    connection_times.append(time_taken)

        # Start threads
        for _ in range(connection_count):
            thread = threading.Thread(target=connect_thread)
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        if connection_times:
            max_time = max(connection_times)
            min_time = min(connection_times)
            avg_time = sum(connection_times) / len(connection_times)
        else:
            max_time = min_time = avg_time = 0

        result = {
            'connections_requested': connection_count,
            'successful_connections': successful_connections,
            'failed_connections': failed_connections,
            'max_time': max_time,
            'min_time': min_time,
            'avg_time': avg_time
        }
        results.append(result)

        # Print the result for this batch
        print(f"Connections Requested: {connection_count}")
        print(f"Successful Connections: {successful_connections}")
        print(f"Failed Connections: {failed_connections}")
        print(f"Max Time: {max_time:.4f} seconds")
        print(f"Min Time: {min_time:.4f} seconds")
        print(f"Average Time: {avg_time:.4f} seconds")
        print("-" * 50)

    # Optionally, display results in a chart
    plot_benchmark_results(results)

def plot_benchmark_results(results):
    """
    Plots the benchmark results using matplotlib.
    """
    import matplotlib.pyplot as plt

    connection_counts = [r['connections_requested'] for r in results]
    avg_times = [r['avg_time'] for r in results]
    max_times = [r['max_time'] for r in results]
    min_times = [r['min_time'] for r in results]
    successful_connections = [r['successful_connections'] for r in results]
    failed_connections = [r['failed_connections'] for r in results]

    plt.figure(figsize=(12, 6))

    plt.subplot(1, 2, 1)
    plt.plot(connection_counts, avg_times, marker='o', label='Average Time')
    plt.plot(connection_counts, max_times, marker='o', label='Max Time')
    plt.plot(connection_counts, min_times, marker='o', label='Min Time')
    plt.xlabel('Number of Parallel Connections')
    plt.ylabel('Time (seconds)')
    plt.title('Connection Times')
    plt.legend()

    plt.subplot(1, 2, 2)
    plt.bar([c - 1 for c in connection_counts], successful_connections, width=1, label='Successful', color='green')
    plt.bar(connection_counts, failed_connections, width=1, label='Failed', color='red')
    plt.xlabel('Number of Parallel Connections')
    plt.ylabel('Number of Connections')
    plt.title('Connection Success vs Failure')
    plt.legend()

    plt.tight_layout()
    plt.show()

def create_gui():
    root = tk.Tk()
    root.title("DataCon Seattle 2025 June")
    root.geometry("400x625")
    root.resizable(False, False)  # Disable window resizing (no maximize option)

    # widgets
    style = ttk.Style()
    style.theme_use('clam')  # Puedes probar con 'clam', 'alt', 'default', 'classic'

    # Windows background 
    root.configure(background='#f0f0f0')

    label = tk.Label(root, text="Select the scenario to execute:", font=("Arial", 14))
    label.pack(pady=10)

    # Dictionary to map scenario names with their constants
    scenarios = {
        "01 - High CPU Single Thread": HIGH_CPU_SINGLE_THREAD,
        "02 - High CPU Multi Thread": HIGH_CPU_MULTI_THREAD,
        "03 - Command Timeout Retry": COMMAND_TIMEOUT_RETRY,
        "04 - Different Execution Plan": DIFFERENT_EXECUTION_PLAN,
        "05 - High Network Latency": HIGH_NETWORK_LATENCY,
        "06 - High Concurrency": HIGH_CONCURRENCY,
        "07 - High CXPACKET": HIGH_CXPACKET,
        "08 - Deadlock Simulation": DEADLOCK_SIMULATION,
        "09 - ODBC Error Reuse Connection": ODBC_ERROR_REUSE_CONNECTION,
        "10 - Chatty Application": CHATTY_APPLICATION,
        "11 - TempDB Allocation": TEMPDB_ALLOCATION,
        "12 - TempDB Allocation Data": TEMPDB_ALLOCATION_DATA,
        "13 - Connection Benchmark": CONNECTION_BENCHMARK,
        "14 - Number of Executions": NUMBER_OF_EXECUTIONS, 
        "15 - Extreme Data Inefficiency": EXTREME_DATA_INEFFICIENCY,
        "16 - Read_Only QDS" : READ_ONLY_QDS
    }

    # Variable for the radiobutton
    scenario_var = tk.IntVar()
    scenario_var.set(1)  # Default value

    # Create radiobuttons for each scenario
    for text, value in scenarios.items():
        tk.Radiobutton(root, text=text, variable=scenario_var, value=value).pack(anchor=tk.W)

    def on_execute():
        selected_scenario = scenario_var.get()
        root.destroy()  # Close the window before executing the scenario
        run_selected_scenario(selected_scenario)

    execute_button = tk.Button(root, text="Execute Scenario", command=on_execute, height=2)
    execute_button.pack(pady=20)

    root.mainloop()

def update_ui():
    """Checks the queue and updates the UI with the latest task status."""
    try:
        while not update_queue.empty():
            total_operations, completed_operations, average_time, pending_tasks, elapsed_time, max_time, min_time, std_dev = update_queue.get_nowait()
            
            lbl_completed.config(text=f"Completed: {completed_operations}/{total_operations}")
            lbl_avg_time.config(text=f"Avg. Execution Time: {average_time:.2f} sec")
            lbl_pending.config(text=f"Pending Tasks: {pending_tasks}")
            lbl_remaining_time.config(text=f"Elapsed Time: {elapsed_time:.2f} sec")
            lbl_execution_errors.config(text=f"Execution Errors: {execution_errors}")
            lbl_connection_errors.config(text=f"Connection Errors: {connection_errors}")

            # Update new statistics
            lbl_max_time.config(text=f"Max Execution Time: {max_time:.2f} sec")
            lbl_min_time.config(text=f"Min Execution Time: {min_time:.2f} sec")
            lbl_std_dev.config(text=f"Standard Deviation: {std_dev:.2f}")
    except queue.Empty:
        pass
    root.after(500, update_ui)  # Schedule the next UI update in 500 ms


def run_query(data_type=1):
    """Simulates a single database query operation with retry policy, returns execution time even on failure."""
    global execution_errors, connection_errors
    start_time = time.time()
    retries = 0
    thread_id = threading.get_ident()
    while retries <= 3:
        try:
            conn, dbNameReturn = ConnectToTheDB(querytimeout=15)
            if conn is None:
                logging.info(f"Error establishing connection to the database - Thread: {thread_id}")
                write_to_log_file(f"Error establishing connection to the database - Thread: {thread_id}")
                connection_errors += 1
                return time.time() - start_time  # Return execution time on failure

            cursor = conn.cursor()

            if data_type == 1:
                cursor.setinputsizes([(pyodbc.SQL_WCHAR, 200, 0)])
            else:
                cursor.setinputsizes([(pyodbc.SQL_VARCHAR, 200, 0)])
            
            # Execute the query with a random value to simulate variable inputs
            logging.info(f"Executing query - Thread: {thread_id}")
            cursor.execute("SELECT COUNT(*) FROM [MSxyzTest].[_x_y_z_MS_HighCPU] WHERE TextToSearch = ?", "Value" + str(random.randint(1, 40000000)))
            row = cursor.fetchone()
            conn.close()
            logging.info(f"Executed query - Thread: {thread_id}")

            return time.time() - start_time  # Return the execution time if successful
        
        except pyodbc.Error as e:
            execution_errors += 1
            retries += 1
            logging.error(f"Execution error in pyodbc - Thread: {thread_id}  {e}; retrying...")
            write_to_log_file(f"Execution error in pyodbc - Thread: {thread_id}  {e}")
        
        except Exception as e:
            execution_errors += 1
            retries += 1
            logging.error(f"General execution error: - Thread: {thread_id} - {e}; retrying...")
            write_to_log_file(f"General execution error in pyodbc - Thread: {thread_id}  {e}")

    # Return execution time after all retries have failed
    return time.time() - start_time


def run_interactive_test(total_operations, max_parallel, data_type):
    """Executes database query operations in parallel and updates the queue with the current status."""
    start_time = time.time()
    execution_times = []
    completed_operations = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_parallel) as executor:
        futures = {executor.submit(run_query, data_type): i for i in range(total_operations)}

        for future in concurrent.futures.as_completed(futures):
            completed_operations += 1
            execution_time = future.result(timeout=300)
            execution_times.append(execution_time)

            pending_tasks = total_operations - completed_operations
            average_time = sum(execution_times) / len(execution_times) if execution_times else 0
            elapsed_time = time.time() - start_time

            # Calculate max, min, and standard deviation
            max_time = max(execution_times) if execution_times else 0
            min_time = min(execution_times) if execution_times else 0
            std_dev = math.sqrt(sum((x - average_time) ** 2 for x in execution_times) / len(execution_times)) if execution_times else 0

            # Put the latest status into the queue, including new statistics
            update_queue.put((total_operations, completed_operations, average_time, pending_tasks, elapsed_time, max_time, min_time, std_dev))

    # Final update to indicate completion
    logging.info("All tasks completed.")


def get_user_input():
    
    """Prompts the user for the total number of operations and the parallel group size."""
    total_operations = simpledialog.askinteger("Input", "Total operations:", initialvalue=200, minvalue=1, maxvalue=1000000)
    if total_operations is None:
        messagebox.showinfo("Operation Cancelled", "The application will now close.")
        root.destroy()
        sys.exit()
    max_parallel = simpledialog.askinteger("Input", "Maximum parallel operations:", initialvalue=10, minvalue=1, maxvalue=total_operations)
    if max_parallel is None:
        messagebox.showinfo("Operation Cancelled", "The application will now close.")
        root.destroy()
        sys.exit()
    data_type = simpledialog.askinteger("Input", "Data Type (1 for SQL_WCHAR, 2 for SQL_VARCHAR):", initialvalue=1, minvalue=1, maxvalue=2)
    if data_type is None:
        messagebox.showinfo("Operation Cancelled", "The application will now close.")
        root.destroy()
        sys.exit()
    return total_operations, max_parallel, data_type


def create_guiNumberOfExecutions():
    """Creates the main GUI and starts the interactive test scenario."""
    global root, lbl_completed, lbl_avg_time, lbl_pending, lbl_remaining_time, lbl_execution_errors, lbl_connection_errors
    global lbl_max_time, lbl_min_time, lbl_std_dev, lbl_parallel_tasks, lbl_total_operations, lbl_query_type

    root = tk.Tk()
    root.title("Task Execution Status")
    root.geometry("500x450")
    root.resizable(False, False)  # Disables maximize and minimize options

    # Display selected values
    lbl_parallel_tasks = tk.Label(root, text="Parallel Tasks: N/A")
    lbl_parallel_tasks.pack(pady=5)

    lbl_total_operations = tk.Label(root, text="Total Operations: N/A")
    lbl_total_operations.pack(pady=5)

    lbl_query_type = tk.Label(root, text="Query Type: N/A")
    lbl_query_type.pack(pady=5)

    # Existing labels
    lbl_completed = tk.Label(root, text="Completed: 0/0")
    lbl_completed.pack(pady=5)

    lbl_avg_time = tk.Label(root, text="Avg. Execution Time: 0.00 sec")
    lbl_avg_time.pack(pady=5)

    lbl_pending = tk.Label(root, text="Pending Tasks: 0")
    lbl_pending.pack(pady=5)

    lbl_remaining_time = tk.Label(root, text="Elapsed Time: 0.00 sec")
    lbl_remaining_time.pack(pady=5)

    lbl_execution_errors = tk.Label(root, text="Execution Errors: 0")
    lbl_execution_errors.pack(pady=5)

    lbl_connection_errors = tk.Label(root, text="Connection Errors: 0")
    lbl_connection_errors.pack(pady=5)

    # New labels for max, min, and standard deviation of execution time
    lbl_max_time = tk.Label(root, text="Max Execution Time: 0.00 sec")
    lbl_max_time.pack(pady=5)

    lbl_min_time = tk.Label(root, text="Min Execution Time: 0.00 sec")
    lbl_min_time.pack(pady=5)

    lbl_std_dev = tk.Label(root, text="Standard Deviation: 0.00 sec")
    lbl_std_dev.pack(pady=5)

    # Get user input and start the interactive test
    total_operations, max_parallel, data_type = get_user_input()
    
    # Update labels with the selected values
    lbl_parallel_tasks.config(text=f"Parallel Tasks: {max_parallel}")
    lbl_total_operations.config(text=f"Total Operations: {total_operations}")
    lbl_query_type.config(text=f"Query Type: {'SQL_WCHAR' if data_type == 1 else 'SQL_VARCHAR'}")

    # Start the background thread
    threading.Thread(target=run_interactive_test, args=(total_operations, max_parallel, data_type), daemon=True).start()

    # Schedule regular UI updates
    update_ui()
    root.mainloop()

def write_to_log_file(message):
    """
    Writes a message to the log file with the current date and time, ensuring concurrency safety.
    
    Parameters:
    - message (str): The message to be saved to the log file.
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')  # Date and time format
    log_entry = f"[{timestamp}] {message}\n"

    try:
        # Ensure only one thread accesses the file at a time
        with log_lock:
            with open(LOG_FILE, 'a') as log_file:
                log_file.write(log_entry)
    except Exception as e:
        # Print an error message if writing to the file fails
        print(f"Error writing to log file: {e}")

def get_env_variable(var_name, default_value=None, allow_empty=False):
    """
    Retrieves and validates an environment variable.
    :param var_name: The name of the environment variable.
    :param default_value: The default value if the variable is missing.
    :param allow_empty: If False, raises an error for empty variables.
    :return: The value of the environment variable or default_value.
    """
    value = os.getenv(var_name, default_value)
    if value is None or (not allow_empty and ( value.strip() == "" or value.strip() == "NOT_SET" or default_value is None)):
            raise ValueError(f"Environment variable '{var_name}' is required but not set.")
    return value

def RunSimpleInefficiencyWithTiming(row_count=10000, iterations=1, show_query_time=True, efficient=False, show_function_time=False):
    """
    Executes RunSimpleInefficiency and logs the time taken for each iteration.
    Includes an option for efficient or inefficient processing.

    Parameters:
    - row_count (int): Number of rows to fetch from the database.
    - iterations (int): Number of iterations for processing.
    - show_query_time (bool): Whether to display query execution time.
    - efficient (bool): Whether to execute the processing efficiently or inefficiently.
    """
    try:
        function_query_time = time.time()
        conn, dbNameReturn = ConnectToTheDB()
        if conn is None:
            logging.info("Error establishing connection to the database.")
            return

        cursor = conn.cursor()
        logging.info(f"(SimpleInefficiency) - Fetching {row_count} rows...")

        # Efficient query execution
        start_query_time = time.time()
        cursor.execute(f"SELECT TOP {row_count} ID, ABS(CHECKSUM(NEWID()) % 1000) AS Value FROM [MSxyzTest].[_x_y_z_MS_HighCPU]")
        rows = cursor.fetchall()
        query_execution_time = time.time() - start_query_time

        if show_query_time:
            logging.info(f"Query executed in {query_execution_time:.4f} seconds with {len(rows)} rows.")

        # Processing
        for iteration in range(iterations):
            start_iteration_time = time.time()  # Start timing for this iteration

            if efficient:
                # Efficient processing
                unique_ids = {row.ID * random.randint(100, 1000) for row in rows}
            else:
                # Inefficient processing
                unique_ids = []
                for row in rows:
                    if row.ID not in unique_ids:
                        unique_ids.append(row.ID * random.randint(100, 1000))

            iteration_time = time.time() - start_iteration_time  # Calculate time for this iteration
            if show_function_time==True:
                logging.info(f"Iteration {iteration + 1}/{iterations} took {iteration_time:.4f} seconds.")

        conn.close()
        function_stop_time = time.time() - function_query_time  # Calculate time for this function
        logging.info(f"Function took {function_stop_time:.4f} seconds.")

    except Exception as e:
        logging.error(f"An error occurred in RunSimpleInefficiencyWithTiming: {e}")

def run_in_threads_ReadOnly_QDS(thread_count, *args, **kwargs):
    """
    Starts multiple threads to run a specified function.

    Parameters:
    - thread_count (int): Number of threads to start.
    - *args: Variable length argument list to pass to the function.
    - **kwargs: Arbitrary keyword arguments to pass to the function.
    """
    threads = []
    for _ in range(thread_count):
        # Create a thread to run RunReadonly_QDS function
        thread = threading.Thread(target=RunReadonly_QDS, args=args, kwargs=kwargs)
        threads.append(thread)
        thread.start()  # Start the thread

    for thread in threads:
        thread.join()  # Wait for all threads to complete


def run_selected_scenario(scenario):
    global CURRENT_SCENARIO
    CURRENT_SCENARIO = scenario

    #Scenario N1 - RunHighCPU - Single Thread
    #--- Value 1 means High CPU usage
    #--- Value 2 means Low CPU usage
    if CURRENT_SCENARIO == HIGH_CPU_SINGLE_THREAD:
        with cProfile.Profile() as Profile:
            RunHighCPU(data_type=USE_SETINPUTSIZES, loop_count=10, timeout=30,bShowStatistics=True)
            results = pstats.Stats(Profile)
            results.strip_dirs().sort_stats('cumulative').print_stats(10)

    #Scenario N2 - RunHighCPU - Multiple Thread
    # Here, we're starting 3 threads that will call RunHighCPU with the provided arguments
    # Second parameter includes call just a single database or different database in every thread.
    if CURRENT_SCENARIO == HIGH_CPU_MULTI_THREAD:
        with cProfile.Profile() as Profile:
            run_in_threads(10, USE_MULTIPLE_DB_IN_HIGH_CPU_MULTI_THREAD, data_type=USE_SETINPUTSIZES, loop_count=10, timeout=30)
            results = pstats.Stats(Profile)
            results.strip_dirs().sort_stats('cumulative').print_stats(50)

    #Scenario N3 - Run Command Timeout
    if CURRENT_SCENARIO == COMMAND_TIMEOUT_RETRY:
        with cProfile.Profile() as Profile:    
            RunCommandTimeout(initial_timeout=1, loop_count=5, retry=True, retry_count=3, retry_increment=4)
            results = pstats.Stats(Profile)
            results.strip_dirs().sort_stats('cumulative').print_stats(10)
            

    #Scenario N4 - Run Different Execution Plan and Degraded
    if CURRENT_SCENARIO == DIFFERENT_EXECUTION_PLAN: 
        RunDifferentExecutionPlan()

    #Scenario N5 - Run High Network Latency
    if CURRENT_SCENARIO == HIGH_NETWORK_LATENCY:
        RunHighNetworkIO(1000,3,timeout=30,dbName='')
        RunHighNetworkIO(100,30,timeout=30,dbName='')

    #Scenario N6 - Run High Concurrency
    if CURRENT_SCENARIO == HIGH_CONCURRENCY:
        simulate_concurrency(item_id=1, decrement_amount=10, thread_count=50)

    #Scenario N7 - Run High CX Packet Latency
    if CURRENT_SCENARIO == HIGH_CXPACKET:
        RunHighCXPacket(30,timeout=30,dbName='')
    
    #Scenario N8 - Run DeadLock Simulation  
    if CURRENT_SCENARIO == DEADLOCK_SIMULATION:
        simulate_deadlock(retry=False)

    #Scenario N9 - Run the test to reuse connection after an error
    if CURRENT_SCENARIO == ODBC_ERROR_REUSE_CONNECTION:
        TestConnectionErrorReuse()

    #Scenario N10 - Run the test to use a Chatty application 
    if CURRENT_SCENARIO == CHATTY_APPLICATION:
        RunChattyApplication(thread_count=10, iterations=10000, use_cache=False, cache_validity=20)

    #Scenario N11 - Run the test to use a Temp DB Allocation 
    if CURRENT_SCENARIO == TEMPDB_ALLOCATION:
        simulate_tempdb_object_contention_parallel(thread_count=10, loop_count=100)

    #Scenario N12 - Run the test to use a Temp DB Data Allocation
    if CURRENT_SCENARIO == TEMPDB_ALLOCATION_DATA:
        simulate_tempdb_data_contention_parallel(thread_count=100, row_count=10000, loop_count=100) 

    #Scenario N13 - Connectivity BenchMark
    if CURRENT_SCENARIO == CONNECTION_BENCHMARK:
        run_connection_benchmark()

    #Scenario N14 - Number of executions
    if CURRENT_SCENARIO == NUMBER_OF_EXECUTIONS:
        create_guiNumberOfExecutions()

    # Scenario N15 - Extreme Data Inefficiency
    if CURRENT_SCENARIO == EXTREME_DATA_INEFFICIENCY:
        pshow_function_time=False
        with cProfile.Profile() as Profile:
            RunSimpleInefficiencyWithTiming(row_count=10000, iterations=50,show_query_time=False,efficient=False,show_function_time=pshow_function_time)
            if(pshow_function_time==True):
                results = pstats.Stats(Profile)
                results.strip_dirs().sort_stats('tottime').print_stats(5)
                results.strip_dirs().sort_stats('ncalls').print_stats(5)
    
    #Scenario N16 - Run Different ReadOnly_QDS
    if CURRENT_SCENARIO == READ_ONLY_QDS: 
        run_in_threads_ReadOnly_QDS(50)

if __name__ == "__main__":
    clear_screen()
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)
    create_gui()


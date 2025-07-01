## Copyright (c) Microsoft Corporation.
#Licensed under the MIT license.

#Azure Execution Connection Time Spent

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Param($FolderParam="", $ExtensionParam ="", $ExecutionTypeParam = "Default", $NameofAppParam ="Default")    

function GiveMeColumnsDemoHighAsyncNetworkIO
{
try 
{
  $NumCol=[int]$(ReadConfigFile("HighAsyncNetworkIO.Demo_Schema_NumColumns")) 
  $TableScript="create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighAsyncNetworkIO.Table.Name")).Trim() + "]([Id] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY"
  for($i=1;$i -le $NumCol;$i++) 
  {
   $TableScript = $TableScript + ", [Field_" + $i + "] [nvarchar](" + $(Get-Random -Minimum 10 -Maximum 4001) + ") NULL"
  }
  $TableScript = $TableScript + ")"
  return $TableScript 
}   
 catch 
  {return ""}
} 

function GiveMeColumnsDemoHighDataIO
{
 try 
 { 
  $NumCol=[int]$(ReadConfigFile("HighDATAIO.Demo_Schema_NumColumns")) 
  $TableScript="create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() +"]([Id] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY"
  for($i=1;$i -le $NumCol;$i++) 
  {
   $TableScript = $TableScript + ", [Field_" + $i + "] [nvarchar](" + $(Get-Random -Minimum 10 -Maximum 4001) + ") NULL"
  }
  $TableScript = $TableScript + ")"
  return $TableScript 
 }   
 catch 
  {return ""}
} 

function GiveMeColumnsDemoHighDataIOByBlocks
{
 try
 {
  $NumCol=[int]$(ReadConfigFile("HighDATAIOByBlocks.Demo_Schema_NumColumns")) 
  $TableScript="create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() +"]([Id] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY"
  for($i=1;$i -le $NumCol;$i++) 
  {
   $TableScript = $TableScript + ", [Field_" + $i + "] [nvarchar](" + $(Get-Random -Minimum 10 -Maximum 4001) + ") NULL"
  }
  $TableScript = $TableScript + ")"
  return $TableScript 
 }   
catch 
 {return ""}
} 


function AddRowsHighAsyncNetworkIO($TableName, $SQLConnectionSource,$FileName,$Title,$TotalRows )
{
 Try
  {

    $TotalTimeToWait = [int]$(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable") )
    $bDataLoaded = $false
    $TotalDummyRows = [int]$(ReadConfigFile(($Title+ ".DummyNumberRows")) )
    
    while((FileExist($FileName)) -eq $true)  
    {
     logMsg("Right now... " + $Title + " the example data is loading...Please, wait until the process finished...Next retry in " +  $(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable")).Trim() + " seconds")
     Start-Sleep -s $TotalTimeToWait
     $bDataLoaded = $true
    }
 
   If($bDataLoaded)
   { return $true}
   
   If( -not (LockFileLoading($FileName)))
   { return $false}
   
   [string]$string =""
   $newProducts =  New-Object -TypeName System.Data.DataTable("Temporal");

   $commandDB = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $commandDB.CommandTimeout = 6000
   $commandDB.Connection=$SQLConnectionSource
   $commandDB.CommandText = "SELECT TOP 1 * FROM " + $("[" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $TableName +"]")
      
   $ReaderDB = $commandDB.ExecuteReader()

   [System.Data.DataTable] $schemaTable = $ReaderDB.GetSchemaTable()
   ForEach($Item in $schemaTable)
   {
     $newProducts.Columns.Add($Item.ColumnName,$Item.DataType) | Out-Null;
   }
   $ReaderDB.Close()

   $value = New-Object System.Data.SqlClient.SqlBulkCopyOptions
   $ConnectionString = $SQLConnectionSource.ConnectionString+";Password="+$(ReadConfigFileSecrets("password"))
   $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString, $value )
   $TotalAdd=[long]$(ReadConfigFile(($Title+".NumberRowSampleData")))

   If( $(ReadConfigFile("SqlBulkCopy.EnableStreaming")).ToUpper().Trim() -eq "Y")
   {
     $SqlBulkCopy.EnableStreaming = $true
   }
   else 
   {
    $SqlBulkCopy.EnableStreaming = $false
   }   
   $SqlBulkCopy.DestinationTableName = $("[" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $TableName +"]")
   $SqlBulkCopy.BatchSize = 100
   $SqlBulkCopy.BulkCopyTimeout = 36000
   logMsg("Loading Example data for " + $Title + " ...Please wait" )

   for ($iRows=1; $iRows -le $TotalDummyRows; $iRows++) 
   {
    $row = $newProducts.NewRow()
    For($iColumn=1;$iColumn -le $schemaTable.Rows.Count-1;$iColumn++)
    {
     $row[$schemaTable.Rows[$iColumn].ColumnName] = $string.PadRight($(Get-Random -Minimum 10 -Maximum ($schemaTable.Rows[$iColumn].ColumnSize+1)), "#")
    }
    $newProducts.Rows.Add($row)
    logMsg("Preparing dummy data for " + $Title  + ". Current number of columns " + ($schemaTable.Rows.Count-1).ToString() + " Data Number: " + $iRows.ToString() + " of total " + $TotalDummyRows.ToString() +" .....Please wait" )
  }    
  
   $Jump = $TotalAdd-$TotalRows
   $Jump = [int]($Jump/$TotalDummyRows)+1

   for ($iQuery=1; $iQuery -le $Jump; $iQuery++) 
     {
         logMsg("Loaded example data for " + $Title + ". Current number of columns " + ($schemaTable.Rows.Count-1).ToString() + " Rows Inserted: " + ($iQuery*$TotalDummyRows).ToString() + " of total " + $TotalAdd.ToString() + ".....Please wait" )
         $SqlBulkCopy.WriteToServer($newProducts)
     }
   DeleteFile($FileName)
   return $true   
  }
    catch
   {
    logMsg("Issue loading " + $Title + ":" + $Error[0].Exception )
    DeleteFile($FileName)
    return $false
   }
}   


function AddRowsHighTempDB($TableName, $SQLConnectionSource,$FileName,$Title,$TotalRows )
{
 Try
  {

    $TotalTimeToWait = [int]$(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable") )
    $bDataLoaded = $false
    
    while((FileExist($FileName)) -eq $true)  
    {
     logMsg("Right now... the example data is loading...Please, wait until the process finished...Next retry in " +  $(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable")).Trim() + " seconds")
     Start-Sleep -s $TotalTimeToWait
     $bDataLoaded = $true
    }
 
   If($bDataLoaded)
   { return $true}

    If( -not (LockFileLoading($FileName)))
   { return $false}

   $newProducts =  New-Object -TypeName System.Data.DataTable("Temporal");
   $newProducts.Columns.Add("Id", [System.Type]::GetType("System.Int64")) | Out-Null;
   $newProducts.Columns.Add("Name", [System.Type]::GetType("System.String")) | Out-Null;
   $value = New-Object System.Data.SqlClient.SqlBulkCopyOptions
   $ConnectionString = $SQLConnectionSource.ConnectionString+";Password="+$(ReadConfigFileSecrets("password"))
   $TotalAdd=[long]$(ReadConfigFile(($Title+ ".NumberRowSampleData")))
   $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString, $value )
   [string]$string =""
   If( $(ReadConfigFile("SqlBulkCopy.EnableStreaming")).ToUpper().Trim() -eq "Y")
   {
     $SqlBulkCopy.EnableStreaming = $true
   }
   else 
   {
    $SqlBulkCopy.EnableStreaming = $false
   }    
   $SqlBulkCopy.DestinationTableName = $("[" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $TableName +"]")
   $SqlBulkCopy.BatchSize = 10000
   $SqlBulkCopy.BulkCopyTimeout = 36000
   logMsg("Loading Example data for " + $Title + ".....Please wait" )

   for ([long]$iQuery=([long]$TotalRows+1); $iQuery -le $TotalAdd; $iQuery++) 
     {
       $row = $newProducts.NewRow()
       $row["Id"] = $iQuery
       $row["Name"] = $string.PadRight($(Get-Random -Minimum 50 -Maximum 201), "#")
       $newProducts.Rows.Add($row)
       if($iQuery % 10000 -eq 0)
       {
        $SqlBulkCopy.WriteToServer($newProducts)
        $newProducts.Clear()
        logMsg("Loaded example data for " + $Title + ". Current number of rows inserted " + $iQuery.ToString() + " of total " + $TotalAdd.ToString() + ".....Please wait" )
       }
     }
     $SqlBulkCopy.WriteToServer($newProducts)
     DeleteFile($FileName)
     return $true
    }

    catch
   {
    logMsg("Issue loading " + $Title + ":" + $Error[0].Exception )
    DeleteFile($FileName)
    return $false
   }
}   

function AddRowsHighLocks($TableName, $SQLConnectionSource,$FileName, $TotalRows)
{
 Try
  {


    $TotalTimeToWait = [int]$(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable") )
    $bDataLoaded = $false
    $TotalDummyRows = [int]$(ReadConfigFile("HighLocks.NumberRowSampleData") )
    
    while((FileExist($FileName)) -eq $true)  
    {
     logMsg("Right now... the example data is loading...Please, wait until the process finished...Next retry in " +  $(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable")).Trim() + " seconds")
     Start-Sleep -s $TotalTimeToWait
     $bDataLoaded = $true
    }
 
   If($bDataLoaded)
   { return $true}

   If( -not (LockFileLoading($FileName)))
   { return $false}

   $newProducts =  New-Object -TypeName System.Data.DataTable("Temporal");
   $newProducts.Columns.Add("Id", [System.Type]::GetType("System.Int64")) | Out-Null;
   $value = New-Object System.Data.SqlClient.SqlBulkCopyOptions
   $ConnectionString = $SQLConnectionSource.ConnectionString+";Password="+$(ReadConfigFileSecrets("password"))
   $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString, $value )
   $SqlBulkCopy.EnableStreaming = $false
   $SqlBulkCopy.DestinationTableName = $("[" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $TableName +"]")
   $SqlBulkCopy.BatchSize = 10000
   $SqlBulkCopy.BulkCopyTimeout = 36000
   logMsg("Loading Example data for HighLocks.....Please wait" )
   for ($iQuery=($TotalRows+1); $iQuery -lt ($TotalDummyRows+1); $iQuery++) 
     {
       $row = $newProducts.NewRow()
       $row["Id"] = $iQuery
       $newProducts.Rows.Add($row)
       if($iQuery % 10000 -eq 0)
       {
        $SqlBulkCopy.WriteToServer($newProducts)
        $newProducts.Clear()
        logMsg("Loaded example data for HighLocks. Current number of rows inserted " + $iQuery.ToString() + " of total " + $TotalDummyRows.ToString() + ".....Please wait" )
       }
     }
     $SqlBulkCopy.WriteToServer($newProducts)
     DeleteFile($FileName)
     return $true
    }

    catch
   {
    logMsg("Issue loading HighLocks:" + $Error[0].Exception )
    DeleteFile($FileName)
    return $false
   }
}   

function AddRowsHighCPU($TableName, $SQLConnectionSource,$FileName,$TotalRows )
{
 Try
  {

   $TotalTimeToWait = [int]$(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable") )
   $bDataLoaded = $false
   
   while((FileExist($FileName)) -eq $true)  
   {
    logMsg("Right now... the example data is loading...Please, wait until the process finished...Next retry in " +  $(ReadConfigFile("TimeToWaitForUnlockingTheLoadingTable")).Trim() + " seconds")
    Start-Sleep -s $TotalTimeToWait
    $bDataLoaded = $true
   }

   If($bDataLoaded)
   { return $true}
   
   If( -not (LockFileLoading($FileName)))
   {return $false}

   $newProducts =  New-Object -TypeName System.Data.DataTable("Temporal");
   $newProducts.Columns.Add("Id", [System.Type]::GetType("System.Int64")) | Out-Null;
   $newProducts.Columns.Add("Name", [System.Type]::GetType("System.String")) | Out-Null;
   $value = New-Object System.Data.SqlClient.SqlBulkCopyOptions
   $ConnectionString = $SQLConnectionSource.ConnectionString+";Password="+$(ReadConfigFileSecrets("password"))
   $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString, $value )
   $TotalAdd=[long]$(ReadConfigFile("HighCPU.NumberRowSampleData"))

   If( $(ReadConfigFile("SqlBulkCopy.EnableStreaming")).ToUpper().Trim() -eq "Y")
   {
     $SqlBulkCopy.EnableStreaming = $true
   }
   else 
   {
    $SqlBulkCopy.EnableStreaming = $false
   }      
   $SqlBulkCopy.DestinationTableName = $("[" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $TableName +"]")
   $SqlBulkCopy.BatchSize = 10000
   $SqlBulkCopy.BulkCopyTimeout = 36000
   logMsg("Loading Example data for HighCPU.....Please wait" )
   for ($iQuery=($TotalRows+1); $iQuery -le $TotalAdd; $iQuery++) 
     {
       $row = $newProducts.NewRow()
       $row["Id"] = $iQuery
       $row["Name"] = $("Test Search " + $(Get-Random -Minimum 1 -Maximum 10000001).ToString())
       $newProducts.Rows.Add($row)
       if($iQuery % 10000 -eq 0)
       {
        $SqlBulkCopy.WriteToServer($newProducts)
        $newProducts.Clear()
        logMsg("Loaded example data for HighCPU. Current number of rows inserted " + $iQuery.ToString() + " of total " + $TotalAdd.ToString() + ".....Please wait" )
       }
     }
     $SqlBulkCopy.WriteToServer($newProducts)
     DeleteFile($FileName)
     return $true
    }

    catch
   {
    logMsg("Issue loading HighCPU:" + $Error[0].Exception )
    DeleteFile($FileName)
    return $false
   }
}   

function LockFileLoading($FileName)
{
 try
 {
  $return = $false
  logMsg("Create the file for locking.." + $FileName )
  for($i=0;$i -le 10;$i++)
  {
   try
    {
     $stream_write = New-Object System.IO.StreamWriter($FileName)
     $stream_write.Write(".")
     $stream_write.Close()
     $return=$true
     logMsg("Created the file for locking.." + $FileName )
     break;
    }
   catch
   { Start-Sleep -s 5 }
  }
  return $return
 }
   catch
   { 
    logMsg("Issue creating the file for locking.." + $Error[0].Exception  )
    return $false
  }
}
#----------------------------------------
# Bulk-Insert process
#----------------------------------------

function BulkInsert($SQLConnectionSource, $ShowStatisticsQuery,$CommandTimeout)
{
 Try
  {
   $BatchSize=[int]$(ReadConfigFile("SqlBulkCopy.BatchSize").Trim())
   $BatchOperations=[int]$(ReadConfigFile("SqlBulkCopy.Operations").Trim())
   $MinBatchSize=[int]$(ReadConfigFile("SqlBulkCopy.MinBatchSize").Trim())
   $Value=$BatchSize+1
   $Value = $(Get-Random -Minimum $MinBatchSize -Maximum $Value)
   $WriteServer = [int]($BatchOperations/$Value)
   $StatisticsEnabled = $SQLConnectionSource.StatisticsEnabled;
   [string]$Tmp = ""   

   $newProducts =  New-Object -TypeName System.Data.DataTable($(ReadConfigFile("BulkInsert.Table.Name")).Trim());
   $newProducts.Columns.Add("Name", [System.Type]::GetType("System.String")) | Out-Null;
   $value = New-Object System.Data.SqlClient.SqlBulkCopyOptions
   $ConnectionString = $SQLConnectionSource.ConnectionString+";Password="+$(ReadConfigFileSecrets("password"))
   $SqlBulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString, $value )
   If( $(ReadConfigFile("SqlBulkCopy.EnableStreaming")).ToUpper().Trim() -eq "Y")
   {
     $SqlBulkCopy.EnableStreaming = $true
   }
   else 
   {
    $SqlBulkCopy.EnableStreaming = $false
   }     
   $SqlBulkCopy.DestinationTableName = ("[" + $(ReadConfigFile("SchemaTablesWork"))+"].[" + $(ReadConfigFile("BulkInsert.Table.Name")).Trim() +"]")
   $SqlBulkCopy.BatchSize = $BatchSize
   $SqlBulkCopy.BulkCopyTimeout = $CommandTimeout

   $SQLConnectionSource.StatisticsEnabled=$true;
   $start = get-date

   for ($iQuery=1; $iQuery -lt $BatchOperations; $iQuery++) 
     {
       $row = $newProducts.NewRow()
       $row["Name"] = $Tmp.PadRight($(Get-Random -Minimum 50 -Maximum 2501), "#")
       $newProducts.Rows.Add($row)
       if($iQuery % $WriteServer -eq 0)
       {
        $SqlBulkCopy.WriteToServer($newProducts)
        $data = $SQLConnectionSource.RetrieveStatistics()        
        $end =get-date 
        $Diff = (New-TimeSpan -Start $start -End $end).TotalMilliseconds
        $TotalTime=$TotalTime+$Diff
        logMsg(" ------<New>-------") (1)
        logMsg("Showing every    : " +$WriteServer.ToString()) (1)
        logMsg("Iteration        : " +$iQuery + " of " + $BatchOperations.ToString() + " Time required for " + $WriteServer.ToString() + " -- Time: " +$Diff.ToString())
        logMsg("NetworkServerTime: " +$data.NetworkServerTime + " Execution Time: " +$data.ExecutionTime + " ServerRoundTrips: " +$data.ServerRoundtrips)
        logMsg("Average          : " +$TotalTime/($iQuery+1) + " of " + $TotalTime)
        logMsg("BuffersReceived  : " +$data.BuffersReceived)
        logMsg("SelectRows       : " +$data.SelectRows) 
        logMsg("SelectCount      : " +$data.SelectCount)
        logMsg("BytesSent        : " +$data.BytesSent)
        logMsg("BytesReceived    : " +$data.BytesReceived)
        $newProducts.Clear()                
        $start = get-date
        $SQLConnectionSource.ResetStatistics()
        $SQLConnectionSource.StatisticsEnabled=$true;
       }
     }
       $SQLConnectionSource.StatisticsEnabled = $StatisticsEnabled
    }
    catch
   {
    logMsg("Issue:" + $Error[0].Exception )
   }
}   


function GiveListOfDBToWork($IPReference,$IPControlPort,$IPControlPortProcess,$NameofApp,$DBName)
{
   $DbsArray = [System.Collections.ArrayList]::new() 
   $SQLConnectionSource = GiveMeConnectionSource $IPReference $IPControlPort $IPControlPortProcess $NameofAppPara "master" #Connecting to the database.
   if($SQLConnectionSource -eq $null)
    { 
     logMsg("It is not possible to connect to the database") (2)
     exit;
    }
   $commandDB = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $commandDB.CommandTimeout = 6000
   $commandDB.Connection=$SQLConnectionSource
   if(TestEmpty($(ReadConfigFile("ElasticDBPoolName"))))
   {
     $commandDB.CommandText = "SELECT name from sys.databases where database_id >=5 order by name"
   }
   else
   {
     $commandDB.CommandText = "SELECT d.name as DatabaseName FROM sys.databases d inner join sys.database_service_objectives dso on d.database_id = dso.database_id WHERE dso.elastic_pool_name = '" + $(ReadConfigFile("ElasticDBPoolName")) + "' ORDER BY d.name"
   }
      
   $ReaderDB = $commandDB.ExecuteReader(); 
   while($ReaderDB.Read())
   {
      [void]$DbsArray.Add($ReaderDB.GetValue(0).ToString())
      logMsg("Database Name selected:" + $ReaderDB.GetValue(0).ToString()) (1)
   }

   $ReaderDB.Close();
   $SQLConnectionSource.Close() 
   return $DbsArray
}
else
{
  return @()
}

function CreateTable($TableName,$connection,$SqlSyntax)
{
 try
 {

   If(-not (CreateSchema($connection)))
   {
     return 0
   }

   $CommandTimeout = [long]$(ReadConfigFile("Table_Creation.CommandTimeout"))

   logMsg( "Creating the table " + $TableName ) 

   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout=$CommandTimeout
   $command.Connection=$connection
   $command.CommandText="SELECT TOP 1 Name FROM sys.tables where Name = '" + $TableName + "' and type='U' and schema_name(schema_id) ='" + $(ReadConfigFile("SchemaTablesWork")).Trim() + "'"
   $Reader = $command.ExecuteReader(); 

   $bFound=($Reader.HasRows)
   $Reader.Close()

   $return =2
   If(-not ($bFound))
   {
     $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
     $commandExecute.CommandTimeout=$CommandTimeout
     $commandExecute.Connection=$connection
     $commandExecute.CommandText = $SqlSyntax
     $Null = $commandExecute.ExecuteNonQuery(); 
     $return =2
     logMsg( "Created the table " + $TableName + " - Success. Parameter Returned : " + $return.ToString()) 
   }
   else {
    logMsg( "Table " + $TableName + " already exists . Parameter Returned : " + $return.ToString()) 
   }
   
  return $return
  }
  catch
   {
    If( $(ReadConfigFile("Table_Creation.ShowErrorInCaseThatFailingSchemaCreation")).ToUpper().Trim() -eq "Y")
    {
     logMsg( "Created the table " + $TableName + " - Error:..." + $Error[0].Exception ) (2)
    }  
    return 0
   } 
}

function CreateStoreProcedure($StoredProc,$connection,$SqlSyntax)
{
 try
 {

   If(-not (CreateSchema($connection)))
   {
     return 0
   }

   $CommandTimeout = [long]$(ReadConfigFile("Table_StoredProc.CommandTimeout"))

   logMsg( "Creating the stored procedure " + $StoredProc ) 

   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout=$CommandTimeout
   $command.Connection=$connection
   $command.CommandText="SELECT TOP 1 Name FROM sys.objects where Name = '" + $StoredProc + "' and type='P' and schema_name(schema_id) ='" + $(ReadConfigFile("SchemaTablesWork")).Trim() + "'"
   $Reader = $command.ExecuteReader(); 

   $bFound=($Reader.HasRows)
   $Reader.Close()

   $return =2
   If(-not ($bFound))
   {
     $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
     $commandExecute.CommandTimeout=$CommandTimeout
     $commandExecute.Connection=$connection
     $commandExecute.CommandText = $SqlSyntax
     $Null = $commandExecute.ExecuteNonQuery(); 
     $return =2
     logMsg( "Created the stored procedure " + $StoredProc + " - Success. Parameter Returned : " + $return.ToString()) 
   }
   else {
    logMsg( "Stored Procedure " + $StoredProc + " already exists . Parameter Returned : " + $return.ToString()) 
   }
   
  return $return
  }
  catch
   {
    If( $(ReadConfigFile("Table_Creation.ShowErrorInCaseThatFailingSchemaCreation")).ToUpper().Trim() -eq "Y")
    {
     logMsg( "Created the stored procedure " + $StoredProc + " - Error:..." + $Error[0].Exception ) (2)
    }  
    return 0
   } 
}

function CreateSchema($connection)
{
 try
 {

   $Schema = $(ReadConfigFile("SchemaTablesWork")).Trim()
   $CommandTimeout = [long]$(ReadConfigFile("Schema.CommandTimeout"))
   logMsg( "Checking if Schema exists : " + $Schema ) 

   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout=$CommandTimeout
   $command.Connection=$connection
   $command.CommandText="SELECT TOP 1 Name FROM sys.schemas where Name = '" + $Schema + "'"
   $Reader = $command.ExecuteReader(); 

   $bFound=($Reader.HasRows)
   $Reader.Close()

   If(-not ($bFound))
   {
     $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
     $commandExecute.CommandTimeout=$CommandTimeout
     $commandExecute.Connection=$connection
     $commandExecute.CommandText="CREATE Schema [" + $Schema + "]"
     $Null = $commandExecute.ExecuteNonQuery(); 
     logMsg( "Created the schema " + $Schema + " - Success") 
   }
  else 
  {
   logMsg( "Schema " + $Schema + " already exists") 
  }
   
   logMsg( "End of checking if schema exists : " + $Schema ) 

  return $true
  }
  catch
   {
    If( $(ReadConfigFile("Schema.ShowErrorInCaseThatFailingSchemaCreation")).ToUpper().Trim() -eq "Y")
    {
      logMsg( "Created the Schema " + $Schema + " - Error:..." + $Error[0].Exception ) (2)
    }      
    return $false
   } 
}


function GiveMeTheSortByWhat()
{
    Param
    (
            [Parameter(Mandatory=$true, Position=0)]
            [string] $Table,
            [Parameter(Mandatory=$false, Position=1)]
            [System.Data.SqlClient.SqlConnection] $connection,
            [Parameter(Mandatory=$false, Position=2)]
            [boolean] $bSort=$true

    )
  try
  { 
    [string]$Return = " order by 1";

    if(!$bSort)
    {
      return "";
    }

    $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $commandExecute.CommandText = "SELECT TOP 1 * FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $Table + "]"
    $commandExecute.Connection = $connection
    $commandExecute.CommandTimeout = 6000
    $Reader = $commandExecute.ExecuteReader()
    while($Reader.Read())
    {
        [int]$RandomValue = Get-Random -Minimum 0 -Maximum $($Reader.FieldCount)
        $Return = " order by [" + $Reader.GetName($RandomValue).ToString() + "]"
    }
    $Reader.Close()
    return $Return
    }
  catch 
   {return ""}
} 
  function lGiveLastNumberOfRows()
  {
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Table,
         [Parameter(Mandatory=$false, Position=1)]
         [System.Data.SqlClient.SqlConnection] $connection,
         [Parameter(Mandatory=$false, Position=2)]
         [string] $Schema="dbo"

    )
    try
    {     
     [long]$Return = 0;
     logMsg( "Review how many rows has this table:" + $Schema + "." + $Table )
     $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
                $commandExecute.CommandText = "SELECT t.Name, s.Name, p.rows AS RowCounts"
                $commandExecute.CommandText = $commandExecute.CommandText + " FROM sys.tables t"
                $commandExecute.CommandText = $commandExecute.CommandText + " INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id"
                $commandExecute.CommandText = $commandExecute.CommandText + " INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id"
                $commandExecute.CommandText = $commandExecute.CommandText + " INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id"
                $commandExecute.CommandText = $commandExecute.CommandText + " LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id"
                $commandExecute.CommandText = $commandExecute.CommandText + " WHERE t.Name ='" + $Table + "' and s.Name = '" + $Schema + "'"
                $commandExecute.CommandText = $commandExecute.CommandText + " GROUP BY t.Name, s.Name,p.rows"
                $commandExecute.Connection = $connection
                $commandExecute.CommandTimeout = [int]$(ReadConfigFile("lGiveLastNumberOfRows.CommandTimeout"))
                $Reader = $commandExecute.ExecuteReader()
                while ($Reader.Read())
                {
                    $Return = [long]$Reader.GetSqlInt64(2)
                }
                $Reader.Close()
                logMsg( "Review how many rows has this table:" + $Schema + "." + $Table + " returned: " + $Return.ToString() + " rows..")
                return $Return;
    }   
    catch 
     {return 0}
}
      

function GiveMeTheColumnsToRetrieve()
{
    Param
    ( 
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Table,
    [Parameter(Mandatory=$false, Position=1)]
    [System.Data.SqlClient.SqlConnection] $connection,
    [Parameter(Mandatory=$false, Position=2)]
    [int] $HowMany=0
    )
   try 
   {
    [string] $Return = " * "
    [string] $ReturnTmp = ""

    if($HowMany -eq 0) { return $Return; }

    $commandExecute = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $commandExecute.CommandText = "SELECT TOP 1 * FROM [" + $(ReadConfigFile("SchemaTablesWork")) +"].["+ $Table + "]"
        $commandExecute.Connection = $connection
        $commandExecute.CommandTimeout = [int]$(ReadConfigFile("GiveMeTheColumnsToRetrieve.CommandTimeout"))
        $Reader = $commandExecute.ExecuteReader()
        while ($Reader.Read())
        {
            [int]$RandomValue = 0
            [int]$Start = 0
            [int]$End = 0
            [int]$RandomValue = Get-Random -Minimum 0 -Maximum $($Reader.FieldCount-1);
            $Start = $RandomValue;
            $End = $Reader.FieldCount - $RandomValue;
            if( $HowMany -gt $End) { $HowMany = $End; }
            for ([int]$NumberColumns = $Start; $NumberColumns -le ($Start+$HowMany); $NumberColumns++)
            {
                $ReturnTmp = $ReturnTmp + "[" + $Reader.GetName($NumberColumns).ToString() + "],"
            }
        }
        if ($ReturnTmp.Length -ne 0) { $ReturnTmp = $ReturnTmp.Substring(0, $ReturnTmp.Length - 1)}
        $Reader.Close()

    if($ReturnTmp.Length -eq 0) { $Return = " * "}
    else { $Return = $ReturnTmp} 

    return $Return;
  }   
  catch 
   {return ""}
}

#----------------------------------------------------------------
#Function to connect to the database using a retry-logic
#----------------------------------------------------------------

Function GiveMeConnectionSource($IPReference,$IPControlPort,$IPControlPortProcess,$NameofApp,$DBName)
{ 
  $NumberAttempts= ReadConfigFile("RetryLogicNumberAttempts")
  for ($i=1; $i -le [int]$NumberAttempts; $i++)
  {
   try
    {
     
     if(TestEmpty($DBName))
     {
      $DBName = $(ReadConfigFile("Db")).ToUpper().Trim()
     }

     if( $(ReadConfigFile("ShowConnectionMessage").ToUpper().Trim()) -eq "Y")
     {
      logMsg( "Connecting to the database: " + $(ReadConfigFile("server")).Trim() + " - DB: " + $DBName + "...Attempt #" + $i + " of " + $NumberAttempts) (1) -SaveFile $true 
     }

      if( TestEmpty($IPReference.InitialIP) -eq $true)
       {$IPReference.InitialIP = CheckDns($(ReadConfigFile("server").Trim()))}
      else
      {
       $IPReference.OtherIP = CheckDns($(ReadConfigFile("server").Trim()))
       If( $IPReference.OtherIP -ne $IPReference.InitialIP )
       {
        if( $(ReadConfigFile("ShowIPChangedMessage").ToUpper().Trim()) -eq "Y")
        {
         logMsg("IP changed noticed....") (1)
        }
       }
      }

       if( $(ReadConfigFile("ShowPortConnection").ToUpper().Trim()) -eq "Y")
       {
        $Results = CheckPort $(ReadConfigFile("server").Trim()) $(ReadConfigFile("Port").Trim())
        if( $(ReadConfigFile("ShowIPPortTest").ToUpper().Trim()) -eq "Y")
        {
         logMsg("Connection IP and port...." + $Results.ToString()) (1)
        }
       }


      $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 

      $SQLConnection.ConnectionString = "Server="+$(ReadConfigFile("Protocol").Trim())
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + $(ReadConfigFile("server").Trim())+"," + $(ReadConfigFile("port"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Database="+$DBName
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Connection Timeout="+$(ReadConfigFile("ConnectionTimeout"))
      If(TestEmpty($NameofApp))
      {
       $NameofApp=$(ReadConfigFile("ApplicationName").Trim())
      }
      else
      {
       $NameofApp=$(ReadConfigFile("ApplicationName").Trim()) + $NameofApp.Trim()
      }
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";ConnectRetryCount="+$(ReadConfigFile("ConnectRetryCount"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";ConnectRetryInterval="+$(ReadConfigFile("ConnectRetryInterval"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Max Pool Size="+$(ReadConfigFile("Max Pool Size"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Min Pool Size="+$(ReadConfigFile("Min Pool Size"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";MultipleActiveResultSets="+$(ReadConfigFile("MultipleActiveResultSets"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Pooling="+$(ReadConfigFile("Pooling"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";User ID="+ $(ReadConfigFileSecrets("user"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Password="+$(ReadConfigFileSecrets("password"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Encrypt="+$(ReadConfigFileSecrets("Encrypt"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";TrustServerCertificate="+$(ReadConfigFileSecrets("TrustServerCertificate"))
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";ApplicationIntent="+$(ReadConfigFileSecrets("ApplicationIntent"))

      If( $(ReadConfigFile("Packet Size")) -ne "-1" )
      {
        $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Packet Size="+$(ReadConfigFile("Packet Size"))
      }
      $SQLConnection.ConnectionString = $SQLConnection.ConnectionString + ";Application Name="+$NameofApp

      $SQLConnection.StatisticsEnabled = 1

      $start = get-date
        $SQLConnection.Open()
      $end = get-date

      $LatencyAndOthers.ConnectionsDone_Number_Success = $LatencyAndOthers.ConnectionsDone_Number_Success+1
      $LatencyAndOthers.ConnectionsDone_MS = $LatencyAndOthers.ConnectionsDone_MS+(New-TimeSpan -Start $start -End $end).TotalMilliseconds

      if( $(ReadConfigFile("ShowConnectionMessage").ToUpper().Trim()) -eq "Y")
      {
       logMsg("Connected to the database in (ms):" +(New-TimeSpan -Start $start -End $end).TotalMilliseconds + " - ID:" + $SQLConnection.ClientConnectionId.ToString() + " -- HostName: " + $SQLConnection.WorkstationId + " Server Version:" + $SQLConnection.ServerVersion) (3)
       logMsg("Connections Failed :" + $LatencyAndOthers.ConnectionsDone_Number_Failed.ToString())
       logMsg("Connections Success:" + $LatencyAndOthers.ConnectionsDone_Number_Success.ToString())
       logMsg("Connections ms     :" + ($LatencyAndOthers.ConnectionsDone_MS / $LatencyAndOthers.ConnectionsDone_Number_Success).ToString())
      }
      
      return $SQLConnection
      break;
    }
  catch
   {
    $LatencyAndOthers.ConnectionsDone_Number_Failed = $LatencyAndOthers.ConnectionsDone_Number_Failed +1
    logMsg("Not able to connect - Retrying the connection..." + $Error[0].Exception.ErrorRecord + "-" + $Error[0].Exception.ToString().Replace("\t"," ").Replace("\n"," ").Replace("\r"," ").Replace("\r\n","").Trim()) (2)
    logMsg("Waiting for next retry in " + $(ReadConfigFile("RetryLogicNumberAttemptsBetweenAttemps")) + " seconds ..")
    Start-Sleep -s $(ReadConfigFile("RetryLogicNumberAttemptsBetweenAttemps"))
    if( $(ReadConfigFile("ClearAllPools").ToUpper().Trim()) -eq "Y" )
      {
        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
      }
   }
  }
}

#----------------------------------------------------------------
#Function to execute any query using a command retry-logic
#----------------------------------------------------------------

Function ExecuteQuery($SQLConnectionSource, $query, $commandType,$Retries,$ShowXMLPlan,$ShowStatisticsQuery,$CommandTimeout,$CommandTimeoutFactor,$HasRows,$IsolationLevel)
{ 
  $bError=$false
  for ($i=1; $i -le $Retries; $i++)
  {
   try
    {
      logMsg -msg $("Executing Query:.." + $Query + " Retry:" + $i.ToString() + " under " + $IsolationLevel + " Command Timeout:" + $CommandTimeout.ToString()) 
      If($bError)
      {
       $bError=$false 
         If($rdr.IsClosed -eq $false)
         {
          $rdr.Close()
         }
      }
      $start = get-date
        $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
        $command.CommandTimeout = $CommandTimeout
        If($i -ge 2) 
        {
          $command.CommandTimeout = $CommandTimeout + $CommandTimeoutFactor
        } 
        $command.Connection=$SQLConnectionSource
        If($ShowXMLPlan -eq "Y")
         {
          $command.CommandText = "SET STATISTICS XML ON;"+$query
         }
         else
         {
          $command.CommandText = $query
         }
        ##$command.ExecuteNonQuery() | Out-Null
        If( $ShowStatisticsQuery -eq "Y" )
        {
          $SQLConnectionSource.ResetStatistics()
        }
        If($CommandType -eq 1 )
        {
          $rdr = $command.ExecuteReader()
          if( $HasRows -eq "Y")
          {
             $Null = $rdr.HashRows
          }
          $rdr.Close()
        }
        If($CommandType -eq 2 )
        {
          $Null = $command.ExecuteNonQuery()
        }

        If($CommandType -eq 3 )
        {
          $rdr = $command.ExecuteReader()
          [long]$TotalRows=0
          while($rdr.Read())
          {
            $TotalRows++
            if ($TotalRows % 10000 -eq 0)
            {
             logMsg -msg $("Leyendo..." + $TotalRows.ToString()) -SaveFile $false -Color 1
            }
          }
          $rdr.Close()
        }

        If($CommandType -eq 4 )
        {
          $command.CommandText = $IsolationLevel + ";" + $command.CommandText
          $Null = $command.ExecuteNonQuery()
        }

  
        If( $ShowStatisticsQuery -eq "Y" )
        {
         $data = $SQLConnectionSource.RetrieveStatistics()
        }
      $end = get-date

        If($ShowXMLPlan -eq "Y" -and $CommandType -eq 1 )
         {
           do
            {
             $datatable = new-object System.Data.DataTable
             $datatable.Load($rdr)
            } while ($rdr.IsClosed -eq $false)
         }
             $LatencyAndOthers.ExecutionsDone_Number_Success = $LatencyAndOthers.ExecutionsDone_Number_Success+1
             $LatencyAndOthers.ExecutionsDone_MS = $LatencyAndOthers.ExecutionsDone_MS+(New-TimeSpan -Start $start -End $end).TotalMilliseconds

             LogMsg("-------------------------" ) -Color 3
             LogMsg("Query                 :  " +$query) 
             LogMsg("Iteration             :  " +$i) 
             If($ShowStatisticsQuery -eq "Y" )
             {
              LogMsg("Time required (ms)    :  " +(New-TimeSpan -Start $start -End $end).TotalMilliseconds) 
              LogMsg("NetworkServerTime (ms):  " +$data.NetworkServerTime) ##Returns the cumulative amount of time (in milliseconds) that the provider spent waiting for replies from the server once the application has started using the provider and has enabled statistics.
              LogMsg("Execution Time (ms)   :  " +$data.ExecutionTime) ##Returns the cumulative amount of time (in milliseconds) that the provider has spent processing once statistics have been enabled, including the time spent waiting for replies from the server as well as the time spent executing code in the provider itself.
              LogMsg("Connection Time       :  " +$data.ConnectionTime) ##The amount of time (in milliseconds) that the connection has been opened after statistics have been enabled (total connection time if statistics were enabled before opening the connection).
              LogMsg("ServerRoundTrips      :  " +$data.ServerRoundtrips) ##Returns the number of times the connection sent commands to the server and got a reply back once the application has started using the provider and has enabled statistics.
              LogMsg("BuffersReceived       :  " +$data.BuffersReceived) 
              LogMsg("SelectRows            :  " +$data.SelectRows) 
              LogMsg("SelectCount           :  " +$data.SelectCount) 
              LogMsg("BytesSent             :  " +$data.BytesSent) 
              LogMsg("BytesReceived         :  " +$data.BytesReceived) 
              LogMsg("CommandTimeout        :  " +$command.CommandTimeout ) 
              LogMsg("Total Exec.Failed     :  " + $LatencyAndOthers.ExecutionsDone_Number_Failed.ToString())
              LogMsg("Total Exec.Success    :  " + $LatencyAndOthers.ExecutionsDone_Number_Success.ToString())
              LogMsg("Avg. Executions ms    :  " + ($LatencyAndOthers.ExecutionsDone_MS / $LatencyAndOthers.ExecutionsDone_Number_Success).ToString())
             }
             If($ShowXMLPlan -eq "Y" -and $CommandType -eq 1 )
             {
               LogMsg("Execution Plan        :  " +$datatable[0].Rows[0].Item(0)) 
               $rdr.Close()
             }

             LogMsg("-------------------------" ) -Color 3
    break;
    }
  catch
   {
    $LatencyAndOthers.ExecutionsDone_Number_Failed = $LatencyAndOthers.ExecutionsDone_Number_Failed+1
    $bError=$true
    LogMsg("------------------------" ) -Color 3
    LogMsg("Query                 : " +$query) 
    LogMsg("Iteration             : " +$i) 
    If(-not (TestEmpty($end)))
    {
      LogMsg("Time required (ms)    : " +(New-TimeSpan -Start $start -End $end).TotalMilliseconds) 
    }
    LogMsg("Total Exec.Failed     :  " + $LatencyAndOthers.ExecutionsDone_Number_Failed.ToString())
    LogMsg("Total Exec.Success    :  " + $LatencyAndOthers.ExecutionsDone_Number_Success.ToString())
    If( $LatencyAndOthers.ExecutionsDone_Number_Success -gt 0)
    {
      LogMsg("Avg. Executions ms    :  " + ($LatencyAndOthers.ExecutionsDone_MS / $LatencyAndOthers.ExecutionsDone_Number_Success).ToString())
    }
    else
    {
     LogMsg("Avg. Executions ms    :  " + ($LatencyAndOthers.ExecutionsDone_MS / $LatencyAndOthers.ExecutionsDone_Number_Failed).ToString())
    }
    logMsg("Not able to run the query - Retrying the operation..." + $Error[0].Exception.ErrorRecord + ' ' + $Error[0].Exception) (2)
    LogMsg("-------------------------" ) -Color 3
    $Timeout = $(ReadConfigFile("CommandExecutionRetriesWaitTime"))
    logMsg("Retrying in..." + $Timeout + " seconds ") (2)
    Start-Sleep -s $Timeout
   }
  }
}

#--------------------------------
#Obtain the DNS details resolution.
#--------------------------------
function CheckDns($sReviewServer)
{
try
 {
    $IpAddress = [System.Net.Dns]::GetHostAddresses($sReviewServer)
    foreach ($Address in $IpAddress)
    {
        $sAddress = $sAddress + $Address.IpAddressToString + " ";
    }
    if( $(ReadConfigFile("ShowIPResolution").ToUpper().Trim()) -eq "Y")
    {
      logMsg("Server IP:" + $sAddress) (3)
    }
    return $sAddress
    break;
 }
  catch
 {
  logMsg("Imposible to resolve the name - Error: " + $Error[0].Exception) (2)
  return ""
 }
}

#--------------------------------
#Obtain the PORT details connectivity
#--------------------------------
function CheckPort($sReviewServer,$Port)
{
try
 {
    $TcpConnection = Test-NetConnection $sReviewServer -Port $Port -InformationLevel Detailed
    if( $(ReadConfigFile("ShowIPPortTest").ToUpper().Trim()) -eq "Y")
    {
      logMsg("Test " + $sReviewServer + " Port:" + $Port + " Status:" + $TcpConnection.TcpTestSucceeded) (3)
    }
    return $TcpConnection.TcpTestSucceeded
    break;
 }
  catch
 {
  logMsg("Imposible to test the port - Error: " + $Error[0].Exception) (2)
  return "Error"
 }
}

#--------------------------------
#Obtain Process Name By ID
#--------------------------------
function ProcessNameByID($Id)
{
try
 {
    $Proc = Get-Process -id $id 
    return $Proc.ProcessName + "-" + $Proc.Description
 }
  catch
 {
  return ""
 }
}

#--------------------------------
#Obtain the list of ports, process and calculate how many are for 1433 and redirect ports
#--------------------------------
function Ports($IPControlPort,$IPControlPortProcess)
{
try
 {
    $IPControlPortProcess.Clear()
    $IPControlPort.IP1433=0
    $IPControlPort.IPRedirect=0
    $IPControlPort.IPTotal=0
    $bFound=$false
    $Number=-1
    $IpAddress = Get-NetTCPConnection
    for ($i=0; $i -lt $IpAddress.Count; $i++)
    {

     $bFound = $false
     $IPControlPort.IPTotal=$IPControlPort.IPTotal+1 

     for ($iP=0; $iP -lt $IPControlPortProcess.Count; $iP++)
     {
       if( $IpAddress[$i].OwningProcess -eq $IPControlPortProcess[$iP].NumProcess)
       {
          $bFound=$true
          $Number=$iP
          break
       }
     }

     if($bFound -eq $false)
     {
        $Tmp = [IPControlPortProcess]::new()
        $TMP.IP1433=0
        $TMP.IPRedirect=0
        $TMP.IPTotal=0
        $TMP.NumProcess = $IpAddress[$i].OwningProcess
        $IPControlPortProcess.Add($TMP) | Out-Null
        $Number=$IPControlPortProcess.Count-1
     }

     If( $IpAddress[$i].RemotePort -eq 1433 )
     {
       $IPControlPort.IP1433=$IPControlPort.IP1433+1 
       $IPControlPortProcess[$Number].IP1433=$IPControlPortProcess[$Number].IP1433+1
     }
     If( $IpAddress[$i].RemotePort -ge 11000 -and $IpAddress[$i].RemotePort -le 12999)
     {
       $IPControlPort.IPRedirect=$IPControlPort.IPRedirect+1 
       $IPControlPortProcess[$Number].IPRedirect=$IPControlPortProcess[$Number].IPRedirect+1
     }
       $IPControlPortProcess[$Number].IPTotal=$IPControlPortProcess[$Number].IPTotal+1
    }
     logMsg("Ports - 1433 : " + $IPControlPort.Ip1433 + " Redirect: " + $IPControlPort.IPRedirect + " Total: " + $IPControlPort.IPTotal)

     If($(ReadConfigFile("ShowPortsDetails").ToUpper().Trim()) -eq "Y" )
     {
      logMsg("Procs:"  + ($IPControlPortProcess.Count-1).ToString() ) 
      for ($iP=0; $iP -lt $IPControlPortProcess.Count; $iP++)
      {
        $ProcessName = ProcessNameByID($IPControlPortProcess[$IP].NumProcess)
        logMsg("------> Proc Number:"  + $IPControlPortProcess[$IP].NumProcess + "-" + $ProcessName + "/ 1433: " + $IPControlPortProcess[$IP].IP1433 + " Redirect:" + $IPControlPortProcess[$IP].IPRedirect + " Other:" + $IPControlPortProcess[$IP].IPTotal)
      }
     }
 }
  catch
 {
  logMsg("Imposible to obtain the ports - Error: " + $Error[0].Exception) (2)
 }
}

#--------------------------------
#Obtain the Performance counters.
#--------------------------------
function PerfCounters($CounterPattern)
{
try
 {
    logMsgPerfCounter( "Obtaining Performance Counters of : " + $CounterPattern )
    $Counters = Get-Counter -Counter $CounterPattern 
    foreach ($Counter in $Counters.CounterSamples)
    {
        logMsgPerfCounter( "Counter: " + $Counter.Path + " - " + $Counter.InstanceName + "-" + $Counter.CookedValue )
    }
    logMsgPerfCounter( "Obtained Performance Counters of : " + $CounterPattern )
 }
  catch
 {
  logMsgPerfCounter( "Imposible to obtain Performance Counters of : " + $CounterPattern + "- Error: " + $Error[0].Exception) (2)
  return ""
 }
}

#--------------------------------------------------------------
#Create a folder 
#--------------------------------------------------------------
Function CreateFolder
{ 
  Param( [Parameter(Mandatory)]$Folder ) 
  try
   {
    $FileExists = Test-Path $Folder
    if($FileExists -eq $False)
    {
     $result = New-Item $Folder -type directory 
     if($result -eq $null)
     {
      logMsg("Imposible to create the folder " + $Folder) (2)
      return $false
     }
    }
    return $true
   }
  catch
  {
   return $false
  }
 }

#-------------------------------
#Delete the file
#-------------------------------
Function DeleteFile{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    logMsg("Checking if the file..." + $FileName + " exists.")  
    $FileExists = Test-Path $FileName
    if($FileExists -eq $True)
    {
     logMsg("Removing the file..." + $FileName)  
     Remove-Item -Path $FileName -Force 
     logMsg("Removed the file..." + $FileName) 
    }
    return $true 
   }
  catch
  {
   logMsg("Remove the file..." + $FileName + " - " + $Error[0].Exception) (2) 
   return $false
  }
 }

#--------------------------------
#Log the operations
#--------------------------------
function logMsg
{
    Param
    (
         [Parameter(Mandatory=$false, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=1)]
         [int] $Color,
         [Parameter(Mandatory=$false, Position=2)]
         [boolean] $Show=$true,
         [Parameter(Mandatory=$false, Position=3)]
         [boolean] $ShowDate=$true,
         [Parameter(Mandatory=$false, Position=4)]
         [boolean] $SaveFile=$true,
         [Parameter(Mandatory=$false, Position=5)]
         [boolean] $NewLine=$true 
 
    )
  try
   {
    If(TestEmpty($msg))
    {
     $msg = " "
    }

    if($ShowDate -eq $true)
    {
      $Fecha = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    }
    $msg = $Fecha + " " + $msg
    If($SaveFile -eq $true)
    {
      Write-Output $msg | Out-File -FilePath $LogFile -Append
    }
    $Colores="White"

    If($Color -eq 1 )
     {
      $Colores ="Cyan"
     }
    If($Color -eq 3 )
     {
      $Colores ="Yellow"
     }
    If($Color -eq 4 )
     {
      $Colores ="Green"
     }
    If($Color -eq 5 )
     {
      $Colores ="Magenta"
     }

     if($Color -eq 2 -And $Show -eq $true)
      {
         if($NewLine)
         {
           Write-Host -ForegroundColor White -BackgroundColor Red $msg 
         }
         else
         {
          Write-Host -ForegroundColor White -BackgroundColor Red $msg -NoNewline
         }
      } 
     else 
      {
       if($Show -eq $true)
       {
        if($NewLine)
         {
           Write-Host -ForegroundColor $Colores $msg 
         }
        else
         {
           Write-Host -ForegroundColor $Colores $msg -NoNewline
         }  
       }
      } 


   }
  catch
  {
    Write-Host $msg 
  }
}

#--------------------------------
#Log the operations
#--------------------------------
function logMsgPerfCounter
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=1)]
         [int] $Color
    )
  try
   {
    $Fecha = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $msg = $Fecha + " " + $msg
    Write-Output $msg | Out-File -FilePath $LogFileCounter -Append
    $Colores="White"
 
    If($Color -eq 1 )
     {
      $Colores ="Cyan"
     }
    If($Color -eq 3 )
     {
      $Colores ="Yellow"
     }

     if($Color -eq 2)
      {
        Write-Host -ForegroundColor White -BackgroundColor Red $msg 
      } 
     else 
      {
        Write-Host -ForegroundColor $Colores $msg 
      } 


   }
  catch
  {
    Write-Host $msg 
  }
}
#--------------------------------
#The Folder Include "\" or not???
#--------------------------------

function GiveMeFolderName([Parameter(Mandatory)]$FolderSalida)
{
  try
   {
    $Pos = $FolderSalida.Substring($FolderSalida.Length-1,1)
    If( $Pos -ne "\" )
     {return $FolderSalida + "\"}
    else
     {return $FolderSalida}
   }
  catch
  {
    return $FolderSalida
  }
}

#--------------------------------
#Validate Param
#--------------------------------
function TestEmpty($s)
{
if ([string]::IsNullOrWhitespace($s))
  {
    return $true;
  }
else
  {
    return $false;
  }
}

#--------------------------------
#Separator
#--------------------------------

function GiveMeSeparator
{
Param([Parameter(Mandatory=$true)]
      [System.String]$Text,
      [Parameter(Mandatory=$true)]
      [System.String]$Separator)
  try
   {
    [hashtable]$return=@{}
    $Pos = $Text.IndexOf($Separator)
    $return.Text= $Text.substring(0, $Pos) 
    $return.Remaining = $Text.substring( $Pos+1 ) 
    return $Return
   }
  catch
  {
    $return.Text= $Text
    $return.Remaining = ""
    return $Return
  }
}

function GiveMeSeparatorReadFile
{
Param([Parameter(Mandatory=$true)]
      [System.String]$Text,
      [Parameter(Mandatory=$true)]
      [System.String]$Separator)
  try
   {
    
    [hashtable]$return=@{}
    $Pos = $Text.Split($Separator)
    $return.Text= $Pos[0]
    $return.Remaining = $Pos[1]
    return $Return
   }
  catch
  {
    $return.Text= $Text
    $return.Remaining = ""
    return $Return
  }
}

#--------------------------------
#Remove invalid chars
#--------------------------------

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)

return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

#---------------------------------------------------------------------------------------------------------------------
#Read the configuration file
#---------------------------------------------------------------------------------------------------------------------
Function ReadConfigFile
{ 
    Param
    (
         [Parameter(Mandatory=$false, Position=0)]
         [string] $Param
    )
  try
   {

    $return = ""

    If(TestEmpty($Param))
    {
     return $return
    }

    $stream_reader = New-Object System.IO.StreamReader($FileConfig)
    while (($current_line =$stream_reader.ReadLine()) -ne $null) ##Read the file
    {
     If(-not (TestEmpty($current_line)))
     {
      if($current_line.Substring(0,2) -ne "//" )
      {
        $Text = GiveMeSeparatorReadFile $current_line "="
        if($Text.Text -eq $Param )
        {
         $return = $Text.Remaining.Trim();
         break;
        }
      }
     }
    }
    $stream_reader.Close()
    return $return
   }
 catch
 {
   logMsg("Error Reading the config file..." + $Error[0].Exception) (2) 
   return ""
 }
}

#--------------------------------------
#Read the TSQL command to test
#--------------------------------------
Function ReadTSQL($query)
{ 
  try
   {

    If(-not ($(FileExist($File))))
    {
      $Null = $query.Add("SELECT 1")
      return $true
    }
    $bRead = $false

    $stream_reader = New-Object System.IO.StreamReader($File)
    while (($current_line =$stream_reader.ReadLine()) -ne $null) ##Read the file
    {
     If(-not (TestEmpty($current_line)))
     {
      $bRead = $true
      $Null = $query.Add($current_line)
     }
    }
    $stream_reader.Close()
    if(-not($bRead)) {  $Null = $query.add("SELECT 1") }
    return $true
   }
 catch
 {
   logMsg("Error Reading the config file..." + $Error[0].Exception) (2) 
   return $false
 }
}

#--------------------------------------
#Read the configuration file - Secrets
#--------------------------------------
Function ReadConfigFileSecrets
{ 
    Param
    (
         [Parameter(Mandatory=$false, Position=0)]
         [string] $Param
    )
  try
   {

    $return = ""

    If(TestEmpty($Param))
    {
     return $return
    }

    $stream_reader = New-Object System.IO.StreamReader($FileSecrets)
    while (($current_line =$stream_reader.ReadLine()) -ne $null) ##Read the file
    {
     If(-not (TestEmpty($current_line)))
     {
      $Text = GiveMeSeparatorReadFile $current_line "="
      if($Text.Text -eq $Param )
      {
       $return = $Text.Remaining;
       break;
      }
     }
    }
    $stream_reader.Close()
    return $return
   }
 catch
 {
   logMsg("Error Reading the config file..." + $Error[0].Exception) (2) 
   return ""
 }
}

#-------------------------------
#File Exists
#-------------------------------
Function FileExist{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    $return=$false
    $FileExists = Test-Path $FileName
    if($FileExists -eq $True)
    {
     $return=$true
    }
    return $return
   }
  catch
  {
   return $false
  }
 }


#---------------------------------------------------------------------------------------------------------------------------------
#Execute the process.
#---------------------------------------------------------------------------------------------------------------------------------


try
{
 cls

Class IPReference #Class to manage the IP address changes
{
 [string]$InitialIP = ""
 [string]$OtherIP = ""
}

Class IPControlPort #Class to manage how many ports are opened
{
 [int]$IP1433 = 0
 [int]$IPRedirect = 0
 [int]$IPTotal = 0
}

Class IPControlPortProcess #Class to manage by process how many ports are opened
{
 [int]$IP1433 = 0
 [int]$IPRedirect = 0
 [int]$NumProcess = 0
 [int]$IPTotal = 0
}

Class LatencyAndOthers #Class to manage the connection latency
{
 [long]$ConnectionsDone_MS = 0
 [long]$ConnectionsDone_Number_Success = 0
 [long]$ConnectionsDone_Number_Failed = 0
 [long]$ExecutionsDone_MS = 0
 [long]$ExecutionsDone_Number_Success = 0
 [long]$ExecutionsDone_Number_Failed = 0
}

Class Connection #Class to manage array of connections.....
{
 $Tmp = [System.Data.SqlClient.SqlConnection]
}

$IPReference = [IPReference]::new()
$IPControlPort = [IPControlPort]::new()
$IPControlPortProcess = [System.Collections.ArrayList]::new() 
$LatencyAndOthers = [LatencyAndOthers]::new()

[System.Collections.ArrayList]$IPArrayConnection = @()
[System.Collections.ArrayList]$Query = @()


If(TestEmpty($FolderParam)) 
{
  $invocation = (Get-Variable MyInvocation).Value
  $Folder = Split-Path $invocation.MyCommand.Path
}
else
{
  $Folder = $FolderParam 
}
$sFolderV = GiveMeFolderName($Folder) #Creating a correct folder adding at the end \.

If(TestEmpty($ExtensionParam))
{
  $LogFile = $sFolderV + "Results.Log"                     #Logging the operations.
  $LogFileCounter = $sFolderV + "Results_PerfCounter.Log"  #Logging the data of performance counter
}
else
{
  $LogFile = $sFolderV + "Results_" + $ExtensionParam +".Log"                     #Logging the operations per operations in parallel mode
  $LogFileCounter = $sFolderV + "Results_PerfCounter_" + $ExtensionParam +".Log"  #Logging the data of performance counter per operations in parallel mode
}

  $File = $sFolderV +"TSQL.SQL"                            #TSQL instructtions
  $FileConfig = $sFolderV + "Config.Txt"                   #Configuration of parameter values
  $FileSecrets = $sFolderV + "Secrets.Txt"                 #Configuration of User&Passowrd
    
[System.Data.SqlClient.SqlConnection]::ClearAllPools() #Clean all the connections and pools...

logMsg("Deleting Logs") (1)
   $result = DeleteFile($LogFile)        #Delete Log file
   $result = DeleteFile($LogFileCounter) #Delete Log file performancecounter
logMsg("Deleted Logs") (1)

 $Null = ReadTSQL $Query                  #Read the file TSQL with SQL instrucctions...
 
 $NumberExecutions=[int]$(ReadConfigFile("NumberExecutions"))
 $Retries=$(ReadConfigFile("CommandExecutionRetries")).ToUpper().Trim()
 $ShowXMLPlan=$(ReadConfigFile("ShowXMLPlan")).ToUpper().Trim()
 $ShowStatisticsQuery=$(ReadConfigFile("ShowStatisticsQuery")).ToUpper().Trim()
 $CommandTimeout=[int]$(ReadConfigFile("CommandTimeout")).ToUpper().Trim()
 $CommandTimeoutFactor=[int]$(ReadConfigFile("CommandTimeoutFactor")).ToUpper().Trim()
 $LimitExecutions=[int]$(ReadConfigFile("LimitExecutions")).ToUpper().Trim()
 $HasRows=$(ReadConfigFile("HasRows")).ToUpper().Trim()
 $DBName=$(ReadConfigFile("Db")).Trim()
 
 LogMsg("Number of execution times " + $NumberExecutions) 
 LogMsg("PID Process for networking monitoring: " + $PID) 

 If(TestEmpty($DBName)) 
 {
   LogMsg("Database Name parameter empty - Finishing the process." ) 
   exit
 }

  if($DBName.ToUpper().Trim() -eq "ALL")
  {
    $DBsArray=GiveListOfDBToWork $IPReference $IPControlPort $IPControlPortProcess $NameofAppParam "master"   
  }
  else
  {
    $DbsArray = [System.Collections.ArrayList]::new() 
    $DbNameArray = $DBName.Split(",")
    for($TmpArrayDBName=0;$TmpArrayDBName -lt $DbNameArray.Count;$TmpArrayDBName++)
    {
     [void]$DbsArray.Add($DbNameArray[$TmpArrayDBName])
    }     
  }
 
 $sw = [diagnostics.stopwatch]::StartNew()

 for ($i=1; $i -le $NumberExecutions; $i++)
  {
   try
    {
      LogMsg(" ---> Operation Number#: " + $i.ToString()) 
      if($DBName -eq "ALL" -or $DbNameArray.Count -gt 1)
      { 
         $lMax = $DbsArray.Count-1
         If($lMax -eq 0) {$lMax=$DbsArray.Count}
         $Value = Get-Random -Minimum 0 -Maximum $($lMax+1)
         $DBNameEfective=$DbsArray[$Value]
      }      
      else
      {
        $DBNameEfective=$DbsArray[0]
      }

      $FileName_Lock_HighTempDB = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighTempDB.Lock"
      $FileName_Lock_HighCPU = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighCPU.Lock"
      $FileName_Lock_HighPacket = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighCXPacket.Lock"
      $FileName_Lock_HighAsyncNetworkIO = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighAsyncNetworkIO.Lock"
      $FileName_Lock_HighDATAIO = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighAsyncDATAIO.Lock"
      $FileName_Lock_HighDATAIOByBlocks = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighDATAIOByBlocks.Lock"
      $FileName_Lock_HighLocks = $sFolderV + $(Remove-InvalidFileNameChars($DBNameEfective)) + "_LockFile_HighLocks.Lock"

      $Null = $IPArrayConnection.Add($(GiveMeConnectionSource $IPReference $IPControlPort $IPControlPortProcess $NameofAppParam $DBNameEfective)) #Connecting to the database.
      if($IPArrayConnection[$i-1] -eq $null)
      { 
        If( $(ReadConfigFile("ShowWhatHappenedMsgAtTheEnd")).Trim() -eq "Y")
        {
          LogMsg("What happened?") (2) 
        }
          exit;
      }

      if($ExecutionTypeParam -eq "HighLogIO")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighLogIO.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighLogIO.Table.Name")).Trim() + "](DataInsert nvarchar(max))")
        If( $CreateTable -gt 0)
        {
         for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
         {
          LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
           ExecuteQuery $IPArrayConnection[$i-1] ("INSERT INTO [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighLogIO.Table.Name")).Trim() + "](DataInsert) values(replicate(CONVERT(NVARCHAR(MAX),'MicrosoftTest-MicrosoftTest-MicrosoftTest-MicrosoftTest'),CEILING(RAND()*(5000-25000)+25000)))") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighLogIO.SetTransactionIsolationLevel")).Trim()
         } 
        }
      }

      if($ExecutionTypeParam -eq "HighTempDB")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDB.Table.Name")).Trim() +"]([Id] [bigint] NOT NULL PRIMARY KEY,[Name] [varchar](200) NULL)")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -lt [long]$(ReadConfigFile("HighTempDB.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighTempDB $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighTempDB $(ReadConfigFile("HighTempDB.FileName")).Trim()  $TotalRows
          }  
          If($Continue)
          {
            for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
            {
              LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
              $ValueRandom = Get-Random -Minimum 60000 -Maximum 600000
              ExecuteQuery $IPArrayConnection[$i-1] ("SELECT TOP " + $ValueRandom.ToString() + " * INTO #t FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighTempDB.Table.Name")).Trim() + "] OPTION (MAXDOP 1); DROP TABLE #t;") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighTempDB.SetTransactionIsolationLevel")).Trim()
            } 
          }
        }
      }

      if($ExecutionTypeParam -eq "HighTempDBAlloc")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDB.Table.Name")).Trim() +"]([Id] [bigint] NOT NULL PRIMARY KEY,[Name] [varchar](200) NULL)")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -lt [long]$(ReadConfigFile("HighTempDB.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighTempDB $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighTempDB $(ReadConfigFile("HighTempDB.FileName")).Trim()  $TotalRows
          }  
          $CreateStoreProcedure = CreateStoreProcedure  $(ReadConfigFile("HighTempDBAllocContention.StoreProcName")).Trim() $IPArrayConnection[$i-1]  $("create procedure ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDBAllocContention.StoreProcName")).Trim() +"] as declare @t1 table( c1 bigint, c2 varchar(40)) insert into @t1 SELECT TOP 100 id,replicate('x',40) FROM ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDB.Table.Name")).Trim() +"]")
          If( $CreateStoreProcedure -gt 0) 
          {
           If($Continue)
           {
             for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
             {
              LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
              $ValueRandom = Get-Random -Minimum 700 -Maximum 800
              ##ExecuteQuery $IPArrayConnection[$i-1] ("EXEC Gen5declare @t1 table( c1 bigint, c2 bigint); insert into @t1 SELECT TOP " + $ValueRandom.ToString() + " id,id*2 FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighTempDB.Table.Name")).Trim() + "]") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighTempDB.SetTransactionIsolationLevel")).Trim()
              ExecuteQuery $IPArrayConnection[$i-1] ("DECLARE @i Int;set @i=1;while @i<="+ $ValueRandom.ToString() + " begin EXEC [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighTempDBAllocContention.StoreProcName")).Trim() + "]" + "; set @i=@i+1; END") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighTempDB.SetTransactionIsolationLevel")).Trim()
             } 
           }
          }
        }  
      }

      if($ExecutionTypeParam -eq "HighTempDBAllocMeta")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDB.Table.Name")).Trim() +"]([Id] [bigint] NOT NULL PRIMARY KEY,[Name] [varchar](200) NULL)")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -lt [long]$(ReadConfigFile("HighTempDB.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighTempDB $(ReadConfigFile("HighTempDB.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighTempDB $(ReadConfigFile("HighTempDB.FileName")).Trim()  $TotalRows
          }  
          $CreateStoreProcedure = CreateStoreProcedure  $(ReadConfigFile("HighTempDBAllocContentionMeta.StoreProcName")).Trim() $IPArrayConnection[$i-1]  $("create procedure ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDBAllocContentionMeta.StoreProcName")).Trim() +"] as CREATE TABLE #t1 ( c1 bigint, c2 varchar(40)) insert into #t1 SELECT TOP 100 id,replicate('x',40) FROM ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighTempDB.Table.Name")).Trim() +"]")
          If( $CreateStoreProcedure -gt 0) 
          {
           If($Continue)
           {
             for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
             {
              LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
              $ValueRandom = Get-Random -Minimum 700 -Maximum 800
              ##ExecuteQuery $IPArrayConnection[$i-1] ("EXEC Gen5declare @t1 table( c1 bigint, c2 bigint); insert into @t1 SELECT TOP " + $ValueRandom.ToString() + " id,id*2 FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighTempDB.Table.Name")).Trim() + "]") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighTempDB.SetTransactionIsolationLevel")).Trim()
              ExecuteQuery $IPArrayConnection[$i-1] ("DECLARE @i Int;set @i=1;while @i<="+ $ValueRandom.ToString() + " begin EXEC [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighTempDBAllocContentionMeta.StoreProcName")).Trim() + "]" + "; set @i=@i+1; END") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighTempDB.SetTransactionIsolationLevel")).Trim()
             } 
           }
          }
        }  
      }

      if($ExecutionTypeParam -eq "HighCPU")
      {
            
        $CreateTable = CreateTable  $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCPU.Table.Name")).Trim() + "]([Id] [bigint] NOT NULL PRIMARY KEY,[TextToSearch] [varchar](200) NULL)")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -lt [long]$(ReadConfigFile("HighCPU.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighCPU $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighCPU $TotalRows
          }  
          If($Continue)
          {
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
            LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
            ExecuteQuery $IPArrayConnection[$i-1] ("SELECT count(Id) FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCPU.Table.Name")).Trim() + "] Where TextToSearch = 'Test Search ' + CONVERT(nvarchar(200),RAND()*(2000000-10000)+10000) OPTION (MAXDOP 1)") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighCPU.SetTransactionIsolationLevel")).Trim()
            }        
          }
       }
      }

      if($ExecutionTypeParam -eq "HighCPUConcurrent")
      {
            
        $CreateTable = CreateTable  $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCPU.Table.Name")).Trim() + "]([Id] [bigint] NOT NULL PRIMARY KEY,[TextToSearch] [varchar](200) NULL)")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -lt [long]$(ReadConfigFile("HighCPU.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighCPU $(ReadConfigFile("HighCPU.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighCPU $TotalRows
          }  
          If($Continue)
          {
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
            LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
            $ValueRandom = Get-Random -Minimum 0 -Maximum 80000000
            ExecuteQuery $IPArrayConnection[$i-1] ("SELECT * FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCPU.Table.Name")).Trim() + "] WHERE ID = " + $ValueRandom.ToString() + " OPTION (MAXDOP 1)") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighCPU.SetTransactionIsolationLevel")).Trim()
            }        
          }
       }
      }
           
      if($ExecutionTypeParam -eq "HighAsyncNetworkIO")
      {
        $CreateTable = CreateTable $(ReadConfigFile("HighAsyncNetworkIO.Table.Name")).Trim() $IPArrayConnection[$i-1]  $(GiveMeColumnsDemoHighAsyncNetworkIO)
        If( $CreateTable -gt 0) 
        {
          $Continue=$true
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighAsyncNetworkIO.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))

          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or ($TotalRows -lt [long]$(ReadConfigFile("HighAsyncNetworkIO.NumberRowSampleData"))))
          {
           $Continue = AddRowsHighAsyncNetworkIO $(ReadConfigFile("HighAsyncNetworkIO.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighAsyncNetworkIO $(ReadConfigFile("HighAsyncNetworkIO.FileName")).Trim() $TotalRows
          }  
          If($Continue)
          {
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
            LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
             $ValueRandom = Get-Random -Minimum 20 -Maximum 1001
             ExecuteQuery $IPArrayConnection[$i-1] ("SELECT TOP " + $ValueRandom.ToString() + " * from [" + $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighAsyncNetworkIO.Table.Name")).Trim()+"]") 1 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighAsyncNetworkIO.SetTransactionIsolationLevel")).Trim()
           } 
          }
       }
      }

      if($ExecutionTypeParam -eq "HighCXPACKET")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() +"]([Id] [bigint] NOT NULL PRIMARY KEY,[Name] [varchar](200) NULL)")
        [string]$string =""        
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -and $TotalRows -eq 0) -or $TotalRows -ne [long]$(ReadConfigFile("HighCXPacket.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighTempDB $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighPacket $(ReadConfigFile("HighCXPacket.FileName")).Trim() $TotalRows
          }  
          If($Continue)
          {
           $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
            LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
            $SortByWhat = $(GiveMeTheSortByWhat $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() $IPArrayConnection[$i-1])
            $ValueRandom = [int](Get-Random -Minimum 10 -Maximum 201)
            $ValueRows = [long](Get-Random -Minimum 50000 -Maximum ($TotalRows+1))
            $DescAsc = " desc"
            If( (Get-Random -Minimum 0 -Maximum 2) -eq 1) {$DescAsc = " asc"}
            
            $string = $string.PadRight($ValueRandom,"#")
            ExecuteQuery $IPArrayConnection[$i-1] ("SELECT * FROM [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighCXPacket.Table.Name")).Trim() + "] where SUBSTRING(Name,1," + $ValueRandom +") = '" + $string + "'" + $sortByWhat + " " + $DescAsc + " ") 2 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighCXPacket.SetTransactionIsolationLevel")).Trim()
           } 
          } 
        }
      }

      if($ExecutionTypeParam -eq "HighBulkInsert")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("BulkInsert.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("BulkInsert.Table.Name")).Trim() + "]([Name] [varchar](max) NULL)")
        If( $CreateTable -gt 0)
        {
          for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
         {
          LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
           BulkInsert $IPArrayConnection[$i-1] $ShowStatisticsQuery $CommandTimeout $SetTransactionIsolationLevel
         } 
        }
      }
      

      if($ExecutionTypeParam -eq "HighDATAIO")
      {

        $CreateTable = CreateTable  $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() $IPArrayConnection[$i-1]  $(GiveMeColumnsDemoHighDataIO)
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          $TotalInfo = [long]$(ReadConfigFile("HighDATAIO.NumberRowSampleData")) 

          If( ($CreateTable -eq 2 -or $TotalRows -eq 0) -or ($TotalRows -lt $TotalInfo)) 
          {
           $Continue = AddRowsHighAsyncNetworkIO $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighDATAIO $(ReadConfigFile("HighDATAIO.FileName")).Trim() $TotalRows
          }  
          If($Continue)
          {
           $SortByWhat = $(GiveMeTheSortByWhat $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() $IPArrayConnection[$i-1])
           $ColumnSelect = $(GiveMeTheColumnsToRetrieve $(ReadConfigFile("HighDATAIO.Table.Name")).Trim() $IPArrayConnection[$i-1] 10)
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
             LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
             ExecuteQuery $IPArrayConnection[$i-1] $("select " + $ColumnSelect  +" from [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighDATAIO.Table.Name")).Trim()+"]" + $SortByWhat + " option (maxdop 1)") 3 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighDATAIO.SetTransactionIsolationLevel")).Trim()
           } 
          }    
        }
      }

      if($ExecutionTypeParam -eq "HighDATAIOByBlocks")
      {

        $CreateTable = CreateTable  $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() $IPArrayConnection[$i-1]  $(GiveMeColumnsDemoHighDataIOByBlocks)
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -or $TotalRows -eq 0) -or $TotalRows -ne [long]$(ReadConfigFile("HighDATAIOByBlocks.NumberRowSampleData"))) 
          {
           $Continue = AddRowsHighAsyncNetworkIO $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighDATAIOByBlocks $(ReadConfigFile("HighDATAIOByBlocks.FileName")).Trim() $TotalRows
          }  
          If($Continue)
          {
           $SortByWhat = $(GiveMeTheSortByWhat $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim()  $IPArrayConnection[$i-1])
           $ColumnSelect = $(GiveMeTheColumnsToRetrieve $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() $IPArrayConnection[$i-1] 10)
           $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
           $lJump = [int]($TotalRows / $LimitExecutions)
           $lOffSet=0
           for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
           {
             LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
             ExecuteQuery $IPArrayConnection[$i-1] $("select " + $ColumnSelect  +" from [" + $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighDATAIOByBlocks.Table.Name")).Trim() + "] " + $SortByWhat + " OFFSET " + $lOffSet.ToString() + " ROWS FETCH NEXT " + $lJump.ToString() +" ROWS ONLY option (maxdop 1)") 3 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighDATAIOByBlocks.SetTransactionIsolationLevel")).Trim()
             $lOffSet = $lOffSet + $lJump;
           } 
          }    
        }
      }


      if($ExecutionTypeParam -eq "HighLocks")
      {
        $CreateTable = CreateTable  $(ReadConfigFile("HighLocks.Table.Name")).Trim() $IPArrayConnection[$i-1]  $("create table ["+ $(ReadConfigFile("SchemaTablesWork")) + "].[" + $(ReadConfigFile("HighLocks.Table.Name")).Trim() +"]([Id] [bigint])")
        If( $CreateTable -gt 0) 
        {
          $Continue=$True
          $TotalInfo = [long]$(ReadConfigFile("HighLocks.NumberRowSampleData")) 

          $TotalRows = lGiveLastNumberOfRows $(ReadConfigFile("HighLocks.Table.Name")).Trim() $IPArrayConnection[$i-1] $(ReadConfigFile("SchemaTablesWork"))
          If( ($CreateTable -eq 2 -or $TotalRows -eq 0) -or ($TotalRows -lt $TotalInfo)) 
          {
           $Continue = AddRowsHighLocks $(ReadConfigFile("HighLocks.Table.Name")).Trim() $IPArrayConnection[$i-1] $FileName_Lock_HighLocks $TotalRows
          }  
          If($Continue)
          {
            for ($iExc=1; $iExc -le $LimitExecutions; $iExc++)
            {
               LogMsg("Query Interaction :  " +$iExc.ToString() + " of " + $LimitExecutions.ToString()) 
               ExecuteQuery $IPArrayConnection[$i-1] ("UPDATE ["+ $(ReadConfigFile("SchemaTablesWork")) + "].["+$(ReadConfigFile("HighLocks.Table.Name")).Trim()+"] SET ID=(RAND()*(2000000-10000)+10000)") 4 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $(ReadConfigFile("HighLocks.SetTransactionIsolationLevel")).Trim()
            } 
          }
        }
      }

      if( $(ReadConfigFile("ShowExecutedQuery")).ToUpper().Trim() -eq "Y" ) 
      { 
       $MaxAttempts= $(ReadConfigFile("MaxAttemptsConnectivityTest")).ToUpper().Trim()
       if(TestEmpty($MaxAttempts))
       {
         $MaxAttempts=50
       }
       for ($iQuery=0; $iQuery -lt $query.Count; $iQuery++) 
        {
         try
         {
          for ($Attempts=0;$Attempts -lt $MaxAttempts;$Attempts++)
          {
           LogMsg(" ---> Query Number#: " + ($iQuery+1) + " - Attempt#:" + ($Attempts+1) ) 
           ExecuteQuery $IPArrayConnection[$i-1] $query[$iQuery] 1 $Retries $ShowXMLPlan $ShowStatisticsQuery $CommandTimeout $CommandTimeoutFactor $HasRows $SetTransactionIsolationLevel
          }  
         }
       catch
       {
         LogMsg("Executing Process - Error:" + $Error[0].Exception) (2)
       }
      }  
     }

         if( $(ReadConfigFile("ShowCounters")).ToUpper().Trim() -eq "Y" )
         {  
              PerfCounters "\Processor(_total)\*"
              PerfCounters "\Memory\*"
              PerfCounters "\Network Interface(*)\*"
              PerfCounters "\Network Adapter(*)\*"
         }

        if( $(ReadConfigFile("ShowPorts")).ToUpper().Trim() -eq "Y" ) 
          { 
           Ports $IPControlPort $IPControlPortProcess 
          }

        if( $(ReadConfigFile("CloseConnections")).ToUpper().Trim() -eq "Y" )
        {
           $IPArrayConnection[$i-1].Close()
           if( $(ReadConfigFile("ShowConnectionMessage")).ToUpper().Trim()-eq "Y")
           {
              LogMsg("Closed Connection") (1) -SaveFile $false      
           }
        }
        else
        {
           if( $(ReadConfigFile("ShowConnectionMessage")).ToUpper().Trim() -eq "Y")
           {
             LogMsg("Without closing the connection") (2) -SaveFile $false
           }
        }

        $WaitTimeBetweenConnections=$(ReadConfigFile("WaitTimeBetweenConnections")).Trim()

        If($WaitTimeBetweenConnections -ne "0")
        {
          LogMsg("Waiting for " + $WaitTimeBetweenConnections + " seconds to continue (Demo purpose)")  -SaveFile $false
          Start-Sleep -s $WaitTimeBetweenConnections
        }

 
     } 
       catch
       {
         LogMsg("Executing Query Interaction: " + $Error[0].Exception) (2) 
       }
    } ##
    LogMsg("Time spent (ms) Procces :  " +$sw.elapsed) 
    LogMsg("Review: https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/sql/provider-statistics-for-sql-server") 
 } 
 catch
 {
     LogMsg("Complete Process - Error:" + $Error[0].Exception) (2)
 }
 

﻿#----------------------------------------------------------------
# Application: Performance Checker
# Propose: Inform about performance recomendations
# Checks:
#    1) Check if the statistics
#        If number of rows in the statistics is different of rows_sampled.
#        If we have more than 15 days that the statistics have been updated.
#    2) Check if we have any auto-tuning recomendations
#    3) Check if the statistics associated to any index is:
#       If number of rows in the statistics is different of rows_sampled.
#       If we have more than 15 days that the statistics have been updated.
#    4) Check if MAXDOP is 0
#    5) Check if we have an index with more than 50% fragmented
#    6) Check if we have missing indexes (SQL Server Instance)
#    7) Check TSQL command execution timeouts using querying QDS
#    8) Obtain the top 10 of wait stats from QDS.
#    9) Export all the results of Query Data Store to .bcp and .xml to be able to import in a consolidate database. It is very useful when you have multiple databases in Azure SQL Managed Instance or Elastic Database Pool. 
#   10) Obtain resource usage per database.
#   11) Total amount of space and rows per table.
#   12) Total amount of space and rows per system table (QDS/PVS, etc..)
# Outcomes: 
#    In the folder specified in $Folder variable we are going to have a file called PerfChecker.Log that contains all the operations done 
#    and issues found. Also, we are going to have a file per database and check done with the results gathered.
#----------------------------------------------------------------

#----------------------------------------------------------------
#Parameters 
#----------------------------------------------------------------
param($server = "servername.database.windows.net", #ServerName parameter to connect,for example, myserver.database.windows.net
      $user = "username", #UserName parameter  to connect
      $passwordSecure = "pwd", #Password Parameter  to connect
      $Db = "ALL", #DBName Parameter  to connect. Type ALL to check all the databases running in the server
      $Folder = "c:\MyDocs\PerfChecker", #Folder Parameter to save the log and solution files, for example, c:\PerfChecker
      $DropExisting=1, #Drop (1) the previous file saved in the folder with extensions .bcp, .xml,.csv, .txt, .task !=1 = leave the files
      $ElasticDBPoolName = "GlobalAzureEP") #Name of the elastic DB Pool if you want to filter only by elastic DB Pool.


#-------------------------------------------------------------------------------
# Check the statistics status
# 1.- Review if number of rows is different of rows_sampled
# 2.- Review if we have more than 15 days that the statistics have been updated.
#-------------------------------------------------------------------------------
function CheckStatistics($connection,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Statistics health (Started) (REF: https://docs.microsoft.com/en-us/sql/t-sql/statements/update-statistics-transact-sql?view=sql-server-ver15)---- " ) (1) $true $FileName 
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT sp.stats_id, stat.name, o.name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter,  DATEDIFF(DAY, last_updated , getdate()) AS Diff, schema_name(o.schema_id) as SchemaName
                           FROM sys.stats AS stat   
                           Inner join sys.objects o on stat.object_id=o.object_id
                           CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
                           WHERE o.type = 'U' AND stat.auto_created ='1' or stat.user_created='1' order by o.name, stat.name"
  $Reader = $command.ExecuteReader(); 
  while($Reader.Read())
   {
     if( $Reader.GetValue(5) -gt $Reader.GetValue(6)) #If number rows is different rows_sampled
     {
       $Item=$Item+1
       logMsg("Possible outdated (Rows_Sampled is less than rows of the table):".PadRight(100," ") + " of " + ($Reader.GetValue(11).ToString() +"."+ ($Reader.GetValue(2).ToString() + " " + $Reader.GetValue(1).ToString())).PadRight(400," "))  (2) $true $FileName 
       logSolution("UPDATE STATISTICS [" + $Reader.GetValue(11).ToString() +"].["+ $Reader.GetValue(2).ToString() + "]([" + $Reader.GetValue(1).ToString() + "]) WITH FULLSCAN") $FileNameLogSolution
     }
     if( TestEmpty($Reader.GetValue(10))) {}
     else
     {
      if($Reader.GetValue(10) -gt 15) #if we have more than 15 days since the lastest update.
      {
       $Item=$Item+1
       logMsg("Possible outdated (15 days since the latest update):".PadRight(100," ") + " of " + ($Reader.GetValue(11).ToString() +"."+ ($Reader.GetValue(2).ToString() + " " + $Reader.GetValue(1).ToString())).PadRight(400," ")) (2) $true $FileName
       logSolution("UPDATE STATISTICS [" + $Reader.GetValue(11).ToString() +"].["+ $Reader.GetValue(2).ToString() + "]([" + $Reader.GetValue(1).ToString() + "]) WITH FULLSCAN") $FileNameLogSolution
      }
     }
   }

   $Reader.Close();
   logMsg( "---- Checking Statistics health (Finished) ---- " ) (1) $true -$FileName 
   return $Item
  }
  catch
   {
    logMsg("Not able to run statistics health checker..." + $Error[0].Exception) (2) $true $FileName 
    return 0
   } 

}


#-------------------------------------------------------------------------------
# Check if we have any auto-tunning recomendations for Azure SQL DB.
#-------------------------------------------------------------------------------

function CheckTunningRecomendations($connection,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Tuning Recomendations (Started) Ref: https://docs.microsoft.com/en-us/azure/azure-sql/database/automatic-tuning-overview ---- " ) (1) $true $FileName
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "select COUNT(1) from sys.dm_db_tuning_recommendations Where Execute_action_initiated_time = '1900-01-01 00:00:00.0000000'"
   $Reader = $command.ExecuteReader(); 
   while($Reader.Read())
   {
     if( $Reader.GetValue(0) -gt 0) 
     {
       $Item=$Item+1
       logMsg("----- Please, review tuning recomendations in the portal" ) (2) $true $FileName
     }
   }

   $Reader.Close();
   logMsg( "---- Checking tuning recomendations (Finished) ---- " ) (1) $true $FileName
   return $Item
  }
  catch
   {
    logMsg("Not able to run tuning recomendations..." + $Error[0].Exception) (2) $true $FileName
    return 0
   } 

}

#-------------------------------------------------------------------------------
# Export all results of Query Data Store
#-------------------------------------------------------------------------------

function ExportQueryDataStore($connection, $DbName , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Exporting all results of Query Data Store ---- " ) (1) $true 
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "select name from sys.all_objects where name like '%query_store%' and type = 'V' order by name" 
   logMsg("Executed the query to obtain the tables of query store..") (1) $true
   
   $Reader = $command.ExecuteReader(); 

   $DbNameFormated = Remove-InvalidFileNameChars($DbName)

   while($Reader.Read())
   {
    
    $sTableNameFormated = Remove-InvalidFileNameChars($Reader.GetSqlString(0).ToString() )
    

    $FileBCP = $sFolderV + $DbNameFormated + "_" + $sTableNameFormated + ".bcp"
    $FileFMT = $sFolderV + $DbNameFormated + "_" + $sTableNameFormated + ".xml"

    $CommandFmt="bcp 'sys." + $Reader.GetSqlString(0).ToString() + "' Format nul -f "+$FileFMT + " -rMsSupportRowTerminator -tMsSupportFieldTerminator -c -x -S " +$server+" -U " + $user + " -P "+$password+" -d "+$DbName
    $CommandOut="bcp 'sys." + $Reader.GetSqlString(0).ToString() + "' out "+$FileBCP + " -c -rMsSupportRowTerminator -tMsSupportFieldTerminator -S " +$server+" -U " + $user + " -P "+$password+" -d "+$DbName
 
    logMsg("Obtain the Format file for " + $DbName + "-" + $FileFMT ) (3) $true
      $result = Invoke-Expression -Command $CommandFmt
    logMsg("Executed the Format file for " + $DbName + "-" + $FileFMT + "-" + $result)  $true

    logMsg("Obtain the BCP file for " + $DbName + "-" + $FileBCP ) $true
      $result = Invoke-Expression -Command $CommandOut 
    logMsg("Executed the BCP file for " + $DbName + "-" + $FileBCP + "-" + $result) $true

    $Item=$Item+1;

   }

   $Reader.Close();
   logMsg( "---- Exporting Query Data Store (Finished) ---- " ) (1) $true 
   return $Item
  }
  catch
   {
    logMsg("Not able to export Query Data Store..." + $Error[0].Exception) (2) $true 
    return 0
   } 

}

#-------------------------------------------------------------------------------
# Check if you have any query that gave a command execution timeout.
#-------------------------------------------------------------------------------

function CheckCommandTimeout($connection,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Command Timeout Execution (Started) Ref: https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-query-store-runtime-stats-transact-sql?view=sql-server-ver15---- " ) (1) $true $FileName
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT
                           qst.query_sql_text,
                           qrs.execution_type,
                           qrs.execution_type_desc,
                           qpx.query_plan_xml,
                           qrs.count_executions,
                           qrs.last_execution_time
                           FROM sys.query_store_query AS qsq
                           JOIN sys.query_store_plan AS qsp on qsq.query_id=qsp.query_id
                           JOIN sys.query_store_query_text AS qst on qsq.query_text_id=qst.query_text_id
                           OUTER APPLY (SELECT TRY_CONVERT(XML, qsp.query_plan) AS query_plan_xml) AS qpx
                           JOIN sys.query_store_runtime_stats qrs on qsp.plan_id = qrs.plan_id
                           WHERE qrs.execution_type in (3,4)
                           ORDER BY qrs.last_execution_time DESC;"
      
   $Reader = $command.ExecuteReader(); 
   while($Reader.Read())
   {
       $Item=$Item+1
       logMsg("----- Please, review the following command timeout execution --------------- " ) (2) $true $FileName
       logMsg("----- Execution Type     : " + $Reader.GetValue(1).ToString() + "-" + $Reader.GetValue(2).ToString()) (2) $true $FileName
       logMsg("----- Execution Count    : " + $Reader.GetValue(4).ToString() + "- Last Execution Time: " + $Reader.GetValue(5).ToString()) (2) $true $FileName
       logMsg("----- TSQL               : " + $Reader.GetValue(0).ToString() ) (2) $true $FileName
       logMsg("----- Execution Plan XML : " + $Reader.GetValue(3).ToString() ) (2) $false $FileName
       logMsg("-----------------------------------------------------------------------------" ) (2) $true $FileName
   }

   $Reader.Close();
   logMsg( "---- Checking Command Timeout Execution (Finished) ---- " ) (1) $true $FileName
   return $Item
  }
  catch
   {
    logMsg("Not able to run Command Timeout Execution..." + $Error[0].Exception) (2) $true $FileName
    return 0
   } 

}



#-------------------------------------------------------------------------------
# Check missing indexes.
#-------------------------------------------------------------------------------

function CheckMissingIndexes($connection ,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Missing Indexes (Started) Ref: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-groups-transact-sql?view=sql-server-ver15 ---- " ) (1) $true $FileName
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT CONVERT (varchar, getdate(), 126) AS runtime,
                           CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact *
                           (migs.user_seeks + migs.user_scans)) AS improvement_measure,
                           REPLACE(REPLACE('CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' +
                           CONVERT (varchar, mid.index_handle) + ' ON ' + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(mid.statement,CHAR(10), ' '), CHAR(13), ' '),'  ',''))) + 
                           '(' + ISNULL (mid.equality_columns,'')
                           + CASE WHEN mid.equality_columns IS NOT NULL
                              AND mid.inequality_columns IS NOT NULL
                           THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
                           + ')'
                           + ISNULL (' INCLUDE (' + mid.included_columns + ')', ''), CHAR(10), ' '), CHAR(13), ' ') AS create_index_statement,
                           migs.avg_user_impact
                           FROM sys.dm_db_missing_index_groups AS mig
                           INNER JOIN sys.dm_db_missing_index_group_stats AS migs
                           ON migs.group_handle = mig.index_group_handle
                           INNER JOIN sys.dm_db_missing_index_details AS mid
                           ON mig.index_handle = mid.index_handle
                           ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC"
   $Reader = $command.ExecuteReader()
   $bFound=$false
   $bCol=$false 
   $ColName=""
   $Content  = [System.Collections.ArrayList]@()
   while($Reader.Read())
   {
     #Obtain the columns only
     if($bCol -eq $false)
     {
      for ($iColumn=0; $iColumn -lt $Reader.FieldCount; $iColumn++) 
      {
       $bCol=$true 
       $ColName=$ColName + $Reader.GetName($iColumn).ToString().Replace("\t"," ").Replace("\n"," ").Replace("\r"," ").Replace("\r\n","").Trim() + " || "
      }
     }

    #Obtain the values of every missing indexes 
    $bFound=$true 
    $TmpContent=""
    for ($iColumn=0; $iColumn -lt $Reader.FieldCount; $iColumn++) 
     {
      $TmpContent= $TmpContent + $Reader.GetValue($iColumn).ToString().Replace("\t"," ").Replace("\n"," ").Replace("\r"," ").Replace("\r\n","").Trim()  + " || "
     }
     $Content.Add($TmpContent) | Out-null
   }
   if($bFound)
   {
     logMsg( "---- Missing Indexes found ---- " ) (1) $true $FileName
     logMsg( $ColName.Replace("\t","").Replace("\n","").Replace("\r","") ) (1) $true $FileName $false 
     for ($iColumn=0; $iColumn -lt $Content.Count; $iColumn++)  
     {
      logMsg( $Content[$iColumn].Replace("\t","").Replace("\n","").Replace("\r","").Replace("\r\n","").Trim() ) (1) $true $FileName $false 
      $Item=$Item+1
     }
   }
   $Reader.Close(); 
   logMsg( "---- Checking missing indexes (Finished) ---- " ) (1) $true $FileName
   return $Item
  }
  catch
   {
    logMsg("Not able to run missing indexes..." + $Error[0].Exception) (2) $true $FileName
    return 0
   } 

}


#-------------------------------------------------------------------------------
# Check if the statistics associated to any index is: 
# 1.- Review if number of rows is different of rows_sampled
# 2.- Review if we have more than 15 days that the statistics have been updated.
#-------------------------------------------------------------------------------

function CheckIndexesAndStatistics($connection, $FileName, $FileNameLogSolution , $iTimeOut )
{
 try
 {
   $Item=0
   logMsg( "---- Checking Indexes and Statistics health (Started) - Reference: https://docs.microsoft.com/en-us/sql/t-sql/statements/update-statistics-transact-sql?view=sql-server-ver15 -" ) (1) $true $FileName 
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT ind.index_id, ind.name, o.name, stat.filter_definition, sp.last_updated, sp.rows, sp.rows_sampled, sp.steps, sp.unfiltered_rows, sp.modification_counter,  DATEDIFF(DAY, last_updated , getdate()) AS Diff, schema_name(o.schema_id) as SchemaName,*
                           from sys.indexes ind
	                       Inner join sys.objects o on ind.object_id=o.object_id
	                       inner join sys.stats stat on stat.object_id=o.object_id and stat.stats_id = ind.index_id
                           CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
                           WHERE o.type = 'U'  order by o.name, stat.name"
  $Reader = $command.ExecuteReader();
  while($Reader.Read())
   {
     if( $Reader.GetValue(5) -gt $Reader.GetValue(6)) #If number rows is different rows_sampled
     {
       $Item=$Item+1
      logMsg("Possible outdated - (Rows_Sampled is less than rows of the table):".PadRight(100," ") + " of " + ($Reader.GetValue(11).ToString() +"."+ $Reader.GetValue(2).ToString() + " " + $Reader.GetValue(1).ToString()).PadRight(400," ")) (2) $true $FileName 
      logSolution("ALTER INDEX [" + $Reader.GetValue(1).ToString() + "] ON [" + $Reader.GetValue(11).ToString() +"].["+ $Reader.GetValue(2).ToString() + "] REBUILD") $FileNameLogSolution
     }
     if( TestEmpty($Reader.GetValue(10))) {}
     else
     {
      if($Reader.GetValue(10) -gt 15)
      {
       $Item=$Item+1
       logMsg("Possible outdated - (15 days since the latest update):".PadRight(100," ") + " of " + ($Reader.GetValue(11).ToString() +"."+ $Reader.GetValue(2).ToString() + " " + $Reader.GetValue(1).ToString()).PadRight(400," ")) (2) $true $FileName 
       logSolution("ALTER INDEX [" + $Reader.GetValue(1).ToString() + "] ON [" + $Reader.GetValue(11).ToString() +"].["+ $Reader.GetValue(2).ToString() + "] REBUILD") $FileNameLogSolution
      }
     }
   }

   $Reader.Close();
   logMsg( "---- Checking Indexes and Statistics health (Finished) ---- " ) (1) $true $FileName 
   return $Item
  }
  catch
   {
    logMsg("Not able to run Indexes and statistics health checker..." + $Error[0].Exception) (2) $true $FileName 
    return 0
   } 

}

#-------------------------------------------------------------------------------
# Check if MAXDOP is 0 
#-------------------------------------------------------------------------------

function CheckScopeConfiguration($connection ,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Scoped Configurations ---- Ref: https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-scoped-configurations-transact-sql?view=sql-server-ver15" ) (1) $true $FileName
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "select * from sys.database_scoped_configurations"
   $Reader = $command.ExecuteReader(); 
   while($Reader.Read())
   {
     if( $Reader.GetValue(1) -eq "MAXDOP")
     {
      if( $Reader.GetValue(2) -eq 0)
      {
       logMsg("You have MAXDOP with value 0" ) (2) $true $FileName
       $Item=$Item+1
      }
     }
   }
   $Reader.Close();
   logMsg( "---- Checking Scoped Configurations (Finished) ---- " ) (1) $true $FileName
   return $Item
  }
  catch
   {
    logMsg("Not able to run Scoped Configurations..." + $Error[0].Exception) (2) $true $FileName
    return 0 
   } 

}

#-------------------------------------------------------------------------------
# Check if we have an index with more than 50% of fragmentation. 
#-------------------------------------------------------------------------------

function CheckFragmentationIndexes($connection,$FileName, $FileNameLogSolution , $iTimeOut)
{
 try
 {
   $Item=0
   logMsg( "---- Checking Index Fragmentation (Note: This process may take some time and resource) - Ref: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver15 ---- " ) (1) $true $FileName
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "select 
			               ObjectSchema = OBJECT_SCHEMA_NAME(idxs.object_id)
			               ,ObjectName = object_name(idxs.object_id) 
			               ,IndexName = idxs.name
			               ,i.avg_fragmentation_in_percent
		                   from sys.indexes idxs
		                   inner join sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,'LIMITED') i  on i.object_id = idxs.object_id and i.index_id = idxs.index_id
		                   where idxs.type in (0 /*HEAP*/,1/*CLUSTERED*/,2/*NONCLUSTERED*/,5/*CLUSTERED COLUMNSTORE*/,6/*NONCLUSTERED COLUMNSTORE*/) 
		                   and (alloc_unit_type_desc = 'IN_ROW_DATA' /*avoid LOB_DATA or ROW_OVERFLOW_DATA*/ or alloc_unit_type_desc is null /*for ColumnStore indexes*/)
		                   and OBJECT_SCHEMA_NAME(idxs.object_id) != 'sys'
		                   and idxs.is_disabled=0
                           and not idxs.name is null
		                   order by ObjectName, IndexName"
   $Reader = $command.ExecuteReader(); 
   while($Reader.Read())
   {
     if( $Reader.GetValue(3) -gt 50) #If fragmentation is greater than 50
     {
       $Item=$Item+1
       logMsg(("High Fragmentation: " + $Reader.GetValue(3).ToString()).PadRight(100," ") + " of " + ($Reader.GetValue(0).ToString() + "." + $Reader.GetValue(1).ToString() +" ["+ $Reader.GetValue(2).ToString() + "]").PadRight(400," ") ) (2) $true $FileName
       logSolution("ALTER INDEX [" + $Reader.GetValue(2).ToString() + "] ON [" + $Reader.GetValue(0).ToString() +"].["+ $Reader.GetValue(1).ToString() + "] REBUILD") $FileNameLogSolution
     }
   }
   $Reader.Close();
   logMsg( "---- Checking Index Fragmentation (Finished) ---- " ) (1) $true $FileName
   return $Item
  }
  catch
   {
    logMsg("Not able to run Index Fragmentation..." + $Error[0].Exception) (2) $true $FileName
    return 0
   } 

}

#----------------------------------------------------------------
#Function to connect to the database using a retry-logic
#----------------------------------------------------------------

Function GiveMeConnectionSource($DBs)
{ 
  for ($i=1; $i -lt 10; $i++)
  {
   try
    {
      logMsg( "Connecting to the database..." + $DBs + ". Attempt #" + $i) (1)
      $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
      $SQLConnection.ConnectionString = "Server="+$server+";Database="+$Dbs+";User ID="+$user+";Password="+$password+";Connection Timeout=60;Application Name=PerfCollector" 
      $SQLConnection.Open()
      logMsg("Connected to the database.." + $DBs) (1)
      return $SQLConnection
      break;
    }
  catch
   {
    logMsg("Not able to connect - " + $DBs + " - Retrying the connection..." + $Error[0].Exception) (2)
    Start-Sleep -s 5
   }
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
#Create a folder 
#-------------------------------
Function DeleteFile{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    $FileExists = Test-Path $FileNAme
    if($FileExists -eq $True)
    {
     Remove-Item -Path $FileName -Force 
    }
    return $true 
   }
  catch
  {
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
         [Parameter(Mandatory=$true, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=1)]
         [int] $Color,
         [Parameter(Mandatory=$false, Position=2)]
         [boolean] $Show=$true, 
         [Parameter(Mandatory=$false, Position=3)]
         [string] $sFileName,
         [Parameter(Mandatory=$false, Position=4)]
         [boolean] $bShowDate=$true

    )
  try
   {
    if($bShowDate -eq $true)
    {
      $Fecha = Get-Date -format "yyyy-MM-dd HH:mm:ss"
      $msg = $Fecha + " " + $msg
    }
    If( TestEmpty($SFileName) )
    {
      Write-Output $msg | Out-File -FilePath $LogFile -Append
    }
    else
    {
      Write-Output $msg | Out-File -FilePath $sFileName -Append
    }
    $Colores="White"
    $BackGround = 
    If($Color -eq 1 )
     {
      $Colores ="Cyan"
     }
    If($Color -eq 3 )
     {
      $Colores ="Yellow"
     }

     if($Color -eq 2 -And $Show -eq $true)
      {
        Write-Host -ForegroundColor White -BackgroundColor Red $msg 
      } 
     else 
      {
       if($Show -eq $true)
       {
        Write-Host -ForegroundColor $Colores $msg 
       }
      } 


   }
  catch
  {
    Write-Host $msg 
  }
}

#--------------------------------
#Log the solution
#--------------------------------
function logSolution
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=3)]
         [string] $sFileName
    )
  try
   {
    Write-Output $msg | Out-File -FilePath $sFileName -Append
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

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)

return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

#-------------------------------------------------------------------------------
# Check queries with more waits stats querying QDS
# Save the result in a csv file on the choosen folder
# 
#-------------------------------------------------------------------------------
function Checkwaits{
 Param([Parameter(Mandatory=$true)]
       [System.String]$DBAccess,
       [Parameter(Mandatory=$true)]
       [System.String]$File)

  try {
    logMsg( "---- Checking Waits health (Started) (REF: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql?view=sql-server-ver16)---- " ) (1)
    $selectdata = "
select TOP 10 wqds.wait_category_desc,
wqds.total_query_wait_time_ms, 
wqds.avg_query_wait_time_ms, 
wqds.execution_type_desc, 
qdsp.query_id,
replace(replace(tex.query_sql_text,CHAR(13),' '),CHAR(10),' ') AS query_sql_text,
CASE
  WHEN
    wqds.wait_category_desc = 'Network IO'
      THEN
        'Please check  - ASYNC_NETWORK_IO, NET_WAITFOR_PACKET, PROXY_NETWORK_IO, EXTERNAL_SCRIPT_NETWORK_IO  - information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
 WHEN
    wqds.wait_category_desc = 'Memory'
      THEN
        'Please check - RESOURCE_SEMAPHORE, CMEMTHREAD, CMEMPARTITIONED, EE_PMOLOCK, MEMORY_ALLOCATION_EXT, RESERVED_MEMORY_ALLOCATION_EXT, MEMORY_GRANT_UPDATE - information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
 WHEN
    wqds.wait_category_desc = 'CPU'
      THEN
        'Please check  - SOS_SCHEDULER_YIELD  - information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
		 WHEN
    wqds.wait_category_desc = 'Buffer IO'
      THEN
        'Please check - PAGEIOLATCH_% - information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
		    WHEN
		   wqds.wait_category_desc = 'Idle'
      THEN
        'Please check  - SLEEP_%, LAZYWRITER_SLEEP, SQLTRACE_BUFFER_FLUSH, SQLTRACE_INCREMENTAL_FLUSH_SLEEP, SQLTRACE_WAIT_ENTRIES, FT_IFTS_SCHEDULER_IDLE_WAIT, XE_DISPATCHER_WAIT, REQUEST_FOR_DEADLOCK_SEARCH, LOGMGR_QUEUE, ONDEMAND_TASK_QUEUE, CHECKPOINT_QUEUE, XE_TIMER_EVENT - information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
		ELSE
		'Please check the link for more information https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database?view=azuresqldb-current'
END AS Recoommendation
from sys.query_store_wait_stats as wqds
join sys.query_store_plan as qdsp 
on qdsp.plan_id = wqds.plan_id
join sys.query_store_query as query
on query.query_id = qdsp.query_id
join sys.query_store_query_text as tex
on query.query_text_id = tex.query_text_id
order by total_query_wait_time_ms desc"
               
    Invoke-Sqlcmd -ServerInstance $server -Database $DBAccess -Query $selectdata  -Username $user -Password $password -Verbose | Export-Csv $File  -Delimiter "," -NoTypeInformation
    
    logMsg( "----------------------------------------- " ) (1)
    logMsg( "---- Checking waits stats (Finished) ---- " ) (1)
    logMsg( "----------------------------------------- " ) (1)
    logMsg( "---- Please check " + $File + " to check all the information about the waits" ) (3)
    logMsg( "----------------------------------------- " ) (1)
  }
  catch {
    logMsg("Not able to run waits stats..." + $Error[0].Exception) (2)
  } 
            
}

#-------------------------------------------------------------------------------
# Check the rows, space used, allocated and numbers of tables. 
#-------------------------------------------------------------------------------
function CheckStatusPerTable($connection ,$FileName, $iTimeOut)
{
 try
 {
   logMsg( "---- Checking Status per Table ---- " ) (1) $true $FileName 
   $Item=0

   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT s.Name + '.' + t.name,
                                  SUM(p.rows) AS RowCounts,
                                  SUM(a.total_pages) * 8 AS TotalSpaceKB, 
                                  SUM(a.used_pages) * 8 AS UsedSpaceKB, 
                                 (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
                        FROM 
                            sys.tables t
                        INNER JOIN      
                            sys.indexes i ON t.OBJECT_ID = i.object_id
                        INNER JOIN 
                            sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
                        INNER JOIN 
                            sys.allocation_units a ON p.partition_id = a.container_id
                        LEFT OUTER JOIN 
                            sys.schemas s ON t.schema_id = s.schema_id
                        WHERE t.is_ms_shipped = 0
                            AND i.OBJECT_ID > 255 
                        GROUP BY 
                            s.Name + '.' + t.name"
  $Reader = $command.ExecuteReader(); 
  $StringReport = "Table                                                                                               "
  $StringReport = $StringReport + "Rows                        "                   
  $StringReport = $StringReport + "Space                       "                  
  $StringReport = $StringReport + "Used                        "                   
  logMsg($StringReport) (1) $true $FileName -bShowDate $false
  
  while($Reader.Read())
   {
    $Item=$Item+1
    $lTotalRows = $Reader.GetValue(1)
    $lTotalSpace = $Reader.GetValue(2)
    $lTotalUsed = $Reader.GetValue(3)
    $lTotalUnUsed = $Reader.GetValue(4)
    $StringReport = $Reader.GetValue(0).ToString().PadRight(100).Substring(0,99) + " "
    $StringReport = $StringReport + $lTotalRows.ToString('N0').PadLeft(20) + " " 
    $StringReport = $StringReport + $lTotalSpace.ToString('N0').PadLeft(20)  + " "
    $StringReport = $StringReport + $lTotalUsed.ToString('N0').PadLeft(20)  
    logMsg($StringReport) (1) $true $FileName -bShowDate $false
   }

   $Reader.Close();
   return $Item
  }
  catch
   {
    $Reader.Close();
    logMsg("Not able to run Checking Status per Table..." + $Error[0].Exception) (2)
    return 0
   } 

}

#-------------------------------------------------------------------------------
# Check the rows, space used, allocated and numbers of system tables
#-------------------------------------------------------------------------------
function CheckStatusPerSystemTable($connection ,$FileName, $iTimeOut)
{
 try
 {
   logMsg( "---- Checking Status per System Table ---- " ) (1) $true $FileName 
   $Item=0

   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "SELECT s.Name  + '.' + t.NAME AS TableName,
                           p.rows,
                           SUM(a.total_pages) / 128.00 AS TotalSpaceMB,
                           SUM(a.used_pages) / 128.00 AS UsedSpaceMB,
                           SUM(a.total_pages - a.used_pages) / 128.00 AS UnusedSpaceKB
                           FROM sys.schemas s
                           INNER JOIN sys.objects t ON t.schema_id = s.schema_id
                           INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
                           INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
                           INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
                           WHERE t.is_ms_shipped = 1
                           GROUP BY s.Name  + '.' + t.NAME, p.Rows
						   ORDER BY p.Rows desc"
  $Reader = $command.ExecuteReader(); 
  $StringReport = "Table                                                                                               "
  $StringReport = $StringReport + "Rows                        "                   
  $StringReport = $StringReport + "Space                       "                  
  $StringReport = $StringReport + "Used                        "                   
  logMsg($StringReport) (1) $true $FileName -bShowDate $false
  
  while($Reader.Read())
   {
    $Item=$Item+1
    $lTotalRows = $Reader.GetValue(1)
    $lTotalSpace = $Reader.GetValue(2)
    $lTotalUsed = $Reader.GetValue(3)
    $lTotalUnUsed = $Reader.GetValue(4)
    $StringReport = $Reader.GetValue(0).ToString().PadRight(100).Substring(0,99) + " "
    $StringReport = $StringReport + $lTotalRows.ToString('N0').PadLeft(20) + " " 
    $StringReport = $StringReport + $lTotalSpace.ToString('N0').PadLeft(20)  + " "
    $StringReport = $StringReport + $lTotalUsed.ToString('N0').PadLeft(20)  
    logMsg($StringReport) (1) $true $FileName -bShowDate $false
   }

   $Reader.Close();
   return $Item
  }
  catch
   {
    $Reader.Close();
    logMsg("Not able to run Checking Status per System Table..." + $Error[0].Exception) (2)
    return 0
   } 

}

#-------------------------------------------------------------------------------
# Show the performance counters of the database
#-------------------------------------------------------------------------------

function CheckStatusPerResource($connection,$FileName, $iTimeOut)
{
 try
 {
   logMsg( "---- Checking Status per Resources ---- " ) (1) $true $FileName
   $Item=0
   $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $command.CommandTimeout = $iTimeOut
   $command.Connection=$connection
   $command.CommandText = "select end_time, avg_cpu_percent, avg_data_io_percent, avg_log_write_percent, avg_memory_usage_percent, max_worker_percent from sys.dm_db_resource_stats order by end_time desc"

  $Reader = $command.ExecuteReader(); 
  $StringReport = "Time                 "
  $StringReport = $StringReport + "Avg_Cpu    "
  $StringReport = $StringReport + "Avg_DataIO "
  $StringReport = $StringReport + "Avg_Log    "              
  $StringReport = $StringReport + "Avg_Memory "                   
  $StringReport = $StringReport + "Max_Workers"                  

  logMsg($StringReport) (1) $true $FileName -bShowDate $false
  while($Reader.Read())
   {
    $Item=$Item+1
    $lTotalCPU = $Reader.GetValue(1)
    $lTotalDataIO = $Reader.GetValue(2)
    $lTotalLog = $Reader.GetValue(3)
    $lTotalMemory = $Reader.GetValue(4)
    $lTotalWorkers = $Reader.GetValue(5)
    $StringReport = $Reader.GetValue(0).ToString().PadLeft(20) + " "
    $StringReport = $StringReport + $lTotalCPU.ToString('N2').PadLeft(10) + " "
    $StringReport = $StringReport + $lTotalDataIO.ToString('N2').PadLeft(10) 
    $StringReport = $StringReport + $lTotalLog.ToString('N2').PadLeft(10) 
    $StringReport = $StringReport + $lTotalMemory.ToString('N2').PadLeft(10) 
    $StringReport = $StringReport + $lTotalWorkers.ToString('N2').PadLeft(10) 
    logMsg($StringReport) (1) $true $FileName -bShowDate $false
   }

   $Reader.Close();
   return $Item
  }
  catch
   {
    logMsg("Not able to run Checking Status per Resources..." + $Error[0].Exception) (2) $true $FileName
    return 0
   } 

}


function sGiveMeFileName{
 Param([Parameter(Mandatory=$true)]
       [System.String]$DBAccess,
       [Parameter(Mandatory=$true)]
       [System.String]$File)
  try 
    {
      return $FolderV + $DBAccess + $File 
     }
  catch {
    return "_UnKnow.csv" 
        } 
  }

try
{
Clear

#--------------------------------
#Check the parameters.
#--------------------------------

if (TestEmpty($server)) { $server = read-host -Prompt "Please enter a Server Name" }
if (TestEmpty($user))  { $user = read-host -Prompt "Please enter a User Name"   }
if (TestEmpty($passwordSecure))  
    {  
    $passwordSecure = read-host -Prompt "Please enter a password"  -assecurestring  
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
    }
else
    {$password = $passwordSecure} 
if (TestEmpty($Db))  { $Db = read-host -Prompt "Please enter a Database Name, type ALL to check all databases"  }
if (TestEmpty($Folder)) {  $Folder = read-host -Prompt "Please enter a Destination Folder (Don't include the last \) - Example c:\PerfChecker" }

$DbsArray = [System.Collections.ArrayList]::new() 


#--------------------------------
#Variables
#--------------------------------
 $CheckStatistics=0
 $CheckIndexesAndStatistics=0
 $CheckMissingIndexes=0
 $CheckScopeConfiguration=0
 $CheckTunningRecomendations=0
 $CheckFragmentationIndexes=0
 $CheckCommandTimeout=0
 $CheckWaits=0
 $ExportQueryDataStore=0
 $CheckStatusPerResource=0
 $CheckStatusPerTable=0
 
 $TotalCheckStatistics=0
 $TotalCheckIndexesAndStatistics=0
 $TotalCheckMissingIndexes=0
 $TotalCheckScopeConfiguration=0
 $TotalCheckTunningRecomendations=0
 $TotalCheckFragmentationIndexes=0
 $TotalCheckCommandTimeout=0
 $TotalCheckWaits=0
 $TotalExportQueryDataStore=0
 $TotalCheckStatusPerResource=0
 $TotalCheckStatusPerTable=0
 $TotalCheckStatusPerSystemTable=0

#--------------------------------
#Run the process
#--------------------------------

logMsg("Creating the folder " + $Folder) (1)
   $result = CreateFolder($Folder) #Creating the folder that we are going to have the results, log and zip.
   If( $result -eq $false)
    { 
     logMsg("Was not possible to create the folder") (2)
     exit;
    }
logMsg("Created the folder " + $Folder) (1)

$sFolderV = GiveMeFolderName($Folder) #Creating a correct folder adding at the end \.

$LogFile = $sFolderV + "PerfChecker.Log"                  #Logging the operations.

logMsg("Deleting Operation Log file") (1)
   $result = DeleteFile($LogFile)         #Delete Log file
logMsg("Deleted Operation Log file") (1)

logMsg("-------------------- Header Filter details --------------") (1)
logMsg("  ServerName:           " + $server) (1)
logMsg("  DB Filter :           " + $DB) (1)
logMsg("  Folder    :           " + $Folder) (1)
logMsg("  Delete Files:         " + $DropExisting) (1)
logMsg("  Elastic DB Pool Name: " + $ElasticDBPoolName) (1)
logMsg("-------------------- Footer Filter details --------------") (1)


if( $DropExisting -eq 1)
{
    foreach ($f in ((Get-ChildItem -Path $sFolderV))) 
    {
        if($f.Extension -in (".bcp") -or $f.Extension -in (".xml") -or $f.Extension -in (".txt") -or $f.Extension -in (".task") -or $f.Extension -in (".csv"))
        {
            logMsg("Deleting Operation file: " + $f.FullName) (1)
            $result = DeleteFile($f.FullName)
            logMsg("Deleted Operation file: " + $f.FullName) (1)
        }
    }
 }
    


if($Db -eq "ALL")
{

   $SQLConnectionSource = GiveMeConnectionSource "master" #Connecting to the database.
   if($SQLConnectionSource -eq $null)
    { 
     logMsg("It is not possible to connect to the database") (2)
     exit;
    }
   $commandDB = New-Object -TypeName System.Data.SqlClient.SqlCommand
   $commandDB.CommandTimeout = 6000
   $commandDB.Connection=$SQLConnectionSource
   if(TestEmpty($ElasticDBPoolName))
   {
     $commandDB.CommandText = "SELECT name from sys.databases where database_id >=5 order by name"
   }
   else
   {
     $commandDB.CommandText = "SELECT d.name as DatabaseName FROM sys.databases d inner join sys.database_service_objectives dso on d.database_id = dso.database_id WHERE dso.elastic_pool_name = '" + $ElasticDBPoolName + "' AND d.name LIKE 'jmjuradotestdb%' ORDER BY d.name"
   }
      
   $ReaderDB = $commandDB.ExecuteReader(); 
   while($ReaderDB.Read())
   {
      [void]$DbsArray.Add($ReaderDB.GetValue(0).ToString())
      logMsg("Database Name selected:" + $ReaderDB.GetValue(0).ToString()) (1)
   }

   $ReaderDB.Close();
   $SQLConnectionSource.Close() 
}
else
{
  $DbsArray.Add($DB)
}

 for($iDBs=0;$iDBs -lt $DbsArray.Count; $iDBs=$iDBs+1)
 {
   logMsg("Connecting to database.." + $DbsArray[$iDBs]) (1) 
   $SQLConnectionSource = GiveMeConnectionSource($DbsArray[$iDBs]) #Connecting to the database.
   if($SQLConnectionSource -eq $null)
    { 
     logMsg("It is not possible to connect to the database " + $DbsArray[$iDBs] ) (2)
     exit;
    }

     logMsg("Connected to database.." + $DbsArray[$iDBs]) (1) 

     $CheckStatistics=0
     $CheckIndexesAndStatistics=0
     $CheckMissingIndexes=0
     $CheckScopeConfiguration=0
     $CheckTunningRecomendations=0
     $CheckFragmentationIndexes=0
     $CheckCommandTimeout=0
     $CheckWaits=0
     $ExportQueryDataStore=0
     $CheckStatusPerResource=0
     $CheckStatusPerTable=0
     $CheckStatusPerSystemTable=0

     $FileName=Remove-InvalidFileNameChars($DbsArray[$iDBs])
     $FileWaitStat = $sFolderV + $FileName + "_PerfCheckerWaitStats.csv" 
     $result = DeleteFile($FileWaitStat)                                 
     
     $CheckStatistics = CheckStatistics $SQLConnectionSource ($sFolderV + $FileName + "_CheckStatistics.Txt") ($sFolderV + $FileName + "_CheckStatistics.Task") (3600)
     $CheckIndexesAndStatistics = CheckIndexesAndStatistics $SQLConnectionSource ($sFolderV + $FileName + "_CheckIndexesStatistics.Txt") ($sFolderV + $FileName + "_CheckIndexesStatistics.Task") (3600)
     $CheckMissingIndexes = CheckMissingIndexes $SQLConnectionSource ($sFolderV + $FileName + "_CheckMissingIndexes.Txt") ($sFolderV + $FileName + "_CheckMissingIndexes.Task") (3600)
     $CheckScopeConfiguration = CheckScopeConfiguration $SQLConnectionSource ($sFolderV + $FileName + "_CheckScopeConfiguration.Txt") ($sFolderV + $FileName + "_CheckScopeConfiguration.Task") (3600)
     $CheckTunningRecomendations = CheckTunningRecomendations $SQLConnectionSource ($sFolderV + $FileName + "_CheckTunningRecomendation.Txt") ($sFolderV + $FileName + "_CheckTunningRecomendation.Task") (3600)
     $CheckFragmentationIndexes = CheckFragmentationIndexes $SQLConnectionSource ($sFolderV + $FileName + "_CheckFragmentationIndexes.Txt") ($sFolderV + $FileName + "_CheckFragmentationIndexes.Task") (3600)
     $CheckCommandTimeout = CheckCommandTimeout $SQLConnectionSource ($sFolderV + $FileName + "_CheckCommandTimeout.Txt") ($sFolderV + $FileName + "_CheckCommandTimeout.Task") (3600)
     $ExportQueryDataStore = ExportQueryDataStore $SQLConnectionSource $DbsArray[$iDBs] 3600
     $CheckStatusPerResource = CheckStatusPerResource $SQLConnectionSource ($sFolderV + $FileName + "_ResourceUsage.Txt") (3600)
     $CheckStatusPerTable = CheckStatusPerTable $SQLConnectionSource ($sFolderV + $FileName + "_TableSize.Txt") (3600)
     $CheckStatusPerSystemTable = CheckStatusPerSystemTable $SQLConnectionSource ($sFolderV + $FileName + "_SystemTableSize.Txt") (3600)
     Checkwaits $DbsArray[$iDBs] $FileWaitStat
   
     $TotalCheckStatistics=$TotalCheckStatistics+$CheckStatistics
     $TotalCheckIndexesAndStatistics=$TotalCheckIndexesAndStatistics+$CheckIndexesAndStatistics
     $TotalCheckMissingIndexes=$TotalCheckMissingIndexes+$CheckMissingIndexes
     $TotalCheckScopeConfiguration=$TotalCheckScopeConfiguration+$CheckScopeConfiguration
     $TotalCheckTunningRecomendations=$TotalCheckTunningRecomendations+$CheckTunningRecomendations
     $TotalCheckFragmentationIndexes=$TotalCheckFragmentationIndexes+$CheckFragmentationIndexes
     $TotalCheckCommandTimeout=$TotalCheckCommandTimeout+$CheckCommandTimeout
     $TotalCheckWaits=$TotalCheckWaits+$CheckWaits
     $TotalExportQueryDataStore=$TotalExportQueryDataStore+$ExportQueryDataStore
     $TotalCheckStatusPerResource = $TotalCheckStatusPerResource + $CheckStatusPerResource
     $TotalCheckStatusPerTable = $TotalCheckStatusPerTable + $CheckStatusPerTable
     $TotalCheckStatusPerSystemTable = $TotalCheckStatusPerSystemTable +$CheckStatusPerSystemTable
     
 
   logMsg("Closing the connection and summary for.....  : " + $DbsArray[$iDBs]) (3)
   logMsg("Number of Issues with statistics             : " + $CheckStatistics )  (1)
   logMsg("Number of Issues with statistics/indexes     : " + $CheckIndexesAndStatistics )  (1)
   logMsg("Number of Issues with Timeouts               : " + $CheckCommandTimeout )  (1)
   logMsg("Number of Issues with Indexes Fragmentation  : " + $CheckFragmentationIndexes )  (1)
   logMsg("Number of Issues with Scoped Configuration   : " + $CheckScopeConfiguration )  (1)
   logMsg("Number of Issues with Tuning Recomendation   : " + $CheckTunningRecomendations )  (1)
   logMsg("Number of Issues with Missing Indexes        : " + $CheckMissingIndexes )  (1)
   logMsg("Number of Tables of Query Data Store Exported: " + $ExportQueryDataStore )  (1)
   logMsg("Number of Resource Usage                     : " + $CheckStatusPerResource )  (1)
   logMsg("Number of Tables Usage                       : " + $CheckStatusPerTable )  (1)
   logMsg("Number of System Tables Usage                : " + $CheckStatusPerSystemTable )  (1)
   
   $SQLConnectionSource.Close() 
 }
 Remove-Variable password
 logMsg("Performance Collector Script was executed correctly")  (3)
 logMsg("Total Number of Issues with statistics             : " + $TotalCheckStatistics )  (1)
 logMsg("Total Number of Issues with statistics/indexes     : " + $TotalCheckIndexesAndStatistics )  (1)
 logMsg("Total Number of Issues with Timeouts               : " + $TotalCheckCommandTimeout )  (1)
 logMsg("Total Number of Issues with Indexes Fragmentation  : " + $TotalCheckFragmentationIndexes )  (1)
 logMsg("Total Number of Issues with Scoped Configuration   : " + $TotalCheckScopeConfiguration )  (1)
 logMsg("Total Number of Issues with Tuning Recomendation   : " + $TotalCheckTunningRecomendations )  (1)
 logMsg("Total Number of Issues with Missing Indexes        : " + $TotalCheckMissingIndexes )  (1)
 logMsg("Total Number of Tables of Query Data Store Exported: " + $TotalExportQueryDataStore )  (1)
 logMsg("Total Number of Resource Usage                     : " + $TotalCheckStatusPerResource )  (1)
 logMsg("Total Number of Tables Usage                       : " + $TotalCheckStatusPerTable )  (1)
 logMsg("Total Number of System Tables Usage                : " + $TotalCheckStatusPerSystemTable )  (1)

}
catch
  {
    logMsg("Performance Collector Script was executed incorrectly ..: " + $Error[0].Exception) (2)
  }
finally
{
   logMsg("Performance Collector Script finished - Check the previous status line to know if it was success or not") (2)
} 
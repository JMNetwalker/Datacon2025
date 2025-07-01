
Param($NumberOfConcurrentTasks,$ScenarioType,$HowManyOperations,$PowerShellLocationToExecute="C:\Users\Jmjurado\OneDrive - Microsoft\NTJMJURADO06\Documentos\BrownBags\2025\DataCon2025\Sessions\Mastering Elastic Database Pools Best Practices\PowerShell\DBTestProject\ExecutionConnectionTimeSpent.ps1") 

#-----------------------------------------------------------
# Identify if the value is empty or not
#-----------------------------------------------------------

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
#Log the operations of this script.aa
#--------------------------------
function logMsgParallel
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

#--------------------------------------------------------------------------
#Obtain the status for every BackgroundJob and execute the remaining ones
#--------------------------------------------------------------------------

Function GiveID(
              [Parameter(Mandatory=$false)] [int]$lMax,
              [Parameter(Mandatory=$false)] [int]$lExecuted)
{ 
 try
 {

  [int]$lPending=0
  [string]$Msg=""

  $Jobs = Get-Job ##Obtain the jobs that PowerShell is executing.

  if($lMax -eq -1 ) ##if we don't have the number of jobs to run the default will be the number of client machine processor.
  {
   $lMax = [int]$env:NUMBER_OF_PROCESSORS
  }

  ##----------------------------------------------
  ##For every job we're going to know the current status and if the process finishes.In case that any job finishes we are going 
  ##to run a new one until the maximum number of loops
  ##----------------------------------------------
  
  ForEach ($di in $Jobs)                         
  {
    if($di.State -eq "Running")
    {
      $lPending=$lPending+1
    }
    $Msg=$("Checking..." + $di.Name + " (" + $di.State + ") of total concurrent " + $lMax.ToString() + " jobs - Executed Already - " + $lExecuted.ToString())
    logMsgParallel -msg $Msg (4)
    ##$Data = Receive-Job $di.Id - if we need to know what is the outcome of the job, uses Receive-Job...
  } 
  if($lPending -lt $lMax) 
    {return $true} ##We reached the maximum of allowed jobs running at the same time.
  
  return {$false}
 }
 catch
  {
 
  }
}

#-------------------------------
#Delete the file
#-------------------------------
Function DeleteFile{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    logMsgParallel("Checking if the file..." + $FileName + " exists.")  
    $FileExists = Test-Path $FileName
    if($FileExists -eq $True)
    {
     logMsgParallel("Removing the file..." + $FileName)  
     Remove-Item -Path $FileName -Force 
     logMsgParallel("Removed the file..." + $FileName) 
    }
    return $true 
   }
  catch
  {
   logMsgParallel("Remove the file..." + $FileName + " - " + $Error[0].Exception) (2) 
   return $false
  }
 }


#--------------------------------------------------
#Controls the different scenario to run.
#--------------------------------------------------

function GiveScenario
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [int]$OverWrite
 )
 try
 {

  If($OverWrite -eq 0) 
  {
    $Value = Get-Random -Minimum 1 -Maximum 10
  }  
  else
  {
    $Value = $OverWrite
  }
  
 If($Value -eq 1) 
 { return "HighLogIO" }

 If($Value -eq 2) 
 { return "HighTempDB" }

 If($Value -eq 3) 
 { return "HighCPU" }

 If($Value -eq 4) 
 { return "HighAsyncNetworkIO" }
 
 If($Value -eq 5) 
 { return "HighCXPACKET"}

 If($Value -eq 6) 
 { return "HighDATAIO"}

 If($Value -eq 7) 
 { return "HighBulkInsert"}

 If($Value -eq 8) 
 { return "HighLocks"}

 If($Value -eq 9) 
 { return "HighTempDBAlloc" }

 If($Value -eq 10) 
 { return "HighTempDBAllocMeta"}

 If($Value -eq 11) 
 { return "HighDATAIOByBlocks" }

 If($Value -eq 12) 
 { return "HighCPUConcurrent"}

 return "Default"
 
 }
 catch
 {
  return "Default"
 }
}

function GiveMeLastSeparator($Text,$Separator)
{
  try
   {
    $Pos = $Text.LastIndexOf($Separator)
    $Return=$Text.Substring(0,$Pos)
    return $Return
   }
  catch
  {
    return $Text
  }
}

#--------------------------------
#Remove invalid chars for a name of a file
#--------------------------------

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)
return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

Function IsInteger([string]$vInteger)
{
    Try
    {
        $null = [convert]::ToInt32($vInteger)
        return $True
    }
    Catch
    {
        return $False
    }
}  

try
{
 clear


 $i=0;
 $invocation = (Get-Variable MyInvocation).Value
  
 if(TestEmpty($PowerShellLocationToExecute))
     {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = [Environment]::GetFolderPath("Desktop") 
        Filter = 'PowerShell Script to execute (*.ps1)|*.ps1'}
        $null = $FileBrowser.ShowDialog()
        $PowerShellLocationToExecute = $FileBrowser.FileName
        if(TestEmpty($PowerShellLocationToExecute))
        { 
         logMsgParallel("Please, specify a PowerShell script to run") (2)
         exit;
        }
     }
 
 $Folder = GiveMeLastSeparator $PowerShellLocationToExecute "\"

 if (TestEmpty($Folder)) 
 {
   logMsgParallel("Please, specify a correct folder") (2)
   exit;
 }
 
 if (TestEmpty($NumberOfConcurrentTasks))  
    { 
      $NumberOfConcurrentTasks = read-host -Prompt $("Please enter a number of concurrent tasks (type -1 to use el default number of Vcores " + $env:NUMBER_OF_PROCESSORS + ")") 
    }

 if (TestEmpty($NumberOfConcurrentTasks)) 
   {
    logMsgParallel("Please, specify a correct number of jobs to perform, the value is empty") (2)
    exit;
   }

 if( -not (IsInteger([string]$NumberOfConcurrentTasks)))
   {
    logMsgParallel("Please, specify a correct number of jobs to perform, the value is not integer") (2)
    exit;
   }

 $integerNumberOfConcurrentTasks = [int]::Parse($NumberOfConcurrentTasks)

 if($integerNumberOfConcurrentTasks -lt 0 -or $integerNumberOfConcurrentTasks -gt 200)
   {
    logMsgParallel("Please, specify a correct number of jobs to perform between 0 and 200") (2)
    exit;
   }

 if (TestEmpty($HowManyOperations))  
    { 
      $HowManyOperations = read-host -Prompt "Please enter a number of process that you want to run" 
    }

 if (TestEmpty($HowManyOperations)) 
   {
    logMsgParallel("Please, specify a correct number of process to run") (2)
    exit;
   }

 if( -not (IsInteger([string]$HowManyOperations)))
   {
    logMsgParallel("Please, specify a correct number of process to run, the value is not integer") (2)
    exit;
   }


 $integerHowManyOperations = [int]::Parse($HowManyOperations)

 if($integerHowManyOperations -lt 1 -or $integerHowManyOperations -gt 2000)
   {
    logMsgParallel("Please, specify a correct number of process to run, it is a value between 1 and 2000") (2)
    exit;
   }
       
 if (TestEmpty($ScenarioType)) 
   {
     $listBox = New-Object System.Windows.Forms.ListBox
     $listBox.Location = New-Object System.Drawing.Point(10,40)
     $listBox.Size = New-Object System.Drawing.Size(260,40)
     $listBox.Height = 80

     [void] $listBox.Items.Add('0 - Random')
     [void] $listBox.Items.Add('1 - HighLogIO')
     [void] $listBox.Items.Add('2 - HighTempDB')
     [void] $listBox.Items.Add('3 - HighCPU')
     [void] $listBox.Items.Add('4 - HighAsyncNetworkIO')
     [void] $listBox.Items.Add('5 - HighCXPACKET')
     [void] $listBox.Items.Add('6 - HighDATAIO')
     [void] $listBox.Items.Add('7 - HighBulkInsert')
     [void] $listBox.Items.Add('8 - HighLocks')
     [void] $listBox.Items.Add('9 - HighTempDBAlloc')
     [void] $listBox.Items.Add('10 - HighTempDBAllocMeta')
     [void] $listBox.Items.Add('11 - HighDATAIOByBlocks')
     [void] $listBox.Items.Add('12 - HighCPUConcurrent')
     [void] $listBox.Items.Add('13 - Standard Connectivity Test (Default)')

     $okButton = New-Object System.Windows.Forms.Button
     $okButton.Location = New-Object System.Drawing.Point(75,120)
     $okButton.Size = New-Object System.Drawing.Size(75,23)
     $okButton.Text = 'OK'
     $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
     
     $cancelButton = New-Object System.Windows.Forms.Button
     $cancelButton.Location = New-Object System.Drawing.Point(150,120)
     $cancelButton.Size = New-Object System.Drawing.Size(75,23)
     $cancelButton.Text = 'Cancel'
     $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

     $listbox.SelectedItem = $listBox.Items.item(0)

     $form = New-Object System.Windows.Forms.Form
     $form.Text = 'Select the scenario to execute'
     $form.Size = New-Object System.Drawing.Size(300,400)
     $form.StartPosition = 'CenterScreen'
     $form.Controls.Add($listBox)

     $form.CancelButton = $cancelButton
     $form.Controls.Add($cancelButton)

     $form.AcceptButton = $okButton
     $form.Controls.Add($okButton)

     $form.Topmost = $true
     
     $result = $form.ShowDialog()

     if ($result -eq [System.Windows.Forms.DialogResult]::OK)
     {
        $x = $listBox.SelectedIndex
     }
     else
     {
      logMsgParallel("Scenario type has not been selected.") (2)
      exit
     }

 }

 $Jobs = Get-Job ##Obtain all the process under this main session of powershell
 Foreach ($di in $Jobs) ##We need to close and kill other previous process.
 {
   logMsgParallel $('Stopping previous scenario: ' + $di.Name) (3)
   Stop-Job $di.Id
   logMsgParallel $('Removing previous scenario: ' + $di.Name) (3)
   Remove-Job $di.Id
 } 

 ##-----------------------------------------------------------------------------------------------------
 ##For every file with extension .lock (file to upload the data). We need to delete these files in case
 ##that previous loading proccess failed
 ##-----------------------------------------------------------------------------------------------------

 foreach ($f in ((Get-ChildItem -Path $Folder))) 
 {
  if($f.Extension.ToString().ToLower() -eq ".lock")   
  {
    $Null = DeleteFile($f.FullName)
  }
 }

 logMsgParallel $('-------------- User Parameters -----------') (3)
 logMsgParallel $('Concurrent Jobs:              ' + $integerNumberOfConcurrentTasks.ToString()) (3)
 logMsgParallel $('Number of process to execute: ' + $integerHowManyOperations) (3)
 logMsgParallel $('Scenario:                     ' + $listBox.SelectedItem) (3)
 logMsgParallel $('Folder:                       ' + $Folder) (3)
 logMsgParallel $('PowerShellScript to execute:  ' + $PowerShellLocationToExecute) (3)
 logMsgParallel $('------------------------------------------') (3)

 #-----------------------------------------------------------------------------------------------------
 #Execute 2000 operations in groups at the same time. 
 #-----------------------------------------------------------------------------------------------------

 while ($i -lt $integerHowManyOperations)
 {
  if((Giveid $integerNumberOfConcurrentTasks $i) -eq $true) ##How many process do you want to run at the same time.
  {
   $Scenario = $(GiveScenario $x)
   $ExtensionParam = "_" + $Scenario + "_" + $i.ToString()
   $ExecutionType = $Scenario
   $NameofApp = $Scenario + "-" + $i.ToString()

   logMsgParallel $("Starting up the scenario: " + $NameofApp + " Extension " + $ExtensionParam + " Type " + $ExecutionType) (1)
   $Null = Start-Job -Name $(($ExecutionType + "-" + $ExtensionParam)) -FilePath $PowerShellLocationToExecute -ArgumentList $Folder, $ExtensionParam, $ExecutionType, $NameofApp
   logMsgParallel $("Started the scenario: ---" + $NameofApp ) (1)
   $i=$i+1;
  }
  else
  {
    logMsgParallel ("Limit of concurrent process reached. Waiting for completion in 5 seconds") (3)
    Start-sleep -Seconds 5
  }
 }
}
 catch
   {
    logMsgParallel("Error executing this process..." + $Error[0].Exception) (2)
   }

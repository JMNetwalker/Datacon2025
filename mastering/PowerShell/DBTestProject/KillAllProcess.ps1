 ##Kill all jobs that this PowerShell instance is running.

 $Jobs = Get-Job
 Foreach ($di in $Jobs)
 {
   Stop-Job $di.Id
   Remove-Job $di.Id
 } 

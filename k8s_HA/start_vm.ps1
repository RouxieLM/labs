# Define working directory and VM names
$loc = "F:\Repo\Vagrant\k8s_HA"
$logFile = "$loc\vagrant-provisioning.log"

$vmList = @(
  "master-1",
  "master-2",
  "master-3",
  "worker-1",
  "worker-2",
  "worker-3",
  "loadbalancer"
)

# Clear previous log
if (Test-Path $logFile) {
  Remove-Item $logFile -Force
}
"[$(Get-Date -Format 'u')] Starting Vagrant VM launch..." | Out-File $logFile

# --- Step 1: Start master-1 synchronously
Write-Output "Starting master-1..."
"[$(Get-Date -Format 'u')] Starting master-1..." | Out-File $logFile -Append

$job = Start-Job -ScriptBlock {
    param($path, $vm)
    Set-Location $path
    vagrant up $vm
} -ArgumentList $loc, $vmList[0]

Wait-Job $job
Receive-Job $job | Out-File $logFile -Append
Remove-Job $job

Write-Output "master-1 started."
"[$(Get-Date -Format 'u')] master-1 started." | Out-File $logFile -Appen

# --- Step 2: Start remaining VMs in parallel
Write-Output "Starting remaining VMs in parallel..."
"[$(Get-Date -Format 'u')] Starting remaining VMs in parallel..." | Out-File $logFile -Append
$parallelJobs = @()

foreach ($vm in $vmList[1..($vmList.Count -1)]) {
  $parallelJobs += Start-Job -ScriptBlock {
    param($path, $vmName)
    Set-Location $path
    vagrant up $vmName
  } -ArgumentList $loc, $vm
}

# --- Step 3: Wait for completion and output results
Wait-Job -Job $parallelJobs

foreach ($job in $parallelJobs) {
  Write-Output "----- Output from job ID $($job.Id) -----"
  "[$(Get-Date -Format 'u')] ----- Output from job ID $($job.Id) -----" | Out-File $logFile -Append
  Receive-Job $job | Out-File $logFile -Append
  Remove-Job $job
}
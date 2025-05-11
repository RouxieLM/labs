# Define working directory and VM names
$loc = "F:\Repo\Vagrant"
$vmList = @(
  "master-1",
  "master-2",
  "master-2",
  "master-3",
  "worker-1",
  "worker-2",
  "worker-3",
  "loadbalancer"
)

# --- Step 1: Start master-1 synchronously
Write-Output "Starting master-1..."
$job = Start-Job -ScriptBlock {
    param($path, $vm)
    Set-Location $path
    vagrant up $vm
} -ArgumentList $loc, $vmList[0]

Wait-Job $job
Receive-Job $job
Remove-Job $job
Write-Output "master-1 started."

# --- Step 2: Start remaining VMs in parallel
Write-Output "Starting remaining VMs in parallel..."
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
  Receive-Job $job
  Remove-Job $job
}
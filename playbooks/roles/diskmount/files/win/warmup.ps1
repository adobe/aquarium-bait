#!powershell
# Warmup by multithread reading the used disk space

# Waiting for the disks population
$wait_sec = 50
while (($wait_sec--) -gt 0) {
    $disks_count = (Get-PhysicalDisk | Get-Disk | Get-Partition | Where-Object DriveLetter).Count
    if ($disks_count -gt 1) {
        break
    }
    echo ("Waiting for disks: " + $disks_count)
    Start-sleep -seconds 1
}

echo ('Started warmup at ' + (Get-Date -Format "yy.MM.dd HH:mm:ss"))

$procs = @()
Get-PhysicalDisk | ForEach-Object {
    # Getting drive letter where disk is mounted
    $driveletter = ($_ | Get-Disk | Get-Partition | Where-Object DriveLetter).DriveLetter
    if( $driveletter -ne 'C' ) {
        $usage = [Math]::Ceiling((Get-PSDrive $driveletter).Used / 1024 / 1024)
        echo ("Warmup Disk: " + $driveletter + " " + $_.DeviceId + " (" + $usage + "MiB used)")
        $procs += $(Start-Process -NoNewWindow -PassThru "C:\util\fio\fio.exe" -ArgumentList ("--thread --filename \\.\PHYSICALDRIVE" + $_.DeviceId + " --rw read --bs 128Ki --iodepth 32 --size " + $usage + "Mi --direct 1 --name warmup_" + $_.DeviceId + " --output C:\tmp\warmup_" + $_.DeviceId + ".log"))
        $fio_started = true
    }
}

echo "Waiting FIO processes to complete..."
$procs | Wait-Process

echo ('Ended warmup at ' + (Get-Date -Format "yy.MM.dd HH:mm:ss"))

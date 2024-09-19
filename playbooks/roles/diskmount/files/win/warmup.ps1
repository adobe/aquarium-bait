#!powershell
# Warmup by multithread reading the used disk space

Get-PhysicalDisk | ForEach-Object {
    # Getting drive letter where disk is mounted
    $driveletter = ($_ | Get-Disk | Get-Partition | Where-Object DriveLetter).DriveLetter
    if( $driveletter -ne 'C' ) {
        $usage = [Math]::Ceiling((Get-PSDrive $driveletter).Used / 1024 / 1024)
        echo ("Warmup Disk: " + $driveletter + " (" + $usage + "MB used)")
        Start-Process -NoNewWindow "C:\util\fio\fio.exe" ("--filename \\.\PHYSICALDRIVE" + $_.DeviceId + " --rw read --bs 1M --iodepth 32 --size " + $usage + "M --direct 1 --name warmup_" + $_.DeviceId)
    }
}

Wait-Process fio

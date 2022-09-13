#!powershell
# Formats the raw disks and mounts them

$count = 0
Get-Disk | Where partitionstyle -eq 'raw' | ForEach-Object {
    $name = "workspace"
    if( $counter -gt 0 ) {
        $name = "$name$counter"
    }

    echo "Processing Disk $name : $_"
    $partition = Initialize-Disk -Number $_.Number -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "$name" -Confirm:$false

    $count++
}

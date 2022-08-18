#!powershell
# Formats the raw disks and mounts them
# In general it should work fine with one workspace disk

# Format the raw disks
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "workspace" -Confirm:$false

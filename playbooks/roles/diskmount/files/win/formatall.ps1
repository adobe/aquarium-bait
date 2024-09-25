#!powershell
# Formats the raw disks and mounts them

echo ('Started formatall at ' + (Get-Date -Format "yy.MM.dd HH:mm:ss"))

$count = 0
Get-Disk | Where partitionstyle -eq 'raw' | ForEach-Object {
    $name = "workspace"
    if( $counter -gt 0 ) {
        $name = "$name$counter"
    }

    echo ("Processing Disk " + $name + " : " + $_)
    $partition = Initialize-Disk -Number $_.Number -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "$name" -Confirm:$false

    # Allow jenkins user to access the disk
    $acl = Get-ACL -Path ($partition.DriveLetter + ":\")
    $accessrule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","FullControl",'ContainerInherit,ObjectInherit','None','Allow')
    $acl.SetAccessRule($accessrule)
    $acl | Set-Acl -Path ($partition.DriveLetter + ":\")

    $count++
}

echo ('Ended formatall at ' + (Get-Date -Format "yy.MM.dd HH:mm:ss"))

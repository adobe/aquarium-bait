#!powershell
# Script waits for file C:\interface\vs_license.txt in format:
# "<product_key> <product_code>", then reads it, executes StorePID.exe
# as priviledged user and removes file after that if it was applied.

$license_path = "C:\interface\vs_license.txt"
$logfile = "C:\tmp\vs_license_watcher.log"

echo ("INFO: Listening for " + $license_path) > $logfile

# Locate the VS IDE path to find the StorePID.exe
if( $env:VS_IDE_PATH ) {
    $VS_IDE_PATH = $env:VS_IDE_PATH
    $env:VS_IDE_PATH = ''
} else {
    $VS_IDE_PATH = Split-Path -Path (Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe' -Name '(default)').Trim('"')
}

$VS_STOREPID_PATH = Join-Path -Path $VS_IDE_PATH -ChildPath StorePID.exe

# Wait for the license file
While( !(Test-Path $license_path) ) { sleep 1 }

echo "INFO: Located license file" >> $logfile

# Processing the input license data
While( $true ) {
    try {
        $license = Get-Content $license_path
        $key_code = $license.Split(" ")
        if ( $key_code[0] -match "[^a-zA-Z0-9-]" ) { echo ("ERROR: Incorrect key" + $key_code[0]) >> $logfile; sleep 1; continue }
        if ( $key_code[1] -match "[^0-9]" ) { echo ("ERROR: Incorrect code" + $key_code[1]) >> $logfile; sleep 1; continue }

        # Execute StorePID
        & $VS_STOREPID_PATH $key_code[0] $key_code[1]
        if ( $LASTEXITCODE -eq 0 ) { break }
        echo ("ERROR: Unable to store license, exit code: " + $LASTEXITCODE) >> $logfile
    } catch { echo ("ERROR: " + $_) >> $logfile }
    sleep 1
}

rm $license_path
echo "INFO: The VS product license was stored" >> $logfile

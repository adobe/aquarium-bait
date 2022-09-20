#!powershell
# Native environment init script for win platform.
# It uses init.d directory with powershell scripts to run applications in background and waits for
# them to complete.

# Env var available for scripts to locate the root of the environment
$env:ENV_PATH = $MyInvocation.MyCommand.Path | Split-Path -Parent

if( "${env:INIT_PATH}" ) {
    $INIT_PATH = $env:INIT_PATH
    $env:INIT_PATH = ''
}

if( -not "$INIT_PATH" ) {
    $INIT_PATH = "${env:ENV_PATH}\init.d"
}

echo "Init scripts in $INIT_PATH..."

# Stop the jobs started by this process on termination
trap {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}

Get-ChildItem -Path "$INIT_PATH" -Recurse | ForEach-Object {
    $f = $_
    switch( $f.Extension ) {
        '.ps1' {
            echo "Starting $f"
            Start-Job -FilePath $f.FullName
        }
        default {
            echo "Ignoring $f"
        }
    }
}

# Wait for all the jobs to complete
Get-Job | Wait-Job

echo "Init scripts completed"

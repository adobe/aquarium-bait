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

Get-ChildItem -Path "$INIT_PATH" -Recurse | ForEach-Object {
    switch( $_.Extension ) {
        '.ps1' {
            echo "Starting $f"
            Start-Job -FilePath $_.FullName
        }
        default {
            echo "Ignoring $f"
        }
    }
}

# Wait for all the jobs to complete
Wait-Job

echo "Init scripts completed"

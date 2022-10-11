#!powershell
# Native environment init script for win platform.
# It uses preinit.d and postinit.d directories with powershell scripts to setup and desetup the
# environment with elevated privileges. By default it's preinit.d, but could be set to postinit.d
# with redefining SETUP_PATH env variable.

# Env var available for scripts to locate the root of the environment
$env:ENV_PATH = $MyInvocation.MyCommand.Path | Split-Path -Parent

if( "${env:SETUP_PATH}" ) {
    $SETUP_PATH = $env:SETUP_PATH
    $env:SETUP_PATH = ''
}

if( -not "$SETUP_PATH" ) {
    $SETUP_PATH = "${env:ENV_PATH}\preinit.d"
}

echo "Setup scripts in $SETUP_PATH..."

Get-ChildItem -Path "$SETUP_PATH" -Recurse | ForEach-Object {
    switch( $_.Extension ) {
        ".ps1" {
            echo "Starting $f"
            & $_.FullName
        }
        default {
            echo "Ignoring $f"
        }
    }
}

echo "Setup scripts completed"

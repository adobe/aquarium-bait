#!/bin/sh -e
# Native environment setup script for lin and mac platforms.
# It uses preinit.d and postinit.d directories with executable shell scripts to setup and desetup
# the environment with elevated privileges. By default it's preinit.d, but could be set to 
# postinit.d with redefining SETUP_PATH env variable.

export ENV_PATH=$(dirname "$0")

[ "$SETUP_PATH" ] || SETUP_PATH="${ENV_PATH}/preinit.d"

echo "$0: Setup scripts in $SETUP_PATH..."

find "$SETUP_PATH" -follow -type f -print | sort -V | while read -r f; do
    case "$f" in
        *.sh)
            if [ -x "$f" ]; then
                echo "$0: Starting $f"
                env -u SETUP_PATH "$f"
            else
                # Warn on shell scripts without exec bit
                echo "$0: Ignoring $f, not executable"
            fi
            ;;
        *) echo "$0: Ignoring $f";;
    esac
done

echo "$0: Setup scripts completed"

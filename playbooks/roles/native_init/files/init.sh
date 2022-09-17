#!/bin/sh -e
# Native environment init script for lin and mac platforms.
# It uses init.d directory with executable shell scripts to run applications in background and
# waits for them to complete.

# Env var available for scripts to locate the root of the environment
export ENV_PATH=$(dirname "$0")

[ "$INIT_PATH" ] || INIT_PATH="${ENV_PATH}/init.d"

echo "$0: Init scripts in $INIT_PATH..."

find "$INIT_PATH" -follow -type f -print | sort -V | while read -r f; do
    case "$f" in
        *.sh)
            if [ -x "$f" ]; then
                echo "$0: Starting $f"
                env -u INIT_PATH "$f" &
            else
                # Warn on shell scripts without exec bit
                echo "$0: Ignoring $f, not executable"
            fi
            ;;
        *) echo "$0: Ignoring $f";;
    esac
done

# Wait for all the jobs to complete
wait

echo "$0: Init scripts completed"

#!/bin/sh -e
# Runs the GitHub Runner with help of configuration file or metadata from Fish API
# The current dir is used to temporarly store the required files
#
# Usage 1:
#   $ CONFIG_FILE=/some/path.env ./github_runner.sh
# Where content of /some/path.env is like:
#   GITHUB_RUNNER_URL=https://github.com/org/repo
#   GITHUB_RUNNER_NAME=test-node
#   GITHUB_RUNNER_LABELS=self-hosted,test-label,...
#   GITHUB_RUNNER_REG_TOKEN=abcdef...
#
# Usage 2 (cloud AWS):
#   $ CONFIG_URL=http://169.254.169.254/latest/user-data ./github_runner.sh
# Where content of the http page is:
#   GITHUB_RUNNER_URL=https://github.com/org/repo
#   GITHUB_RUNNER_NAME=test-node
#   GITHUB_RUNNER_LABELS=self-hosted,test-label,...
#   GITHUB_RUNNER_REG_TOKEN=abcdef...
#
# Usage 3:
#   $ NO_CONFIG_WAIT=1 GITHUB_RUNNER_URL=<url> GITHUB_RUNNER_REG_TOKEN=<secret> GITHUB_RUNNER_NAME=<name> GITHUB_RUNNER_LABELS=<labels> ./github_runner.sh

# If the CONFIG_FILE var is not set then use workspace volume config env file path
[ "$CONFIG_FILE" ] || CONFIG_FILE=/Volumes/ws/config/github_runner.env

getConfigUrls() {
    # Prepare a list of the gateway endpoints to locate Fish API host

    # In case CONFIG_URL is set - use only it
    if [ "x$CONFIG_URL" != "x" ]; then
        echo "$CONFIG_URL"
        return
    fi

    # If CONFIG_URL is empty then we list the available gateways to eventually get Fish API response
    # Get the list of the gateways, usually like "127.0.0 172.16.1"
    ifs=$(ifconfig | grep 'inet ' | awk '{print $2}' | cut -d '.' -f -3 | awk '{print $0".1"}')
    for interface in $ifs; do
        echo "https://$interface:8001/meta/v1/data/?format=env"
    done
}

receiveMetadata() {
    out=$1
    rm -f "$out"
    getConfigUrls | while read url; do
        echo "Checking ${url} for configs..."

        # The images can't use the secured connection because the certs are tends to become outdated
        curl -sSLo "$out" --insecure "$url" 2>/dev/null || true
        if grep -s '^GITHUB_RUNNER_URL' "$out"; then
            echo "Found GitHub runner config for repo: $(grep '^GITHUB_RUNNER_URL' "$out")"
            return
        fi
        if grep -s '^CONFIG_URL' "$out"; then
            echo "Found new config url: $(grep '^CONFIG_URL' "$out")"
            return
        fi
        rm -f "$out"
    done
}

echo "Init GitHub runner script $(date "+%y.%m.%d %H:%M:%S")"

# Looking for the disk/api configurations
until [ "$NO_CONFIG_WAIT" ]; do
    # Read config env file from config path
    [ ! -f "${CONFIG_FILE}" ] || . "${CONFIG_FILE}"

    # Looking the available network gateways for Aquarium Fish meta API
    receiveMetadata METADATA.env
    if [ -f METADATA.env ]; then
        . ./METADATA.env
    fi

    if [ "${GITHUB_RUNNER_URL}" -a "${GITHUB_RUNNER_REG_TOKEN}" -a "${GITHUB_RUNNER_NAME}" -a "${GITHUB_RUNNER_LABELS}" ]; then
        echo "Received all the required variables."
        break
    else
        echo "Waiting for the configuration from '$CONFIG_FILE' or FISH METADATA API..."
        sleep 5
    fi
done

# Set the flags to use in case the github server https is not trusted (local env for example)
# Just passing the github server cert will often not work because the SAN will not match
if [ "x${GITHUB_RUNNER_HTTPS_INSECURE}" = "xtrue" ]; then
    curl_insecure="--insecure"
    export GITHUB_ACTIONS_RUNNER_TLS_NO_VERIFY=1
fi

# Waiting for workspace
ws_path=.

# Go into custom workspace directory if it's set
# WARNING: It's impossible to use volume mount if you run without UI - requires Full Disk Access
# which is really hard to set. Unfortunately `diskutil enableOwnership` & chown also not working.
if [ "${GITHUB_RUNNER_WORKSPACE}" ]; then
    ws_path="${GITHUB_RUNNER_WORKSPACE}"
    workdiropt="--work $ws_path"
fi

# Wait for the write access to the directory
mkdir -p "${ws_path}" || true
until touch "$ws_path/.testwrite"; do
    echo "Wait for '$ws_path' dir write access available..."
    sleep 5
    mkdir -p "${ws_path}" || true
done
rm -f "$ws_path/.testwrite"

until cd "${ws_path}"; do
    echo "Wait for '${ws_path}' dir available..."
    sleep 5
done

# Wait for github response
until curl -s -o /dev/null -w '%{http_code}' ${curl_insecure} "${GITHUB_RUNNER_URL}" | grep -s '302\|403\|200' > /dev/null; do
    echo "Wait for '${GITHUB_RUNNER_URL}' github response..."
    sleep 5
done

# The github runner could be preloaded, so skipping download if it's here
if [ ! -d "$HOME/github_runner" ]; then
    # Find and download the runner archive
    arch=$(uname -m)
    if [ "x$arch" = "xx86_64" ]; then
        down_arch="x64"
    else
        # looks like arm then
        down_arch="arm64"
    fi

    # Static for now, but maybe in the future if someone would need - some separated storage could be used
    list_url="https://api.github.com/repos/actions/runner/releases/latest"

    # Server could be unresponsive, so repeating until success
    while true; do
        # Locating latest runner
        runner_url=$(curl -s ${curl_insecure} "$list_url" | fgrep '"browser_download_url":' | grep -o 'https://.*actions-runner-osx-[^"]*' | fgrep -- "-${down_arch}-" | head -1 || true)
        echo "Picked $runner_url to download"
        curl -sSLo /tmp/agent.tar.gz ${curl_insecure} "$runner_url" || true
        if [ -s /tmp/agent.tar.gz ]; then
            break
        fi
        # Seems failure, so repeating after sleep
        sleep 5
        # NOTE: RANDOM will work in macos sh because it's not sh at all
        sleep $((RANDOM % 25)) || true
    done

    # Unpacking the agent archive
    mkdir -p "$HOME/github_runner"
    tar -C "$HOME/github_runner" -xf /tmp/agent.tar.gz
    rm -f /tmp/agent.tar.gz
fi

# Github runner requires to execute the scripts in github_runner directory
cd "$HOME/github_runner"

# Configuring the runner only once
if [ ! -f .configonce ]; then
    ./config.sh --unattended --ephemeral --no-default-labels $workdiropt --url "$GITHUB_RUNNER_URL" \
      --token "$GITHUB_RUNNER_REG_TOKEN" --name "$GITHUB_RUNNER_NAME" --labels "$GITHUB_RUNNER_LABELS"

    touch .configonce
fi

# Run the agent once - we don't need it to restart due to dynamic nature of the agent
echo "Running the GitHub runner '${GITHUB_RUNNER_NAME}'..."

# Prevent the agent configs affect on the build environment (by `docker --env-file` for example)
# by removing the export flag for known ones and at the same way making a way to pass the required
# build variables if required by the environment
env -u GITHUB_RUNNER_URL -u GITHUB_RUNNER_REG_TOKEN -u GITHUB_RUNNER_NAME -u GITHUB_RUNNER_WORKSPACE \
    -u GITHUB_RUNNER_HTTPS_INSECURE -u CONFIG_FILE -u CONFIG_URL -u NO_CONFIG_WAIT ./run.sh

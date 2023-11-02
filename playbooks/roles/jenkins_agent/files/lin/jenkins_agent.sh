#!/bin/sh -e
# Runs the Jenkins Agent with help of configuration file or metadata from Fish API
# The current dir is used to temporarly store the required files
#
# Usage 1:
#   $ CONFIG_FILE=/some/path.env ./jenkins_agent.sh
# Where content of /some/path.env is like:
#   JENKINS_URL=https://...
#   JENKINS_AGENT_NAME=test-node
#   JENKINS_AGENT_SECRET=abcdef...
#
# Usage 2 (cloud AWS):
#   $ CONFIG_URL=http://169.254.169.254/latest/user-data ./jenkins_agent.sh
# Where content of the http page is:
#   JENKINS_URL=https://...
#   JENKINS_AGENT_NAME=test-node
#   JENKINS_AGENT_SECRET=abcdef...
#
# Usage 3:
#   $ NO_CONFIG_WAIT=1 JENKINS_URL=<url> JENKINS_AGENT_SECRET=<secret> JENKINS_AGENT_NAME=<name> ./jenkins_agent.sh

# If the CONFIG_FILE var is not set then use workspace volume config env file path
[ "$CONFIG_FILE" ] || CONFIG_FILE=/mnt/ws/config/jenkins_agent.env

getConfigUrls() {
    # Prepare a list of the gateway endpoints to locate Fish API host

    # In case CONFIG_URL is set - use only it
    if [ "x$CONFIG_URL" != "x" ]; then
        echo "$CONFIG_URL"
        return
    fi

    # If CONFIG_URL is empty then we list the available gateways to eventually get Fish API response
    # Get the list of the gateways, usually like "127.0.0 172.16.1"
    ifs=$(ip a | grep 'inet ' | awk '{print $2}' | cut -d '.' -f -3 | awk '{print $0".1"}')
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
        if grep -s '^JENKINS_URL' "$out"; then
            echo "Found jenkins agent config for server: $(grep '^JENKINS_URL' "$out")"
            return
        fi
        if grep -s '^CONFIG_URL' "$out"; then
            echo "Found new config url: $(grep '^CONFIG_URL' "$out")"
            return
        fi
        rm -f "$out"
    done
}

echo "Init jenkins agent script $(date "+%y.%m.%d %H:%M:%S")"

# Looking for the disk/api configurations
until [ "$NO_CONFIG_WAIT" ]; do
    # Read config env file from config path
    [ ! -f "${CONFIG_FILE}" ] || . "${CONFIG_FILE}"

    # Looking the available network gateways for Aquarium Fish meta API
    receiveMetadata METADATA.env
    if [ -f METADATA.env ]; then
        . ./METADATA.env
    fi

    if [ "${JENKINS_URL}" -a "${JENKINS_AGENT_SECRET}" -a "${JENKINS_AGENT_NAME}" ]; then
        echo "Received all the required variables."
        break
    else
        echo "Waiting for the configuration from '$CONFIG_FILE' or FISH METADATA API..."
        sleep 5
    fi
done

# Set the flags to use in case the jenkins server https is not trusted (local env for example)
# Just passing the jenkins server cert will often not work because the SAN will not match
if [ "x${JENKINS_HTTPS_INSECURE}" = "xtrue" ]; then
    curl_insecure="--insecure"
    jenkins_insecure="-disableHttpsCertValidation"
fi

# Waiting for workspace
ws_path=.

# Go into custom workspace directory if it's set
if [ "${JENKINS_AGENT_WORKSPACE}" ]; then
    ws_path="${JENKINS_AGENT_WORKSPACE}"
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

# Wait for jenkins response
until curl -s -o /dev/null -w '%{http_code}' ${curl_insecure} "${JENKINS_URL}" | grep -s '403\|200' > /dev/null; do
    echo "Wait for '${JENKINS_URL}' jenkins response..."
    sleep 5
done

# Download the agent jar and connect to jenkins
curl -sSLo agent.jar ${curl_insecure} "${JENKINS_URL}/jnlpJars/agent.jar"

# Run the agent once - we don't need it to restart due to dynamic nature of the agent
echo "Running the Jenkins agent '${JENKINS_AGENT_NAME}'..."

# Prevent the agent configs affect on the build environment (by `docker --env-file`
# for example) by removing the export flag for known ones and at the same way making
# a way to pass the required build variables if required by the environment
env -u JENKINS_URL -u JENKINS_AGENT_SECRET -u JENKINS_AGENT_NAME -u JENKINS_AGENT_WORKSPACE \
    -u JENKINS_HTTPS_INSECURE -u JAVA_HOME -u JAVA_OPTS -u CONFIG_FILE -u CONFIG_URL -u NO_CONFIG_WAIT \
    "${JAVA_HOME}/bin/java" ${JAVA_OPTS} -cp agent.jar hudson.remoting.jnlp.Main -headless \
    ${jenkins_insecure} -url "${JENKINS_URL}" "${JENKINS_AGENT_SECRET}" "${JENKINS_AGENT_NAME}"

#!/bin/sh -e
# Runs the Jenkins Agent with help of configuration file or metadata from Fish API
# The current dir is used to temporarly store the required files
#
# Usage 1:
#   $ CONFIG_FILE=/some/path.env ./jenkins_agent.sh
# Usage 2:
#   $ NO_CONFIG_WAIT=1 JENKINS_URL=<url> JENKINS_AGENT_SECRET=<secret> JENKINS_AGENT_NAME=<name> ./jenkins_agent.sh

# If the CONFIG_FILE var is not set then use workspace volume config env file path
[ "$CONFIG_FILE" ] || CONFIG_FILE=/Volumes/workspace/config/jenkins_agent.env

receiveMetadata() {
    out=$1
    rm -f "$out"
    # Get the list of the gateways, usually like "127.0.0 172.16.1"
    ifs=$(ifconfig | grep 'inet ' | awk '{print $2}' | cut -d '.' -f -3)
    for proto in https http; do
        for interface in ${ifs}; do
            fish_api_url="${proto}://${interface}.1:8001"
            echo "Checking ${fish_api_url} META API..."

            # TODO: not sure how to properly solve the insecure issue,
            # probably in the future when we will use some corporate CA
            curl -sSLo "$out" --insecure "${fish_api_url}/meta/v1/data/?format=env&prefix=data" 2>/dev/null || true
            if grep -s '^data_JENKINS_URL' "$out"; then
                echo "Found required metadata in ${fish_api_url}"
                return
            fi
            rm -f "$out"
        done
    done
}

# Looking for the disk/api configurations
until [ "$NO_CONFIG_WAIT" ]; do
    # Read config env file from config path
    [ ! -f "${CONFIG_FILE}" ] || source "${CONFIG_FILE}"

    # Looking the available network gateways for Aquarium Fish meta API
    receiveMetadata METADATA.env
    if [ -f METADATA.env ]; then
        source METADATA.env
        [ "${JENKINS_URL}" ]             || JENKINS_URL=${data_JENKINS_URL}
        [ "${JENKINS_AGENT_SECRET}" ]    || JENKINS_AGENT_SECRET=${data_JENKINS_AGENT_SECRET}
        [ "${JENKINS_AGENT_NAME}" ]      || JENKINS_AGENT_NAME=${data_JENKINS_AGENT_NAME}
        [ "${JENKINS_AGENT_WORKSPACE}" ] || JENKINS_AGENT_WORKSPACE="${data_JENKINS_AGENT_WORKSPACE}"
    fi

    if [ "${JENKINS_URL}" -a "${JENKINS_AGENT_SECRET}" -a "${JENKINS_AGENT_NAME}" -a "${JENKINS_AGENT_WORKSPACE}" ]; then
        echo "Received all the required variables."
        break
    else
        echo "Waiting for the configuration from '$CONFIG_FILE' or FISH METADATA API..."
        sleep 5
    fi
done

# Wait for jenkins response
until curl -s -o /dev/null -w '%{http_code}' --insecure "${JENKINS_URL}" | grep -s '403\|200' > /dev/null; do
    echo "Wait for '${JENKINS_URL}' jenkins response..."
    sleep 5
done

# Go into workspace directory
mkdir -p "${JENKINS_AGENT_WORKSPACE}" || true
until cd "${JENKINS_AGENT_WORKSPACE}" 2>/dev/null; do
    # Try to create the required directory
    echo "Wait for '${JENKINS_AGENT_WORKSPACE}' dir available..."
    sleep 5
    mkdir -p "${JENKINS_AGENT_WORKSPACE}" || true
done

# Download the agent jar and connect to jenkins
curl -sSLo agent.jar --insecure "${JENKINS_URL}/jnlpJars/agent.jar"

# Run the agent once - we don't need it to restart due to dynamic nature of the agent
echo "Running the Jenkins agent '${JENKINS_AGENT_NAME}'..."
"${JAVA_HOME}/bin/java" -cp agent.jar hudson.remoting.jnlp.Main -headless \
    -url "${JENKINS_URL}" "${JENKINS_AGENT_SECRET}" "${JENKINS_AGENT_NAME}"

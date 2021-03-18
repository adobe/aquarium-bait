#!/bin/sh -e
# Gets Aquarium Fish resource metadata as env file and lauch the jenkins agent
# The current dir will be used to temporarly store the required files
#
# Usage 1:
#   $ CONFIG_FILE=/some/path.env ./jenkins_agent.sh
# Usage 2:
#   $ NO_FISH=1 JENKINS_URL=url JENKINS_AGENT_SECRET=secret JENKINS_AGENT_NAME=name ./jenkins_agent.sh

root_dir=$(dirname "$0")

# Wait for config file if it's set to use
until [ -z "${CONFIG_PATH}" -o -f "${CONFIG_PATH}" ]; do
    echo "Wait for ${CONFIG_PATH} file..."
    sleep 5
done

# Read config env file from config path
[ ! -f "${CONFIG_PATH}" ] || source "${CONFIG_PATH}"

receiveMetadata() {
    out=$1
    rm -f "$out"
    # Get the list of the gateways, usually like "127.0.0.1 172.16.1.1"
    ifs=$(netstat -rn | grep ' UH' | grep '\.1' | cut -d ' ' -f 1)
    for proto in https http; do
        for interface in ${ifs}; do
            fish_api_url="${proto}://${interface}:8001"
            echo "Checking ${fish_api_url} META API..."

            # TODO: not sure how to properly solve the insecure issue,
            # probably in the future when we will use some corporate CA
            curl -sSLo "$out" --insecure "${fish_api_url}/meta/v1/data/?format=env" || true
            if grep -q '^data_JENKINS_URL' "$out"; then
                echo "Found required metadata in ${fish_api_url}"
                return
            else
                rm -f "$out"
            fi
        done
    done
}

# Looking the available network gateways for Aquarium Fish meta API
until [ "${NO_FISH_API}" ]; do
    receiveMetadata METADATA.env
    if [ -f METADATA.env ]; then
        source METADATA.env
        [ "${JENKINS_URL}" ] || JENKINS_URL=${data_JENKINS_URL}
        [ "${JENKINS_AGENT_SECRET}" ] || JENKINS_AGENT_SECRET=${data_JENKINS_AGENT_SECRET}
        [ "${JENKINS_AGENT_NAME}" ] || JENKINS_AGENT_NAME=${data_JENKINS_AGENT_NAME}
        break
    else
        sleep 5
    fi
done

# Wait for jenkins response
until [ "$(curl -s -o /dev/null -w '%{http_code}' "${JENKINS_URL}")" = '403' ]; do
    echo "Wait for '${JENKINS_URL}' jenkins response..."
    sleep 5
done

# Download the agent jar and connect to jenkins
curl -sSLo agent.jar "${JENKINS_URL}/jnlpJars/agent.jar"

# Run the agent
"${JAVA_HOME}/bin/java" -cp agent.jar hudson.remoting.jnlp.Main -headless \
    -url "${JENKINS_URL}" "${JENKINS_AGENT_SECRET}" "${JENKINS_AGENT_NAME}"

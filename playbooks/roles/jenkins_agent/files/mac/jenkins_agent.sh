#!/bin/sh -e
# Reads env configuration file if it's here, downloads the agent and run it
# The current dir will be used to temporarly store the required files
#
# Usage 1:
#   $ CONFIG_FILE=/some/path.env ./jenkins_agent.sh
# Usage 2:
#   $ JENKINS_URL=url JENKINS_SECRET=secret JENKINS_AGENT_NAME=name ./jenkins_agent.sh

root_dir=$(dirname "$0")

# Wait for config file
until [ -z "${CONFIG_PATH}" -o -f "${CONFIG_PATH}" ]; do
    echo "Wait for ${CONFIG_PATH} file..."
    sleep 5
done

# Read config env file from config path
[ ! -f "${CONFIG_PATH}" ] || source "${CONFIG_PATH}"

# Wait for network init & jenkins response
until [ "$(curl -s -o /dev/null -w '%{http_code}' "${JENKINS_URL}")" = '403' ]; do
    echo "Wait for ${JENKINS_URL} jenkins response..."
    sleep 5
done

# Download jenkins cli to dynamically create/delete a node
curl -sSLo jenkins-cli.jar "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"

# Download the agent jar and connect to jenkins
curl -sSLo agent.jar "${JENKINS_URL}/jnlpJars/agent.jar"

cleanup() {
    "${JAVA_HOME}/bin/java" -jar jenkins-cli.jar -s "${JENKINS_URL}" \
        -auth "agent:${JENKINS_SECRET}" delete-node "${JENKINS_AGENT_NAME}" || true
}

cleanup

# Create agent node on jenkins master
cat "${root_dir}/agent_node.xml.tpl" | "${root_dir}/xml_replace.py" \
    "name=${JENKINS_AGENT_NAME}" \
    "description=${JENKINS_AGENT_DESCRIPTION}" \
    "remoteFS=${JENKINS_AGENT_REMOTE_FS}" \
    "label=${JENKINS_AGENT_LABELS}" | \
    "${JAVA_HOME}/bin/java" -jar jenkins-cli.jar -s "${JENKINS_URL}" \
    -auth "agent:${JENKINS_SECRET}" create-node "${JENKINS_AGENT_NAME}"

# Clean agent on exit
trap cleanup EXIT

# Get jnlp agent token
crumb=$(curl -sSL -u "agent:${JENKINS_SECRET}" "${JENKINS_URL}"'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)')
agent_token=$(curl -sSL -u "agent:${JENKINS_SECRET}" -H "${crumb}" -X GET \
    "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/slave-agent.jnlp" | \
    sed "s/.*<application-desc main-class=\"hudson.remoting.jnlp.Main\"><argument>\([a-z0-9]*\).*/\1/")

# Run the agent
"${JAVA_HOME}/bin/java" -cp agent.jar hudson.remoting.jnlp.Main -headless \
    -url "${JENKINS_URL}" "${agent_token}" "${JENKINS_AGENT_NAME}"

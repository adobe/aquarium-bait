#!powershell
# Runs the Jenkins Agent with help of configuration file or metadata from Fish API
# The current dir is used to temporarly store the required files
#
# Usage 1:
#   ps> $CONFIG_FILE="D:\jenkins_agent.config.ps1" ; ./jenkins_agent.ps1
# Usage 2:
#   ps> $NO_CONFIG_WAIT="1" ; $JENKINS_URL="<url>" ; $JENKINS_AGENT_SECRET="<secret>" ; $JENKINS_AGENT_NAME="<name>" ; ./jenkins_agent.ps1

# Check if CONFIG_FILE var is not set - use the "workspace" labeled disk to read the configuration
if( -not "$CONFIG_FILE" ) {
    $workspace_disk = (Get-Volume -FileSystemLabel "workspace" -ea SilentlyContinue).DriveLetter
    if( "$workspace_disk" ) {
        $CONFIG_FILE = "${workspace_disk}:\config\jenkins_agent.ps1"
    }
}

# Skip the cert validation for Aquarium Fish META api in powershell 5.1
# Not sure how to solve this issue, maybe in the future when we will have the corporate CA
Add-Type @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem)
    {
        return true;
    }
}
'@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;

function receiveMetadata {
    param (
        $out
    )

    # Get the list of gateways to test
    $ifs = Get-NetIPConfiguration | ForEach-Object {
        # Will return first 3 octets of the IP address
        ($_.IPv4Address.IPAddress.split('.')[0,1,2]) -Join '.'
    }
    ForEach( $proto in ('https','http') ) {
        ForEach( $interface in $ifs ) {
            $fish_api_url = "${proto}://${interface}.1:8001"
            echo "Checking ${fish_api_url} META API..."

            try {
                Invoke-WebRequest "${fish_api_url}/meta/v1/data/?format=ps1&prefix=data" -OutFile "$out" -ea SilentlyContinue
            } catch [System.Net.WebException] {
                echo "  ... failed: $($_.Exception.Message)"
            }
            if( Test-Path -Path "$out" -PathType Leaf ) {
                if( Select-String -Path "$out" -Pattern '^\$data_JENKINS_URL' ) {
                    echo "  ... found the required JENKINS_URL metadata"
                    return
                } else {
                    echo "  ... not found the required JENKINS_URL metadata"
                    rm "$out"
                }
            }
        }
    }
}

While( -not "$NO_CONFIG_WAIT" ) {
    # Check the workspace disk configuration exists and load the configuration
    if( "$CONFIG_FILE" -and (Test-Path -Path "$CONFIG_FILE" -PathType Leaf) ) {
        . "$CONFIG_FILE"
    }

    # Try to receive metadata from Fish API on the gateway
    receiveMetadata METADATA.ps1
    if( Test-Path -Path METADATA.ps1 -PathType Leaf ) {
        . .\METADATA.ps1
        if( -not "${JENKINS_URL}" )             { $JENKINS_URL = "${data_JENKINS_URL}" }
        if( -not "${JENKINS_AGENT_SECRET}" )    { $JENKINS_AGENT_SECRET = "${data_JENKINS_AGENT_SECRET}" }
        if( -not "${JENKINS_AGENT_NAME}" )      { $JENKINS_AGENT_NAME = "${data_JENKINS_AGENT_NAME}" }
        if( -not "${JENKINS_AGENT_WORKSPACE}" ) { $JENKINS_AGENT_WORKSPACE = "${data_JENKINS_AGENT_WORKSPACE}" }
    }

    if( "${JENKINS_URL}" -and "${JENKINS_AGENT_SECRET}" -and "${JENKINS_AGENT_NAME}" -and "${JENKINS_AGENT_WORKSPACE}" ) {
        echo "Received all the required variables."
        break
    }
    echo "Waiting for the configuration from '${CONFIG_FILE}' or FISH METADATA API..."
    sleep 5
}


# Wait for jenkins response
While( $true ) {
    $code = try { (Invoke-WebRequest "${JENKINS_URL}").StatusCode } catch { $_.Exception.Response.StatusCode.Value__ }
    if( $code -eq 200 -or $code -eq 403 ) {
        break
    }
    echo "Wait for '${JENKINS_URL}' jenkins response..."
    sleep 5
}

# Go into workspace directory
While( $true ) {
    New-Item -path "${JENKINS_AGENT_WORKSPACE}" -type directory -ea SilentlyContinue
    cd "${JENKINS_AGENT_WORKSPACE}" -ea SilentlyContinue
    if( $pwd = "${JENKINS_AGENT_WORKSPACE}" ) {
        break
    }
    echo "Wait for '${JENKINS_AGENT_WORKSPACE}' dir available..."
    sleep 5
}

# Download the agent jar and connect to jenkins
Invoke-WebRequest "${JENKINS_URL}/jnlpJars/agent.jar" -OutFile agent.jar

# Run the agent once - we don't need it to restart due to dynamic nature of the agent
echo "Running the Jenkins agent '${JENKINS_AGENT_NAME}'..."
& "${env:JAVA_HOME}\bin\java.exe" -cp agent.jar hudson.remoting.jnlp.Main -headless `
    -url "${JENKINS_URL}" "${JENKINS_AGENT_SECRET}" "${JENKINS_AGENT_NAME}"

#!powershell
# Runs the Jenkins Agent with help of configuration file or metadata from Fish API
# The current dir is used to temporarly store the required files
#
# Usage 1:
#   ps> $CONFIG_FILE="D:\jenkins_agent.config.ps1" ; ./jenkins_agent.ps1
# Where content of file is like:
#   $JENKINS_URL="https://..."
#   $JENKINS_AGENT_NAME="test-node"
#   $JENKINS_AGENT_SECRET="abcdef..."
#
# Usage 2 (cloud AWS):
#   ps> $CONFIG_URL="http://169.254.169.254/latest/user-data" ; ./jenkins_agent.ps1
# Where content of the http page is:
#   $JENKINS_URL="https://..."
#   $JENKINS_AGENT_NAME="test-node"
#   $JENKINS_AGENT_SECRET="abcdef..."
#
# Usage 3:
#   ps> $NO_CONFIG_WAIT="1" ; $JENKINS_URL="<url>" ; $JENKINS_AGENT_SECRET="<secret>" ; $JENKINS_AGENT_NAME="<name>" ; ./jenkins_agent.ps1

if( "${env:CONFIG_URL}" ) {
    $CONFIG_URL = $env:CONFIG_URL
    $env:CONFIG_URL = ''
}

if( "${env:CONFIG_FILE}" ) {
    $CONFIG_FILE = $env:CONFIG_FILE
    $env:CONFIG_FILE = ''
}

# Check if CONFIG_FILE var is not set - use the "workspace" labeled disk to read the configuration
if( -not "$CONFIG_FILE" ) {
    $workspace_disk = (Get-Volume -FileSystemLabel "workspace" -ea SilentlyContinue).DriveLetter
    if( "$workspace_disk" ) {
        $CONFIG_FILE = "${workspace_disk}:\config\jenkins_agent.ps1"
    }
}

# Will increase the Invoke-WebRequest downloading dramatically
$ProgressPreference = 'SilentlyContinue'

# Skip the cert validation for Aquarium Fish META api in powershell 5.1
# It's an appropriate solution because just allows to connect the controlled host services
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
$default_cp = [System.Net.ServicePointManager]::CertificatePolicy;
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy;

function getConfigUrls {
    # Prepare a list of the gateway endpoints to locate Fish API host

    # In case CONFIG_URL is set - use only it
    if( "$CONFIG_URL" ) {
        echo "$CONFIG_URL"
        return
    }

    # If CONFIG_URL is empty then we list the available gateways to eventually get Fish API response
    # Get the list of the gateways, usually like "127.0.0 172.16.1"
    # Get the list of gateways to test
    $ifs = Get-NetIPConfiguration | ForEach-Object {
        # Will return first 3 octets of the IP address
        ($_.IPv4Address.IPAddress.split('.')[0,1,2]) -Join '.'
    }
    ForEach( $interface in $ifs ) {
        echo "https://${interface}.1:8001/meta/v1/data/?format=ps1"
    }
}

function receiveMetadata {
    param (
        $out
    )

    # Get the list of gateways to test
    $ifs = Get-NetIPConfiguration | ForEach-Object {
        # Will return first 3 octets of the IP address
        ($_.IPv4Address.IPAddress.split('.')[0,1,2]) -Join '.'
    }
    getConfigUrls | ForEach-Object -Process {
        $url = $_
        echo "Checking ${url} META API..."

        try {
            Invoke-WebRequest "${url}" -OutFile "$out" -ea SilentlyContinue
        } catch [System.Net.WebException] {
            echo "  ... failed: $($_.Exception.Message)"
        }
        if( Test-Path -Path "$out" -PathType Leaf ) {
            if( Select-String -Path "$out" -Pattern '^\$JENKINS_URL' ) {
                echo ("  ... found jenkins agent config: " + (Select-String -Path "$out" -Pattern '^\$JENKINS_URL'))
                return
            }
            if( Select-String -Path "$out" -Pattern '^\$CONFIG_URL' ) {
                echo ("  ... found new config url: " + (Select-String -Path "$out" -Pattern '^\$CONFIG_URL'))
                return
            }
            echo "  ... no useful configs found"
            rm "$out"
        }
    }
}

echo ('Init jenkins agent script ' + (Get-Date -Format "yy.MM.dd HH:mm:ss"))

While( -not "$NO_CONFIG_WAIT" ) {
    # Check the workspace disk configuration exists and load the configuration
    if( "$CONFIG_FILE" -and (Test-Path -Path "$CONFIG_FILE" -PathType Leaf) ) {
        . "$CONFIG_FILE"
    }

    # Try to receive metadata from Fish API on the gateway
    receiveMetadata METADATA.ps1
    if( Test-Path -Path METADATA.ps1 -PathType Leaf ) {
        . .\METADATA.ps1
    }

    if( "${JENKINS_URL}" -and "${JENKINS_AGENT_SECRET}" -and "${JENKINS_AGENT_NAME}" ) {
        echo "Received all the required variables."
        break
    }
    echo "Waiting for the configuration from '${CONFIG_FILE}' or FISH METADATA API..."
    sleep 5
}

# Set the flags to use in case the jenkins server https is not trusted (local env for example)
# Just passing the jenkins server cert will often not work because the SAN/CN will not match
if( "$JENKINS_HTTPS_INSECURE" -eq "true" ) {
    $jenkins_insecure = "-disableHttpsCertValidation"
    # Use the saved certificate policy to restore the validation
    [System.Net.ServicePointManager]::CertificatePolicy = $default_cp;
}

# Go into custom workspace directory if it's set
if( "${JENKINS_AGENT_WORKSPACE}" ) {
    While( $true ) {
        New-Item -path "${JENKINS_AGENT_WORKSPACE}" -type directory -ea SilentlyContinue
        cd "${JENKINS_AGENT_WORKSPACE}" -ea SilentlyContinue
        if( "$pwd" -eq "$JENKINS_AGENT_WORKSPACE" ) {
            break
        }
        echo "Wait for '${JENKINS_AGENT_WORKSPACE}' dir available..."
        sleep 5
    }
}

# Download the agent jar
While( $true ) {
    try {
        Invoke-WebRequest "${JENKINS_URL}/jnlpJars/agent.jar" -OutFile agent.jar
        if (Test-Path agent.jar) {
            $fileSize = (Get-Item agent.jar).Length
            if ($fileSize -gt 0) {
                break
            }
        }
    } catch {  }
    echo "Wait for '${JENKINS_URL}' jenkins response..."
    sleep 5
}

# Run the agent once - we don't need it to restart due to dynamic nature of the agent
echo "Running the Jenkins agent '${JENKINS_AGENT_NAME}'..."
& "${env:JAVA_HOME}\bin\java.exe" ${env:JAVA_OPTS} -cp agent.jar hudson.remoting.jnlp.Main -headless `
    ${jenkins_insecure} -url "${JENKINS_URL}" "${JENKINS_AGENT_SECRET}" "${JENKINS_AGENT_NAME}"

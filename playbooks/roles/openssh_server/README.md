# OpenSSH Server role

The role installs OpenSSH on the remote machine, can listen on multiple ports and replaces winrm if
uses port 5986.

Primarily created for Windows because all other systems already have it. SSH proven to be much
faster transport than WinRM and it actually unifies the infrastructure access so quite benificial.

## Tasks

* Install SSHd

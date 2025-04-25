# Github runner role

This role setup github user and automatic service retreiver of github runner agent from github.com

## Tasks

* Setup github user
* Creates retreiver & runner of service for github runner

## WARNING

This role makes your build environment exposed to github.com, means you will have not much choice,
but allow your firewalls to allow github.com connections with the potential leaking of your IP to
github.com public repos if you're not protecting your automation properly. One solution could be
is to install MITM proxy to intercept not-approved repositories connections, but unfortunately
there is no ready-to-use solution for that.

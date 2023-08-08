# Special container to be used as network isolation with access just to the host.docker.internal
# It's really needed on macos, because there is no particularly good way to isolate docker builds
# Usage:
#   1. Build it:
#     $ docker build --tag bait_proxy ./init/docker/bait_proxy
#   2. Start as:
#     $ docker run --rm -it --cap-add=NET_ADMIN --name bait_proxy bait_proxy
#   3. Use it in another container:
#     $ docker run --rm -it --net=container:bait_proxy ubuntu:20.04
ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG APT_URL
ARG APT_SEC_URL

# It doesn't really like the https when there is no ca-certificates soo...
RUN ( [ -z "${APT_URL}" -a -z "${APT_SEC_URL}" ] || echo 'Acquire { https::Verify-Peer false }' > /etc/apt/apt.conf.d/99tmp-verify-peer.conf ) && \
    ( [ -z "${APT_URL}" ] || sed -i "s|http://archive.ubuntu.com/|${APT_URL}|g" /etc/apt/sources.list ) && \
    ( [ -z "${APT_SEC_URL}" ] || sed -i "s|http://security.ubuntu.com/|${APT_SEC_URL}|g" /etc/apt/sources.list ) && \
    apt update && apt install -y iptables dnsutils && rm -rf /var/lib/apt/lists/*

# Executing the commands to isolate the network
ENTRYPOINT sh -xc 'iptables -P INPUT DROP && \
    iptables -P OUTPUT DROP && \
    iptables -P FORWARD DROP && \
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT && \
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT && \
    iptables -A INPUT -d $(dig host.docker.internal +short | grep -o ".*" || echo "172.17.0.1")/32 -p tcp -m tcp -j ACCEPT && \
    iptables -A OUTPUT -d $(dig host.docker.internal +short | grep -o ".*" || echo "172.17.0.1")/32 -p tcp -m tcp -j ACCEPT && \
    cat -'

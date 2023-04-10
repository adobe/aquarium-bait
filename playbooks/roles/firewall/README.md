# Firewall role

The firewall role allows to unify the firewall rules across the operating systems (Lin, Mac, Win).

By Aquarium design those firewall rules should not be baked into the image, because the outside env
could change in time which will make the image useless in new conditions. But still could help
someone to apply the firewall rules in more or less common way.

By default the firewall is blocking new connections, but allows to add allowlist of rules to
enable environment to connect to those specific services.

## Tasks

* Enable firewall
* Cleanup the existing outgoing firewall rules
* Set outgoing firewall rules
* Block all new outgoing connections except for the created rules
* Optionally modify the hosts file to contain the hosts needed (useful with no dns access)

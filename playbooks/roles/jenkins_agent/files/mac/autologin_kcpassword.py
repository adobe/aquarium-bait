#!/usr/bin/env python3
# The script generates /etc/kcpassword file to enable user autologin along with
# writing default username to com.apple.loginwindow.plist

import sys

passwd = input().strip()
key = [125, 137, 82, 35, 210, 188, 221, 234, 163, 185, 31]
key_len = len(key)

passwd = [ord(x) for x in list(passwd)]

r = len(passwd) % key_len

if r > 0:
    passwd += [0] * (key_len - r)

for i in range(0, len(passwd), len(key)):
    ki = 0
    for j in range(i, min(i + len(key), len(passwd))):
        passwd[j] = passwd[j] ^ key[ki]
        ki += 1

passwd = [chr(x) for x in passwd]
final_key = "".join(passwd)
fd = open("/etc/kcpassword", "w", 0o600)
fd.write(final_key)
fd.close()

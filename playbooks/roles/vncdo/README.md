# VNCDo rle

Role allows to run vnc commands from the local machine to interact with VM UI

## Tasks

## Usage

Look at the documentation here: https://vncdotool.readthedocs.io/en/latest/usage.html and check the
keymap in the sources: https://github.com/sibson/vncdotool/blob/v0.13.0/vncdotool/client.py#L21

```
- name: Execute vncdo in case installation failed to allow kernel extensions
  include_role:
    name: vncdo
  vars:
    vncdo_template: system_preferences_security_vendor_allow.vdo

- name: Execute vncdo to login
  include_role:
    name: vncdo
  vars:
    vncdo_script: |
      # Login to default user
      pause 60 type "{{ ansible_sudo_pass }}" key enter
```

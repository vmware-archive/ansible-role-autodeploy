# ansible-role-autodeploy

[Ansible](https://github.com/ansible/ansible) module for installing,
configuring and manipulating VMware AutoDeploy.

## Requirements

This role currently supports Debian/Ubuntu and CentOS distros.

The role also requires a valid install of PowerCLI.

## Role Variables

*TODO*: Documentation here is under way . . .

## Example playbook

```yaml
---
- name: prepare vcenter for autodeploy
  hosts: vcsa
  remote_user: root
  roles:
    - autodeploy
  vars:
    - autodeploy_vcsa: true
    - autodeploy_rules: false
  vars_files:
    - /var/lib/chaperone/answerfile.yml

- name: prepare autodeploy rules
  hosts: ruleshost
  roles:
    - autodeploy
  vars:
    - autodeploy_vcsa: false
    - autodeploy_rules: true
    - ansible_ssh_user: administrator
    - ansible_ssh_pass: VMware1!
    - ansible_ssh_port: 5986
    - ansible_connection: winrm
  vars_files:
    - /var/lib/chaperone/answerfile.yml
```

# License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.
SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only

This code is Dual Licensed Apache License 2.0 or GPLv3

You may obtain a copy of the License(s) at

    http://www.apache.org/licenses/LICENSE-2.0

    or

    https://www.gnu.org/licenses/gpl-3.0.en.html

## Author Information

This role was created in 2015 by [Jake Dupuy / VMware](http://www.vmware.com/).

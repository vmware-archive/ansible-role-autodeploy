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
 
Copyright 2015 VMware, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Author Information

This role was created in 2015 by [Jake Dupuy / VMware](http://www.vmware.com/).

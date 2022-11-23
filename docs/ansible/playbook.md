# Playbooks

*Playbooks* are first thing you think of when using Ansible. This section describes some good practices.  

## Directory structure

The *main* playbook should have a recognizable name, e.g. referencing the projects name or scope.
If you have multiple playbooks, create a new folder `playbooks` and store all playbooks there, except the *main* playbook (here called `site.yml`).

```bash
.
├── ansible.cfg
├── site.yml
└── playbooks
    ├── database.yml
    ├── loadbalancer.yml
    └── webserver.yml
```

The `site.yml` file contains references to the other playbooks:

```yaml
---
# Main playbook including all other playbooks

- import_playbook: playbooks/database.yml
- import_playbook: playbooks/webserver.yml
- import_playbook: playbooks/loadbalancer.yml
```

The *lower-level* playbooks contains actual [*plays*](playbook.md#plays):

```yaml
---
# playbooks/database

- name: Install and configure PostgreSQL database
  hosts: postgres_servers
  roles:
    - postgres

```

To be able to run the overall playbook, as well as the imported playbooks, add this parameter to your `ansible.cfg`, otherwise roles are not found:

```ini
[defaults]
roles_path = .roles
```

## Playbook definition

Don't put too much logic in your playbook, put it in your roles (or even in custom modules).  
A playbook **could** contain `pre_tasks`, `roles`, `tasks` and `post_tasks` sections, try to limit your playbooks to a **list of a roles**. 

!!! warning
    Avoid using both *roles* and *tasks *sections, the latter possibly containing `import_role` or `include_role` tasks. The order of execution between *roles* and *tasks* isn’t obvious, and hence mixing them should be avoided.  

Either you need only static importing of roles and you can use the roles section, or you need dynamic inclusion and you should use only the tasks section. Of course, for very simple cases, you can just use tasks without roles (but playbooks/projects grow quickly, refactor to roles early).

### Plays

Avoid putting multiple plays in a playbook, if not really necessary. As every play most likely targets a different host group, create a separate playbook file for it. This way you achieve to most flexibility.

```yaml
# file k8s-installation.yml
- name: Initialize Control-Plane Nodes
  hosts: kubemaster
  become: true
  roles:
    - k8s-control-plane

- name: Install and configure Worker Nodes
  hosts: kubeworker
  become: true
  roles:
    - k8s-worker-nodes
```

Separate the two plays into their respective playbooks files and reference them in an overall playbook file:

```yaml
# file k8s-control-plane-playbook.yml
- name: Initialize Control-Plane Nodes
  hosts: kubemaster
  become: true
  roles:
    - k8s-control-plane
```

```yaml
# file k8s-worker-node-playbook.yml
- name: Install and configure Worker Nodes
  hosts: kubeworker
  become: true
  roles:
    - k8s-worker-nodes
```

```yaml
# file k8s-installation.yml

- import_playbooks: k8s-control-plane-playbook.yml
- import_playbooks: k8s-worker-node-playbook.yml
```
# Playbooks

## Directory structure

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

The *lower-level* playbooks contain actual *plays*:

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

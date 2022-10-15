# Project

## Version Control
Keep your playbooks and inventory file in git (or another version control system), and commit when you make changes to them. This way you have an audit trail describing when and why you changed the rules that are automating your infrastructure.

!!! tip
    Always use version control!

## Ansible configuration

Always use a project-specific `ansible.cfg` in the parent directory of your project. The following configuration can be used as a starting point:

```ini
inventory = inventory/production.ini

# Playbook-Output in YAML instead of JSON, needs additional collection
stdout_callback = community.general.yaml

```

## Dependencies

Your project will have certain dependencies, make sure to provide a `requirements.yml` for necessary Ansible collections and a `requirements.txt` for necessary Python packages.  
Consider using [*Execution Environments*](installation.md#execution-environments) where all dependencies are combined in a Container Image.

### Collections

Always provide a `requirements.yml` with **all** collections used within your project.  
This makes sure that required collections can be installed, if only the *ansible-core* binary is installed.

```yaml
---
collections:
  - community.general
  - ansible.posix
  
  - name: cisco.ios
    version: '>=3.1.0'  
```

Install all collections from the *requirements*-file:

```bash
ansible-galaxy collection install -r requirements.yml
```

### Python packages

Always provide a `requirements.txt` with **all** Python packages need by modules used within your project.

```txt
boto
openshift>=0.6
PyYAML>=3.11
```

Install all dependencies from the *requirements*-file:

```bash
pip3 install -r requirements.txt
```

## Directory structure

```bash

```
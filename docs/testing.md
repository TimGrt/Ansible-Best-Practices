# Testing


!!! warning
    **Work in Progress** - More description necessary.

## Molecule

Molecule project is designed to aid in the development and testing of Ansible roles, provides support for testing with multiple instances, operating systems and distributions, virtualization providers, test frameworks and testing scenarios.  
Molecule is mostly used to test roles in isolation (although it is possible to test multiple roles or playbooks at once). To test against a fresh system, molecule uses Docker to provision virtualized test hosts, run commands on them and assert the success. Molecule does not connect via ssh to the container, instead it uses an Ansible installation inside the container. It is therefor necessary to use a custom build container image. 

Take a look at the [Molecule documentation](https://molecule.readthedocs.io/en/latest/index.html#){ target="_blank" } for a full overview.

### Installation

The described configuration below expects the Docker container runtime on the Ansible Controller (other drivers are available), the binary and dependencies are installed through the *Python package manager*.  
Use a *Python Virtual environment* (requires the `python3-venv` package) to encapsulate the installation from the rest of your Controller.

```bash
python3 -m venv molecule-venv
```

Activate the VE:

```bash
source molecule-virtualenv/bin/activate
```

Install dependencies (an own Ansible is necessary, `ansible-lint` is optional, but useful):

```bash
pip3 install --upgrade pip
pip3 install ansible-core
pip3 install molecule==3.5.2
pip3 install molecule-docker
pip3 install ansible-lint
```

!!! note
    Currently (21.05.2022), there is a bug when trying to login with `molecule login` command. Use version 3.5.2 of the molecule package!

Python package `molecule-docker` requires the modules of the *community.docker* collection. When you only installed `ansible-core`, you'll need to install the collection separately:

```bash
ansible-galaxy collection install community.docker
```

Use `deactivate` to leave your VE.

### Configuration


You may use these example as a starting point. It expects that the [Docker image](https://hub.docker.com/r/timgrt/centos7-ansible) is already present (use `docker pull timgrt/centos7-ansible`) and `ansible-lint` is installed. See the install instructions above.

=== "Central Molecule configuration"
    !!! example "molecule.yml"
        ```yaml
        ---
        # For more information regarding the used container image, see https://hub.docker.com/r/timgrt/centos7-ansible

        driver:
          name: docker
        platforms:
          - name: instance1
            groups:
              - molecule
            image: timgrt/centos7-ansible:latest
            tmpfs:
              - /run
              - /tmp
            volumes:
              - /sys/fs/cgroup:/sys/fs/cgroup:ro
            privileged: true
            command: "/usr/sbin/init"
            pre_build_image: true
        provisioner:
          name: ansible
          options:
            D: true
          connection_options:
            ansible_user: ansible
          config_options:
            defaults:
              interpreter_python: auto_silent
              callback_whitelist: profile_tasks, timer, yaml
              stdout_callback: yaml
          inventory:
            links:
              group_vars: ../../../../inventory/group_vars/
        lint: |
          set -e
          ansible-lint .
        scenario:
          create_sequence:
            - create
            - prepare
          converge_sequence:
            - create
            - prepare
            - converge
            - lint
          test_sequence:
            - destroy
            - create
            - prepare
            - converge
            - idempotence
            - lint
            - destroy
          destroy_sequence:
            - destroy
        ```
=== "Playbook file"
    !!! example "converge.yml"
        The *role* to test must be defined here, change `role-name` to the actual name.
        ```yaml
        ---
        - name: Converge
          hosts: molecule
          become: true
          roles:
            - role-name
        ```
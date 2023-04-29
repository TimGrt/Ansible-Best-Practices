# Testing

With many people contributing to the automation, it is crucial to test the automation content in-depth. So when you’re developing new Ansible Content like playbooks, roles and collections, it’s a good idea to test the content in a test environment before using it to automate production infrastructure. Testing ensures the automation works as designed and avoids unpleasant surprises down the road.  
Testing automation content is often a challenge, since it requires the deployment of specific testing infrastructure as well as setting up the testing conditions to ensure the tests are relevant.

Consider the following list for testing your Ansible content, with increasing complexity:

1. yamllint
2. ansible-playbook --syntax-check
3. ansible-lint
4. molecule test
5. ansible-playbook --check (*against production*)
6. Parallel infrastructure

## Syntax check

The whole playbook (and all roles and tasks) need to, minimally, pass a basic ansible-playbook syntax check run.

```bash
ansible-playbook main.yml --syntax-check
```

Running this as a step in a CI Pipeline is advisable.

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
pip3 install molecule
pip3 install molecule-docker
pip3 install ansible-lint
```

!!! note
    Currently (21.05.2022), there is a bug when trying to login with `molecule login` command. Use version 3.5.2 of the molecule package!  
    This is fixed in version 4.0.3, update if possible.

Python package `molecule-docker` requires the modules of the *community.docker* collection. When you only installed `ansible-core`, you'll need to install the collection separately:

```bash
ansible-galaxy collection install community.docker
```

Use `deactivate` to leave your VE.

### Configuration

You may use these example configurations as a starting point. It expects that the [Docker image](https://hub.docker.com/r/timgrt/centos7-ansible) is already present (use `docker pull timgrt/centos7-ansible`) and `ansible-lint` is installed. See the install instructions above.

The *molecule* configuration files are kept in the role folder you want to test. Create the directory `molecule/default` and at least the `molecule.yml` and `converge.yml`:

```bash hl_lines="5 6 7 8"
roles/
└── webserver-demo
    ├── defaults
    │   └── main.yml
    ├── molecule
    │   └── default
    │       ├── converge.yml
    │       └── molecule.yml
    ├── tasks
    │   └── main.yml
    └── templates
        └── index.html
```

=== "Central Molecule configuration"
    !!! example "molecule.yml"

        ```yaml
        ---
        driver:
          name: docker
        platforms: # (1)!
          - name: instance1 # (2)!
            groups: # (3)!
              - molecule
            image: timgrt/centos7-ansible:latest # (4)!
            tmpfs:
              - /run
              - /tmp
            volumes:
              - /sys/fs/cgroup:/sys/fs/cgroup:ro
            privileged: true
            cgroupns_mode: host
            command: "/usr/sbin/init"
            pre_build_image: true # (5)!
        provisioner:
          name: ansible
          options:
            D: true # (6)!
          connection_options:
            ansible_user: ansible # (7)!
          config_options:
            defaults:
              interpreter_python: auto_silent
              callback_whitelist: profile_tasks, timer, yaml # (8)!
          inventory:
            links:
              group_vars: ../../../../inventory/group_vars/ # (9)!
        lint: | # (10)!
          set -e
          ansible-lint .
        scenario: # (11)!
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
            - converge
            - idempotence
            - lint
            - destroy
          destroy_sequence:
            - destroy
        ```

        1. List of hosts to provision by *molecule*, copy the list item and use a unique name if you want to deploy multiple containers.
        2. The *name* of your container, for better identification you could use e.g. `demo.${USER}.molecule` which uses your username from environment variable    substitution, showing who deployed the container for what purpose.
        3. Additional *groups* the host should be part of, using a custom `molecule` group for referencing in `converge.yml`.  
        If you want your container to inherit variables from *group_vars* (see *inventory.links.group_vars* in the *provisioner* section), add the group(s) to this list.
        4. For more information regarding the used container image, see [https://hub.docker.com/r/timgrt/centos7-ansible](https://hub.docker.com/r/timgrt/centos7-ansible){:target="_blank"}
        5. Container image must be present before running Molecule, pull it with `docker pull timgrt/centos7-ansible`
        6. Enables *diff* mode, set to `false` if you don't want that.
        7. Uses the *ansible* user to connect to the container (defined in the container image), this way you can test with `become`. Otherwise you would connect with the *root* user, most likely this is not what you would do in production.
        8. Adds a timer to every task and the overall playbook run, as well as formatting the Ansible output to YAML for better readability.  
        Install necessary collections with `ansible-galaxy collection install ansible.posix community.general`.
        9. If you want your container to inherit variables from *group_vars*, reference the location of your *group_vars* (here they are stored in the subfolder *inventory* of the project, searching begins in the scenario folder *defaults*). Delete the *inventory* key and all content if you don't need this.
        10. This runs the Best-Practice checker *ansible-lint* in the *converge* and *test* sequence, must be installed separately, see [Linting](linting.md) for more information.
        11. A scenario allows Molecule to test a role in a particular way, these are the stages when executing Molecule.  
        For example, running `molecule converge` would create a container (if not already created), prepare it (if not already prepared), run the *converge* stage and lint the role.  
        Remove the list items you don't need if necessary.

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

=== "Preparation stage"
    !!! example "prepare.yml"
        Adds an **optional** preparation stage (referenced by `prepare` in the *scenario* definition).  
        For example, if you want to test SSH Key-Pair creation in your container (this is also used by the *user* module to create SSH keys), install the necessary packages before running the role itself.

        ```yaml
        ---
        - name: Prepare
          hosts: molecule
          become: true
          tasks:
            - name: Install OpenSSH for ssh-keygen
              ansible.builtin.yum:
                name: openssh
                state: present
        ```

        Remember, you are using a Docker image, not every package from the distribution is installed by default to minimze the image size.

=== "Verification"
    !!! example "verify.yml"
        Adds an **optional** verification stage (referenced by `verify` in the *scenario* definition). **Not used in the example above.**

        Add this block to your `molecule.yml` as a top-level key:

        ```yaml
        verifier:
          name: ansible
        ```

        The `verify.yml` contains your tests for your role.

        ```yaml
        ---
        - name: Verify
          hosts: molecule
          become: true
          tasks:
            - name: Get service facts
              ansible.builtin.service_facts:

            # Service may have started, returning 'OK' in the service module, but may have failed later.
            - name: Ensure that MariaDB is in running state
              assert:
                that:
                  - ansible_facts['services']['mariadb.service']['state'] == 'running'
        ```

        Other *verifiers* like *testinfra* can be used.

### Usage

Molecule is executed from within the role you want to test, change directory:

```bash
cd roles/webserver-demo
```

From here, run the molecule scenario.

To only create the defined containers, but not run the Ansible tasks:

```bash
molecule create
```

To run the Ansible tasks of the role (if the container does not exist, it will be created):

```bash
molecule converge
```

To execute a full test circle (existing containers are deleted, re-created and Ansible tasks are executed, containers are deleted(!) afterwards):

```bash
molecule test
```

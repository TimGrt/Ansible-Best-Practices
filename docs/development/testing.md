<!-- markdownlint-disable MD024 -->
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

```console
ansible-playbook main.yml --syntax-check
```

Running this as a step in a CI Pipeline is advisable.

## Linting

Take a look at the [Linting section](linting.md) for further information.

## Molecule

The *Molecule* project is designed to aid in the development and testing of Ansible roles, provides support for testing with multiple instances, operating systems and distributions, virtualization providers, test frameworks and testing scenarios.  
Molecule is mostly used to test roles in isolation (although it is possible to test multiple roles or playbooks at once). To test against a fresh system, molecule uses a container runtime to provision virtualized/containerized test hosts, runs commands on them and asserts the success.  
By default, Containers don't allow services to be installed, started and stopped as in a virtual machine. We will be using custom *systemd-enabled* images, which are designed to run an init system as PID 1 for running multi-services inside the container. Also, some additional configuration is needed in the Molecule configuration file as shown below.

Take a look at the [Molecule documentation](https://ansible.readthedocs.io/projects/molecule/){ target="_blank" } for a full overview.

### Installation

The described configuration below expects the *Podman* container runtime on the Ansible Controller (other drivers like *Docker* are available). You can install Podman with the following command:

```console
sudo apt install podman
```

The *Molecule* binary and dependencies are installed through the *Python package manager*, you'll need a fairly new Python version (*Python >= 3.10* with *ansible-core >= 2.12*).  
Use a *Python Virtual environment* (requires the `python3-venv` package) to encapsulate the installation from the rest of your Controller.

```console
python3 -m venv molecule-venv
```

Activate the VE:

```console
source molecule-venv/bin/activate
```

Install dependencies, after upgrading pip:

```console
pip3 install --upgrade pip setuptools
```

```console
pip3 install ansible-core molecule molecule-plugins[podman]
```

Molecule plugins contains the following provider:

* azure
* containers
* docker
* ec2
* gce
* podman
* vagrant

!!! note
    The Molecule Podman provider requires the modules of the *containers.podman* collection (as it provisions the containers with Ansible itself).  
    If you only installed `ansible-core`, you'll need to install the collection separately:

    ```console
    ansible-galaxy collection install containers.podman
    ```

If you are done with Molecule testing, use `deactivate` to leave your VE.

### Configuration

The *molecule* configuration files are kept in the role folder you want to test. Create the directory `molecule/default` and at least the `molecule.yml` and `converge.yml`:

``` { .console .no-copy .hl_lines="5 6 7 8" }
roles/
└── webserver_demo
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

You may use these example configurations as a starting point. It expects that the Container image is already present (use `podman pull docker.io/timgrt/rockylinux9-ansible:latest`).

=== "Central Molecule configuration"
    !!! example "molecule.yml"

        ```yaml
        ---
        driver:
          name: podman
        platforms: # (1)!
          - name: instance1 # (2)!
            groups: # (3)!
              - molecule
              - rocky
            image: docker.io/timgrt/rockylinux9-ansible:latest # (4)!
            volumes:
              - /sys/fs/cgroup:/sys/fs/cgroup:ro
            command: "/usr/sbin/init"
            pre_build_image: true # (5)!
            exposed_ports:
              - 80/tcp
            published_ports: # (6)!
              - 8080:80/tcp
        provisioner:
          name: ansible
          options:
            D: true # (7)!
          connection_options:
            ansible_user: ansible # (8)!
          config_options:
            defaults:
              interpreter_python: auto_silent
              callbacks_enabled: ansible.posix.profile_tasks, ansible.posix.timer # (9)!
              callback_result_format: yaml # (10)!
              roles_path: "$MOLECULE_PROJECT_DIRECTORY/.." # (11)!
          inventory:
            links:
              group_vars: ../../../../inventory/group_vars/ # (12)!
        scenario: # (13)!
          create_sequence:
            - create
            - prepare
          converge_sequence:
            - create
            - prepare
            - converge
          test_sequence:
            - destroy
            - create
            - converge
            - idempotence
            - destroy
          destroy_sequence:
            - destroy
        ```

        1. List of hosts to provision by *molecule*, copy the list item and use a unique name if you want to deploy multiple containers. In the following example one Container with Rocky Linux 8 and one Ubuntu 20.04 container are provisioned.
            ```yaml
              - name: rocky8-instance1
                image: docker.io/timgrt/rockylinux9-ansible:latest
                volumes:
                  - /sys/fs/cgroup:/sys/fs/cgroup:ro
                tmpfs:
                  - /run
                  - /tmp
                command: "/usr/sbin/init"
                pre_build_image: true
                groups:
                  - molecule
                  - rocky
              - name: ubuntu2004
                image: docker.io/timgrt/ubuntu2004-ansible:latest
                volumes:
                  - /sys/fs/cgroup:/sys/fs/cgroup:ro
                command: "/lib/systemd/systemd"
                pre_build_image: true
                groups:
                  - molecule
                  - ubuntu
            ```
        2. The *name* of your container, for better identification you could use e.g. `demo.${USER}.molecule` which uses your username from environment variable    substitution, showing who deployed the container for what purpose.
        3. Additional *groups* the host should be part of, using a custom `molecule` group for referencing in `converge.yml`.  
        If you want your container to inherit variables from *group_vars* (see *inventory.links.group_vars* in the *provisioner* section), add the group(s) to this list.
        4. For more information regarding the used container image, see [https://hub.docker.com/r/timgrt/rockylinux9-ansible](https://hub.docker.com/r/timgrt/rockylinux9-ansible){:target="_blank"}. The image provides a *systemd-enabled* environment, this ensures you can install and start services with *systemctl* as in any normal VM.  
        Some more useful images are:
            * [Rocky Linux 8](https://hub.docker.com/r/timgrt/rockylinux8-ansible){ target="_blank" }
            * [Fedora 39](https://hub.docker.com/r/timgrt/fedora37-ansible){ target="_blank" }
            * [Ubuntu 20.04](https://hub.docker.com/r/timgrt/ubuntu2004-ansible){ target="_blank" }
            * [Debian 10](https://hub.docker.com/r/timgrt/debian10-ansible){ target="_blank" }
            * [OpenSuse 15](https://hub.docker.com/r/timgrt/opensuse15-ansible){ target="_blank" }
            * [RHEL 8](https://github.com/TimGrt/rhel8-molecule-test-image/pkgs/container/rhel8-molecule-test-image){ target="_blank" }
        5. Container image must be present before running Molecule, pull it with `podman pull docker.io/timgrt/rockylinux9-ansible:latest`
        6. When running a webserver inside the container (on port 80), this will publish the container port 80 to the host port 8080. Now, you can check the webserver content by using `http://localhost:8080` (or use the IP of your host).
        7. Enables *diff* mode, set to `false` if you don't want that.
        8. Uses the *ansible* user to connect to the container (must be available in the container image!), this way you can test with `become`. Otherwise you would connect with the *root* user, most likely this is not what you would do in production.
        9. Adds a timer to every task and the overall playbook run, as well as formatting the Ansible output to YAML for better readability.  
        Install necessary collection with `ansible-galaxy collection install ansible.posix`.
        10. Formats the output to YAML format.
        11. Necessary parameter to find the role to test, when not storing the role in a collection and using the `extensions` folder.
        12. If you want your container to inherit variables from *group_vars*, reference the location of your *group_vars* (here they are stored in the subfolder *inventory* of the project, searching begins in the scenario folder *defaults*). Delete the *inventory* key and all content if you don't need this.
        13. A scenario allows Molecule to test a role in a particular way, these are the stages when executing Molecule.  
        For example, running `molecule converge` would create a container (if not already created), prepare it (if not already prepared) and run the *converge* stage/playbook.  

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
              ansible.builtin.package:
                name: openssh
                state: present
        ```

        Remember, you are using a Container image, not every package from the distribution is installed by default to minimize the image size.

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

```console
cd roles/webserver_demo
```

From here, run the molecule scenario, after activating your Python VE with molecule:

```console
source molecule-venv/bin/activate
```

To only create the defined containers, but not run the Ansible tasks:

```console
molecule create
```

To run the Ansible tasks of the role (if the container does not exist, it will be created):

```console
molecule converge
```

To execute a full test circle (existing containers are deleted, re-created and Ansible tasks are executed, containers are deleted(!) afterwards):

```console
molecule test
```

If you want to login to a running container instance:

```console
molecule login
```

## Minimal testing environment

!!! tip
    This is meant as a *quick and dirty* testing or demo environment only, for anything more sophisticated, use [Molecule](testing.md#molecule) (as you most likely will be moving your content into one or more roles anyway).

You'll miss out on the convenient and frankly easy to use possibilities of *Molecule*, but, if you just need a small environment for testing your Ansible content without impacting your Ansible Control Node, the following setup spins up a small one in (Podman) containers. You will need Podman and Ansible (naturally), but nothing else.

### Installation

You can install Podman with the following command:

```console
sudo apt install podman
```

The playbook to create the testing instances uses the *containers.podman* collection, if you only installed `ansible-core`, you'll need to install the collection separately:

```console
ansible-galaxy collection install containers.podman
```

### Configuration

Copy the three files in the separate tabs, a playbook for creating the testing environment, an inventory file defining the testing instances and a small demo playbook which can be used to test your Ansible content.

=== "Create test environment"
    !!! example "testing_environment.yml"

        ```yaml
        ---
        - name: Create or delete demo environment for local testing
          hosts: localhost
          connection: local
          vars:
            testing_image: docker.io/timgrt/rockylinux9-ansible:latest
          tasks:
            - name: "{{ (delete | default(false)) | ternary('Delete', 'Create') }} demo instance"
              containers.podman.podman_container:
                name: "{{ item }}"
                hostname: "{{ item }}"
                image: "{{ testing_image }}"
                volumes:
                  - /sys/fs/cgroup:/sys/fs/cgroup:ro
                command: "/usr/sbin/init"
                state: "{{ (delete | default(false)) | ternary('absent', 'started') }}"
              loop: "{{ groups['test'] }}"
        ```

=== "Testing inventory"
    !!! example "testing_inventory.yml"
        Add additional instances in the `test` group, if necessary.

        ```yaml
        [test]
        instance1

        [test:vars]
        ansible_user=ansible
        ansible_connection=podman
        ```

=== "Testing Playbook"
    !!! example "testing_inventory.yml"
        Add your tasks to this playbook and start testing. If you want to use your own playbook, target the `test` group as well.

        ```yaml
        ---
        - name: Testing playbook
          hosts: test
          tasks:
            - name: Output distribution
              ansible.builtin.debug:
                msg: "{{ ansible_distribution }}"
        ```

### Usage

First, create the testing instances by executing the `testing_environment.yml` playbook:

```console
ansible-playbook -i testing_inventory.ini testing_environment.yml
```

Add your tasks to the `testing_playbook.yml` (or use your existing playbook, target the `test` group) and execute:

```console
ansible-playbook -i testing_inventory.ini testing_playbook.yml
```

After finishing your tests remove the instances by running the `testing_environment.yml` playbook and provide the *extra-var* `delete`:

```console
ansible-playbook -i testing_inventory.ini testing_environment.yml -e delete=true
```
<!-- markdownlint-enable MD024 -->
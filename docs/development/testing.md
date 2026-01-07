---
icon: lucide/flask-conical
---

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

The *Molecule* project is designed to aid in the development and testing of Ansible roles, provides support for testing with multiple instances, operating systems and distributions, virtualization providers and testing scenarios. Test scenarios can target any system or service reachable from Ansible, from containers and virtual machines to cloud infrastructure, hyperscaler services, APIs, databases, and network devices. Molecule can also validate inventory configurations and dynamic inventory sources.  
Molecule is mostly used to test roles in isolation (although it is possible to test multiple roles or playbooks at once).  

!!! note
    **The following guide describes the testing with (systemd-enabled) Podman container images, other drivers are available!**

To test against a fresh system, molecule uses a container runtime to provision virtualized/containerized test hosts, runs commands on them, asserts the success and destroys them afterwards.  
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

Create the directory `molecule/default` and at least the `molecule.yml` and `converge.yml`.  
Depending on your project setup (*classic* role structure or collection), the Molecule configuration files need to be stored at different locations.

<div class="grid" markdown>

!!! abstract "Role"

    The *molecule* configuration files are kept in the role folder you want to test:

    ``` { .console hl_lines="5-8" .no-copy }
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

!!! abstract "Collection"

    The *molecule* configuration files are kept in a **separate** folder `extensions` in the collection root directory:

    ``` { .console hl_lines="3-7" .no-copy }
    .
    ├── README.md
    ├── extensions
    │   └── molecule
    │       └── default
    │           ├── converge.yml
    │           └── molecule.yml
    ├── galaxy.yml
    ├── meta
    │   └── runtime.yml
    └── roles
        └── webserver_demo
            ├── defaults
            │   └── main.yml
            ├── tasks
            │   └── main.yml
            └── templates
                └── welcome.html.j2
    ```

    !!! tip
        The Playbook file `converge.yml` **must** reference the role to test with the FQCN!

</div>

You may use this (minimal) example configuration as a starting point.

=== "Central Molecule configuration"
    !!! example "molecule.yml"

        ```yaml
        ---
        driver:
          name: podman
        platforms: # (1)!
          - name: rhel9-instance1 # (2)!
            image: ghcr.io/timgrt/rhel9-molecule-test-image:main # (3)!
            volumes: # (4)!
              - /sys/fs/cgroup:/sys/fs/cgroup:ro
            command: "/usr/sbin/init"
            published_ports: # (5)!
              - 8080:80/tcp
            groups: # (6)!
              - molecule
        ansible:
          executor:
            args:
              ansible_playbook:
                - --inventory=../../../../inventory/ # (7)!
          cfg:
            defaults:
              interpreter_python: auto_silent
              remote_user: ansible # (8)!
              callbacks_enabled: ansible.posix.timer, ansible.posix.profile_tasks # (9)!
              callback_result_format: yaml  # (10)!
              roles_path: "${MOLECULE_PROJECT_DIRECTORY}/.." # (11)!
            diff: # (12)!
              always: true
        ```

        1. List of hosts to provision by *molecule*, copy the list item and use a unique name if you want to deploy multiple containers. In the following example one Container with Rocky Linux 8 and one Ubuntu 20.04 container are provisioned.
            ```yaml
              - name: rocky8
                image: docker.io/timgrt/rockylinux8-ansible:latest
                pre_build_image: true
                volumes:
                  - /sys/fs/cgroup:/sys/fs/cgroup:ro
                groups:
                  - molecule
                  - rocky
              - name: ubuntu2004
                image: docker.io/timgrt/ubuntu2004-ansible:latest
                pre_build_image: true
                volumes:
                  - /sys/fs/cgroup:/sys/fs/cgroup:ro
                command: "/lib/systemd/systemd"
                groups:
                  - molecule
                  - ubuntu
            ```
        2. The *name* of your container, for better identification you could use e.g. `demo.${USER}.molecule` which uses your username from environment variable substitution, showing who deployed the container for what purpose.
        3. For more information regarding the used container image, see [https://hub.docker.com/r/timgrt/rockylinux9-ansible](https://hub.docker.com/r/timgrt/rockylinux9-ansible){:target="_blank"}. The image provides a *systemd-enabled* environment, this ensures you can install and start services with *systemctl* as in any normal VM.  
        Some more useful images are:
            * [Rocky Linux 8](https://hub.docker.com/r/timgrt/rockylinux8-ansible){ target="_blank" }
            * [Fedora 39](https://hub.docker.com/r/timgrt/fedora37-ansible){ target="_blank" }
            * [Ubuntu 20.04](https://hub.docker.com/r/timgrt/ubuntu2004-ansible){ target="_blank" }
            * [Debian 10](https://hub.docker.com/r/timgrt/debian10-ansible){ target="_blank" }
            * [OpenSuse 15](https://hub.docker.com/r/timgrt/opensuse15-ansible){ target="_blank" }
            * [RHEL 8](https://github.com/TimGrt/rhel8-molecule-test-image/pkgs/container/rhel8-molecule-test-image){ target="_blank" }
        4. The *volume mount* is necessary for a systemd-enabled container.
        5. When running a webserver inside the container (on port 80), this will publish the container port 80 to the host port 8080. Now, you can check the webserver content by using `http://localhost:8080` (or use the IP of your host).
        6. Additional *groups* the host should be part of. **Use a custom `molecule` group for referencing in `converge.yml`**.  
        7. If you want your container to inherit variables from *group_vars*, reference the location of the folder where the *group_vars* folder is stored (here in the subfolder *inventory* of the project, searching begins in the scenario folder *defaults*). Add the required group to the instance above.  
          **If you don't need this, remove the `executor` key and it's content.**
        8. Uses the *ansible* user to connect to the container (must be available in the container image!), this way you can test with `become`. Otherwise you would connect with the *root* user, most likely this is not what you would do in production.
        9.  Adds a timer to every task and the overall playbook run, as well as formatting the Ansible output to YAML for better readability.  
        Install necessary collection with `ansible-galaxy collection install ansible.posix`.
        10. Formats the output to YAML format.
        11. Necessary parameter to find the role to test, when **not** storing the role in a collection and using the `extensions` folder.
        12. Enables *diff* mode, useful for troubleshooting. Remove this key if you don't want this.

=== "Playbook file"
    !!! example "converge.yml"

        The *role* to test must be defined here.

        ```yaml
        ---
        - name: Converge
          hosts: molecule # (1)!
          become: true
          roles:
            - webserver_demo # (2)!
        ```

        1. **You should use a custom/molecule-only group here!**

            !!! warning
                If you target the `all` group, Molecule may run the automation on your **actual** nodes!
        2. In a collection project (and the Molecule configuration in the `extensions` folder), the role **must** be referenced by FQCN!

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

#### Molecule variables

The configuration options may contain environment variables, either *Molecule-specific* or *default* environment variables, e.g. `USER`. Some example variables are the following:

| (Environment-)Variable                      | Description                                                                                                                          |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `MOLECULE_PROJECT_DIRECTORY`                | Path to your project (role) directory, can be used to set a specific directory.<br>**Necessary when not using collection structure** |
| `MOLECULE_SCENARIO_NAME`                    | Name of the Molecule *scenario* (by default it is called `default`), you can define multiple scenarios                               |
| <nobr>`MOLECULE_EPHEMERAL_DIRECTORY`</nobr> | Path to generated directory, by default `~/.ansible/tmp/molecule.<hash>.<scenario-name>/`                                            |

!!! tip
    The full list can be found in the [Molecule documentation](https://docs.ansible.com/projects/molecule/configuration/#variable-substitution){ target="_blank" }.

The variables can be used to create custom instance names:

```yaml hl_lines="3"
---
platforms:
  - name: rhel9-$MOLECULE_SCENARIO_NAME-$USER
    image: ghcr.io/timgrt/rhel9-molecule-test-image:main
```

??? example
    This would result in the following name (shown with the output of `molecule list -f yaml`):

    ``` { .console hl_lines="11 17" .no-copy }
    (ve-molecule) timgrt@wsl-ubuntu:demo$ molecule list -f yaml
    INFO     Collection 'cc_ansible_community.demo' detected.
    INFO     Scenarios will be used from 'extensions/molecule'
    WARNING  Driver podman does not provide a schema.
    INFO     default ➜ list: Executing
    INFO     default ➜ list: Executed: Successful
    ---
    - Converged: 'false'
      Created: 'true'
      Driver Name: podman
      Instance Name: rhel9-default-timgrt
      Provisioner Name: ansible
      Scenario Name: default
    - Converged: 'false'  
      Created: 'false'  
      Driver Name: podman  
      Instance Name: rhel9-hardening-timgrt  
      Provisioner Name: ansible  
      Scenario Name: hardening
    ```

### Usage

In a *collection* project, you can execute Molecule directly from the project root directory.  
If your are using Molecule in a *classic* project, it is executed from **within the role** you want to test, change directory:

``` { .console .no-copy }
cd roles/webserver_demo
```

From here, run the molecule scenario, after activating your Python VE with molecule:

```console
source molecule-venv/bin/activate
```

To **only create** the defined containers, but not run the Ansible tasks:

```console
molecule create
```

To run the Ansible tasks of the role (if the container does not exist, it will be created):

```console
molecule converge
```

To destroy the provisioned infrastructure.

```console
molecule destroy
```

To execute a full test circle (existing containers are deleted, re-created and Ansible tasks are executed and containers are deleted(!) afterwards):

```console
molecule test
```

If you want to login to a running container instance:

```console
molecule login
```

#### Temporary files

Molecule writes a couple of temporary files to indicate which steps of a *sequence* were already performed. For example, if a test instance was already *created* and *prepared*, this state is written to a `state.yml` file. All temporary files are written to `~/.ansible/tmp/molecule.<hash>.<scenario-name>/`.

??? example

    ``` { .console .no-copy }
    $ tree ~/.ansible/tmp/molecule.KpdR.default/
    /home/timgrt/.ansible/tmp/molecule.KpdR.default/
    ├── ansible.cfg
    ├── inventory
    │   └── ansible_inventory.yml
    ├── molecule.yml
    └── state.yml
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
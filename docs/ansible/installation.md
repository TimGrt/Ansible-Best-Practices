# Installation

## Standard install method

The latest version can only be obtained via the Python package manager, the *ansible-core* package contains the binaries and 69 standard modules.

```console
pip3 install ansible-core
```

The included modules can be listed with `ansible-doc --list ansible.builtin`.  
If more special modules are needed, the complete *ansible* package can be installed, this corresponds to the "old" installation method (*batteries included*).

```console
pip3 install ansible
```

!!! tip
    It makes sense to install **only the *ansible-core* package**. Afterwards, install the few collections necessary for your project via `ansible-galaxy`.
    This way you have an up-to-date, lean installation without unnecessary modules and plugins.  
    Take a look at the following section for the recommended installation.

Most OS package managers like *apt* or *yum* also provide the `ansible-core` or `ansible` packages, these versions are not latest but a couple of minor versions behind.

??? example "Installing Ansible with OS package manager"
    Even in fairly recent distributions the Ansible versions are not up to date:

    ``` { .console .no-copy .title="Python package manager" .hl_lines="3" }
    $ pip3 show ansible-core
    Name: ansible-core
    Version: 2.14.3
    ...
    ```

    ``` { .console .no-copy .title="RockyLinux 8.7 (RHEL 8)" .hl_lines="4" }
    $ dnf info ansible-core
    Available Packages
    Name         : ansible-core
    Version      : 2.13.3
    Release      : 2.el8_7
    Architecture : x86_64
    Size         : 2.8 M
    Source       : ansible-core-2.13.3-2.el8_7.src.rpm
    Repository   : appstream
    ...
    ```

    ``` { .console .no-copy .title="Ubuntu 22.04" .hl_lines="3" }
    $ apt info ansible-core
    Package: ansible-core
    Version: 2.12.0-1ubuntu0.1
    Priority: optional
    Section: universe/admin
    Origin: Ubuntu
    ...
    ```

### Install Collections

The recommended installation method is through the Python package manager, necessary modules and plugins not included in the `ansible-core` binary are installed through *collections*.  
Additional collections (the included collection is called *ansible.builtin*) are installed with the `ansible-galaxy` command-line utility:

```console
ansible-galaxy collection install community.general
```

Multiple collections can be installed at once with a `requirements.yml` file.

Thereby the [chapter Project > Collections](project.md#collections) is to be considered. If a container runtime is available, the complete installation can also be bundled in a container image (so-called *Execution Environment*).

By default, collections are installed into a (hidden) folder in the home directory (`~/.ansible/collections/ansible_collections/`). This is defined by the `collections_path` configuration setting.

If you want to store collections alongside you project, create a folder `collections` in your project directory and install collections by providing the `--collections-path` (`-p`) argument:

```console
ansible-galaxy collection install community.general --collections-path ./collections/
```

#### List installed collections

Show the name and version of each collection installed in the `collections_path`:

```console
ansible-galaxy collection list
```

#### Upgrade installed collections

To upgrade installed collections use the `--upgrade` (`-U`) argument:

```console
ansible-galaxy collection install community.general --upgrade
```

#### Install collections offline

Download the collection tarball from [Galaxy](https://galaxy.ansible.com/){ target=_blank } for offline use:

1. Navigate to the collection page.
2. Click on *Download tarball*.
3. Copy the archive to the remote server.
4. Install the collection with the `ansible-galaxy` CLI utility, use the `--offline` argument:

    ```console
    ansible-galaxy collection install ~/community-general-6.4.0.tar.gz --offline
    ```

## Execution environments

Execution Environments are container images that serve as Ansible control nodes.

### Ansible Builder

Ansible Builder is a tool that aids in the creation of Ansible Execution Environments. It does this by using the dependency information defined in various Ansible Content Collections, as well as by the user. Ansible Builder will produce a directory that acts as the build context for the container image build, which will contain the *Containerfile* (*Dockerfile*), along with any other files that need to be added to the image. There is no need to write a single line of Dockerfile, which makes it easy to build and use Execution Environments (EE).

To build an EE, install `ansible-builder` from the Python Package Manager:

```console
pip3 install ansible-builder
```

Define at least the definition file for the Execution Environment and other files, depending on your use-case.

=== "EE definition file"
    !!! example "execution-environment.yml"
        ```yaml
        ---
        version: 1

        build_arg_defaults:
          EE_BASE_IMAGE: 'quay.io/ansible/ansible-runner:latest'

        ansible_config: 'ansible.cfg'

        dependencies:
          galaxy: requirements.yml
          python: requirements.txt
          system: bindep.txt

        additional_build_steps:
          prepend: |
            RUN pip3 install --upgrade pip setuptools
        ```
=== "Collection Dependencies"
    !!! example "requirements.yml"
        ```yaml
        ---
        collections:
          - redhat.openshift
        ```
=== "Python Dependencies"
    !!! example "requirements.txt"
        ```text
        awxkit>=13.0.0
        boto>=2.49.0
        botocore>=1.12.249
        boto3>=1.9.249
        openshift>=0.6.2
        requests-oauthlib
        ```
=== "Cross-Platform requirements"
    !!! example "bindep.txt"
        If there are RPMS necessary, put them here.
        ```text
        subversion [platform:rpm]
        subversion [platform:dpkg]
        ```

For more information, go to the [Ansible Builder Documentation](https://ansible-builder.readthedocs.io/en/stable/){ target=_blank }

To build the EE, run this command (assuming you have Docker installed, by default Podman is used):

```console
ansible-builder build --tag=demo/openshift-ee --container-runtime=docker
```

The resulting container images can be viewed with the `docker images` command:

``` { .console .no-copy }
$ docker images
REPOSITORY                        TAG       IMAGE ID       CREATED              SIZE
demo/openshift-ee                 latest    2ea9d5d7b185   10 seconds ago       1.14GB
```

### Ansible Runner

Using the EE requires a binary which can make use of the Container images, it is not possible to run them with the `ansible-playbook` binary. You have to use (and install) either the `ansible-navigator` or the `ansible-runner` binary.

```console
pip3 install ansible-runner
```

To use the Ansible from the container image, e.g. run this command which executes an ad hoc command (*setup* module) against localhost:

```console
ansible-runner run --container-image demo/openshift-ee /tmp -m setup --hosts localhost
```

Most parameters should be self-explanatory:

* *run* - Run ansible-runner in the foreground
* *--container-image demo/openshift* - Container image to use when running an ansible task
* */tmp* - base directory containing the ansible-runner metadata (project, inventory, env, etc)
* *-m setup* - Module to execute
* *--hosts localhost* - set of hosts to execute against (here only localhost)

The output looks like expected:

``` { .console .no-copy }
$ ansible-runner run --container-image demo/openshift-ee /tmp -m setup --hosts localhost
[WARNING]: No inventory was parsed, only implicit localhost is available
localhost | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "192.168.178.114",
            "172.17.0.1"
        ],
        "ansible_all_ipv6_addresses": [
            "2001:9e8:4a14:2401:a00:27ff:febf:4207",
            "fe80::a00:27ff:febf:4207",
            "fe80::42:9eff:fef9:df59"
        ],
        "ansible_apparmor": {
            "status": "enabled"
        },
        "ansible_architecture": "x86_64",
        "ansible_bios_date": "12/01/2006",
        "ansible_bios_vendor": "innotek GmbH",
        "ansible_bios_version": "VirtualBox",
        "ansible_board_asset_tag": "NA",
        "ansible_board_name": "VirtualBox",
        "ansible_board_serial": "NA",
        "ansible_board_vendor": "Oracle Corporation",
        ...
```

### Ansible Navigator

The `ansible-navigator` is text-based user interface (TUI) for the Red Hat Ansible Automation Platform. It is a command based tool for creating, reviewing, and troubleshooting Ansible content, including inventories, playbooks, and collections.
The Navigator also makes use of the Execution Environments and provides an easier to use interface to interact with EEs.

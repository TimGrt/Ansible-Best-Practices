# Installation

## Standard install method

The latest version can only be obtained via the Python package manager, the *ansible-core* package contains the binaries and 71 standard modules.

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

## Install Collections

Necessary modules and plugins **not** included in the `ansible-core` binary are installed through *collections*.  
Additional collections (the included collection is called *ansible.builtin*) are installed with the `ansible-galaxy` command-line utility:

```console
ansible-galaxy collection install community.general
```

Multiple collections can be installed at once with a `requirements.yml` file.  
Thereby the [chapter Project > Collections](project.md#collections) is to be considered. If a container runtime is available, the complete installation can also be bundled in a container image (so-called *Execution Environment*).

To install collections from *(Private) Automation Hub* adjust the `galaxy` section in your `ansible.cfg`. Take a look at the [chapter Project > Ansible configuration > Configure Ansible Galaxy](project.md#configure-ansible-galaxy)

### List installed collections

Show the name and version of each collection installed in the `collections_path`:

```console
ansible-galaxy collection list
```

### Upgrade installed collections

To upgrade installed collections use the `--upgrade` (`-U`) argument:

```console
ansible-galaxy collection install community.general --upgrade
```

### Store collections with your project

By default, collections are installed into a (hidden) folder in the home directory (`~/.ansible/collections/ansible_collections/`). This is defined by the `collections_path` configuration setting.

If you want to store collections alongside you project, create a folder `collections` in your project directory and install collections by providing the `--collections-path` (`-p`) argument:

```console
ansible-galaxy collection install community.general --collections-path ./collections/
```

The `collections` folder is a default folder, collections stored there are automatically picked up by Ansible.

### Install collections offline

Download the collection tarball from [Galaxy](https://galaxy.ansible.com/){ target=_blank } for offline use:

1. Navigate to the collection page.
2. Click on *Download tarball*.
3. Copy the archive to the remote server.
4. Install the collection with the `ansible-galaxy` CLI utility, use the `--offline` argument:

    ```console
    ansible-galaxy collection install ~/community-general-6.4.0.tar.gz --offline
    ```

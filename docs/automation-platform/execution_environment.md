# Execution environments

Execution Environments are container images that serve as Ansible control nodes.  
EEs provide you with:

* Software dependency isolation
* Portability across teams and environments
* Separation from other automation content and tooling

## Ansible Builder

Ansible Builder is a tool that aids in the creation of Ansible Execution Environments. It does this by using the dependency information defined in various Ansible Content Collections, as well as by the user. Ansible Builder will produce a directory that acts as the build context for the container image build, which will contain the *Containerfile* (*Dockerfile*), along with any other files that need to be added to the image. There is no need to write a single line of Dockerfile, which makes it easy to build and use Execution Environments.

To build an EE, install `ansible-builder` from the Python Package Manager:

```console
pip3 install ansible-builder
```

Define at least the definition file for the Execution Environment and other files, depending on your use-case.

=== "EE definition file"
    !!! example "execution-environment.yml"
        ```yaml
        ---
        version: 3

        images:
          base_image: # (1)!
            name: ghcr.io/ansible-community/community-ee-base:latest

        dependencies: # (2)!
          galaxy: requirements.yml # (3)!
          python: requirements.txt # (4)!
          system: bindep.txt

        ```

        1. Some more useful base images are (take a look if a more recent tag is available):
            * quay.io/rockylinux/rockylinux:9
            * ghcr.io/ansible-community/community-ee-minimal:latest
            * registry.redhat.io/ansible-automation-platform-24/ee-supported-rhel9:1.0.0-456
            * registry.redhat.io/ansible-automation-platform/ee-minimal-rhel9::2.15.5-4
        2. If you want to install a specific Ansible version add this configuration under the `dependencies` key:
        ```yaml
        dependencies:
          ansible_core:
            package_pip: ansible-core==2.14.3
        ```
        3. Instead of using a separate file, you can provide collections (and roles) as a list:
        ```yaml
        dependencies:
          galaxy:
            collections:
              - kubernetes.core
            roles:
              - timgrt.terraform
        ```
        4. Instead of using a separate file, you can provide the Python packages as a list:
        ```yaml
        dependencies:
          python:
            - awxkit
            - boto
            - botocore
            - boto3
            - openshift
            - requests-oauthlib
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

??? failure "Package manager not found?"
    In case you see an error like this: `unable to execute /usr/bin/dnf: No such file or directory`.
    This can happen when using RHEL minimal images, you need to adjust the package manager path. Add the following setting to your `execution-environment.yml`:

    ```yaml
    options:
      package_manager_path: /usr/bin/microdnf
    ```

For more information, go to the [Ansible Builder Documentation](https://ansible-builder.readthedocs.io/en/stable/){ target=_blank }.

To build the EE, run this command (assuming you have Docker installed, by default Podman is used):

```console
ansible-builder build --tag=demo/openshift-ee --container-runtime=docker -v=3
```

The resulting container images can be viewed with the `docker images` command:

``` { .console .no-copy }
$ docker images
REPOSITORY                        TAG       IMAGE ID       CREATED              SIZE
demo/openshift-ee                 latest    2ea9d5d7b185   10 seconds ago       1.14GB
```

You can also build Execution Environments with *ansible-navigator*, the Builder is installed alongside Navigator.

```console
ansible-navigator builder build --tag=demo/openshift-ee --container-runtime=docker
```

!!! tip
    If you run Ansible EEs ansible_host_key_checking is false on default. This means you can connect to every remote node without any security. [See below](automation-platform/execution_environment.md/#Mounting%20certificates%20inside%20the%20EE%20while%20using%20ansible-navigator) ## TODO Link

## Ansible Runner

Using the EE requires a binary which can make use of the Container images, it is not possible to run them with the `ansible-playbook` binary. You have to use (and install) either the `ansible-navigator` or the `ansible-runner` binary.

!!! tip
    The *Ansible Navigator* is easier to use than the `ansible-runner`, use this one for creating, reviewing, running and troubleshooting Ansible content, including inventories, playbooks, collections, documentation and execution environments.  

Ansible Runner is a tool and python library to provide a stable and consistent interface abstraction to Ansible, it represents the modularization of the part of Ansible AWX that is responsible for running `ansible` and `ansible-playbook` tasks and gathers the output from it.

If you want to use it standalone, install the `ansible-runner` binary:

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

## Ansible Navigator

The `ansible-navigator` is *text-based user interface* (TUI) for the Red Hat Ansible Automation Platform.
The Navigator also makes use of the Execution Environments and provides an easier to use interface to interact with EEs (than *ansible-runner*).  
Install the `ansible-navigator` binary and its dependencies with the Python package manager:

```console
pip3 install ansible-navigator
```

If you want to use the Navigator with EEs, you'll need a *container runtime*, install Docker or Podman an your system.

With the Navigator you, for example, can inspect **all locally available* Execution Environments

Take a look at the [Playbooks section](playbook.md#with-ansible-navigator) on how to run playbooks in Execution Environments with the Navigator.

Some `ansible-navigator` commands map to `ansible` commands (prefix every Navigator command with `ansible-navigator`):

| Navigator command           | Description                                                                                                        |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| <nobr>`exec -- ansible ...`</nobr> | Runs Ansible *ad-hoc* commands.                                                                                    |
| `builder`                   | Builds new execution environments, the `ansible-builder` utility is installed with `ansible-navigator`.            |
| `config`                    | Explore the current ansible configuration as with `ansible-config`.                                                |
| `doc`                       | Explore the documentation for modules and plugins as with `ansible-doc`.                                           |
| `inventory`                 | Inspect the inventory and browser groups and hosts.                                                                |
| `lint`                      | Runs best-practice checker, `ansible-lint` needs to be installed locally or in the selected execution-environment. |
| `run`                       | Runs Playbooks.                                                                                                    |
| <nobr>`exec -- ansible-test ...`</nobr>  | Executes sanity, unit and integration tests for Collections.                                                       |
| <nobr>`exec -- ansible-vault ...`</nobr> | Runs utility to encrypt or decrypt Ansible content.                                                                |

## Mounting certificates inside the EE while using ansible-navigator

At times you might not want to build a new EE to provide an EE with your custom certificates. For this instance, you can utilize the aforementioned volume mounts with a special flag: **:O** .

The flag **:O** mounts the directory as Overlay filesystem, which makes it ‘immutable’. Any changes to a mounted Overlay filesystem are temporary and will only happen in the container’s context - not on the host the mount originated from.

Additionally, podman applies the private SELinux label to the mount, which is the same as when specifying :z (as we used above).

This enables you to use it rootless in podman, without the need to relabel the SELinux labels on your certificates.

To make use of this feature for your certificates, you’ll need to specify the following in your ansible-navigator configuration file:

```yaml
volume-mounts:
  - src: '/etc/pki/ca-trust'
    dest: '/etc/pki/ca-trust'
    options: 'O'
```

Of course, you can mount all sorts of host directories the same way - this is not specifically tied to certificates.

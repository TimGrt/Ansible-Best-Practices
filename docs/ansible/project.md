---
icon: lucide/folder-git-2
---

# Project

Your Ansible project needs more than just a playbook and an inventory. Before starting it is useful to ship a custom configuration

## Version Control

Keep your playbooks and inventory file in git (or another version control system), and commit when you make changes to them. This way you have an audit trail describing when and why you changed the rules that are automating your infrastructure.

!!! tip
    Always use version control!

Take a look at the [Development section](git.md) for additional information.

## Directory structure

``` { .console .no-copy }
.
├── ansible.cfg
├── hosts
├── k8s_install.yml
├── README.md
├── requirements.txt
├── requirements.yml
└── roles
    ├── k8s_bootstrap
    │   ├── files
    │   │   ├── daemon.json
    │   │   └── k8s.conf
    │   ├── tasks
    │   │   ├── install_kubeadm.yml
    │   │   ├── main.yml
    │   │   └── prerequisites.yml
    │   └── templates
    │       └── kubernetes.repo.j2
    ├── k8s_control_plane
    │   ├── files
    │   │   └── kubeconfig.sh
    │   └── tasks
    │       └── main.yml
    └── k8s_worker_nodes
        └── tasks
            └── main.yml
```

### Filenames

Folder- and file-names consisting of multiple words are separated with **underscores** (e.g. `roles/grafana_deployment/tasks/grafana_installation.yml`).  
YAML files are saved with the extension `.yml`.  
Use descriptive names that are human-readable and **do not shorten more than necessary**. A pattern `object[_feature]_action` has proven useful as it guarantees a proper sorting in the file system for roles and playbooks. **Ansible supports long identifier names, so use them!**

<div class="grid" markdown>

=== "Good"

    !!! success ""
        ``` { .console .no-copy }
        .
        ├── ansible.cfg
        ├── hosts
        ├── k8s_install.yml
        ├── README.md
        ├── requirements.yml
        └── roles
            ├── k8s_bootstrap
            │   ├── files
            │   │   ├── daemon.json
            │   │   └── k8s.conf
            │   ├── tasks
            │   │   ├── install_kubeadm.yml
            │   │   ├── main.yml
            │   │   └── prerequisites.yml
            │   └── templates
            │       └── kubernetes.repo.j2
            ├── k8s_control_plane
            │   ├── files
            │   │   └── kubeconfig.sh
            │   └── tasks
            │       └── main.yml
            └── k8s_worker_nodes
                └── tasks
                    └── main.yml
        ```
=== "Bad"

    !!! failure ""
        Playbook-name without underscores and wrong file extension, role folders or task files inconsistent, with underscores and wrong extension.
        ``` { .console .no-copy }
        .
        ├── ansible.cfg
        ├── hosts
        ├── k8s-install.yaml
        ├── README.md
        └── roles
            ├── k8s-bootstrap
            │   ├── files
            │   │   ├── daemon.json
            │   │   └── k8s.conf
            │   ├── tasks
            │   │   ├── installKubeadm.yaml
            │   │   ├── main.yml
            │   │   └── prerequisites.yaml
            │   └── templates
            │       └── kubernetes.repo.j2
            ├── k8sControlPlane
            │   ├── files
            │   │   └── kubeconfig.sh
            │   └── tasks
            │       └── main.yaml
            └── k8s_worker-nodes
                └── tasks
                    └── main.yaml
        ```

</div>

## YAML Syntax

Following a basic YAML coding style across the whole team improves readability and reusability.

### Indentation

Two spaces are used to indent everything, e.g. list items or dictionary keys.

=== "Good"

    !!! success ""
        Playbook:

        ```yaml
        --8<-- "example-multiple-plays-playbook.yml"
        ```

        Variable-file:

        ```yaml
        --8<-- "example-list-variable-file.yml"
        ```

=== "Bad"

    !!! failure ""
        Playbook with roles **not** indented by two whitespaces.

        ``` { .yaml .no-copy }
        - name: Demo play
          hosts: database_servers
          roles:
          - common
          - postgres
        ```

        List in variable-file indented with four whitespaces:

        ``` { .yaml .no-copy }
        ntp_server_list:
            - 0.de.pool.ntp.org
            - 1.de.pool.ntp.org
            - 2.de.pool.ntp.org
            - 3.de.pool.ntp.org
        ```

The so-called YAML "one-line" syntax is not used, neither for passing parameters in tasks, nor for lists or dictionaries.

=== "Good"

    !!! success ""
        ```yaml
        --8<-- "example-install-package-from-repo-task.yml"
        ```

        ```yaml
        --8<-- "example-multiple-packages-install-task.yml"
        ```
=== "Bad"

    !!! failure ""
        Task with *One-line* syntax:

        ```{ .yaml .no-copy }
        - name: Install the latest version of Apache from the testing repo
          package: name=httpd enablerepo=testing state=present
        ```

        List in task with *One-line* syntax:

        ```{ .yaml .no-copy }
        - name: Install a list of packages
          package:
            name: ['nginx', 'postgresql', 'postgresql-server']
            state: present
        ```

### Booleans

Use `true` and `false` for boolean values in playbooks.  
Do not use the Ansible-specific `yes` and `no` as boolean values in YAML as these are completely custom extensions used by Ansible and are not part of the YAML spec. Also, avoid the use of the Python-style `True` and `False` for boolean values.

=== "Good"

    !!! success ""
        ```yaml
        --8<-- "example-boolean-task.yml"
        ```

=== "Bad"

    !!! failure ""
        ```{ .yaml .no-copy }
        - name: Start and enable service httpd
          ansible.builtin.service:
            name: httpd
            enabled: yes
            state: started
        ```

*YAML 1.1* allows all variants whereas *YAML 1.2* allows only *true/false*, you can avoid a massive migration effort for when it becomes the default.

Use the `| bool` filter when using bare variables (expressions consisting of just one variable reference without any operator) in `when` conditions.

=== "Good"

    !!! success ""
        Using a variable `upgrade_allowed` with the default value `false`, task is executed when overwritten with `true` value.
        ```yaml
        --8<-- "example-boolean-condition-task.yml"
        ```

=== "Bad"

    !!! failure ""
        ```{ .yaml .no-copy }
        - name: Upgrade all packages, excluding kernel & foo related packages
          ansible.builtin.package:
            name: "*"
            state: latest
            exclude: kernel*,foo*
          when: upgrade_allowed
        ```

### Quoting

Do not use quotes unless you have to, especially for short module-keyword-like strings like *present*, *absent*, etc.  
When using quotes, use the same *type* of quotes throughout your playbooks. Always use **double quotes** (`"`), whenever possible.

## Comments

Use loads of comments!  
Well, the *name* parameter should describe your task in detail, but if your task uses multiple filters or regex's, comments should be used for further explanation.  
Commented code is generally to be avoided. Playbooks or task files are not committed, if they contain commented out code.  

!!! failure inline end "Bad"

    **Why is the second task commented?**  
    Is it not necessary anymore?  
    Does it not work as expected?

```{ .yaml .no-copy }
- name: Change port to {{ grafana_port }}
    community.general.ini_file:
        path: /etc/grafana/grafana.ini
        section: server
        option: http_port
        value: "{{ grafana_port }}"
    become: true
    notify: restart grafana

# - name: Change theme to {{ grafana_theme }}
#   ansible.builtin.lineinfile:
#     path: /etc/grafana/grafana.ini
#     regexp: '.*default_theme ='
#     line: "default_theme = {{ grafana_theme }}"
#   become: yes
#   notify: restart grafana
```

!!! success "Comment commented tasks"
    If you really have to comment the whole task, add a description why, when and by whom it was commented.

## Ansible configuration

Always use a project-specific `ansible.cfg` in the parent directory of your project. The following configuration can be used as a starting point:

```ini
[defaults]
# Define inventory, no need to provide '-i' anymore.
inventory = inventory/production.ini

# Playbook-Output in YAML instead of JSON
callback_result_format = yaml
```

### Show check mode

The following parameter enables displaying markers when running in check mode.

```ini
[defaults]
check_mode_markers = true
```

The markers are `DRY RUN` at the beginning and ending of playbook execution (when calling `ansible-playbook --check`) and `CHECK MODE` as a suffix at every play and task that is run in check mode.

??? example "Example output"

    ``` { .console .no-copy }
    $ ansible-playbook -i inventory.ini playbook.yml -C

    DRY RUN ******************************************************************

    PLAY [Install and configure Worker Nodes] [CHECK MODE] *******************

    TASK [Gathering Facts] [CHECK MODE] **************************************
    ok: [k8s-worker1]
    ok: [k8s-worker2]
    ok: [k8s-worker2]

    ...

    ```

### Show task path when failed

For easier development when handling with very big playbooks, it may be useful to know which file holds the failed task. To display the path to the file containing the failed task and the line number, add this parameter:

```ini
[defaults]
show_task_path_on_failure = true
```

??? example "Example output"

    When set to `true`:

    ``` { .console .no-copy }
    ...

    TASK [Set motd message for k8s worker node] **************************************************
    task path: /home/timgrt/kubernetes_installation/roles/kube_worker/tasks/configure.yml:39
    fatal: [k8s-worker1]: FAILED! =>
    ...

    ```

    When set to `false`:

    ``` { .console .no-copy }
    ...

    TASK [Set motd message for k8s worker node] ****************************************************
    fatal: [k8s-worker1]: FAILED! =>
    ...

    ```

Even if you don't set this, the path is displayed automatically for every task when running with `-vv` or greater verbosity, but you'll need to run the playbook again.

### Configure ansible-galaxy

By default, ansible-galaxy uses [https://galaxy.ansible.com](https://galaxy.ansible.com){:target="_blank"} as the Galaxy server. To configure additional servers like *Automation Hub* or *Private Automation Hub*, you'll need to configure these in the `galaxy` section.  

Create a new section for each server name, set the url option for each server name and set the API token for each server name, if necessary.

```ini
[galaxy]
server_list = release_galaxy,automation_hub # (1)!

[galaxy_server.release_galaxy]
url = https://galaxy.ansible.com/ # (2)!

[galaxy_server.automation_hub]
url = https://console.redhat.com/api/automation-hub/content/published/ # (3)!
auth_url = https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token # (4)!
token = <secret-token>
```

1. **Comma-separated** list of server identifiers in a **prioritized** order (in the example galaxy.ansible.com is searched first, then Automation Hub).  
The name of the server does not matter, but needs to match the corresponding `galaxy_server.*` section.  
2. galaxy.ansible.com doesn't need authentication to download collections (or roles).  
If you want to publish stuff, you'll need an API Token (or username and password).  
3. Gets content from the `published` repository, to get stuff from the `validated` repository, adjust or add a new section and add it to the `server_list`.  
4. The URL of a Keycloak server *token_endpoint* if using SSO authentication. Requires `token`.  

!!! danger
    Take extra care when using tokens (or passwords) in your `ansible.cfg`, as they might get added to Git by accident.  
    Add the file to your `.gitignore`.

Take a look at the [Ansible documentation for additional information](https://docs.ansible.com/ansible/latest/collections_guide/collections_installing.html#configuring-the-ansible-galaxy-client){:target="_blank"}.

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

```console
ansible-galaxy collection install -r requirements.yml
```

If you want to install Collections directly from Git (circumventing Galaxy or Automation Hub) use the following configuration:

```yaml
collections:
  - name: https://github.com/TimGrt/Ansible-Bootstrap.git # (1)!
    type: git
    version: main # (2)!
```

1. The Git-URL to the Collection content, ensure that you can pull/clone from this address without authentication. The collection name will be deduced from the `galaxy.yml` of the collection (the content is cloned to a temporary location and then installed as if done with the *ansible-galaxy* utility).
2. The branch to use, if you want to test with a feature branch, adjust this.

### Python packages

Always provide a `requirements.txt` with **all** Python packages need by modules used within your project.

```text
boto
openshift>=0.6
PyYAML>=3.11
```

Install all dependencies from the *requirements*-file:

```console
pip3 install -r requirements.txt
```

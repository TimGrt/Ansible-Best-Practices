# Project

## Version Control
Keep your playbooks and inventory file in git (or another version control system), and commit when you make changes to them. This way you have an audit trail describing when and why you changed the rules that are automating your infrastructure.

!!! tip
    Always use version control!

## Ansible configuration

Always use a project-specific `ansible.cfg` in the parent directory of your project. The following configuration can be used as a starting point:

```ini
# Define inventory, no need to provide '-i' anymore.
inventory = inventory/production.ini

# Playbook-Output in YAML instead of JSON, needs additional collection.
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
.
├── ansible.cfg
├── hosts
├── k8s-install.yml
├── README.md
├── requirements.txt
├── requirements.yml
└── roles
    ├── k8s-bootstrap
    │   ├── files
    │   │   ├── daemon.json
    │   │   └── k8s.conf
    │   ├── tasks
    │   │   ├── install-kubeadm.yml
    │   │   ├── main.yml
    │   │   └── prerequisites.yml
    │   └── templates
    │       └── kubernetes.repo.j2
    ├── k8s-control-plane
    │   ├── files
    │   │   └── kubeconfig.sh
    │   └── tasks
    │       └── main.yml
    └── k8s-worker-nodes
        └── tasks
            └── main.yml
```

### Filenames

Folder- and file-names consisting of multiple words are separated with hyphens (e.g. `roles/grafana-deployment/tasks/grafana-installation.yml`).  
YAML files are saved with the extension `.yml`. 

=== "Good"
    !!! success ""
        ```bash
        .
        ├── ansible.cfg
        ├── hosts
        ├── k8s-install.yml
        ├── README.md
        ├── requirements.yml
        └── roles
            ├── k8s-bootstrap
            │   ├── files
            │   │   ├── daemon.json
            │   │   └── k8s.conf
            │   ├── tasks
            │   │   ├── install-kubeadm.yml
            │   │   ├── main.yml
            │   │   └── prerequisites.yml
            │   └── templates
            │       └── kubernetes.repo.j2
            ├── k8s-control-plane
            │   ├── files
            │   │   └── kubeconfig.sh
            │   └── tasks
            │       └── main.yml
            └── k8s-worker-nodes
                └── tasks
                    └── main.yml
        ```
=== "Bad"
    !!! failure ""
        Playbook-name without hyphens and wrong file extension, role folders or task files inconsistent, with underscores and wrong extension.
        ```bash
        .
        ├── ansible.cfg
        ├── hosts
        ├── k8s-install.yaml
        ├── README.md
        └── roles
            ├── k8s_bootstrap
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

!!! note "Subject to change"
    Maybe this has to change in the future, as *collection roles* only allow *underscores* for separation.  
    See [Ansible Docs - Roles directory](https://docs.ansible.com/ansible/devel/dev_guide/developing_collections_structure.html#roles-directory) for more information.  
    Also, *ansible-lint* checks role names to ensure they conform these requirements, which must be disabled otherwise.

## YAML Syntax

Following a basic YAML coding style accross the whole team, improves readability and reusability.

### Indentation
Two spaces are used to indent everything, e.g. list items or dictionary keys.

=== "Good"
    !!! success ""
        Playbook:
        ```yaml
        - name: Demo play
          hosts: database_servers
          roles:
            - common
            - postgres
        ```
        Variable-file:
        ```yaml
        ntp_server_list:
          - 0.de.pool.ntp.org
          - 1.de.pool.ntp.org
          - 2.de.pool.ntp.org
          - 3.de.pool.ntp.org
        ```
=== "Bad"
    !!! failure ""
        Playbook with roles **not** indented by two whitespaces.
        ```yaml
        - name: Demo play
          hosts: database_servers
          roles:
          - common
          - postgres
        ```
        List in variable-file indented with four whitespaces:
        ```yaml
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
        - name: Install the latest version of Apache from the testing repo
          ansible.builtin.yum:
            name: httpd
            enablerepo: testing
            state: present
        ```
        ```yaml
        - name: Install a list of packages
          ansible.builtin.yum:
            name:
              - nginx
              - postgresql
              - postgresql-server
            state: present
        ```
=== "Bad"
    !!! failure ""
        Task with *One-line* syntax:
        ```yaml
        - name: Install the latest version of Apache from the testing repo
          yum: name=httpd enablerepo=testing state=present
        ```
        List in task with *One-line* syntax:
        ```yaml
        - name: Install a list of packages
          yum:
            name: ['nginx', 'postgresql', 'postgresql-server']
            state: present
        ```

### Booleans
Use `true` and `false` for boolean values in playbooks.  
Do not use the Ansible-specific `yes` and `no` as boolean values in YAML as these are completely custom extensions used by Ansible and are not part of the YAML spec. Also, avoid the use of the Python-style `True` and `False` for boolean values.

=== "Good"
    !!! success ""
        ```yaml
        - name: Start and enable service httpd
          ansible.builtin.service:
            name: httpd
            enabled: true
            state: started
        ```
=== "Bad"
    !!! failure ""
        ```yaml
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
        - name: Upgrade all packages, excluding kernel & foo related packages
          ansible.builtin.yum:
            name: '*'
            state: latest
            exclude: kernel*,foo*
          when: upgrade_allowed | bool
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        - name: Upgrade all packages, excluding kernel & foo related packages
          ansible.builtin.yum:
            name: '*'
            state: latest
            exclude: kernel*,foo*
          when: upgrade_allowed
        ```

### Quoting

Do not use quotes unless you have to, especially for short module-keyword-like strings like *present*, *absent*, etc.



## Comments

Use loads of comments!  
Well, the *name* parameter should desribe your task in detail, but if your task uses multiple filters or regexes, comments should be used for further explanation.  
Commented code is generally to be avoided. Playbooks or task files are not committed, if they contain commented out code.  


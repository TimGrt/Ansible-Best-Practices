# Playbooks

*Playbooks* are first thing you think of when using Ansible. This section describes some good practices.  

## Directory structure

The *main* playbook should have a recognizable name, e.g. referencing the projects name or scope.
If you have multiple playbooks, create a new folder `playbooks` and store all playbooks there, except the *main* playbook (here called `site.yml`).

```bash
.
├── ansible.cfg
├── site.yml
└── playbooks
    ├── database.yml
    ├── loadbalancer.yml
    └── webserver.yml
```

The `site.yml` file contains references to the other playbooks:

```yaml
---
# Main playbook including all other playbooks

- import_playbook: playbooks/database.yml
- import_playbook: playbooks/webserver.yml
- import_playbook: playbooks/loadbalancer.yml
```

The *lower-level* playbooks contains actual [*plays*](playbook.md#plays):

```yaml title="playbooks/database.yml"
---

- name: Install and configure PostgreSQL database
  hosts: postgres_servers
  roles:
    - postgres

```

To be able to run the overall playbook, as well as the imported playbooks, add this parameter to your `ansible.cfg`, otherwise roles are not found:

```ini
[defaults]
roles_path = .roles
```

## Playbook definition

Don't put too much logic in your playbook, put it in your roles (or even in custom modules).  
A playbook **could** contain `pre_tasks`, `roles`, `tasks` and `post_tasks` sections, try to limit your playbooks to a **list of a roles**.

!!! warning
    Avoid using both *roles* and *tasks* sections, the latter possibly containing `import_role` or `include_role` tasks. The order of execution between *roles* and *tasks* isn’t obvious, and hence mixing them should be avoided.

Either you need only static importing of roles and you can use the roles section, or you need dynamic inclusion and you should use only the tasks section. Of course, for very simple cases, you can just use tasks without roles (but playbooks/projects grow quickly, refactor to roles early).

### Plays

Avoid putting multiple plays in a playbook, if not really necessary. As every play most likely targets a different host group, create a separate playbook file for it. This way you achieve to most flexibility.

```yaml title="k8s-installation.yml"
- name: Initialize Control-Plane Nodes
  hosts: kubemaster
  become: true
  roles:
    - k8s-control-plane

- name: Install and configure Worker Nodes
  hosts: kubeworker
  become: true
  roles:
    - k8s-worker-nodes
```

Separate the two plays into their respective playbooks files and reference them in an overall playbook file:

```yaml title="k8s-control-plane-playbook.yml"
- name: Initialize Control-Plane Nodes
  hosts: kubemaster
  become: true
  roles:
    - k8s-control-plane
```

```yaml title="k8s-worker-node-playbook.yml"
- name: Install and configure Worker Nodes
  hosts: kubeworker
  become: true
  roles:
    - k8s-worker-nodes
```

```yaml title="k8s-installation.yml"
# file k8s-installation.yml

- import_playbooks: k8s-control-plane-playbook.yml
- import_playbooks: k8s-worker-node-playbook.yml
```

### Module defaults

If your playbook uses modules which need the be called with the same set of parameters or arguments, you can define these as *module_defaults*.  
The defaults can be set at *play*, *block* or *task* level.

Module defaults are defined by [*grouping* together modules that share common sets of parameters](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_module_defaults.html#module-defaults-groups){:target="_blank"}, especially for modules making heavy use of API-interaction such as cloud modules.  

Since **ansible-core 2.12**, collections can define their own groups in the `meta/runtime.yml` file. *module_defaults* does not take the collections keyword into account, so the *fully qualified group name* must be used for new groups in module_defaults.

=== "Good"
    !!! good-practice-no-title ""
        ```yaml hl_lines="4 5 6 7 8"
        - name: Demo play with modules which need to call the same arguments
          hosts: aci
          module_defaults:
            group/cisco.aci.all:
              host: "{{ apic_api }}"
              username: "{{ apic_user }}"
              password: "{{ apic_password }}"
              validate_certs: false
          tasks:
            - name: Get system info
              cisco.aci.aci_system:
                state: query

            - name: Create a new demo tenant
              cisco.aci.aci_tenant:
                name: demo-tenant
                description: Tenant for demo purposes
                state: present
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        Authentication parameters are repeated in every task.
        ```yaml
        - name: Demo play with modules which need to call the same arguments
          hosts: aci
          tasks:
            - name: Get system info
              cisco.aci.aci_system:
                host: "{{ apic_api }}"
                username: "{{ apic_user }}"
                password: "{{ apic_password }}"
                validate_certs: false
                state: query

            - name: Create a new demo tenant
              cisco.aci.aci_tenant:
                host: "{{ apic_api }}"
                username: "{{ apic_user }}"
                password: "{{ apic_password }}"
                validate_certs: false
                name: demo-tenant
                description: Tenant for demo purposes
                state: present
        ```

To identify the correct group (*remember, these are **not** inventory groups*), take a look at the `meta/runtime.yml` of the desired collection. It needs to define the `action_groups` list, for example:

```yaml title="~/.ansible/collections/ansible_collections/cisco/aci/meta/runtime.yml"
---
requires_ansible: '>=2.9.10'
action_groups:
  all:
    - aci_aaa_custom_privilege
    - aci_aaa_domain
    - aci_aaa_role
    - aci_aaa_ssh_auth
    - aci_aaa_user
    - aci_aaa_user_certificate
    - aci_aaa_user_domain
    - aci_aaa_user_role
    - aci_access_port_block_to_access_port
    ...
```

The *group* is called `all`, therefore the module defaults groups needs to be `group/cisco.aci.all`.

!!! note
    Any module defaults set at the play level (and block/task level when using `include_role` or `import_role`) will apply to **any** roles used, which may cause unexpected behavior in the role.

## Collections in playbooks

In a playbook, you can control the collections Ansible searches for modules and action plugins to execute.

!!! quote "tl;dr"
    This is not recommended, try to avoid this.

```yaml
- name: Initialize Control-Plane Nodes
  hosts: kubemaster
  collections:
    - kubernetes.core
    - computacenter.utils
  become: true
  roles:
    - k8s-control-plane
```

With that you could omit the *provider.collection* part when using modules, by default you would reference a module with the [FQCN](tasks.md#modules-and-collections):

```yaml
- name: Check if Weave is already installed
  kubernetes.core.k8s_info:
    api_version: v1
    kind: DaemonSet
    name: weave-net
    namespace: kube-system
  register: weave_daemonset
```

With the `collections` list defined as part of the play definition, you could write your tasks like this:

```yaml
- name: Check if Weave is already installed
  k8s_info:
    api_version: v1
    kind: DaemonSet
    name: weave-net
    namespace: kube-system
  register: weave_daemonset
```

!!! warning
    If your playbook uses both the collections keyword and one or more roles, the roles do not inherit the collections set by the playbook!  
    The collections keyword merely creates an ordered *search path* for non-namespaced plugin and role references. It does not install content or otherwise change Ansible’s behavior around the loading of plugins or roles. Note that an FQCN is still required for non-action or module plugins (for example, lookups, filters, tests).

!!! tip
    It is preferable to use a module or plugin’s FQCN over the `collections` keyword!

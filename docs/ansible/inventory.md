# Inventory

An *inventory* is a list of managed nodes, or hosts, that Ansible deploys and configures. The inventory can either be static or dynamic.

## Convert INI to YAML

The most common format for the *Ansible Inventory* is the `.ini` format, but sometimes you might need the inventory file in the *YAML* format.  
 A `.ini` inventory file for example might look like this:

```ini title="inventory.ini"
[control]
controller ansible_host=localhost ansible_connection=local

[target]
rocky8 ansible_connection=docker
```

You can convert your existing inventory to the YAML format with the `ansible-inventory` utility.

```console
ansible-inventory -i inventory.ini -y --list > inventory.yml
```

The resulting file is your inventory in YAML format:

```yaml title="inventory.yml"
all:
  children:
    control:
      hosts:
        controller:
          ansible_connection: local
          ansible_host: localhost
    target:
      hosts:
        rocky8:
          ansible_connection: docker
```

## Static inventory

!!! warning
    **Work in Progress** - More description necessary.

## Dynamic inventory

!!! warning
    **Work in Progress** - More description necessary.

### Custom dynamic inventory

In case no suitable inventory plugin exists, you can easily write your own. Take a look at the [Ansible Development - Extending](extending.md#inventory-plugins) section for additional information.

## In-Memory Inventory

Normally Ansible requires an inventory file, to know which machines it is meant to operate on.

This is typically a manual process but can be greatly improved by using a dynamic inventory to pull inventory information from other systems.

Suppose, however, you needed to create *X* number of instances, which are transient in nature and had no existing details available to populate an inventory file for Ansible to utilise. If *X* is a small number, you could easily hand-craft the inventory file while the playbook already runs.

Use the [`add_host` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/add_host_module.html#ansible-collections-ansible-builtin-add-host-module){:target="_blank"}, which makes use of Ansible's ability to populate an *in-memory inventory* with information it generates while creating new instances.

Take a look at the following example, the first *play* creates a couple of Containers and adds them to a new group. The seconds plays targets this new group and connects to the newly created Containers.

```yaml
---
- name: Add hosts to additional groups
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    container_list:
      - node1
      - node2
      - node3
  tasks:
    - name: Start managed node containers
      containers.podman.podman_container:
        name: "{{ item }}"
        image: docker.io/timgrt/rockylinux8-ansible:latest
        hostname: "{{ item }}.example.com"
        stop_signal: 15
        state: started
      loop: "{{ container_list }}"

    - name: Add container to new group
      ansible.builtin.add_host:
        name: "{{ item }}" # (1)!
        groups: managed_node_containers # (2)!
        ansible_connection: podman # (3)!
        ansible_python_interpreter: /usr/libexec/platform-python # (4)!
        stage: test # (5)!
      loop: "{{ container_list }}"

- name: Run tasks on containers created in previous play
  hosts: managed_node_containers
  tasks:
    - name: Output stage variable
      ansible.builtin.debug:
        msg: "{{ stage }}"
```

1. Every container instance is added by looping the variable `container_list`. As the `name` parameter must be a string a loop is necessary.
2. This is the name of the new group! It is targeted in the second play. The `groups` parameter can be a list of multiple group names.
3. These are variables needed to connect to the new instances. As they are Podman containers the *podman* connection plugin is used.
4. The Python interpreter which is used in the new instances. Not always necessary, as normally Ansible discovers the interpreter pretty reliable.
5. This is a custom variable for all new instances. You can add more variables here if necessary.

??? example "Playbook output"

    ```{ .console .no-copy }
    $ ansible-playbook in-memory-inventory.yml

    PLAY [Add hosts to additional groups] *******************************************************************************************************************************

    TASK [Start managed node containers] ********************************************************************************************************************************
    ok: [localhost] => (item=node1)
    ok: [localhost] => (item=node2)
    ok: [localhost] => (item=node3)

    TASK [Add container to new group] ***********************************************************************************************************************************
    changed: [localhost] => (item=node1)
    changed: [localhost] => (item=node2)
    changed: [localhost] => (item=node3)

    PLAY [Run tasks on containers created in previous play] *************************************************************************************************************

    TASK [Gathering Facts] **********************************************************************************************************************************************
    ok: [node2]
    ok: [node1]
    ok: [node3]

    TASK [Output stage variable] ****************************************************************************************************************************************
    ok: [node1] =>
        msg: test
    ok: [node2] =>
        msg: test
    ok: [node3] =>
        msg: test
    ```

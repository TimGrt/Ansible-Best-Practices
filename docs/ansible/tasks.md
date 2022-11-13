# Tasks

Tasks should always be inside of a role. Do not use tasks in a play directly.  
Logically related tasks are to be separated into individual files, the `main.yml` of a role only imports other task files.

```bash
.
└── roles
    └── k8s-bootstrap
        └── tasks
            ├── install-kubeadm.yml
            ├── main.yml
            └── prerequisites.yml
```

The file name of a task file should describe the content.
```yaml
---
# tasks/main.yml
- import_tasks: prerequisites.yml
- import_tasks: install-kubeadm.yml
```

## Tags
Don't use too many tags, it gets confusing very quickly.  
Tags should only be allowed for imported task files within the `main.yml` of a role. Tags at the task level in sub-task files should be avoided.

```yaml
---
# tasks/main.yml
- import_tasks: installation.yml
  tags:
    - install

- import_tasks: configuration.yml
  tags:
    - configure
```

Try to use the same tags across your roles, this way you would be able to run only e.g. *installation* tasks from multiple roles.

## Idempotence

Each task must be idempotent, if non-idempotent modules are used (*command*, *shell*, *raw*) these tasks must be developed via appropriate parameters or conditions to an idempotent mode of operation.  

!!! tip
    In general, the use of non-idempotent modules should be reduced to a necessary minimum. 

### *command* vs. *shell* module

In most of the use cases, both shell and command modules perform the same job. However, there are few main differences between these two modules. The *command* module uses the Python interpreter on the target node (as all other modules), the *shell* module runs a real shell on the target (pipeing and redirections are available, as well as access to environment variables).

!!! tip
    Always try to use the `command` module over the `shell` module, if you do not explicitly need shell functionality.

Parsing shell metacharacters can lead to unexpected commands being executed if quoting is not done correctly so it is more secure to use the command module when possible. To sanitize any variables passed to the shell module, you should use `{{ var | quote }}` instead of  
just `{{ var }}` to make sure they do not include evil things like semicolons.

### *creates* and *removes*

Check mode is supported for non-idempotent modules when passing `creates` or `removes`. If running in check mode and either of these are specified, the module will check for the existence of the file and report the correct changed status. If these are not supplied, the task will be skipped.

!!! warning
    **Work in Progress** - More description necessary.


### *failed_when* and *changed_when*

=== "Good"
    !!! success ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! failure ""
        This task never reports a changed state or fails when an error occurs.
        ```yaml
        - name: Install webserver package
          shell: sudo yum install http
          changed_when: false
          failed_when: false
        ```

## Naming tasks

It is possible to leave off the *name* for a given task, though it is recommended to provide a description about why something is being done instead. This description is shown when the playbook is run.  
Write task names in the imperative (e.g. *"Ensure service is running"*), this communicates the action of the task. Start with a capital letter.

=== "Good"
    !!! success ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        - yum:
            name: httpd
            state: present
        ```
        Using name parameter, but not starting with capital letter, nor desrcibing the task properly.
        ```yaml
        - name: install package
          yum:
            name: httpd
            state: present
        ```

### Prefix task names in sub-task files

It is a common practice to have `tasks/main.yml` file including other tasks files, which we’ll call *sub-tasks* files. Make sure that the tasks' names in these sub-tasks files are prefixed with a shortcut reminding of the sub-tasks file’s name. Especially in a complex role with multiple (sub-)tasks file, it becomes difficult to understand which task belongs to which file.  

```yaml
- name: kubeadm-setup | Install kubeadm, kubelet and kubectl
  ansible.builtin.yum:
    name:
      - kubelet
      - kubeadm
      - kubectl
    state: present
```

The log output will then look like this:

```bash
...
TASK [k8s-bootstrap: kubeadm-setup | Install kubeadm, kubelet and kubectl] **********
changed: [kubemaster]
...
```

## FQCN

Use the *full qualified collection names (FQCN)* for modules, they are supported since Version 2.9 and ensures your tasks are set for the future.

=== "Good"
    !!! success ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        - yum:
            name: httpd
            state: present
        ```

In Ansible 2.10, many plugins and modules have migrated to Collections on Ansible Galaxy. Your playbooks should continue to work without any changes. Using the FQCN in your playbooks ensures the explicit and authoritative indicator of which collection to use as some collections may contain duplicate module names.

## State definition
The `state` parameter is optional to a lot of modules. Whether `state: present` or `state: absent`, it’s always best to leave that parameter in your playbooks to make it clear, especially as some modules support additional states.

## Conditionals

If the `when:` condition results in a line that is very long, and is an `and` expression, then break it into a list of conditions.

=== "Good"
    !!! success ""
        ```yaml
        - name: Set motd message for k8s worker node
          ansible.builtin.copy:
            content: "This host is used as k8s worker.\n"
            dest: /etc/motd
          when: 
            - inventory_hostname in groups['kubeworker']
            - kubeadm_join_result.rc == 0
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        - name: Set motd message for k8s worker node
          copy:
            content: "This host is used as k8s worker.\n"
            dest: /etc/motd
          when: inventory_hostname in groups['kubeworker'] and kubeadm_join_result.rc == 0
        ```

When using conditions on *blocks*, move the `when` statement to the top, below the *name* parameter, to improve readability.

=== "Good"
    !!! success ""
        ```yaml
        - name: Install, configure, and start Apache
          when: ansible_facts['distribution'] == 'CentOS'
          block:
            - name: Install httpd and memcached
              ansible.builtin.yum:
                name:
                  - httpd
                  - memcached
                state: present

            - name: Apply the foo config template
              ansible.builtin.template:
                src: templates/src.j2
                dest: /etc/foo.conf

            - name: Start service bar and enable it
              ansible.builtin.service:
                name: bar
                state: started
                enabled: true
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        - name: Install, configure, and start Apache
          block:
            - name: Install httpd and memcached
              ansible.builtin.yum:
                name:
                - httpd
                - memcached
                state: present

            - name: Apply the foo config template
              ansible.builtin.template:
                src: templates/src.j2
                dest: /etc/foo.conf

            - name: Start service bar and enable it
              ansible.builtin.service:
                name: bar
                state: started
                enabled: True
          when: ansible_facts['distribution'] == 'CentOS'
        ```

Avoid the use of `when: foo_result is changed` whenever possible. Use handlers, and, if necessary, handler chains to achieve this same result.

## Loops

!!! warning
    **Work in Progress** - More description necessary.


## Filter

!!! warning
    **Work in Progress** - More description necessary.

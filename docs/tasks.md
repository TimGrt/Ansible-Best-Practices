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

## Idempotence

Each task must be idempotent, if non-idempotent modules are used (*command*, *shell*, *raw*) these tasks must be developed via appropriate parameters or conditions to an idempotent mode of operation.  

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

In general, the use of non-idempotent modules should be reduced to a necessary minimum. 

## Always *name* tasks
It is possible to leave off the *name* for a given task, though it is recommended to provide a description about why something is being done instead. This description is shown when the playbook is run.

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

## Always mention the *state*
The `state` parameter is optional to a lot of modules. Whether `state: present` or `state: absent`, it’s always best to leave that parameter in your playbooks to make it clear, especially as some modules support additional states.


## Tags

Don't use too many tags, it gets confusing very quickly.  
Tags are only allowed for imported task files within the `main.yml` of a role. Tags at the task level are not allowed.

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

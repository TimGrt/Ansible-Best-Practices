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

### *command* vs. *shell* module

In most of the use cases, both shell and command modules perform the same job. However, there are few main differences between these two modules. The *command* module uses the Python interpreter on the target node (as all other modules), the *shell* module runs a real shell on the target (pipeing and redirections are available, as well as access to environment variables).

!!! tip
    Always try to use the `command` module over the `shell` module, if you do not explicitly need shell functionality.

Parsing shell metacharacters can lead to unexpected commands being executed if quoting is not done correctly so it is more secure to use the command module when possible. To sanitize any variables passed to the shell module, you should use `{{ var | quote }}` instead of just `{{ var }}` to make sure they do not include evil things like semicolons.

### *creates* and *removes*

Check mode is supported when passing creates or removes. If running in check mode and either of these are specified, the module will check for the existence of the file and report the correct changed status. If these are not supplied, the task will be skipped.

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

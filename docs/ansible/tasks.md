# Tasks

Tasks should always be inside of a role. Do not use tasks in a play directly.  
Logically related tasks are to be separated into individual files, the `main.yml` of a role only imports other task files.

``` { .console .no-copy }
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

## Naming tasks

It is possible to leave off the *name* for a given task, though it is recommended to provide a description about why something is being done instead. This description is shown when the playbook is run.  
Write task names in the imperative (e.g. *"Ensure service is running"*), this communicates the action of the task. Start with a capital letter.

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy }
        - yum:
            name: httpd
            state: present
        ```
        Using name parameter, but not starting with capital letter, nor describing the task properly.
        ``` { .yaml .no-copy }
        - name: install package
          yum:
            name: httpd
            state: present
        ```

### Prefix task names in sub-task files

It is a common practice to have `tasks/main.yml` file including other tasks files, which we’ll call *sub-tasks* files. Make sure that the tasks' names in these sub-tasks files are prefixed with a shortcut reminding of the sub-tasks file’s name. Especially in a complex role with multiple (sub-)tasks file, it becomes difficult to understand which task belongs to which file.  

For example, having a sub-task file `tasks/kubeadm-setup.yml` with every task in it having a short reminder to which file it belongs.

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

``` { .console .no-copy }
...
TASK [k8s-bootstrap: kubeadm-setup | Install kubeadm, kubelet and kubectl] **********
changed: [kubemaster]
...
```

!!! note
    If you move around your tasks often during development phase, it may be difficult to keep this up to date.

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

In most of the use cases, both shell and command modules perform the same job. However, there are few main differences between these two modules. The [*command*](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html){:target="_blank"} module uses the Python interpreter on the target node (as all other modules), the [*shell*](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html){:target="_blank"} module runs a real shell on the target (pipes and redirects are available, as well as access to environment variables).

!!! tip
    Always try to use the `command` module over the `shell` module, if you do not explicitly need shell functionality.

Parsing shell meta-characters can lead to unexpected commands being executed if quoting is not done correctly so it is more secure to use the command module when possible. To sanitize any variables passed to the shell module, you should use `{{ var | quote }}` instead of  
just `{{ var }}` to make sure they do not include evil things like semicolons.

### *creates* and *removes*

Check mode is supported for non-idempotent modules when passing `creates` or `removes`. If running in check mode and either of these are specified, the module will check for the existence of the file and report the correct changed status. If these are not supplied, the task will be skipped.

!!! warning
    **Work in Progress** - More description necessary.

### *failed_when* and *changed_when*

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        This task never reports a changed state or fails when an error occurs.
        ``` { .yaml .no-copy }
        - name: Install webserver package
          shell: sudo yum install http
          changed_when: false
          failed_when: false
        ```

## Modules (and Collections)

Use the *full qualified collection names (FQCN)* for modules, they are supported since Version 2.9 and ensures your tasks are set for the future.

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.yum:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy }
        - yum:
            name: httpd
            state: present
        ```

In Ansible 2.10, many plugins and modules have migrated to **Collections** on Ansible Galaxy. Your playbooks should continue to work without any changes. Using the FQCN in your playbooks ensures the explicit and authoritative indicator of which collection to use as some collections may contain duplicate module names.

## Module parameters

### Module defaults

The `module_defaults` keyword can be used at the play, block, and task level. Any module arguments explicitly specified in a task will override any established default for that module argument.  
It makes the most sense to define the *module defaults* at [*play* level, take a look in that section](playbook.md#module-defaults) for an example and things to consider.

### Permissions

When using modules like `copy` or `template` you can (and should) set permissions for the files/templates deployed with the `mode` parameter.

For those used to */usr/bin/chmod*, remember that modes are actually octal numbers. You must either add a **leading zero** so that Ansible’s YAML parser knows it is an octal number (like `0644` or `01777`) or quote it (like `"644"` or `"1777"`) so Ansible receives a string and can do its own conversion from string into number.

!!! warning
    Giving Ansible a number without following one of these rules will end up with a decimal number which will have unexpected results.

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        - name: Copy index.html template
          ansible.builtin.template:
            src: welcome.html
            dest: /var/www/html/index.html
            mode: 0644
            owner: apache
            group: apache
          become: true
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        Missing leading zero:
        ``` { .yaml .no-copy }
        - name: copy index
          template:
            src: welcome.html
            dest: /var/www/html/index.html
            mode: 644
            owner: apache
            group: apache
          become: true
        ```
        This leads to these permissions!
        ``` { .console .no-copy }
        [root@demo /]# ll /var/www/html/
        total 68
        --w----r-T 1 apache apache 67691 Nov 18 14:30 index.html
        ```

### State definition

The `state` parameter is optional to a lot of modules. Whether `state: present` or `state: absent`, it’s always best to leave that parameter in your playbooks to make it clear, especially as some modules support additional states.

## Conditionals

If the `when:` condition results in a line that is very long, and is an `and` expression, then break it into a list of conditions.

=== "Good"
    !!! good-practice-no-title ""
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
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy }
        - name: Set motd message for k8s worker node
          copy:
            content: "This host is used as k8s worker.\n"
            dest: /etc/motd
          when: inventory_hostname in groups['kubeworker'] and kubeadm_join_result.rc == 0
        ```

When using conditions on *blocks*, move the `when` statement to the top, below the *name* parameter, to improve readability.

=== "Good"
    !!! good-practice-no-title ""
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
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy }
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

Converting from `with_<lookup>` to `loop` is described with a [Migration Guide](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html#migrating-from-with-x-to-loop){:target="_blank"} in the Ansible documentation

### Limit loop output

When looping over complex data structures, the console output of your task can be enormous. To limit the displayed output, use the `label` directive with `loop_control`. For example, this tasks creates users with multiple parameters in a loop:

```yaml
- name: Create local users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
    append: "{{ item.append }}"
    comment: "{{ item.comment }}"
    generate_ssh_key: true
    password_expire_max: "{{ item.password_expire_max }}"
  loop: "{{ user_list }}"
  loop_control:
    label: "{{ item.name }}" # (1)!
```

1. Content of variable `user_list`:

    ```yaml
    user_list:
      - name: tgruetz
        groups: admins,docker
        append: false
        comment: Tim Grützmacher
        shell: /bin/bash
        password_expire_max: 180
      - name: joschmi
        groups: developers,docker
        append: true
        comment: Jonathan Schmidt
        shell: /bin/zsh
        password_expire_max: 90
      - name: mfrink
        groups: developers
        append: true
        comment: Mathias Frink
        shell: /bin/bash
        password_expire_max: 90
    ```

Running the playbook results in the following task output, only the content of the *name* parameter is shown instead of all key-value pairs in the list item.

=== "Good"
    !!! good-practice-no-title ""
        ```console
        TASK [common : Create local users] *********************************************
        Friday 18 November 2022  12:18:01 +0100 (0:00:01.955)       0:00:03.933 *******
        changed: [demo] => (item=tgruetz)
        changed: [demo] => (item=joschmi)
        changed: [demo] => (item=mfrink)
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        Not using the `label` in the `loop_control` dictionary results in a very long output:
        ``` { .console .no-copy }
        TASK [common : Create local users] *********************************************
        Friday 18 November 2022  12:22:40 +0100 (0:00:01.512)       0:00:03.609 *******
        changed: [demo] => (item={'name': 'tgruetz', 'groups': 'admins,docker', 'append': False, 'comment': 'Tim Grützmacher', 'shell': '/bin/bash', 'password_expire_max': 90})
        changed: [demo] => (item={'name': 'joschmi', 'groups': 'developers,docker', 'append': True, 'comment': 'Jonathan Schmidt', 'shell': '/bin/zsh', 'password_expire_max': 90})
        changed: [demo] => (item={'name': 'mfrink', 'groups': 'developers', 'append': True, 'comment': 'Mathias Frink', 'shell': '/bin/bash', 'password_expire_max': 90})
        ```

## Filter

!!! warning
    **Work in Progress** - More description necessary.

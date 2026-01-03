# Tasks

**Tasks should always be inside of a role.** Do not use tasks in a play directly.  
Logically related tasks are to be separated into individual files, the `main.yml` of a role only **imports** other task files.

``` { .console .no-copy }
.
└── roles
    └── k8s_bootstrap
        └── tasks
            ├── install_kubeadm.yml
            ├── main.yml
            └── prerequisites.yml
```

The file name of a task file should describe the content.

```yaml title="roles/k8s_bootstrap/tasks/main.yml"
--8<-- "example-role-main-task.yml"
```

??? info "`noqa` statement"
    The file `main.yml` only references other task-files, still, the *ansible-lint* utility would trigger, as every *task* should have the `name` parameter.  
    While this is correct (and you should always name your **actual** *tasks*), the *name* parameter on *import* statements is **not shown anyway**, as they are pre-processed at the time playbooks are parsed. Take a look at the following section regarding *import vs. include*.  

    !!! success
        Therefore, silencing the linter in this particular case with the `noqa` statement is acceptable.  

    In contrast, *include* statements like `ansible.builtin.include_tasks` should have the `name` parameter, as these statements are processed when they are encountered during the execution of the playbook.

## import vs. include

Ansible offers two ways to reuse tasks: *statically* with `ansible.builtin.import_tasks` and *dynamically* with `ansible.builtin.include_tasks`.  
Each approach to reuse distributed Ansible artifacts has advantages and limitations, take a look at the [Ansible documentation for an in-depth comparison of the two statements](https://docs.ansible.com/ansible/devel/playbook_guide/playbooks_reuse.html#comparing-includes-and-imports-dynamic-and-static-reuse){:target="_blank"}.  

!!! tip
    In most cases, use the static `ansible.builtin.import_tasks` statement, it has more advantages than disadvantages.

One of the biggest disadvantages of the dynamic *include_tasks* statement, syntax errors are not found easily with `--syntax-check` or by using *ansible-lint*. You may end up with a failed playbook, although all your testing looked fine. Take a look at the following example, the recommended `ansible.builtin.import_tasks` statement on the left, the `ansible.builtin.include_tasks` statement on the right.

!!! quote ""

    <div class="grid" markdown>

    !!! success "Syntax or linting errors found"

        Using *static* `ansible.builtin.import_tasks`:

        ```{ .yaml title="roles/prerequisites/tasks/main.yml" .no-copy}
        ---
        - ansible.builtin.import_tasks: prerequisites.yml
        - ansible.builtin.import_tasks: install_kubeadm.yml
        ```

        Task-file with syntax error (module-parameters are not indented correctly):

        ```{ .yaml title="install_kubeadm.yml" hl_lines="3 4" .no-copy}
        - name: Install Kubernetes Repository
          ansible.builtin.template:
          src: kubernetes.repo.j2
          dest: /etc/yum.repos.d/kubernetes.repo
        ```

        Running playbook with `--syntax-check` or running `ansible-lint`:

        ```{ .console .no-copy}
        $ ansible-playbook k8s_install.yml --syntax-check
        ERROR! conflicting action statements: ansible.builtin.template, src

        The error appears to be in '/home/timgrt/kubernetes_installation/roles/k8s-bootstrap/tasks/install_kubeadm.yml': line 3, column 3, but may
        be elsewhere in the file depending on the exact syntax problem.

        The offending line appears to be:


        - name: Install Kubernetes Repository
          ^ here
        $ ansible-lint k8s_install.yml
        WARNING  Listing 1 violation(s) that are fatal
        syntax-check[specific]: conflicting action statements: ansible.builtin.template, src
        roles/k8s_bootstrap/tasks/install_kubeadm.yml:3:3


                          Rule Violation Summary  
        count tag                    profile rule associated tags
            1 syntax-check[specific] min     core, unskippable  

        Failed: 1 failure(s), 0 warning(s) on 12 files.
        ```

    !!! failure "Syntax or linting errors **NOT** found!"

        Using *dynamic* `ansible.builtin.include_tasks`:

        ```{ .yaml title="roles/prerequisites/tasks/main.yml" .no-copy}
        ---
        - ansible.builtin.include_tasks: prerequisites.yml
        - ansible.builtin.include_tasks: install_kubeadm.yml
        ```

        Task-file with syntax error (module-parameters are not indented correctly):

        ```{ .yaml title="install_kubeadm.yml" hl_lines="3 4" .no-copy}
        - name: Install Kubernetes Repository
          ansible.builtin.template:
          src: kubernetes.repo.j2
          dest: /etc/yum.repos.d/kubernetes.repo
        ```
        Running playbook with `--syntax-check` or running `ansible-lint`:

        ```{ .console .no-copy}
        $ ansible-playbook k8s_install.yml --syntax-check

        playbook: k8s_install.yml
        $ ansible-lint k8s_install.yml

        Passed: 0 failure(s), 0 warning(s) on 12 files. Last profile that met the validation criteria was 'production'.
        ```

        !!! danger
            As the `--syntax-check` or `ansible-lint` are doing a static *code* analysis and the task-files are **not** included statically, possible syntax errors are not recognized!

        Your playbook will fail when running it live, revealing the syntax error.

    </div>

!!! info
    There are also big differences in resource consumption and performance, *imports* are quite lean and fast, while *includes* require a lot of management and accounting.

## Naming tasks

It is possible to leave off the *name* for a given task, though it is recommended to provide a description about why something is being done instead. This description is shown when the playbook is run.  
Write task names in the imperative (e.g. *"Ensure service is running"*), this communicates the action of the task. Start with a capital letter.

=== "Good"
    !!! success ""
        ```yaml
        --8<-- "example-install-package-task.yml"
        ```
=== "Bad"
    !!! failure ""
        ``` { .yaml .no-copy }
        - package:
            name: httpd
            state: present
        ```
        Using name parameter, but not starting with capital letter, nor describing the task properly.
        ``` { .yaml .no-copy }
        - name: install package
          package:
            name: httpd
            state: present
        ```

## Tags

Don't use too many tags, it gets confusing very quickly.  
Tags should only be allowed for imported task files within the `main.yml` of a role. Tags at the task level in sub-task files should be avoided.

```yaml title="tasks/main.yml"
--8<-- "example-main-with-tags-task.yml"
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

!!! warning
    **Work in Progress** - More description necessary.

=== "Good"
    !!! success ""
        ```yaml
        - name: Install webserver package
          ansible.builtin.package:
            name: httpd
            state: present
        ```
=== "Bad"
    !!! failure ""
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
    !!! success ""
        ```yaml
        --8<-- "example-install-package-task.yml"
        ```
=== "Bad"
    !!! failure ""
        ``` { .yaml .no-copy }
        - package:
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

For those used to */usr/bin/chmod*, remember that modes are actually octal numbers.  
Add a **leading zero** (or `1` for setting sticky bit), showing Ansible’s YAML parser it is an octal number **and** quote it (like `"0644"` or `"1777"`), this way Ansible receives a string and can do its own conversion from string into number.

!!! warning
    Giving Ansible a number without following one of these rules will end up with a decimal number which can have unexpected results.

=== "Good"
    !!! success ""
        ```yaml
        --8<-- "example-copy-template-task.yml"
        ```
=== "Bad"
    !!! failure ""
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

## Files vs. Templates

Ansible differentiates between *files* for static content (deployed with `copy` module) and *templates* for content, which should be rendered dynamically with Jinja2 (deployed with `template` module).  

!!! tip
    In almost every case, use *templates*, deployed via `template` module.  

Even if there currently is nothing in the file that is being templated, if there is the possibility in the future that it might be added, having the file handled by the `template` module makes adding that functionality much simpler than if the file is initially handled by the `copy` module( and then needs to be moved before it can be edited).

Additionally, you now can add a *marker*, indicating that manual changes to the file will be lost:

=== "Template"

    ```yaml+jinja
    {{ ansible_managed | ansible.builtin.comment }}
    ```

=== "Rendered output"

    ```cfg
    #
    # Ansible Managed
    #
    ```

??? info "`ansible.builtin.comment` filter"
    By default, `{{ ansible_managed }}` is replaced by the string `Ansible Managed` as is (can be adjusted in the [`ansible.cfg`)](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-managed-str){:target="_blank"}.  
    In most cases, the appropriate *comment* symbol must be prefixed, this should be done with the `ansible.builtin.comment` filter.  
    For example, `.xml` files need to be commented differently, which can be configured:

    === "Template"

        ```yaml+jinja
        {{ ansible_managed | ansible.builtin.comment('xml') }}
        ```

    === "Rendered output"
        ```xml
        <!--
        -
        - Ansible managed
        -
        -->
        ```

    You can also use the `decorate` parameter to choose the symbol yourself.  
    Take a look at the [Ansible documentation for additional information](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/comment_filter.html){:target="_blank"}.

When using the `template` module, append `.j2` to the template file name. Keep filenames and templates as close to the name on the destination system as possible.

## Conditionals

If the `when:` condition results in a line that is very long, and is an `and` expression, then break it into a list of conditions.

=== "Good"
    !!! success ""
        ```yaml
        --8<-- "example-multiple-when-conditions-task.yml"
        ```
=== "Bad"
    !!! failure ""
        ``` { .yaml .no-copy }
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
        --8<-- "example-block-with-when-tasks.yml"
        ```
=== "Bad"
    !!! failure ""
        ``` { .yaml .no-copy }
        - name: Install, configure, and start Apache
          block:
            - name: Install httpd and memcached
              ansible.builtin.package:
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
--8<-- "example-loop-label-task.yml"
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
    !!! success ""
        ```console
        TASK [common : Create local users] *********************************************
        Friday 18 November 2022  12:18:01 +0100 (0:00:01.955)       0:00:03.933 *******
        changed: [demo] => (item=tgruetz)
        changed: [demo] => (item=joschmi)
        changed: [demo] => (item=mfrink)
        ```
=== "Bad"
    !!! failure ""
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

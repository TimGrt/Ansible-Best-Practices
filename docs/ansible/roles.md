# Roles

New playbook functionality is always added in a role. Roles should only serve a defined purpose that is unambiguous by the role name.
The role name should be short and unique. It is separated with hyphens, if it consists of several words.

## Readme

Every role must have a role-specific `README.md` describing scope and focus of the role. Use the following example:

````markdown
# Role name/title

Brief description of the role, what it does and what not.

## Requirements

Technical requirements, e.g. necessary packages/rpms, own modules or plugins.

## Role Variables

The role uses the following variables:

| Variable Name | Type    | Default Value | Description            |
| ------------- | ------- | ------------- | ---------------------- |
| example       | Boolean | false         | Brief description      |

## Dependencies

This role expects to run **after** the following roles:
* repository
* networking
* common
* software

## Tags

The role can be executed with the following tags:
* install
* configure
* service

## Example Playbook

Use the role in a playbook like this (after running plays/roles from dependencies section):
```yaml
- name: Execute role
  hosts: example_servers
  become: true
  roles:
    - example_role
```

## Authors

Tim Grützmacher - <tim.gruetzmacher@computacenter.com>

````

## Role structure

### Role skeleton

The `ansible-galaxy` utility can be used to create the role *skeleton* with the following command:

```console
ansible-galaxy role init roles/demo
```

This would create the following directory:

``` { .console .no-copy }
roles/demo/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
├── .travis.yml
└── vars
    └── main.yml
```

At least the folders (and content) `tests` (a sample inventory and playbook for testing, we will use a different testing method) and `vars` (variable definitions, not used according to this Best Practice Guide, because we use only *group_vars*, *host_vars* and *defaults*) are not necessary. Also the `.travis.yml` (a CI/CD solution) definition is not useful.

!!! tip
    Use a custom role skeleton which is used by `ansible-galaxy`!

Consider the following role skeleton, note the missing *vars* and *test* folder and the newly added [Molecule folder](testing.md#molecule).

``` { .console .no-copy }
roles/role_skeleton/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── molecule
│   └── default
│       ├── converge.yml
│       └── molecule.yml
├── README.md
├── tasks
│   └── main.yml
└── templates
```

You need to define the following parameter in your custom `ansible.cfg`:

```ini
[galaxy]
role_skeleton = roles/role_skeleton
```

!!! success
    Afterwards, initializing a new role with `ansible-galaxy role init` creates a role structure with exactly the content you need!

## Metadata

The role *can* contain a `meta/main.yml` file which can be used to define **role dependencies**, **optional Galaxy Metadata**, **role argument validation** and **multiple entrypoints**.

### Role dependencies

Role dependencies let you automatically pull in other roles when using a role. Ansible loads all listed roles, runs the roles listed under dependencies first, then runs the role that lists them.

```yaml title="meta/main.yml"
---
dependencies:
  - role: common
  - role: apache
    vars:
      apache_port: 80
  - role: postgres
    vars:
      dbname: blarg
      other_parameter: 12
```

With the above, Ansible would execute `common` role first, `apache` role second, `postgres` role third and, at last, the role which defined these dependencies.

### Multiple entrypoints

Sometimes it can be useful to run only specific tasks from a role (these tasks should be kept in a separate task file), instead of the complete role. Take a look at the following playbook:

```yaml title="Playbook"
---
- name: Install and configure webserver
  hosts: webservers
  pre_tasks:
    - name: Run Red Hat-specific tasks from common role
      ansible.builtin.import_role:
        name: common
        tasks_from: redhat
      when: "ansible_facts['os_family'] == 'RedHat'"
  roles:
    - webserver
```

The playbook above would run only the tasks from `roles/common/tasks/redhat.yml`, before executing the `webserver` role.

!!! tip
    The usage of a different entry-points is possible **without** using `meta/main.yml`, but is especially useful when using *role argument validation*.

### Role argument validation

When defined, a new task is inserted at the beginning of role execution that will validate the parameters (*variables*) supplied for the role against the specification. If the parameters fail validation, the role will fail execution.

!!! info
    Image the *input parameters* as variables with **no default values** which your role relies on and, if undefined, should stop/fail your role before doing any work.

=== "Metadata definition"
    !!! example "meta/main.yml"

        ```yaml
        ---
        argument_specs: # (1)!
          main: # (2)!
            options: # (3)!
              tenant_name: # (4)!
                required: true # (5)!
                type: str # (6)!
                description: Name of tenant to be created in the APIC. # (7)!

              tenant_description: # (8)!
                type: str
                description: Description of the tenant, typically an email address.

              application_profile_name:
                required: true
                type: str
                description: Name of the application profile to be created within the tenant.

              application_profile_monitoring_policy:
                type: str
                description: Monitoring policy for the application profile.
                choices: # (9)!
                  - default
                  - custom

              epg_list:
                required: true
                type: list
                elements: dict # (10)!
                description: |
                  List of EPGs to be created within the tenant.
                  Each EPG must have an 'epg_name' and can optionally have an 'epg_description' and a 'priority'.
                options: # (11)!
                  epg_name:
                    required: true
                    type: str
                    description: Name of the EPG.
                  epg_description:
                    type: str
                    description: Description of the EPG.
                  priority:
                    type: int
                    description: The QoS class. Will be prefixed with 'level', e.g. 'level1'
                    choices:
                      - 1
                      - 2
                      - 3
        ```

        1. The *key* to define role argument specifications.
        2. The role *entry point* name, should be `main` first. Any additional entry-point is added as a new dict key with the same structure as shown. The key name will be the base name of the tasks file to execute, with no `.yml` or `.yaml` file extension.
        3. Options are often called *parameters* or *arguments*, these are the necessary *input* **variable** for your role.
        4. The variable name.
        5. Marks this variable as definitely necessary, if it is missing, the role will abort.
        6. The data type of the variable, can be one of: `str`, `int`, `float`, `bool`, `list`, `dict`, `path`, `raw`, `jsonarg`, `json`, `bytes`, `bits`
        7. A longer description that may contain multiple lines. Use `short_description` as an alternative which should always be a string and never a list, and should **not** end in a period.
        8. Example for an *optional* variable, there is no `required: true` here.
        9. List of allowed option values.
        10. Specifies the data type for list elements when the type is `list`.
        11. If the parent option takes a `dict` or `list` of dicts, you can define the structure here.

=== "Execution output"

    !!! success "Output with valid arguments"
        ```console
        PLAY [ACI automation] **************************************************************

        TASK [apic : Validating arguments against arg spec 'main'] *************************
        ok: [sandboxapicdc.cisco.com]

        TASK [apic : Create tenant] ********************************************************
        ...
        ```

    ??? failure "Output with failed argument validation"
        ```console
        PLAY [ACI automation] ***********************************************************

        TASK [apic : Validating arguments against arg spec 'main'] **********************
        fatal: [sandboxapicdc.cisco.com]: FAILED! =>
            argument_errors:
            - 'missing required arguments: tenant_name'
            argument_spec_data:
                application_profile_monitoring_policy:
                    choices:
                    - default
                    - custom
                    description: Monitoring policy for the application profile.
                    type: str
                application_profile_name:
                    description: Name of the application profile to be created within the tenant.
                    required: true
                    type: str
                epg_list:
                    description: |-
                        List of EPGs to be created within the tenant.
                        Each EPG must have an 'epg_name' and can optionally have an 'epg_description' and a 'priority'.
                    elements: dict
                    options:
                        epg_description:
                            description: Description of the EPG.
                            type: str
                        epg_name:
                            description: Name of the EPG.
                            required: true
                            type: str
                        priority:
                            choices:
                            - 1
                            - 2
                            - 3
                            description: The QoS class. Will be prefixed with 'level', e.g. 'level1'
                            type: int
                    required: true
                    type: list
                tenant_description:
                    description: Description of the tenant, typically an email address.
                    type: str
                tenant_name:
                    description: Name of tenant to be created in the APIC.
                    required: true
                    type: str
            changed: false
            msg: |-
                Validation of arguments failed:
                missing required arguments: tenant_name
            validate_args_context:
                argument_spec_name: main
                name: apic
                path: /home/timgrt/ansible-community-call-solutions/2025-08-12-advanced-role-usage/roles/apic
                type: role

        PLAY RECAP **********************************************************************
        sandboxapicdc.cisco.com    : ok=0    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
        ```

Use the [documentation for role argument validation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#role-argument-validation){:target="_blank"} to view all available options.

!!! tip
    Role argument validation can be used for **basic** input validation, but is limited to checking the correct type (also for deeply nested elements in dicts or lists) and ensuring that only allowed choices can be provided.  

    For **anything more sophisticated** necessary to validate input variables (e.g. ensure that a string is a valid email, an IPv4 address, matches a defined regex pattern, ...) take a look at the [Variables section](variables.md#variable-validation) for the `ansible.builtin.assert` or `ansible.builtin.validate` modules.

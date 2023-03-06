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
    - example-role
```

## Authors

Tim Grützmacher - <tim.gruetzmacher@computacenter.com>

````

## Role structure

### Role skeleton

The `ansible-galaxy` utility can be used to create the role *skeleton* with the following command:

```bash
ansible-galaxy role init roles/demo
```

This would create the following directory:

```bash
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

```bash
roles/role-skeleton/
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
role_skeleton = roles/role-skeleton
```

!!! success
    Afterwards, initializing a new role with `ansible-galaxy role init` creates a role structure with exactly the content you need!

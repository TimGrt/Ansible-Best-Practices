# Credentials

Credentials are utilized for authentication when launching Jobs against machines, synchronizing with inventory sources, and importing project content from a version control system.

You can grant users and teams the ability to use these credentials, without actually exposing the credential to the user.

## Custom Credentials

Although a growing number of [*credential types*](https://docs.ansible.com/automation-controller/latest/html/userguide/credentials.html#ug-credentials-cred-types){:target="_blank"} are already available, it is possible to
define additional *custom* credential types that works in ways similar to existing ones.  
For example, you could create a custom credential type that injects an API token for a third-party web service into an environment variable, which your playbook or custom inventory script could consume.

For example, to provide login credentials for plugins and modules of the [Dell EMC OpenManage Enterprise Collection](https://docs.ansible.com/ansible/latest/collections/dellemc/openmanage/ome_inventory_inventory.html#ansible-collections-dellemc-openmanage-ome-inventory-inventory){:target="_blank"} you need to create a custom credential, as no existing credentials type is available.  
You can set the *environment variables* `OME_USERNAME` and `OME_PASSWORD` by creating a new AAP credentials type.

In the left navigation bar, choose *Credential Types* and click *Add*, besides the name you need to fill two fields:

| Configuration            | Description                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| *Input*    | Which input fields you will make available when creating a credential of this type. |
| *Injector* | What your credential type will provide to the playbook                              |

```yaml title="Input Configuration"
fields:
  - type: string
    id: username
    label: Username
  - type: string
    id: password
    label: Password
    secret: true
required:
  - username
  - password
```

```yaml title="Injector Configuration"
env:
  OME_USERNAME: "{{ username }}"
  OME_PASSWORD: "{{ password }}"
```

!!! warning
    You are responsible for avoiding collisions in the `extra_vars`, `env`, and file namespaces. Also, avoid environment variable or extra variable names that start with `ANSIBLE_` because they are reserved.

Save your credential type, create a new credential of this type and attach it to the Job template with the playbook targeting the OpenManage Enterprise API.

An example task may look like this:

```yaml
--8<-- "example-credentials-from-env-task.yml"
```

!!! tip
    Depending on the module used, you may leave out the `username` and `password` key, environment variables are evaluated first.  Take a look at the module documentation if this is possible, otherwise use the *lookup* plugin as shown above.

Additional information can be found in the [Ansible documentation](https://docs.ansible.com/automation-controller/latest/html/userguide/credential_types.html){:target="_blank"}.

### Automation and templating

Creating a custom credential with a playbook can be tricky as you need to provide the special, reserved curly braces character as part of the *Injector Configuration*.  
During the playbook run, Ansible will try to template the values which will fail as they are undefined (and you want the *literal* string representation anyway). Therefore, prefix the values with `!unsafe` to prevent templating the values.

```yaml hl_lines="19 20"
--8<-- "example-custom-credential-task.yml"
```

Take a look at [Disable variable templating](variables.md#disable-variable-templating) for additional information.

# Variables

## Where to put variables

I always store all my variables at the following **three** locations:

* *group_vars* folder
* *host_vars* folder
* *defaults* folder in roles

The *defaults*-folder contains only default values for all variables used by the role.

## Naming Variables

The variable name should be self-explanatory (*as brief as possible, as detailed as necessary*), use multiple words and don't shorten things.

* Multiple words are separated with underscores (`_`)
* *List*-Variables are suffixed with `_list`
* *Dictionary*-Variables are suffixed with `_dict`
* *Boolean* values are provided with lowercase `true` or `false`

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        download_directory: ~/.local/bin
        regions_list:
          - us-east
          - eu-central
        cidr_blocks_dict:
          production:
            vpc_cidr: "172.31.0.0/16"
          staging:
            vpc_cidr: "10.0.0.0/24"
        needs_agent: false
        knows_oop: true
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy }
        dir: ~/.local/bin
        regions:
          - us-east
          - eu-central
        cidr_blocks:
          production:
            vpc_cidr: "172.31.0.0/16"
          staging:
            vpc_cidr: "10.0.0.0/24"
        needsAgent: no
        knows_oop: True
        ```

!!! tip "Avoid deeply nested structures"
    While it may be tempting to create *nested* variable structures as the can hold loads of information, they may be hard to work with (lopp through, get specific fields, etc.).

    ```yaml
    logical_volumes:
      - device: /dev/sdb1
        volume_group: SSD-RAID1
        volumes:
          - name: lv0
            size: 20G
          - name: lv1
            size: 20G
      - device: /dev/sdc1
        volume_group: HDD-RAID1
        volumes:
          - name: lv0
            size: 20G
          - name: lv1
            size: 20G
    ```

    If dealing/creating with structures like these, ensure that at least every item contains the same set of keys.

    **Aim for *flat* variables if possible.**

## Referencing variables

After a variable is defined, use *Jinja2* syntax to reference it. Jinja2 variables use *double curly braces* (`{{` and `}}`).  
Use spaces after and before the double curly braces and the variable name.  
When referencing *list* or *dictionary* variables, try to use the *bracket notation* instead of the *dot notation*.
Bracket notation always works and you can use variables inside the brackets. Dot notation can cause problems because some keys collide with attributes and methods of python dictionaries.

=== "Good"
    !!! good-practice-no-title ""
        Simple variable reference:
        ```yaml
        --8<-- "example-simple-variable-task.yml"
        ```
        Bracket-notation and using variable (*interface_name*) inside:
        ```yaml
        --8<-- "example-bracket-notation-variable-task.yml"
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        Not using whitespaces around variable name.
        ``` { .yaml .no-copy }
        - name: Deploy configuration file
          ansible.builtin.template:
            src: foo.cfg.j2
            dest: "{{remote_install_path}}/foo.cfg"
        ```
        Not using whitespaces and using dot-notation.
        ``` { .yaml .no-copy }
        - name: Output IPv4 address of eth0 interface
          ansible.builtin.debug:
            msg: "{{ansible_facts.eth0.ipv4.address}}"
        ```

## Encrypted variables

!!! tip
    All variables with sensitive content should be *vault*-encrypted.  

Although encrypting just the value of a single variable is possible (with `ansible-vault encrypt_string`), you should avoid this. Store all sensitive variables in a single file and encrypt the whole file.  
For example, to store sensitive variables in `group_vars`, create the subdirectory for the group and within create two files named `vars.yml` and `vault.yml`.  
Inside of the `vars.yml` file, define all of the variables needed, including any sensitive ones. Next, copy all of the sensitive variables over to the `vault.yml` file and prefix these variables with `vault_`. Adjust the variables in the *vars* file to point to the matching *vault_* variables using Jinja2 syntax, and ensure that the vault file is vault encrypted.

=== "Good"
    !!! good-practice-no-title ""
        ```yaml
        ---
        # file: group_vars/database_servers/vars.yml
        username: "{{ vault_username }}"
        password: "{{ vault_password }}"
        ```
        ```yaml
        ---
        # file: group_vars/database_servers/vault.yml
        # NOTE: THIS FILE MUST ALWAYS BE VAULT-ENCRYPTED
        vault_username: admin
        vault_password: ex4mple
        ```
        ??? info "I can still read the credentials...?"
            Obviously, you wouldn't be able to read the content of the file `group_vars/database_servers/vault.yml`, as the file would be encrypted.  
            **This only demonstrates how the variables are referencing each other.**  
            The encrypted `vault.yml` file looks something like this:
            ``` { .yaml .no-copy }
            $ANSIBLE_VAULT;1.1;AES256
            30653164396132376333316665656131666165613863343330616666376264353830323234623631
            6361303062336532303665643765336464656164363662370a663834313837303437323332336631
            65656335643031393065333366366639653330353634303664653135653230656461666266356530
            3935346533343834650a323934346666383032636562613966633136663631636435333834393261
            36363833373439333735653262306331333062383630623432633134386138656636343137333439
            61633965323066633433373137383330366466366332626334633234376231393330363335353436
            62383866616232323132376366326161386561666238623731323835633237373036636561666165
            36363838313737656232376365346136633934373861326130636531616438643036656137373762
            39616234353135613063393536306536303065653231306166306432623232356465613063336439
            34636232346334386464313935356537323832666436393336366536626463326631653137313639
            36353532623161653266666436646135396632656133623762643131323439613534643430636333
            31386635613238613233
            ```
=== "Bad"
    !!! bad-practice-no-title ""
        ``` { .console .no-copy }
        # file: group_vars/database_servers.yml
        username: admin
        password: ex4mple
        ```

Defining variables this way makes sure that you can still find them with *grep*.  
Encrypting files can be done with this command:

```console
ansible-vault encrypt group_vars/database_servers/vault.yml
```

Once a variable file is encrypted, it should **not** be decrypted again (because it may get committed unencrypted). View or edit the file like this:

```console
ansible-vault view group_vars/database_servers/vault.yml
```

```console
ansible-vault edit group_vars/database_servers/vault.yml
```

!!! warning
    There are modules which will print the values of encrypted variables into STDOUT while using them or with higher verbosity. Be sure to check the parameters and return values of all modules which use encrypted variables!

A good example is the `ansible.builtin.user` module, it automatically obfuscates the value for the *password* parameter, replacing it with the string `NOT_LOGGING_PASSWORD`.  
The `ansible.builtin.debug` module on the other hand is a bad example, it will output the password in clear-text (well, by design, but this is not what you would expect)!

!!! success
    Always add the **`no_log: true`** key-value-pair for tasks that run the risk of leaking vault-encrypted content!

=== "Good"
    !!! good-practice-no-title ""
        ```yaml hl_lines="13"
        --8<-- "example-no-log-variable-playbook.yml"
        ```
        ??? info "Output of playbook run"
            Using the *stdout_callback: community.general.yaml* for better readability, see [Ansible configuration](project.md#ansible-configuration){:target="_blank"} for more info.  
            ``` { .console .no-copy .hl_lines="22" }
            $ ansible-playbook nolog.yml -v

            [...]

            TASK [Add user] *********************************************
            [WARNING]: The input password appears not to have been hashed. The 'password'
            argument must be encrypted for this module to work properly.
            ok: [db_server1] => changed=false
              append: false
              comment: ''
              group: 1002
              home: /home/admin
              move_home: false
              name: admin
              password: NOT_LOGGING_PASSWORD
              shell: /bin/bash
              state: present
              uid: 1002

            ASK [Debugging a vaulted Variable with no_log] *************
            ok: [db_server1] =>
              censored: 'the output has been hidden due to the fact that ''no_log: true'' was specified for this result'

            [...]

            ```
            The *debug* task does not print the value of the password, the output is censored.

            !!! hint
                Observing the output from the *"Add user"* task, you can see that the value of the *password* parameter is not shown.
                The *warning* from the *"Add user"* task stating an unencrypted password is related to not having hashed the password. You can achieve this by using the *password_hash* filter:
                ```yaml
                password: "{{ vault_password | password_hash('sha512', 'mysecretsalt') }}"
                ```
                This example uses the string `mysecretsalt` for salting, in cryptography, a salt is random data that is used as an additional input to a one-way function. Consider using a variable for the salt and treat it the same as the password itself!
                ```yaml
                password: "{{ vault_password | password_hash('sha512', vault_salt) }}"
                ```
                In this example, the salt is stored in a variable, the same way as the password itself. If you hashed the password, the warning will disappear.
=== "Bad"
    !!! bad-practice-no-title ""
        ``` { .yaml .no-copy hl_lines="13" }
        - name: Not using no_log parameter
          hosts: database_servers
          become: true
          tasks:
            - name: Add user
              ansible.builtin.user:
                name: "{{ username }}"
                password: "{{ password }}"

            - name: Debugging a vaulted Variable
              ansible.builtin.debug:
                msg: "{{ password }}"
        ​
        ```
        ??? info "Output of playbook run"
            ``` { .console .no-copy .hl_lines="22" }
            $ ansible-playbook nolog.yml -v

            [...]

            TASK [Add user] *********************************************
            [WARNING]: The input password appears not to have been hashed. The 'password'
            argument must be encrypted for this module to work properly.
            ok: [db_server1] => changed=false
              append: false
              comment: ''
              group: 1002
              home: /home/admin
              move_home: false
              name: admin
              password: NOT_LOGGING_PASSWORD
              shell: /bin/bash
              state: present
              uid: 1002

            ASK [Debugging a vaulted Variable with no_log] *************
            ok: [db_server1] =>
              msg: ex4mple

            [...]
            ```

### Prevent unintentional commits

Use a *pre-commit hook* to prevent accidentally committing unencrypted sensitive content. The easiest way would be to use the *pre-commit* framework/tool with the following configuration:

```yaml title=".pre-commit-config.yaml"
repos:
  - repo: https://github.com/timgrt/pre-commit-hooks
      rev: v0.2.1
      hooks:
        - id: check-vault-files
```

Take a look at the [development section](linting.md#git-pre-commit-hook) for additional information.

## Variable validation

Playbooks often need user input, this may lead to errors like

* required variables not provided
* wrong variable type (e.g. integer instead of string, string instead of list, ...)
* typos in variable values
* ...

It is useful to validate the user input early and provide a meaningful error message, if necessary.

### Assert module

For simple variable validations, use the [`ansible.builtin.assert` module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assert_module.html){:target="_blank"}, it checks if a given expressions evaluates to *true*.

```yaml
- name: Ensure AAP credentials are provided
  ansible.builtin.assert:
    that:
      - lookup('env', 'CONTROLLER_HOST') | length > 0
      - lookup('env', 'CONTROLLER_HOST') | length > 0
      - lookup('env', 'CONTROLLER_HOST') | length > 0
    quiet: true
    fail_msg: |
      AAP login credentials are missing!
      Export environment variables locally ir add the correct credential to the Job template.
```

The task above for example checks if three environment variables are set or rather contain input (the lookup plugin produces an empty string if the environment variable is not found). If the environment variable is found and is longer than zero, the expressions evaluates to true, otherwise the error message in the `fail_msg` parameter is shown and the playbook fails (for this host).

### Validate module

Input validation for complex (deeply nested) variables can be challenging with the `ansible.builtin.assert` module, therefore use the `ansible.utils.validate` module.  
By default, the [JSON Schema](https://json-schema.org/docs){:target="_blank"} engine is used by the module to validate the data with the provided criteria, other engines can be used as well.  

JSON Schema is extremely widely used and nearly equally widely implemented. There are implementations of JSON Schema validation for many programming languages or environments (e.g. you can use it in VScode where it will validate your variable files, while you are writing it, before you even run the playbook.) and it is well documented. It provides

* Structured Data Description
* Rule Definition and Enforcement
* Produce clear documentation
* Extensibility
* Data Validation

Take a look at the following example.

=== "Variable File"

    ```yaml
    ---
    server_list:
      - fqdn: server1.example.com
        ipv4_address_list:
          - 10.0.5.36
          - 192.168.2.67
        cores: 4
        memory: 16GB
        disk_space: 100GB
        business_owner: john.doe@example.com # (1)!
      - fqdn: server2 # (2)!
        ipv4_address_list:
          - 10.0.5.55
          - 192.168.2.89
        cores: 2
        memory: 8 # (3)!
        disk_space: 100GB
    ```
    { .annotate }

    1. This is an optional field, as you can in the [JSON Schema](#__tabbed_5_2) definition in line 47
    2. That is not a FQDN! The [JSON Schema](#__tabbed_5_2) definition validates that it is (line 17), as well as checking if the required domain is used.
    3. The memory value is expected to be a string, prefixed with GB. The [JSON Schema](#__tabbed_5_2) definition (line 34) ensures the correct type and prefix.

=== "JSON Schema"

    ```json linenums="1"
    {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "Server List variable file validation",
        "description": "A schema to validate the variable file containing the server list",
        "type": "object",
        "additionalProperties": false,
        "properties": {
            "server_list": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "properties": {
                        "fqdn": {
                            "type": "string",
                            "description": "Server name with example.com domain",
                            "pattern": "^([a-z0-9]+)(\\.example\\.com)$"
                        },
                        "ipv4_address_list": {
                            "type": "array",
                            "items": {
                                "type": "string",
                                "format": "ipv4"
                            }
                        },
                        "cores": {
                            "type": "number",
                            "minimum": 1,
                            "maximum": 64
                        },
                        "memory": {
                            "type": "string",
                            "description": "Memory size in GB, expects a number followed by GB",
                            "pattern": "^\\d+GB$"
                        },
                        "disk_space": {
                            "type": "string",
                            "description": "Disk size in GB, expects a number followed by GB",
                            "pattern": "^\\d+GB$"
                        },
                        "business_owner": {
                            "type": "string",
                            "description": "Email address of the responsible person for this server",
                            "format": "email"
                        }
                    },
                    "required": [
                        "fqdn",
                        "ipv4_address_list",
                        "cores",
                        "memory",
                        "disk_space"
                    ]
                }
            }
        },
        "required": [
            "server_list"
        ]
    }
    ```

To validate the variable file with the provided JSON Schema file, use the following task:

```yaml
- name: Variable file validation
  ansible.utils.validate:
    data: "{{ lookup('file', 'variables.yml') | from_yaml | to_json }}"
    criteria: "{{ lookup('file', 'json_schemas/server_list_validation.json') }}"
    engine: ansible.utils.jsonschema
```

The files are read in with a file lookup, the variables file is converted to JSON.  
To be able to use the module (or the filter-, test- or lookup-Plugin with the same name), you'll need the `ansible.utils` collection and an additional Python package:

```console
ansible-galaxy collection install ansible.utils
```

```console
pip3 install jsonschema
```

??? example "Playbook output showing validation errors"

    ```{. console .hl_lines="11 12 22 23" .no-copy }
    TASK [Variable file validation] ****************************************************************************************
    fatal: [localhost]: FAILED! =>
        changed: false
        errors:
        -   data_path: server_list.1.fqdn
            expected: ^([a-z0-9]+)(\.example\.com)$
            found: server2
            json_path: $.server_list[1].fqdn
            message: '''server2'' does not match ''^([a-z0-9]+)(\\.example\\.com)$'''
            relative_schema:
                description: Server name with example.com domain
                pattern: ^([a-z0-9]+)(\.example\.com)$
                type: string
            schema_path: properties.server_list.items.properties.fqdn.pattern
            validator: pattern
        -   data_path: server_list.1.memory
            expected: string
            found: 8
            json_path: $.server_list[1].memory
            message: 8 is not of type 'string'
            relative_schema:
                description: Memory size in GB, expects a number followed by GB
                pattern: ^\d+GB$
                type: string
            schema_path: properties.server_list.items.properties.memory.type
            validator: type
        msg: |-
            Validation errors were found.
            At 'properties.server_list.items.properties.fqdn.pattern' 'server2' does not match '^([a-z0-9]+)(\\.example\\.com)$'.
            At 'properties.server_list.items.properties.memory.type' 8 is not of type 'string'.

    PLAY RECAP *************************************************************************************************************
    localhost                  : ok=0    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0  
    ```

To create the initial JSON schema for your variable input, multiple tools are available online, for example to convert from [YAML to JSON](https://transform.tools/yaml-to-json){:target="_blank"} and afterwards from [JSON to JSON-Schema](https://transform.tools/json-to-json-schema){:target="_blank"}.

??? example "Usage with `ansible.utils.validate` filter plugin, also for single variable"

    The previous examples validated complete variable files (with potentially multiple variables), the following example shows how to validate a single variable (the same as above) with a provided JSON schema file.  
    It will also make use of the `ansible.utils.validate` plugin with additional tasks for a more dense output.

    === "Tasks"

        ```yaml
        - name: Run variable validation
          ansible.builtin.set_fact:
            server_list_variable_validation: "{{ server_list | ansible.utils.validate(validation_criteria, engine='ansible.utils.jsonschema') }}"
          vars:
            validation_criteria: "{{ lookup('ansible.builtin.file', 'json_schemas/server_list.json') }}"

        - name: Output validation errors for server_list variable
          ansible.builtin.debug:
            msg: "Error in {{ item.data_path }}"
          loop: "{{ server_list_variable_validation }}"
          loop_control:
            label: "{{ item.message }}"
          when: server_list_variable_validation | length > 0

        - name: Assert variable validation
          ansible.builtin.assert:
            that:
              - server_list_variable_validation | length == 0
            quiet: true
            fail_msg: "Validation failed, fix the errors shown above!"
        ```

        The validation plugin produces a list of validations. The second task is shown if the list contains entries, the last task fails the playbook by using the assert module if the validation list is not empty.

    === "JSON Schema"

        Pretty much the same validation as before, but this time the uppermost type (line) is *array* (a *list*).

        ```json hl_lines="5"
        {
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "title": "Server List variable validation",
            "description": "A schema to validate the variable server_list",
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                    "fqdn": {
                        "type": "string",
                        "description": "Server name with example.com domain",
                        "pattern": "^([a-z0-9]+)(\\.example\\.com)$"
                    },
                    "ipv4_address_list": {
                        "type": "array",
                        "items": {
                            "type": "string",
                            "format": "ipv4"
                        }
                    },
                    "cores": {
                        "type": "number",
                        "minimum": 1,
                        "maximum": 64
                    },
                    "memory": {
                        "type": "string",
                        "description": "Memory size in GB, expects a number followed by GB",
                        "pattern": "^\\d+GB$"
                    },
                    "disk_space": {
                        "type": "string",
                        "description": "Disk size in GB, expects a number followed by GB",
                        "pattern": "^\\d+GB$"
                    },
                    "business_owner": {
                        "type": "string",
                        "description": "Email address of the responsible person for this server",
                        "format": "email"
                    }
                },
                "required": [
                    "fqdn",
                    "ipv4_address_list",
                    "cores",
                    "memory",
                    "disk_space"
                ]
            }
        }
        ```

    The tasks produce the following output, only showing the *data path* and the *violation message* as the list item label.

    ``` { .console .no-copy }
    TASK [Run variable validation] **************************************************************************************
    ok: [localhost]

    TASK [Output validation errors for server_list variable] ************************************************************
    ok: [localhost] => (item='server2' does not match '^([a-z0-9]+)(\\.example\\.com)$') =>
        msg: Error in 1.fqdn
    ok: [localhost] => (item=8 is not of type 'string') =>
        msg: Error in 1.memory

    TASK [Assert variable validation] ***********************************************************************************
    fatal: [localhost]: FAILED! =>
        assertion: server_list_variable_validation | length == 0
        changed: false
        evaluated_to: false
        msg: Validation failed, fix the errors shown above!

    PLAY RECAP **********************************************************************************************************
    localhost                  : ok=2    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
    ```

## Disable variable templating

Sometimes, it is necessary to provide special characters like curly braces. The most common use cases include passwords that allow special characters like `{` or `%`, and JSON arguments that look like templates but should not be templated.  

```{ .yaml .no-copy }
---
examplepassword: !unsafe 234%234{435lkj{{lkjsdf
```

!!! abstract
    When handling values returned by lookup plugins, Ansible uses a data type called `unsafe` to block templating. Marking data as unsafe prevents malicious users from abusing Jinja2 templates to execute arbitrary code on target machines. The Ansible implementation `!unsafe` ensures that these values are never templated. You can use the same unsafe data type in variables you define, to prevent templating errors and information disclosure.

For complex variables such as hashes or arrays, use `!unsafe` on the individual elements, take a look at [this example for AWX/AAP automation](credentials.md#automation-and-templating).

For Jinja2 templates this behavior can be achieved with the `{% raw %}` and `{% endraw %}` tags.  
Consider the following *template* where *name_of_receiver_group* should be replaced with a variable you set elsewhere, but *details* contains stuff which should stay as it is:

```{ .yaml .title="templates/alertmanager.yml.j2" .no-copy }
receivers:
- name: "{{ name_of_receiver_group }}"
  opsgenie_configs:
  - api_key: 123-123-123-123-123
    send_resolved: false
    {% raw %}
    # protecting the go templates inside the raw section.
    details: { details: "{{ .CommonAnnotations.SortedPairs.Values | join \" \" }}" }
    {% endraw %}
```

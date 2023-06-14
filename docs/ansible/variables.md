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
        create_key: true
        needs_agent: false
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        ```yaml
        dir: ~/.local/bin
        create_key: yes
        needsAgent: no
        knows_oop: True
        ```

## Referencing variables

After a variable is defined, use *Jinja2* syntax to reference it. Jinja2 variables use *double curly braces* (`{{` and `}}`).  
Use spaces after and before the double curly braces and the variable name.  
When referencing *list* or *dictionary* variables, try to use the *bracket notation* instead of the *dot notation*.
Bracket notation always works and you can use variables inside the brackets. Dot notation can cause problems because some keys collide with attributes and methods of python dictionaries.

=== "Good"
    !!! good-practice-no-title ""
        Simple variable reference:
        ```yaml
        - name: Deploy configuration file
          ansible.builtin.template:
            src: foo.cfg.j2
            dest: "{{ remote_install_path }}/foo.cfg"
        ```
        Bracket-notation and using variable (*interface_name*) inside:
        ```yaml
        - name: Output IPv4 address of {{ interface_name }} interface
          ansible.builtin.debug:
            msg: "{{ ansible_facts[interface_name]['ipv4']['address'] }}"
        ```
=== "Bad"
    !!! bad-practice-no-title ""
        Not using whitespaces around variable name.
        ```yaml
        - name: Deploy configuration file
          ansible.builtin.template:
            src: foo.cfg.j2
            dest: "{{remote_install_path}}/foo.cfg"
        ```
        Not using whitespaces and using dot-notation.
        ```yaml
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
            ```yaml
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
        ```yaml
        # file: group_vars/database_servers.yml
        username: admin
        password: ex4mple
        ```

Defining variables this way makes sure that you can still find them with *grep*.  
Encrypting files can be done with this command:

```bash
ansible-vault encrypt group_vars/database_servers/vault.yml
```

Once a variable file is encrypted, it should **not** be decrypted again (because it may get committed unencrypted). View or edit the file like this:

```bash
ansible-vault view group_vars/database_servers/vault.yml
```

```bash
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
        ---
        - name: Using no_log parameter
          hosts: database_servers
          tasks:
            - name: Add user
              ansible.builtin.user:
                name: "{{ username }}"
                password: "{{ password }}"

            - name: Debugging a vaulted variable with no_log
              ansible.builtin.debug:
                msg: "{{ password }}"
              no_log: true
        ```
        ??? info "Output of playbook run"
            Using the *stdout_callback: community.general.yaml* for better readability, see [Ansible configuration](project.md#ansible-configuration) for more info.  
            ```bash hl_lines="22"
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
        ```yaml hl_lines="13"
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
            ```bash hl_lines="22"
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
      rev: v0.2.0
      hooks:
        - id: check-vault-files
```

Take a look at the [development section](linting.md#git-pre-commit-hook) for additional information.

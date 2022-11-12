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
    !!! success ""
        ```yaml
        download_directory: ~/.local/bin
        create_key: true
        needs_agent: false
        ```
=== "Bad"
    !!! failure ""
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
    !!! success ""
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
    !!! failure ""
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
    !!! success ""
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
            The encrypted file looks something like this:
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
    !!! failure ""
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

Once a variable file is encrypted, it should **not** be decrypted again (because it may get commited unencrypted). View or edit the file like this:

```bash
ansible-vault view group_vars/database_servers/vault.yml
```
```bash
ansible-vault edit group_vars/database_servers/vault.yml
```

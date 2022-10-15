# Variables

## Where to put variables

I always store all my variables at the following **three** locations:

* *group_vars* folder
* *host_vars* folder
* *defaults* folder in roles

The *defaults*-folder contains only default values for all variables used by the role.

## Naming Variables

The variable name should be self-explanatory, use multiple words and don't shorten things.

* Multiple words are separated with underscores (`_`)
* *List*-Variables are suffixed with `_list`
* *Dictionary*-Variables are suffixed with `_dict`

=== "Good"
    !!! success ""
        ```yaml
        download_directory: ~/.local/bin


        ```
=== "Bad"
    !!! failure ""
        ```yaml
        dir: ~/.local/bin
        ```

## Encrypted variables

!!! tip
    All variables with sensitive content should be *vault*-encrypted.  

Although encrypting just the value of a single variable is possible (with `ansible-vault encrypt_string`), you should avoid this. Store all sensitive variables in a single file and encrypt to file.  
For example, to store sensitive variables in `group_vars`, create the subdirectory for the group and within create two files named `vars.yml` and `vault.yml`.  
Inside of the `vars.yml` file, define all of the variables needed, including any sensitive ones. Next, copy all of the sensitive variables over to the `vault.yml` file and prefix these variables with `vault_`. Adjust the variables in the *vars* file to point to the matching *vault_* variables using Jinja2 syntax, and ensure that the vault file is vault encrypted.

=== "Good"
    !!! success ""
        ```yaml
        ---
        # file: group_vars/database_servers/vars.yml
        username: "{{ vault_username }}"
        password: "{{ vault_password }}"

        ---
        # file: group_vars/database_servers/vault.yml
        # NOTE: THIS FILE MUST ALWAYS BE VAULT-ENCRYPTED
        vault_username: admin
        vault_password: s3cr3tp4$$w0rd
        ```
=== "Bad"
    !!! failure ""
        ```yaml
        # file: group_vars/database_servers.yml
        username: admin
        password: s3cr3tp4$$w0rd
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

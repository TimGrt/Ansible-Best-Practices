# Inventory

!!! warning
    **Work in Progress** - More description necessary.

## Convert INI to YAML

The most common format for the *Ansible Inventory* is the `.ini` format, but sometimes you might need the inventory file in the *YAML* format.  
 A `.ini` inventory file for example might look like this:

```ini title="inventory.ini"
[control]
controller ansible_host=localhost ansible_connection=local

[target]
rocky8 ansible_connection=docker
```

You can convert your existing inventory to the YAML format with the `ansible-inventory` utility.

```bash
ansible-inventory -i inventory.ini -y --list > inventory.yml
```

The resulting file is your inventory in YAML format:

```yaml title="inventory.yml"
all:
  children:
    control:
      hosts:
        controller:
          ansible_connection: local
          ansible_host: localhost
    target:
      hosts:
        rocky8:
          ansible_connection: docker
```
 
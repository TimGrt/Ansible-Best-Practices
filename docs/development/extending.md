# Extending Ansible

Ansible is easily customizable, you can extend Ansible by adding custom modules or plugins.  
You might wonder whether you need a module or a plugin. Ansible modules are units of code that can control system resources or execute system commands. Ansible provides a module library that you can execute directly on remote hosts or through playbooks.  
Similar to modules are plugins, which are pieces of code that extend core Ansible functionality. Ansible uses a plugin architecture to enable a rich, flexible, and expandable feature set. It ships with several plugins and lets you easily use your own plugins.

## Custom facts

The `setup` module in Ansible automatically discovers a standard set of facts about each host. If you want to add custom values to your facts, you can provide permanent custom facts using the `facts.d` directory or even write a custom facts module.

### Static facts

The easiest method is to add an `.ini` file to `/etc/ansible/facts.d` on the remote host, e.g.

```ini title="/etc/ansible/facts.d/general.fact"
[owner]
name=Computacenter AG
community=Ansible Community

[environment]
stage=production
```

!!! warning
    Ensure the file has the `.fact` extension and is **not** executable, this will break the `ansible.builtin.setup` module!

For example, running an ad-hoc command against an example host with the custom fact:

```bash
$ ansible -i inventory test -m ansible.builtin.setup -a filter=ansible_local
ubuntu | SUCCESS => {
     "ansible_facts": {
        "ansible_local": {
            "general": {
                "environment": {
                    "stage": "production"
                },
                "owner": {
                    "community": "Ansible Community",
                    "name": "Computacenter AG"
                }
            }
        },
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false
}
```

The parent key for the custom fact is the name of the file, the lower keys are the section names of the *ini* file.

!!! hint
    The key in `ansible_facts` for custom content is always `ansible_local`, this has nothing to do with running locally.

### Dynamic facts

You can also use `facts.d` to execute a script on the remote host, generating dynamic custom facts to the *ansible_local* namespace. Consider the following points when creating dynamic custom facts:

* must return JSON data
* must have the `.fact` extension (therefor add the correct Shebang)
* is executable by the Ansible connection user
* dependencies must be installed on the remote host

For example, a custom fact returning information about running or exited Docker containers on the remote host can look like this:

```python title="/etc/ansible/facts.d/docker-containers.fact"
#!/usr/bin/env python3

# DEPENDENCY: requires Python module 'docker', install e.g. with 'pip3 install docker' or install 'python3-docker' rpm with package manager

import json

try:
    import docker
except ModuleNotFoundError:
    print(json.dumps({"error": "Python docker module not found! Install requirements!"}))
    raise SystemExit()

try:
    client = docker.from_env()
except docker.errors.DockerException:
    print(json.dumps({"error": "Docker Client not instantiated! Is Docker running?"}))
    raise SystemExit()

def exited_containers():
    exited_containers = []

    for container in client.containers.list(all=True,filters={"status": "exited"}):
        exited_containers.append({"id": container.short_id, "name": container.name, "image": container.image.tags[0]})

    return exited_containers

def running_containers():
    running_containers = []

    for container in client.containers.list():
        running_containers.append({"id": container.short_id, "name": container.name, "image": container.image.tags[0]})

    return running_containers


def main():

    container_facts = {"running": running_containers(), "exited": exited_containers()}
    print(json.dumps(container_facts))

if __name__ == '__main__':
   main()
```

The custom fact returns a JSON dictionary with two lists, `running` and `exited`. Every list item has the Container ID, name and image.

??? warning
    Using the fact requires the Python docker module (mind the `import docker` statement) and the Docker service running on the target node.  
    Otherwise, an error message is returned, e.g.:

    ```bash
    "ansible_local": {
            "docker-containers": {
                "error": "Python docker module not found! Install requirements!"
            }
        }
    ```
    ```bash
    "ansible_local": {
            "docker-containers": {
                "error": "Docker Client not instantiated! Is Docker running?"
            }
        }
    ```

Executing fact gathering for example returns this:

```bash
$ ansible -i inventory test -m setup -a filter=ansible_local
ubuntu | SUCCESS => {
    "ansible_facts": {
        "ansible_local": {
            "docker-containers": {
                "exited": [
                    {
                        "id": "a6bfc512b842",
                        "image": "timgrt/rockylinux8-ansible:latest",
                        "name": "rocky-linux"
                    }
                ],
                "running": [
                    {
                        "id": "f3731d560625",
                        "image": "local/timgrt/ansible-best-practices:latest",
                        "name": "ansible-best-practices"
                    }
                ]
            }
        },
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false
}
```

In the example, we have one running container and one stopped container.

??? example "Additional info"
    Running `docker ps` on the target host
    ```bash
    $ docker ps -a
    CONTAINER ID   IMAGE                                 COMMAND                  CREATED             STATUS                           PORTS                  NAMES
    a6bfc512b842   timgrt/rockylinux8-ansible:latest     "/usr/lib/systemd/sy…"   About an hour ago   Exited (137) About an hour ago                          rocky-linux
    f3731d560625   local/timgrt/ansible-best-practices   "/bin/sh -c 'python …"   4 hours ago         Up 4 hours                       0.0.0.0:8080->80/tcp   ansible-best-practices
    ```
    Executing the script standalone (using a JSON module for better readability):
    ```bash
    $ /etc/ansible/facts.d/docker-containers.fact | python3 -m json.tool
    {
        "running": [
            {
                "id": "f3731d560625",
                "name": "ansible-best-practices",
                "image": "local/timgrt/ansible-best-practices:latest"
            }
        ],
        "exited": [
            {
                "id": "a6bfc512b842",
                "name": "rocky-linux",
                "image": "timgrt/rockylinux8-ansible:latest"
            }
        ]
    }
    ```

## Store custom content

Custom modules can be stored in the `library` folder in your project root directory, plugins need to be stored in folders called `<plugin type>_plugins`, e.g. `filter_plugins`. These locations are still valid, but it is **recommended** to store custom content in a *collection*, this way you have all your custom content in a single location (folder).

You can store custom collections with your Ansible project, create it with the *ansible-galaxy* utility and provide the `--init-path` parameter. The folder `collections/ansible_collections` will automatically be picked up by Ansible (although your custom collection is not shown by the `ansible-galaxy collection list` command, adjust the `ansible.cfg` for that, take a look into the next subsection).

```bash
ansible-galaxy collection init computacenter.utils --init-path collections/ansible_collections
```

This creates the following structure:

```bash
collections/
└── ansible_collections
    └── computacenter
        └── utils
            ├── README.md
            ├── docs
            ├── galaxy.yml
            ├── plugins
            │   └── README.md
            └── roles
```

Create subfolders beneath the `plugins` folder, `modules` for modules and e.g. `filter` for filter plugins. Take a look into the included `README.md` in the *plugins* folder. Store your custom content in python files in the respective folders.

!!! tip
    Only underscores (`_`) are allowed for filenames inside collections!  
    Naming a file `cc-filter-plugins.py` will result in an error!

### Listing (custom) collections

When storing custom collections alongside your project and you want to list all collections, you need to adjust your Ansible configuration. You will be able to use your custom collection nevertheless, this is more a quality of life change.

Adjust the `collections_paths` parameter in the `defaults` section of your `ansible.cfg`:

```ini
[defaults]
collections_paths = ~/.ansible/collections:/usr/share/ansible/collections:./collections
```

The first two paths are the default locations for collections, paths are separated with colons.

??? example "Listing collections"
    Using a custom collection in the project folder `test` with adjusted configuration file.
    ```bash
    $ ansible-galaxy collection list

    # /home/tgruetz/.ansible/collections/ansible_collections
    Collection        Version
    ----------------- -------
    ansible.netcommon 4.1.0  
    ansible.posix     1.4.0  
    ansible.utils     2.8.0  
    cisco.aci         2.3.0  
    cisco.ios         4.2.0  
    community.docker  3.3.2  
    community.general 6.1.0  

    # /home/tgruetz/test/collections/ansible_collections
    Collection          Version
    ------------------- -------
    computacenter.utils 1.0.0
    ```

## Developing modules

Modules are reusable, standalone scripts that can be used by the Ansible API, the *ansible* command, or the *ansible-playbook* command.   Modules provide a defined interface. Each module accepts arguments and returns information to Ansible by printing a JSON string to stdout before exiting. **Modules execute on the target system (usually that means on a remote system) in separate processes.** Modules are technically plugins, but for historical reasons we do not usually talk about “module plugins”.

!!! warning
    **Work in Progress** - More description necessary.

## Developing plugins

Plugins extend Ansible’s core functionality and **execute on the control node within the /usr/bin/ansible process.** Plugins offer options and extensions for the core features of Ansible e.g. transforming data, logging output, connecting to inventory, and more. Take a look into the [*Ansible Developer Documentation*](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html){:target="_blank"} for an overview of the different plugin types.

All plugins must

* be written in Python ([*in a compatible version of Python*](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#control-node-requirements){:target="_blank"})
* raise errors ([*when things go wrong*](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#raising-errors){:target="_blank"})
* return strings in unicode ([*to run through Jinja2*](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#string-encoding){:target="_blank"})
* conform to Ansible’s configuration and documentation standards ([*how to use your plugin*](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#plugin-configuration-documentation-standards){:target="_blank"})

Depending on the type of plugin you want to create, different considerations need to be taken, the next subsections give a brief overview with a small example. Always use the latest Ansible documentation for additional information.

!!! tip
    The usage of the FQCN for your Plugin is mandatory!

### Filter plugins

[Filter plugins](https://docs.ansible.com/ansible/latest/dev_guide/developing_plugins.html#filter-plugins){:target="_blank"} manipulate data. They are a feature of Jinja2 and are also available in Jinja2 templates used by the *template* module. As with all plugins, they can be easily extended, but instead of having a file for each one you can have several per file.

This file may be used as a minimal starting point, it includes a small example:

!!! example "cc_filter_plugins.py"

    ```python
    from __future__ import absolute_import, division, print_function
    __metaclass__ = type
    
    from ansible.errors import AnsibleError # (1)!
    from ansible.module_utils.common.text.converters import to_native, to_text # (2)!

    import types

    try:
        import netaddr # (3)!
    except ImportError as e:
        raise AnsibleError('Missing dependency! - %s' % to_native(e))


    def sort_ip(unsorted_ip_list): # (4)!
    # Function sorts a given list of IP addresses
    
        if not isinstance(unsorted_ip_list, list): # (5)!
            raise AnsibleError("Filter needs list input, got '%s'" % type(unsorted_ip_list))
        else:
            sorted_ip_list = sorted(unsorted_ip_list, key=netaddr.IPAddress) # (6)!
            
        return sorted_ip_list # (7)!


    class FilterModule(object): # (8)!
        
        def filters(self):
            return {
                # Sorting list of IP Addresses
                'sort_ip': sort_ip # (9)!
            }
    ```

    1. This is the most generic [AnsibleError object](https://github.com/ansible/ansible/blob/devel/lib/ansible/errors/__init__.py){:target="_blank"}, depending on the specific plugin type you’re developing you may want to use different ones.
    2. Use this to convert plugin output to convert output into Python’s unicode type (*to_text*) or for wrapping other exceptions into error messages (*to_native*).
    3. This is a non-standard dependency, the user needs to install this beforehand (e.g. `pip3 install netaddr --user`), therefor surrounding it with *try-execpt*. **Document necessary requirements!**
    4. Example plugin definition, this sorts a given list of IP addresses ( Jinja2 *sort* filter does not work correctly with IPs), it expects a list.
    5. Testing if input is a *list*, otherwise return an error message. Maybe another error type (e.g. *AnsibleFilterTypeError*) is more approriate? What other exceptions need to be caught?
    6. This line sorts the list with the [*built-in Python sorted()*](https://docs.python.org/3/library/functions.html#sorted){:target="_blank"} library, the key specifies the comparison key for each list element, it uses the *netaddr* library.
    7. The function returns a sorted list of IPs.
    8. Main class, this is called by Ansible's *PluginLoader*.
    9. Mapping of filter name and definition, you may call your filter like this: `"{{ ip_list | sort_ip }}"` (this only works when stored in the project root in the folder `filter_plugins`, otherwise you need to use the FQCN!). Filter name and definition do not need to have the same name.  Add more filter definitions by comma-separation.

The Python file needs to be stored in a collection, e.g.:

```bash
collections/
└── ansible_collections
    └── computacenter
        └── utils
            ├── README.md
            ├── docs
            ├── galaxy.yml
            ├── plugins
            │   ├── README.md
            │   └── filter
            │       └── cc_filter_plugins.py
            └── roles
```

Now, the filter can be used:

```yaml
sorted_ip_list: "{{ ip_list | computacenter.utils.sort_ip }}"
```

### Dynamic inventory plugins

Ansible can pull informations from different sources, like ServiceNow, Cisco etc. If your source is not covered with the integrated inventory plugins, you can create your own.

For more informations take a look at [Ansible docs - Developing inventory plugin](https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html){:target="_blank"}.

**Key things to note:**

* The DOCUMENTATION section is required and used by the plugin. Note how the options here reflect exactly the options we specified in the csv_inventory.yaml file in the previous step.
* The NAME should exactly match the name of the plugin everywhere else.
* For details on the imports and base classes/helpers.

Documentaion -> Declare option that are needed in the plugin.
Examples -> Example with parameter for a inventory file to run the script.
Python Code -> Different methods like verify_file, parse and more.

```python
from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = r"""
name: cisco_prime.py
author:
  - Kevin Blase
  - Jonathan Schmidt
short_description: Inventory source for Cisco Prime API.
description:
  - Builds inventory from Cisco Prime API.
  - Requires a configuration file ending in C(prime.yml) or C(prime.yaml).
    See the example section for more details.
version_added: 1.0.0
extends_documentation_fragment:
  - ansible.builtin.constructed
notes:
  - Nothing
options:
  plugin:
    description:
      - The name of the Cisco Prime API Inventory Plugin.
      - This should always be C(custom.inventory.cisco_prime).
    required: true
    type: str
    choices: [ custom.inventory.cisco_prime ]
...
"""

EXAMPLES = r"""
---
# Inventory File
plugin: custom.inventory.cisco_prime
api_user: "user123"
api_pass: "password123"
api_host_url: "host.domain.tld"
"""

import requests
# import traceback
# from ansible.errors import AnsibleParserError
from ansible.inventory.group import to_safe_group_name
from ansible.plugins.inventory import (
    BaseInventoryPlugin,
    Constructable,
    to_safe_group_name,
)

class InventoryModule(BaseInventoryPlugin, Constructable):

    NAME = 'custom.inventory.cisco_prime'  # used internally by Ansible, it should match the file name but not required

    def verify_file(self, path):
        valid = False
        if super(InventoryModule, self).verify_file(path):
            if path.endswith(('prime.yaml', 'prime.yml')):
                valid = True
            else:
                self.display.vvv(
                    'Skipping due to inventory source not ending in "prime.yaml" nor "prime.yml"')
        return valid

    def add_host(self, hostname, host_vars):
        self.inventory.add_host(hostname, group='all')

        for var_name, var_value in host_vars.items():
            self.inventory.set_variable(hostname, var_name, var_value)

        strict = self.get_option('strict')

        # Add variables created by the user's Jinja2 expressions to the host
        self._set_composite_vars(self.get_option('compose'), host_vars, hostname, strict=True)

        # Create user-defined groups using variables and Jinja2 conditionals
        self._add_host_to_composed_groups(self.get_option('groups'), host_vars, hostname, strict=strict)
        self._add_host_to_keyed_groups(self.get_option('keyed_groups'), host_vars, hostname, strict=strict)
...
```

The Python file needs to be stored in a collection, e.g.:

```bash
collections/
└── ansible_collections
    └── computacenter
        └── utils
            ├── README.md
            ├── plugins
            │   ├── README.md
            │   └── inventory
            │       └── cc_dyn_inv_plugin.py
            └── roles
```

To run this script, create a inventory file with the correct entries, as in the *examples* section of the inventory script.

```yaml
# inventory.yml
plugin: custom.inventory.cisco_prime
api_user: "user123"
api_pass: "password123"
api_host_url: "host.domain.tld"
```

Run your playbook, referencing the custom inventory plugin file:

```bash
ansible-playbook -i inventory.yml main.yml
```

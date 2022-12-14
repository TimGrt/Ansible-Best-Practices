# Extending Ansible

Ansible is easily customizable, you can extend Ansible by adding custom modules or plugins.  
You might wonder whether you need a module or a plugin. Ansible modules are units of code that can control system resources or execute system commands. Ansible provides a module library that you can execute directly on remote hosts or through playbooks.  
Similar to modules are plugins, which are pieces of code that extend core Ansible functionality. Ansible uses a plugin architecture to enable a rich, flexible, and expandable feature set. It ships with several plugins and lets you easily use your own plugins.

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

Create subfolders beneath the `plugins` folder, `modules` for modules and e.g. `filter` for filter plugins. Take a look into the included `README.md` in the *plugins* folder.

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

!!! tip
    Only underscores (`_`) are allowed for filenames inside collections!  
    Naming the file `cc-filter-plugins.py` will result in an error!

Now, the filter can be used:

```yaml
sorted_ip_list: "{{ ip_list | sort_ip }}"
```

# Operations

The [Red Hat EMEA Ansible Launch Team](https://ansible-ops-model.gitlab.io/#about-us){:target="_blank"} created a good practice based [Operational Model for AAP](https://ansible-ops-model.gitlab.io/){:target="_blank"}, for people who want inspiration for how you can run a central automation platform based on Ansible Automation Platform.  
The model, which covers **people, process, technology, service management and strategy** is divided between three different advancement levels, from [MVP](https://ansible-ops-model.gitlab.io/mvp/){:target="_blank"} over [2.0](https://ansible-ops-model.gitlab.io/twozero/){:target="_blank"} to [Advanced](https://ansible-ops-model.gitlab.io/advanced/){:target="_blank"}.

<figure markdown="span">
  ![AAP Operational Model](https://gitlab.com/ansible-ops-model/ansible-ops-model.gitlab.io/-/raw/8cf1e7e7e6457994a7526df486e4b1b106917e9f/assets/images/aap-operational-model.jpg)
</figure>

## Configuration as Code

Running or operating the Automation Platform at scale can be challenging, when dealing with large, complex environments. You often need to **replicate configurations** between environments or sites.  
Database replication to copy data from one environment to another (for instance, importing data from one Ansible Automation Platform site to another) is one approach. This approach can require a dedicated infrastructure, specialized teams to handle the process, and complex procedures for switching the active site. This design can affect consistency across multiple environments or sites.  
Another possibility is treating the AAP configuration **as code** and using Ansible automation to automate the AAP itself.

The [Red Hat Communities of Practice](https://redhat-cop.github.io/){:target="_blank"} created many useful collections, roles and playbooks for AAP configuration as code.

As there are new components (*Automation Gateway*) and new APIs with Ansible Automation Platform 2.5+, automating AAP requires different collections.

### AWX & AAP <= 2.4

For automating AWX and Automation Platform 2.4 and earlier, use the [Controller Configuration Collection](https://galaxy.ansible.com/ui/repo/published/infra/controller_configuration/){:target="_blank"}.

```console
ansible-galaxy collection install infra.controller_configuration
```

### AAP 2.5+

For automating Automation Platform 2.5 and later, use the [AAP Configuration Collection](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration/){:target="_blank"}.

```console
ansible-galaxy collection install infra.aap_configuration
```

## Extended configuration and helper roles

The [AAP Configuration Extended Collection](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/){:target="_blank"} contains some very useful roles and playbooks for automating **existing and manually configured** AAP instances, as well as supporting with the migration between AAP 2.4 and 2.5.  

For example:

* [infra.controller_configuration.filetree_create](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/content/role/filetree_create/){:target="_blank"} - creates a filetree with YAML files of the existing AAP configuration
* [infra.controller_configuration.upgrade_config](https://galaxy.ansible.com/ui/repo/published/infra/aap_configuration_extended/content/role/upgrade_config/){:target="_blank"} - converts the configuration files used for AAP <= 2.4 CaC collections to the new format supported by the AAP >= 2.5 CaC collections.

```console
ansible-galaxy collection install infra.aap_configuration_extended
```

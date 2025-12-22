# Get started

When starting a new automation project, you (and potentially together with your team!) will need to make a couple of initial decisions and prepare your project, before starting to develop the actual automation content.

## 1. Create Git project

Use version control and follow a basic Git workflow. Use Pre-Commit to enforce code formatting or run tests before a commit is made.

* [Configure Git](git.md#configuration)
* [Create, configure and use Pre-Commit](git.md#pre-commit)

## 2. Define naming scheme and where to put variables

Decide on a proper naming convention and stick to it.

* [Naming content](project.md#filenames)
* [Variable storage](variables.md#where-to-put-variables)

## 3. Configure Ansible

Create a basic configuration file in your project root folder.

* [Project-specific Ansible configuration file](project.md#ansible-configuration)

## 4. Role or Collection

*Are you creating content which can be used by others or is the scope limited?*  
Collections are easier to consume than roles. Create multiple repositories for collections or roles and additional ones for playbooks and variables if useful.

* [Collection structure](collections.md)
* [Roles structure](roles.md)

## 5. Define inventory

Use a dynamic inventory source if possible, otherwise create a static inventory file with your target nodes.

* [Dynamic inventory](inventory.md#dynamic-inventory)
* [Static inventory](inventory.md#static-inventory)

## 6. Choose execution engine

*Content will be run in AAP later on?*  
Use **ansible-navigator** with **Execution Environment** from AAP (or create a custom one) during development on CLI.  
Otherwise stick to **ansible-core**.

* [Build Execution Environment](installation.md#ansible-builder) and [run with ansible-navigator](playbook.md#with-ansible-navigator)

## Final notes

!!! tip
    **Remember, these are only recommendations.** Use your own judgement and experiences made from previous projects.  
    **Embrace change!** Your project will evolve, if changes are useful for better readability or functionality, do it (after discussing with and consulting the rest of the team).

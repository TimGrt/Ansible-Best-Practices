# Linting

!!! warning
    **Work in Progress** - More description necessary.

[*Ansible Lint*](https://ansible-lint.readthedocs.io/){:target="_blank"} is a best-practice checker for Ansible, maintained by the Ansible community.

## Installation

Ansible Lint is installed through the Python packet manager:

!!! note
    *Ansible Lint* always needs *Ansible* itself
```bash
pip3 install ansible-lint
```



## Automated Linting

Running *ansible-lint* through a CI pipeline automatically when commiting (or merging) changes to the Git repository is **highly advisable**.



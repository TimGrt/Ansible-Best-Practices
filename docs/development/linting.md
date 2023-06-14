# Linting

[*Ansible Lint*](https://ansible-lint.readthedocs.io/){:target="_blank"} is a best-practice checker for Ansible, maintained by the Ansible community.

## Installation

Ansible Lint is installed through the Python packet manager:

!!! note
    *Ansible Lint* always needs *Ansible* itself, *ansible-core* is enough.

```bash
pip3 install ansible-lint
```

## Configuration

Minimal configuration is necessary, use the following as a starting point in your project directory:

```yaml title=".ansible-lint"
---
profile: shared

# Silence infos, warnings and don't show summary
quiet: true

skip_list:
  - role-name

# Enable some useful rules which are opt-in
enable_list:
  - args
  - empty-string-compare
  - no-log-password
  - no-same-owner
```

Profiles gradually increase the strictness of rules, from lowest to highest, every profile extends to previous:

Strictness | Profile name | Description
---------- | ------------ | -----------
1 | min | ensures that Ansible can load content, rules in this profile are mandatory
2 | basic | prevents common coding issues and enforces standard styles and formatting
3 | moderate | ensures that content adheres to best practices for making content easier to read and maintain
4 | safety | avoids module calls that can have non-determinant outcomes or security concerns
5 | **shared** | for packaging and publishing to *galaxy.ansible.com*, *automation-hub*, or a private instance
6 | production | for inclusion in AAP as *validated* or *certified* content

Take a look at the [official documentation](https://ansible-lint.readthedocs.io/configuring/){:target="_blank"} for more information.

## Usage

The usage is fairly simple, just run `ansible-lint <your-playbook>`.  
The tool will check your playbook for best-practices, it traverses your playbook and will lint all included playbooks and roles.

Take a look at the [*ansible-lint documentation*](https://ansible-lint.readthedocs.io/){:target="_blank"} for additional information.

### Lint in Docker Image

The following *Dockerfile* can be used to build a Docker Container image which bundles *ansible-lint* and its dependencies:

??? example "Dockerfile"

    ```Dockerfile
    FROM python:3.9-slim

    # Enable colored output
    ENV TERM xterm-256color

    # Defining Ansible environment variable to not output depreaction warnings. This is not useful in the linting container.
    # This overwrites the value in the ansible.cfg from volume mount
    ENV ANSIBLE_DEPRECATION_WARNINGS=false

    # Install requirements.
    RUN apt-get update && apt-get install -y \
      git \
      && rm -rf /var/lib/apt/lists/*

    # Update pip
    RUN python3 -m pip install --no-cache-dir --no-compile --upgrade pip

    # Install ansible-lint and dependencies
    RUN pip3 install --no-cache-dir --no-compile ansible-lint ansible yamllint

    WORKDIR /data
    ENTRYPOINT ["ansible-lint"]
    CMD ["--version"]
    ```

Build the container image, the command expects that the *Dockerfile* is present in the current directory:

```bash
docker build -t ansible-lint .
```

After building the image, the image can be used. Inside of the Ansible project directory, run this command (e.g. this lints the `site.yml` playbook).

```bash
docker run --rm -v $(pwd):/data ansible-lint site.yml
```

The output for example is something like this, *ansible-lint* reports a warning regarding unnecessary white-spaces in a line, as well as an error regarding unset file permissions (fix could be setting `mode: 0644` in the task):

```{ .bash .no-copy }
$ docker run --rm -v $(pwd):/data ansible-lint site.yml
WARNING  Overriding detected file kind 'yaml' with 'playbook' for given positional argument: site.yml
WARNING  Listing 2 violation(s) that are fatal
yaml: trailing spaces (trailing-spaces)
roles/network/tasks/cacheserve-loopback-interface.yml:19

risky-file-permissions: File permissions unset or incorrect
roles/network/tasks/cacheserve-loopback-interface.yml:43 Task/Handler: Deploy loopback interface config for Cacheserve

You can skip specific rules or tags by adding them to your configuration file:
# .ansible-lint
warn_list:  # or 'skip_list' to silence them completely
  - experimental  # all rules tagged as experimental
  - yaml  # Violations reported by yamllint

Finished with 1 failure(s), 1 warning(s) on 460 files.
```

To simplify the usage, consider adding an *alias* to your `.bashrc`, e.g.:

```bash
# .bashrc
# User specific aliases and functions
alias lint="docker run --rm -v $(pwd):/data ansible-lint"
```

After running `source ~/.bashrc` you can use the alias:

```bash
lint site.yml
```

## Automated Linting

Lining can and should be done automatically, this way you can't forget to check your playbook for best practices. This can be done on multiple levels, either locally as part of your Git workflow, as well as with a pipeline in your remote repository.

### Git pre-commit hook

A nice way to check for best practices during your Git worflow is the usage of a *pre-commit* hook. These hooks can be simple bash script, which are run whenever you are commiting changes locally to the staging area or a framework/utility like [pre-commit](https://pre-commit.com/){:target="_blank"}.

Take a look at the [Version Control section](git.md#pre-commit) for installing and configuring *pre-commit* hooks.

### CI Pipeline

Running *ansible-lint* through a CI pipeline automatically when merging changes to the Git repository is **highly advisable**.

A possible pipeline in Gitlab may look like this, utilizing the container image above:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_PIPELINE_SOURCE == 'web'
    - if: $CI_PIPELINE_SOURCE == 'schedule'

variables:
  GIT_STRATEGY: clone

stages:
  - prepare
  - syntax
  - lint

prepare:
  stage: prepare
  script:
    - 'echo -e "### Prepare playbook execution. ###"'
    - 'cp ansible.cfg.sample-lab ansible.cfg'
    - 'echo -e "$VAULT_PASSWORD" > .vault-password'
  artifacts:
    paths:
      - ansible.cfg
      - .vault-password
  cache:
    paths:
      - ansible.cfg
      - .vault-password
  tags:
    - ansible-lint

syntax-check:
  stage: syntax
  script:
    - 'echo -e "Perform a syntax check on the playbook. ###"'
    - 'docker run --rm --entrypoint ansible-playbook -v $(pwd):/data ansible-lint site.yml --syntax-check'
  cache:
    paths:
      - ansible.cfg
      - .vault-password
  dependencies:
    - prepare
  tags:
    - ansible-lint

ansible-lint:
  stage: lint
  script:
    - 'echo -e "### Check for best practices with ansible-lint. ###"'
    - 'echo -e "### Using ansible-lint version: ###"'
    - 'docker run --rm -v $(pwd):/data ansible-lint'
    - 'docker run --rm -v $(pwd):/data ansible-lint site.yml'
  cache:
    paths:
      - ansible.cfg
      - .vault-password
  dependencies:
    - prepare
  tags:
    - ansible-lint

```

If you want to utilize the installed *ansible* and *ansible-lint* utilities on the host running the Gitlab Runner change the commands in the *syntax* stage to `ansible-playbook site.yml --syntax-check` and in the *lint* stage to `ansible-lint --version` and `ansible-lint site.yml`.

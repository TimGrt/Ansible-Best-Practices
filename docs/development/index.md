# Development

This topic is split into four main sections, each section covers a different additional tool to consider when *developing* your Ansible content.

<div class="grid cards" markdown>

* [:octicons-git-pull-request-16: &nbsp; Version Control](git.md)

    ---
    Small guide for version controlling playbooks.

* [:octicons-verified-16: &nbsp; Linting](linting.md)

    ---
    Installation and usage of the community backed Ansible Best Practice checker.

* [:octicons-stopwatch-16: &nbsp; Testing](testing.md)

    ---
    How to test your Ansible content during development.

* [:octicons-plug-16: &nbsp; Extending](extending.md)

    ---
    How to create your own custom modules and plugins.

* [:octicons-meter-16: &nbsp; Monitoring & Troubleshooting](monitoring.md)

    ---
    How to monitor your playbook for resource consumption or time taken.

</div>

## Tools

Each section above make use of an additional tool to support you during your Ansible content development. In most cases the standalone installation, as well as a custom container-based installation and usage method is described.  

The Ansible community provides a Container image bundling all the tools described in the sections above.

```console
docker pull quay.io/ansible/creator-ee
```

For example you could output the version of the installed tools like this:

```console
docker run --rm quay.io/ansible/creator-ee ansible-lint --version
```

```console
docker run --rm quay.io/ansible/creator-ee molecule --version
```

Take a look into the respective sections for more information and additional usage instructions.

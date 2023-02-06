# Development


This topic is split into three main sections, each section covers a different additional tool to consider when *developing* your Ansible content.

* [:octicons-verified-16: &nbsp; Linting](linting.md) - Installation and usage of the community backed Ansible Best Practice checker
* [:octicons-stopwatch-16: &nbsp; Testing](testing.md) - How to test your Ansible content during development
* [:octicons-plug-16: &nbsp; Extending](extending.md) - Create your own custom modules and plugins


## Tools

Each section above make use of an additional tool to support you during your Ansible content development, in most cases the standalone installation, as well as a custom container-based installation and usage method is described.  

The Ansible community provides a Container image bundling all the tools described in the sections above.

```bash
docker pull quay.io/ansible/creator-ee
```

For example you could output the version of the installed tools like this:

```bash
docker run --rm quay.io/ansible/creator-ee ansible-lint --version
```

```bash
docker run --rm quay.io/ansible/creator-ee molecule --version
```

Take a look into the respective sections for more information and additional usage instructions.
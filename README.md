# Ansible-Best-Practices

[![Markdown Lint](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml) [![Deploy to Github pages & Container registry](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/cd.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/cd.yml) [![Built with Material for MkDocs](https://img.shields.io/badge/Material_for_MkDocs-526CFE?logo=MaterialForMkDocs&logoColor=white)](https://squidfunk.github.io/mkdocs-material/)

A collection of Best Practices for Ansible projects in MkDocs, published to [Github pages](https://timgrt.github.io/Ansible-Best-Practices) and [Github Container Registry](https://github.com/TimGrt/Ansible-Best-Practices/pkgs/container/ansible-best-practices).  

```bash
podman pull ghcr.io/timgrt/ansible-best-practices:latest
```

Start a container from the image, the webserver is available at Port 8080:

```bash
podman run -d -p 8080:80/tcp --name best-practice-guide ghcr.io/timgrt/ansible-best-practices:latest
```

## Manual build

The project contains the source files for an MkDocs project, a *Containerfile* is provided which bundles all requirements and displays the resulting content in a webserver.

Clone the project and change into the base directory, afterwards build the image:

```bash
podman build -t best-practice-guide .
```

Start a container from the image, the webserver is available at Port 8080:

```bash
podman run -d -p 8080:80/tcp --name ansible-guide best-practice-guide
```

## Development

We document our Coding Guidelines in the [Contributing Guidelines](https://github.com/TimGrt/Ansible-Best-Practices/blob/main/.github/CONTRIBUTING.md), this document also includes instructions on how the setup a development environment.

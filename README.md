# Ansible-Best-Practices

[![Integration](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml) [![Deploy to Github pages & Container registry](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/cd.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/cd.yml) [![Zensical Badge](https://img.shields.io/badge/Made_with_Zensical-orange?style=flat-square)](https://zensical.org/about/)

A collection of Best Practices for Ansible projects, published to [Github pages](https://timgrt.github.io/Ansible-Best-Practices) and [Github Container Registry](https://github.com/TimGrt/Ansible-Best-Practices/pkgs/container/ansible-best-practices).  

## Manual Deployment

If you want to deploy the Guide yourself, pull to Container image:

```bash
podman pull ghcr.io/timgrt/ansible-best-practices:latest
```

Start a container from the image, the webserver is available at Port 8080:

```bash
podman run -d -p 8080:8080/tcp --name best-practice-guide ghcr.io/timgrt/ansible-best-practices:latest
```

## Manual build

The project contains the source files for a Zensical project, a *Containerfile* is provided which bundles all requirements and displays the resulting content in a webserver.

Clone the project and change into the base directory, afterwards build the image:

```bash
podman build -t best-practice-guide .
```

Start a container from the image, the webserver is available at Port 8080:

```bash
podman run -d -p 8080:8080/tcp --name ansible-guide best-practice-guide
```

## Development

We document our Coding Guidelines in the [Contributing Guidelines](https://github.com/TimGrt/Ansible-Best-Practices/blob/main/.github/CONTRIBUTING.md), this document also includes instructions on how the setup a development environment.

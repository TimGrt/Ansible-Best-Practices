# Ansible-Best-Practices

[![Deploy MkDocs to Github pages](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml)

A collection of Best Practices for Ansible projects in MkDocs, published to [Github pages](https://timgrt.github.io/Ansible-Best-Practices) and [Github Container Registry](https://github.com/TimGrt/Ansible-Best-Practices/pkgs/container/ansible-best-practices).  

```bash
docker pull ghcr.io/timgrt/ansible-best-practices:latest
```

## Manual build

The project contains the source files for an MkDocs project, a *Dockerfile* is provided which bundles all requirements and displays the resulting content in a webserver.

Clone the project and change into the base directory, afterwards build the image:

```bash
docker build -t best-practice-guide .
```

Start a container from the image, the webserver is available at Port 8080:

```bash
docker run -d -p 8080:80/tcp --name ansible-guide best-practice-guide
```

Go to `http://localhost:8080` to view the Best-Practice Guide.

## Development

Create a Python virtual environment:

```bash
python3 -m venv mkdocs-venv
```

Activate:

```bash
source mkdocs-venv/bin/activate
```

Install MkDocs dependencies:

```bash
pip3 install -r requirements.txt
```

Run Live-Preview server (available on Port 8000):

```bash
mkdocs serve
```

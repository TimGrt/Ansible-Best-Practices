# Ansible-Best-Practices

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=551970753) [![Deploy MkDocs to Github pages](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml/badge.svg)](https://github.com/TimGrt/Ansible-Best-Practices/actions/workflows/ci.yml)

A collection of Best Practices for Ansible projects in MkDocs.

## How-to Guide

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
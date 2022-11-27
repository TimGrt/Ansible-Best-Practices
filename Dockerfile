FROM python:3.9-slim

WORKDIR /tmp

# Copy Python packages/dependencies file
COPY requirements.txt .

# Update pip and install Python dependencies
RUN python3 -m pip install --no-cache-dir -U pip
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Install Git executable and copy .git folder for git-revision-date-localized-plugin
RUN apt-get update \
 && apt-get install --no-install-recommends -y git\
 && apt-get autoremove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY .git .git

# Copy documentation source files to working directory
COPY docs docs
COPY mkdocs.yml .

# Build new documentation
RUN mkdocs build

EXPOSE 80

# Run webserver
CMD python -m http.server 80 -d site/
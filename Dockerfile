FROM python:3.11-alpine AS builder
WORKDIR /tmp
# Copy Python packages/dependencies file
COPY requirements.txt .
# Install Python dependencies
RUN python3 -m pip install --no-cache-dir -r requirements.txt
# Install Git executable for git-revision-date-localized-plugin
RUN apk upgrade --update-cache -a \
 && apk add --no-cache git\
 && rm -rf /var/cache/apk/*
# Copy .git folder for git-revision-date-localized-plugin
COPY .git .git
# Copy documentation source files to working directory
COPY docs docs
COPY mkdocs.yml .
# Build new documentation
RUN mkdocs build

FROM python:3.11-alpine
WORKDIR /tmp
COPY --from=builder /tmp/site ./site
EXPOSE 80
# Run webserver
CMD ["python", "-m", "http.server", "80", "-d", "site/"]

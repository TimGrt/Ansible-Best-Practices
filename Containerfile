FROM python:3.14-alpine AS builder
WORKDIR /tmp
# Install Git executable for git-revision-date-localized-plugin
RUN apk upgrade --update-cache -a \
 && apk add --no-cache git\
 && rm -rf /var/cache/apk/*
# Copy Python packages/dependencies file
COPY requirements.txt .
# Install Python dependencies
RUN python3 -m pip install --no-cache-dir -r requirements.txt
# Copy documentation source files to working directory
COPY docs docs
COPY includes includes
COPY zensical.toml .
# Build new documentation
RUN zensical build

FROM python:3.14-alpine
STOPSIGNAL SIGKILL
RUN adduser -D docs
USER docs
WORKDIR /tmp
COPY --from=builder /tmp/site ./site
EXPOSE 8080
HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1
# Run webserver
CMD ["python", "-m", "http.server", "8080", "-d", "site/"]

# localdocs

A lightweight static HTTP server and maintenance toolset for local mirrored documentation.

## Components

- `serve.sh`: Universal server launcher. Works on arbitrary host interfaces (`127.0.0.1`, `0.0.0.0`, LAN IPs), custom ports, custom document directories, and pluggable backends (`auto`, `python`, or `quark`).
- `Dockerfile`: Multi-stage build producing suckless `quark` statically linked against musl in a scratch image. Uses build arguments (`UID`, `GID`) to match the host user.
- `run-quark.sh`: Docker launcher for `localdocs-quark`. Dynamically maps the host user ID/GID, binds to configurable host interfaces, drops capabilities, and limits memory to 20 MB.
- `update.sh`: Regenerates `index.html` and `pages.html` for any docs directory. Builds filterable catalogs for sites, loose documents, and audio files, then validates all local links.
- `localdocs-dedupe`: Computes SHA-256 hashes across files in the target directory and moves duplicate copies (such as HTTrack query variants) into `.trash-<date>/`.
- `localdocs-update`: Automated driver script that invokes `localdocs-dedupe` followed by `update.sh`.

## Requirements

- Python 3
- Docker (optional, only needed for containerized quark)

## Usage

### Serve Documentation

Use `serve.sh` to serve documents with any backend:

```sh
# Auto-detects backend (quark if docker is available, otherwise python http.server)
./serve.sh

# Serve with standard Python http.server (no Docker required)
./serve.sh --server python

# Bind to all interfaces on port 9000 for LAN access
./serve.sh --host 0.0.0.0 --port 9000

# Serve an arbitrary documentation directory
./serve.sh /path/to/docs
```

Or run the containerized quark server directly:

```sh
# Default: 127.0.0.1:8000 serving ~/localdocs
./run-quark.sh

# Custom host binding, port, and directory
HOST=0.0.0.0 PORT=8080 ./run-quark.sh /path/to/docs
```

### Rebuild Index and Deduplicate

```sh
# Process ~/localdocs
./localdocs-update

# Process an arbitrary directory
./localdocs-update /path/to/docs
```

Or run steps individually:

```sh
./localdocs-dedupe --dry-run /path/to/docs
./localdocs-dedupe /path/to/docs
./update.sh /path/to/docs
```

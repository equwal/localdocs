# localdocs

A lightweight static HTTP server and maintenance toolset for local mirrored documentation.

## Components

- `Dockerfile`: Multi-stage build producing suckless `quark` statically linked against musl in a scratch image.
- `run-quark.sh`: Builds and launches the `localdocs-quark` container. Binds read-only to `127.0.0.1:8000`, drops all capabilities except `SYS_CHROOT`, `SETUID`, and `SETGID`, and caps memory at 20 MB.
- `update.sh`: Regenerates `index.html` and `pages.html` from `~/localdocs`. Generates search-filterable listings for sites, standalone documents, and audio files, then validates every internal hyperlink.
- `localdocs-dedupe`: Computes SHA-256 hashes across files in `~/localdocs` and moves redundant copies (such as HTTrack query variants) into `.trash-<date>/`.
- `localdocs-update`: Automated driver script that invokes `localdocs-dedupe` followed by `update.sh`.

## Requirements

- Python 3
- Docker

## Usage

### Start HTTP Server

```sh
./run-quark.sh
```

Serves documentation at `http://127.0.0.1:8000` from `~/localdocs`.

### Rebuild Index and Deduplicate

```sh
./localdocs-update
```

Or run steps individually:

```sh
./localdocs-dedupe --dry-run
./localdocs-dedupe
./update.sh
```

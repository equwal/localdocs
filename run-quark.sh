#!/bin/sh
# Build and (re)start the localdocs quark container: arbitrary host/port, read-only, 20 MB RAM.
cd "$(dirname "$(readlink -f "$0")")" || exit 1

DOCS_DIR="${1:-$HOME/localdocs}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"

docker build \
  --build-arg UID="$(id -u)" \
  --build-arg GID="$(id -g)" \
  -t localdocs-quark . || exit 1

docker rm -f localdocs-quark 2>/dev/null
exec docker run -d --name localdocs-quark --restart unless-stopped \
  --read-only --cap-drop ALL --cap-add SYS_CHROOT --cap-add SETUID --cap-add SETGID \
  --security-opt no-new-privileges --memory 20m \
  -v "$DOCS_DIR:/docs:ro" -p "$HOST:$PORT:8000" localdocs-quark

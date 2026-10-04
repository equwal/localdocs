#!/bin/sh
# Build and (re)start the localdocs quark container: 127.0.0.1:8000, read-only, 20 MB RAM (youki fails to create the container at 16m).
cd "$(dirname "$(readlink -f "$0")")" || exit 1
docker build -t localdocs-quark . || exit 1
docker rm -f localdocs-quark 2>/dev/null
exec docker run -d --name localdocs-quark --restart unless-stopped \
  --read-only --cap-drop ALL --cap-add SYS_CHROOT --cap-add SETUID --cap-add SETGID \
  --security-opt no-new-privileges --memory 20m \
  -v "$HOME/localdocs:/docs:ro" -p 127.0.0.1:8000:8000 localdocs-quark

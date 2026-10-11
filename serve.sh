#!/bin/sh
# Serve localdocs over HTTP on an arbitrary host interface, port, and backend.
# Usage: ./serve.sh [OPTIONS] [DIRECTORY]
#
# Options:
#   -b, --host HOST       Host address to bind (default: 127.0.0.1, or HOST env var)
#   -p, --port PORT       Port to listen on (default: 8000, or PORT env var)
#   -d, --dir DIR         Directory to serve (default: ~/localdocs, or DIR env var)
#   -s, --server BACKEND  Server: auto (default), python, or quark
#   -h, --help            Show this help message

set -e

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
DIR="${DIR:-$HOME/localdocs}"
BACKEND="${BACKEND:-auto}"

show_help() {
  sed -n '2,10p' "$0" | sed 's/^# *//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--host) HOST="$2"; shift 2 ;;
    -p|--port) PORT="$2"; shift 2 ;;
    -d|--dir)  DIR="$2"; shift 2 ;;
    -s|--server) BACKEND="$2"; shift 2 ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [ -d "$1" ]; then
        DIR="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [ ! -d "$DIR" ]; then
  echo "Error: Directory '$DIR' does not exist." >&2
  exit 1
fi

case "$BACKEND" in
  quark)
    if command -v docker >/dev/null 2>&1; then
      d=$(dirname "$(readlink -f "$0")")
      HOST="$HOST" PORT="$PORT" "$d/run-quark.sh" "$DIR"
    elif command -v quark >/dev/null 2>&1; then
      echo "Starting native quark on $HOST:$PORT..."
      exec quark -l -h "$HOST" -p "$PORT" -d "$DIR"
    else
      echo "Error: Neither docker nor quark binary found." >&2
      exit 1
    fi
    ;;
  python)
    echo "Serving $DIR with python http.server at http://$HOST:$PORT..."
    exec python3 -m http.server -b "$HOST" -d "$DIR" "$PORT"
    ;;
  auto)
    if command -v docker >/dev/null 2>&1; then
      d=$(dirname "$(readlink -f "$0")")
      HOST="$HOST" PORT="$PORT" "$d/run-quark.sh" "$DIR"
    elif command -v quark >/dev/null 2>&1; then
      echo "Starting native quark on $HOST:$PORT..."
      exec quark -l -h "$HOST" -p "$PORT" -d "$DIR"
    elif command -v python3 >/dev/null 2>&1; then
      echo "Serving $DIR with python http.server at http://$HOST:$PORT..."
      exec python3 -m http.server -b "$HOST" -d "$DIR" "$PORT"
    else
      echo "Error: No suitable server found (tried docker, quark, python3)." >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown backend: $BACKEND (choose 'auto', 'quark', or 'python')" >&2
    exit 1
    ;;
esac

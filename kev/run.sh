#!/bin/bash
# Start the local Kev decision server for Kev Voice.
#
#   bash kev/run.sh                          default: kev-4b on 127.0.0.1:8008
#   KEV_MODEL=jaredpalmer/kev-9b bash kev/run.sh
#   bash kev/run.sh --port 8123              extra flags pass through to kev.serve
#
# The app reads KEV_CUA_URL if you use a different host or port.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
KEV_HOME="${KEV_HOME:-$DIR/vendor/kev}"

if [ ! -d "$KEV_HOME" ]; then
    bash "$DIR/setup.sh"
fi

cd "$KEV_HOME"
exec uv run --extra serve python -m kev.serve \
    --run "${KEV_MODEL:-jaredpalmer/kev-4b}" \
    --port "${KEV_PORT:-8008}" \
    "$@"

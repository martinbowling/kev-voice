#!/bin/bash
# Set up the Kev decision server for Kev Voice.
#
#   bash kev/setup.sh                    clone/update Kev and install its serve dependencies
#   bash kev/setup.sh --download-model   also pre-download the adapter and base weights
#   KEV_MODEL=jaredpalmer/kev-9b bash kev/setup.sh --download-model
#
# Kev is cloned into kev/vendor/kev (override with KEV_HOME) and is never
# modified. Requires uv: https://docs.astral.sh/uv/
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
KEV_REPO="${KEV_REPO:-https://github.com/jaredpalmer/kev.git}"
KEV_HOME="${KEV_HOME:-$DIR/vendor/kev}"
KEV_MODEL="${KEV_MODEL:-jaredpalmer/kev-4b}"

if ! command -v uv >/dev/null 2>&1; then
    echo "uv is required to run Kev. Install it with:" >&2
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
fi

mkdir -p "$(dirname "$KEV_HOME")"
if [ -d "$KEV_HOME/.git" ]; then
    echo "Updating Kev in $KEV_HOME"
    git -C "$KEV_HOME" pull --ff-only --quiet
else
    echo "Cloning Kev into $KEV_HOME"
    git clone --depth 1 "$KEV_REPO" "$KEV_HOME"
fi

echo "Installing serve dependencies"
(cd "$KEV_HOME" && uv sync --extra serve)

if [ "${1:-}" = "--download-model" ]; then
    echo "Pre-downloading $KEV_MODEL"
    (cd "$KEV_HOME" && uv run --extra serve python - "$KEV_MODEL" <<'PY'
import sys
from huggingface_hub import snapshot_download
from kev.checkpoint import is_hub_id, read_meta, resolve_run

run = sys.argv[1]
path = resolve_run(run)
meta = read_meta(path)
if is_hub_id(meta.base):
    snapshot_download(
        meta.base,
        revision=meta.base_revision or None,
        allow_patterns=["*.json", "*.safetensors", "*.txt", "*.jinja", "*.model"],
    )
print(f"model cached: {run} (base {meta.base})")
PY
    )
fi

echo "Kev ready in $KEV_HOME"

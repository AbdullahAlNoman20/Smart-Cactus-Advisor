#!/usr/bin/env bash
# start.sh
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
PY="$ROOT/.portable/venv/bin/python"
[ -x "$PY" ] || { echo "Run ./setup.sh first"; exit 1; }
[ -f "$ROOT/frontend/build/index.html" ] || { echo "Frontend build missing. Run ./setup.sh"; exit 1; }

unset PYTHONPATH PYTHONHOME || true
export PYTHONNOUSERSITE=1 TF_CPP_MIN_LOG_LEVEL=2

(cd "$ROOT/backend" && exec "$PY" -m waitress --listen=127.0.0.1:5055 --threads=4 app:app) &
BP=$!
trap 'kill $BP 2>/dev/null || true' EXIT INT TERM

echo "Open: http://localhost:3055   (Ctrl+C to stop)"
"$PY" -m http.server 3055 --bind 127.0.0.1 --directory "$ROOT/frontend/build"
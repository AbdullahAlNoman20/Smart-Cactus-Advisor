# ===== setup.sh -- POORA FILE REPLACE KORO (Linux/Mac: system python/node thakle skip) =====
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"; P="$ROOT/.portable"; mkdir -p "$P"
export PYTHONNOUSERSITE=1
unset PYTHONPATH PYTHONHOME || true

find_py() {
  for c in python3.12 python3.11 python3.10 python3 python; do
    command -v "$c" >/dev/null 2>&1 || continue
    if "$c" -c 'import sys,venv;sys.exit(0 if (3,10)<=sys.version_info[:2]<(3,13) else 1)' 2>/dev/null; then
      command -v "$c"; return 0
    fi
  done
  return 1
}

VPY="$P/venv/bin/python"
if [ ! -x "$VPY" ] || ! "$VPY" -c 'import sys' 2>/dev/null; then
  rm -rf "$P/venv"
  if SYSPY="$(find_py)" && "$SYSPY" -m venv "$P/venv" 2>/dev/null; then
    echo "[1-2/5] System Python used: $SYSPY (download skip)"
  else
    rm -rf "$P/venv"
    case "$(uname -s)-$(uname -m)" in
      Linux-x86_64)  UVT=x86_64-unknown-linux-gnu ;;
      Linux-aarch64) UVT=aarch64-unknown-linux-gnu ;;
      Darwin-arm64)  UVT=aarch64-apple-darwin ;;
      Darwin-x86_64) UVT=x86_64-apple-darwin ;;
      *) echo "Unsupported OS/arch"; exit 1 ;;
    esac
    export UV_PYTHON_INSTALL_DIR="$P/python" UV_CACHE_DIR="$P/cache" UV_PYTHON_PREFERENCE=only-managed
    if [ ! -x "$P/uv" ]; then
      echo "[1/5] Downloading uv..."
      curl -fsSL "https://github.com/astral-sh/uv/releases/latest/download/uv-$UVT.tar.gz" | tar -xz -C "$P" --strip-components=1
    fi
    echo "[2/5] Creating private Python 3.11 venv..."
    "$P/uv" venv --python 3.11 "$P/venv"
  fi
fi

echo "[3/5] Installing backend dependencies..."
"$VPY" -m ensurepip --upgrade >/dev/null 2>&1 || true
"$VPY" -m pip install --upgrade pip --disable-pip-version-check
"$VPY" -m pip install --disable-pip-version-check -r "$ROOT/backend/requirements.txt" waitress==3.0.0

USE_SYS_NODE=0
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  NMAJ="$(node -v | sed 's/^v//' | cut -d. -f1)"
  [ "$NMAJ" -ge 18 ] 2>/dev/null && USE_SYS_NODE=1
fi
if [ "$USE_SYS_NODE" -eq 1 ]; then
  echo "[4/5] System Node found (download skip)"
else
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) NT=linux-x64 ;; Linux-aarch64) NT=linux-arm64 ;;
    Darwin-arm64) NT=darwin-arm64 ;; Darwin-x86_64) NT=darwin-x64 ;;
  esac
  if [ ! -x "$P/node/bin/node" ]; then
    echo "[4/5] Downloading private Node 20..."
    rm -rf "$P/node"; mkdir -p "$P/node"
    curl
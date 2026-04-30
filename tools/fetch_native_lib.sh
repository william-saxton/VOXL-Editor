#!/usr/bin/env bash
# Fetches the libvoxl_native binary from a GitHub release of the `voxl` repo.
#
# Usage:
#   tools/fetch_native_lib.sh                    # latest release, current platform
#   tools/fetch_native_lib.sh v1.2.0             # specific tag, current platform
#   tools/fetch_native_lib.sh latest linux       # latest release, explicit platform
#   tools/fetch_native_lib.sh v1.2.0 windows     # specific tag, windows
#   tools/fetch_native_lib.sh latest all         # latest release, both platforms
#
# Requires: gh (GitHub CLI) authenticated, OR curl + a public repo.
set -euo pipefail

REPO="${VOXL_REPO:-william-saxton/voxl}"
TAG="${1:-latest}"
PLATFORM="${2:-auto}"

if [ "$PLATFORM" = "auto" ]; then
  case "$(uname -s)" in
    Linux*)  PLATFORM=linux ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM=windows ;;
    Darwin*) echo "macOS not yet supported" >&2; exit 1 ;;
    *)       echo "Unknown platform; pass 'linux' or 'windows' as 2nd arg" >&2; exit 1 ;;
  esac
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$ROOT/bin"
mkdir -p "$BIN_DIR"

fetch_one() {
  local plat="$1"
  local asset
  case "$plat" in
    linux)   asset="libvoxl_native-linux-x86_64.tar.gz" ;;
    windows) asset="libvoxl_native-windows-x86_64.zip" ;;
    *) echo "unknown platform: $plat" >&2; return 1 ;;
  esac

  echo "Fetching $asset from $REPO@$TAG ..."
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  if command -v gh >/dev/null 2>&1; then
    gh release download "$TAG" --repo "$REPO" --pattern "$asset" --dir "$tmp"
  else
    local url
    if [ "$TAG" = "latest" ]; then
      url="https://github.com/$REPO/releases/latest/download/$asset"
    else
      url="https://github.com/$REPO/releases/download/$TAG/$asset"
    fi
    curl -fsSL -o "$tmp/$asset" "$url"
  fi

  case "$asset" in
    *.tar.gz) tar -xzf "$tmp/$asset" -C "$BIN_DIR" ;;
    *.zip)    unzip -o "$tmp/$asset" -d "$BIN_DIR" >/dev/null ;;
  esac
  echo "Installed $plat lib into $BIN_DIR/"
}

if [ "$PLATFORM" = "all" ]; then
  fetch_one linux
  fetch_one windows
else
  fetch_one "$PLATFORM"
fi

echo "Done."
ls -la "$BIN_DIR/"

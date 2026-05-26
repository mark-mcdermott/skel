#!/usr/bin/env bash
set -e

INSTALL_DIR="${1:-/usr/local/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -m 755 "$SCRIPT_DIR/skel.sh" "$INSTALL_DIR/skel"
echo "Installed skel to $INSTALL_DIR/skel"

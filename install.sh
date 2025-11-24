#!/usr/bin/env bash
set -Eeuo pipefail
# Minimal installer wrapper
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo bash "$SCRIPT_DIR/scripts/install_mobile_reality.sh"

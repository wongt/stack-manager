#!/usr/bin/env bash
set -euo pipefail

DEST="${DEST:-/usr/local/bin}"
FORCE="${FORCE:-no}"

die(){ echo "❌ $*" >&2; exit 1; }
info(){ echo "➤ $*"; }
ok(){ echo "✅ $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/bin/stack"

[[ -f "$SRC" ]] || die "stack binary not found at $SRC"

install_cli() {
  mkdir -p "$DEST"
  if [[ -f "$DEST/stack" && "$FORCE" != "yes" ]]; then
    die "File exists: $DEST/stack (set FORCE=yes to overwrite)"
  fi
  info "Installing stack CLI → $DEST/stack"
  install -m 0755 "$SRC" "$DEST/stack"
  ok "Installed stack CLI"
}

usage() {
cat <<EOF
Usage:
  install.sh [--force]

Environment variables:
  DEST=/usr/local/bin   Installation path
  FORCE=yes             Overwrite existing installation

Examples:
  ./scripts/install.sh
  DEST=/usr/bin FORCE=yes ./scripts/install.sh
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && usage && exit 0

install_cli
ok "Done."

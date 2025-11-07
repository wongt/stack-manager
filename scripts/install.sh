#!/usr/bin/env bash
set -euo pipefail

# ---- Config (can be set via env) ----
DEST="${DEST:-/usr/local/bin}"
FORCE="${FORCE:-no}"
REPO="${REPO:-}"       # e.g. wongt/stack-manager
BRANCH="${BRANCH:-}"   # e.g. main or develop
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com}"

die(){ echo "❌ $*" >&2; exit 1; }
info(){ echo "➤ $*"; }
ok(){ echo "✅ $*"; }

# When piped (curl | bash), BASH_SOURCE may be unset.
# Fall back to $0 directory or CWD.
_this="${BASH_SOURCE[0]:-}"
if [[ -n "$_this" && -e "$_this" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$_this")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd 2>/dev/null || echo "$SCRIPT_DIR")"

SRC_LOCAL="$REPO_ROOT/bin/stack"
TMP_DL=""

usage() {
  cat <<EOF
Usage:
  # From a cloned repo:
  ./scripts/install.sh [--force]
     ENV: DEST=/usr/local/bin  FORCE=yes

  # Direct from GitHub (no clone):
  curl -fsSL ${RAW_BASE}/<user>/<repo>/<branch>/scripts/install.sh \\
    | REPO=<user>/<repo> BRANCH=<branch> bash

  Optional ENV:
    DEST   install path (default: /usr/local/bin)
    FORCE  yes|no overwrite (default: no)
    REPO   github repo (owner/name) for remote install
    BRANCH branch or tag name for remote install
    RAW_BASE override raw host (default: ${RAW_BASE})
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && usage && exit 0

install_file() {
  local src="$1"
  [[ -f "$src" ]] || die "Source not found: $src"
  mkdir -p "$DEST"
  if [[ -f "$DEST/stack" && "$FORCE" != "yes" ]]; then
    die "File exists: $DEST/stack (set FORCE=yes to overwrite)"
  fi
  info "Installing stack CLI → $DEST/stack"
  install -m 0755 "$src" "$DEST/stack"
  ok "Installed: $DEST/stack"
}

download_stack() {
  [[ -n "$REPO" && -n "$BRANCH" ]] || die "REPO and BRANCH must be set for remote install."
  local url="${RAW_BASE}/${REPO}/${BRANCH}/bin/stack"
  info "Downloading $url"
  TMP_DL="$(mktemp)"
  curl -fsSL "$url" -o "$TMP_DL" || die "Failed to download: $url"
  chmod +x "$TMP_DL"
}

main() {
  if [[ -f "$SRC_LOCAL" ]]; then
    info "Found local stack binary at: $SRC_LOCAL"
    install_file "$SRC_LOCAL"
  else
    info "Local bin/stack not found. Attempting remote install…"
    download_stack
    install_file "$TMP_DL"
    rm -f "$TMP_DL"
  fi
  ok "Done."
}

main

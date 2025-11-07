#!/usr/bin/env bash
set -euo pipefail

VERSION="0.2.0"

# ---------- Default configuration ----------
COMPOSE_FILES=("docker-compose.yml")
ENV_FILE=".env"
STACK_NAME_DEFAULT="${APP:-}"
DETACH="false"
WAIT_TIMEOUT=300
CONTEXT="${DOCKER_CONTEXT:-}"

# ---------- Helpers ----------
die(){ echo "❌ $*" >&2; exit 1; }
info(){ echo "➤ $*"; }
ok(){ echo "✅ $*"; }

compose_args() {
  local args=()
  for f in "${COMPOSE_FILES[@]}"; do
    [[ -f "$f" ]] || die "Compose file not found: $f"
    args+=(-c "$f")
  done
  printf "%s " "${args[@]}"
}

stack_name() {
  local name="${STACK_NAME_DEFAULT}"
  [[ -z "${name:-}" && -f "$ENV_FILE" ]] && set +u && . "$ENV_FILE" && set -u && name="${APP:-}"
  [[ -z "${name:-}" && -f ".stackrc" ]] && set +u && . ".stackrc" && set -u && name="${APP:-}"
  [[ -z "${name:-}" ]] && die "No stack name set. Add APP= in .stackrc or .env."
  printf "%s" "$name"
}

require_swarm() {
  docker info --format '{{.Swarm.LocalNodeState}}' | grep -qE 'active|manager' \
    || die "Docker Swarm inactive on this node. Run: docker swarm init"
}

wait_ready() {
  local stack="$1" deadline=$(( $(date +%s) + WAIT_TIMEOUT ))
  info "Waiting for stack '$stack' to become ready (timeout: ${WAIT_TIMEOUT}s)…"
  while true; do
    local states total running
    mapfile -t states < <(docker stack ps "$stack" --no-trunc --format '{{.CurrentState}}' 2>/dev/null || true)
    total=${#states[@]}
    (( total == 0 )) && sleep 1 && [[ $(date +%s) -lt $deadline ]] && continue
    running=0
    for s in "${states[@]}"; do [[ "$s" =~ ^Running\ |^Complete\  ]] && ((running++)); done
    (( running == total )) && ok "All $total tasks are running/complete." && return 0
    [[ $(date +%s) -ge $deadline ]] && die "Timed out waiting for stack readiness."
    sleep 2
  done
}

usage() {
cat <<EOF
stack-manager ${VERSION}

Usage:
  stack [command]

Commands:
  up            Deploy/update the stack in current directory
  down|rm       Remove the stack
  ps            Show services/tasks
  logs          Tail logs of all services
  redeploy      Force update of all services (rolling)
  wait          Wait until tasks running/complete
  prune         Prune unused docker objects
  --help        Show this help
  --version     Show version

Environment files:
  .stackrc  - Stack-specific configuration (APP, COMPOSE_FILES, etc.)
  .env      - Environment variables passed to compose

Examples:
  stack up
  stack down
  stack ps
  DETACH=true stack up
EOF
}

[[ "${1:-}" == "--help" ]] && usage && exit 0
[[ "${1:-}" == "--version" ]] && echo "$VERSION" && exit 0

cmd="${1:-}"; shift || true

case "$cmd" in
  up)
    [[ -f ".stackrc" ]] && set +u && . ".stackrc" && set -u
    [[ -f "$ENV_FILE" ]] && info "Loaded $ENV_FILE"
    require_swarm
    local name; name="$(stack_name)"
    info "Deploying stack '$name'"
    # shellcheck disable=SC2046
    docker stack deploy $(compose_args) --with-registry-auth --prune --detach="$DETACH" "$name"
    [[ "$DETACH" == "false" ]] && wait_ready "$name"
    ok "Deployed $name"
    ;;
  down|rm)
    local name; name="$(stack_name)"
    info "Removing stack '$name'"
    docker stack rm "$name" || true
    ok "Removed $name"
    ;;
  ps)
    local name; name="$(stack_name)"
    docker stack services "$name"
    echo
    docker stack ps "$name" --no-trunc
    ;;
  logs)
    local name; name="$(stack_name)"
    docker service ls --format '{{.Name}}' | grep -E "^${name}_" | xargs -r docker service logs -f --since=10m
    ;;
  redeploy)
    local name; name="$(stack_name)"
    docker service ls --format '{{.Name}}' | grep -E "^${name}_" | while read -r svc; do
      docker service update --force --label-add "redeploy-ts=$(date +%s)" "$svc"
    done
    ;;
  wait)
    local name; name="$(stack_name)"
    wait_ready "$name"
    ;;
  prune)
    docker system prune -f
    ;;
  "")
    usage
    ;;
  *)
    die "Unknown command: $cmd"
    ;;
esac

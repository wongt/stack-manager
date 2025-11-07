# stack-manager CLI — Usage

## Overview
`stack` is a lightweight Docker Swarm deployment helper.  
It standardizes how you deploy, update, and remove stacks using
versioned Compose files and simple environment configuration.

## Commands
| Command | Description |
|----------|--------------|
| `stack up` | Deploy or update the stack in the current directory. |
| `stack down` | Remove the stack. |
| `stack ps` | Show services and running tasks. |
| `stack logs` | Follow logs for all services. |
| `stack redeploy` | Force rolling update of all services. |
| `stack prune` | Prune unused images/volumes/networks. |
| `stack wait` | Wait for all tasks to reach running/complete state. |

## Configuration
Each stack directory should contain:

- **`docker-compose.yml`** — required service definition.
- **`.stackrc`** — optional stack settings:
  ```bash
  APP="traefik"
  COMPOSE_FILES=("docker-compose.yml" "docker-compose.prod.yml")
  DETACH="false"
  WAIT_TIMEOUT="600"
  DOCKER_CONTEXT="swarm-prod"
  ```
- **`.env`** — standard Compose environment variables (ignored by Git).

## Examples
```bash
cd stacks/traefik
stack up
stack ps
stack logs
```

Use environment overrides inline:
```bash
DETACH=true WAIT_TIMEOUT=900 stack up
```

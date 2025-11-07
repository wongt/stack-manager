# stack-manager 🐋

A simple, zero-dependency CLI to manage Docker Swarm stacks reproducibly.

---

## ✨ Features
- Deploy/update/remove stacks with one command.
- Waits until services are healthy.
- Works per-directory using `.stackrc` + `.env`.
- Drop-in portable Bash script — no Python/Go dependencies.
- Perfect for home-lab or production Swarm clusters.

---

## 📦 Install
```bash
curl -fsSL https://raw.githubusercontent.com/wongt/stack-manager/main/scripts/install.sh | bash
```

or clone:
```bash
git clone https://github.com/wongt/stack-manager.git
cd stack-manager
./scripts/install.sh
```

After install:
```bash
stack --version
```

---

## 🧩 Directory structure for stacks
```
stacks/
 ├─ traefik/
 │   ├─ docker-compose.yml
 │   ├─ .env.example
 │   ├─ .stackrc
 │   └─ README.md
 └─ kestra/
     ├─ docker-compose.yml
     ├─ .env.example
     ├─ .stackrc
     └─ README.md
```

Each folder defines one deployable Swarm stack.

---

## 🚀 Usage
```bash
cd stacks/traefik
stack up        # deploy or update
stack ps        # view services
stack logs      # follow logs
stack down      # remove
```

---

## 🧠 Example `.stackrc`
```bash
APP="traefik"
COMPOSE_FILES=("docker-compose.yml")
DETACH="false"
WAIT_TIMEOUT="600"
```

---

## 🛠️ CI/CD integration
1. Install the CLI in your CI job:
   ```yaml
   - name: Install stack CLI
     run: |
       curl -fsSL -o /usr/local/bin/stack \
         https://raw.githubusercontent.com/wongt/stack-manager/main/bin/stack
       chmod +x /usr/local/bin/stack
   ```
2. Deploy stacks directly:
   ```yaml
   - run: cd stacks/traefik && stack up
   ```

---

## 🧾 License
[MIT](./LICENSE)

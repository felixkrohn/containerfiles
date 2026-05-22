---
name: container-orchestration
description: Manages runtime environments using podman and buildah. Can spin up containers with specific language versions, tools, or custom images on demand. Use when tasks require specific environment setups that aren't available in the base pi image.
compatibility: Requires rootless podman/buildah support (Docker socket mounting for docker-compatible operations)
---

# Container Orchestration Skill

The pi-code agent runs inside a container with **buildah** and **podman** pre-installed, enabling it to dynamically create and use runtime environments without needing permanent installation.

## Capabilities

### 1. Run Temporary Runtime Containers

Execute commands in isolated environment containers:

```bash
# Python specific version (e.g., Python 3.12)
podman run --rm -v $(pwd):/work:z python:3.12-slim bash -c "cd /work && pip install -r requirements.txt && python script.py"

# Node.js specific version
podman run --rm -v $(pwd):/work:z node:20-alpine npm install && npm test

# Rust toolchain
podman run --rm -v $(pwd):/work:z rust:latest cargo build

# Custom multi-tool environment
podman run --rm -it --name dev-env ubuntu:24.04 bash
```

### 2. Build Custom Images with buildah

Create optimized images for repeated use:

```bash
# Basic image build from Containerfile
buildah bud -t my-python-app .

# Build with secrets (credentials, API keys)
buildah bud --secret id=api_key src=/path/to/key.txt -t secure-image .

# Multi-stage builds
podman build -f Containerfile.multi -t optimized-app .
```

### 3. Push/Pull Images to Registries

Store and retrieve custom images:

```bash
# Login to registry (Docker Hub, Quay.io, etc.)
buildah login docker.io

# Pull base image
podman pull python:3.12-slim

# Push built image
buildah push my-python-app docker-daemon:myregistry.com/myapp:latest
```

### 4. Container Management Commands

Common operations pi can execute:

| Command | Purpose |
|---------|---------|
| `podman ps` | List running containers |
| `podman images` | List available images |
| `podman logs <container>` | View container output |
| `podman stop/start/rm` | Container lifecycle management |

## Security Considerations

- **Rootless operation**: All commands run as non-root user (UID 1000)
- **Volume mounts**: Use `:z` suffix for SELinux compatibility when mounting host directories
- **Network isolation**: Containers are isolated by default; use `--net=host` only when necessary
- **Secrets handling**: Pass sensitive data via buildah secrets, not environment variables

## Common Patterns

### Pattern 1: One-off Script Execution

```bash
podman run --rm -v $(pwd):/work:z python:3.12-slim sh -c "cd /work && pip install pandas && python analyze.py"
```

### Pattern 2: Development Environment with Persistent Volume

```bash
# Start interactive dev container mounted to project
podman run -it --rm \
  -v $(pwd):/work:z \
  -v ~/.npm-global:/home/node/.npm:Z \
  node:20-alpine \
  npm install && bash
```

### Pattern 3: Build and Test Pipeline

```bash
# Step 1: Build image with application code
buildah bud -t myapp .

# Step 2: Run tests in isolated container
podman run --rm myapp pytest tests/

# Step 3: Push verified image
buildah push myapp docker-daemon:myregistry.com/myapp:v1.0
```

### Pattern 4: Multi-language Project Support

For projects requiring multiple language environments, create separate containers per task:

```bash
# Python processing stage
podman run --rm -v $(pwd):/work:z python:3.12-slim pip install data-processor && python process.py

# Node.js build stage  
podman run --rm -v $(pwd):/work:z node:20-alpine npm run build

# Go compilation stage
podman run --rm -v $(pwd):/work:z golang:1.22 go build ./...
```

## Available Base Images

### Official Docker Hub Images (also available via podman pull)
- `python:<version>-slim` - Python environments
- `node:<version>-alpine` - Node.js environments  
- `golang:<version>` - Go toolchains
- `rust:latest` or `rust:<version>` - Rust compilation
- `ubuntu:24.04`, `debian:stable-slim` - General Linux bases
- `fedora:latest` - Fedora base (same as pi's container)

### Container Registries
Podman can pull from any OCI-compatible registry without authentication for public images:
- Docker Hub (`docker.io`)
- Quay.io (`quay.io`)
- GitHub Container Registry (`ghcr.io`)
- Google Container Registry (`gcr.io`)
- Amazon ECR (requires login)

## Troubleshooting

### Permission Denied on Volume Mounts
Add `:z` or `:Z` suffix to volume mounts for SELinux relabeling.

```bash
# :z - shared content label (multiple containers can access)
-v $(pwd):/work:z

# :Z - private content label (single container only, more secure)  
-v $(pwd):/work:Z
```

### Storage Full or Corrupted
Reset podman storage:

```bash
podman system prune -a  # Remove unused images and containers
buildah rmi --all       # Remove all buildah images
```

### Network Issues with Host Networking
If `--net=host` is needed, ensure the container has proper network device access. For rootless operation, user namespace mapping must be configured correctly.

## Integration with pi Agent Workflows

When a task requires specific tooling:

1. **Check if available in base image** - If yes, use directly
2. **Identify appropriate runtime container** - Select matching language/version
3. **Execute via podman run --rm** - For one-off tasks (auto-cleanup)
4. **Use buildah for custom images** - When repeated usage or optimization needed

Example workflow: "Install Python dependencies and run tests"

```bash
# Instead of installing pip/packages on host, use ephemeral container
podman run --rm \
  -v $(pwd):/work:z \
  python:3.12-slim \
  sh -c "cd /work && pip install -r requirements.txt && pytest"
```

This keeps the pi environment clean and reproducible while enabling any toolchain on demand.

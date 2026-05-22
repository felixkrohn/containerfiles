# pi-code Container with Buildah/Podman Support
Fedora-based container using the upstream buildah container pattern as a foundation. Provides:

- **buildah & podman**: Full container building and orchestration capabilities
- **Rootless operation**: Proper user namespace configuration for running containers from within the pi agent
- **Dynamic environment support**: Can spin up Python, Node.js, Rust, Go, or any other language runtime on-demand via ephemeral containers

**Build:**
```bash
podman build -t localhost/pi-code-buildah:latest -f Containerfile-pi-buildah .
```

## How It Works

The pi agent runs as a non-root user (UID 1000) inside an ephemeral container. With the enhanced `Containerfile-pi-buildah`, it can now:

1. **Pull runtime images** from any OCI registry (`podman pull python:3.12-slim`)
2. **Execute code in isolated environments** (`podman run --rm -v $(pwd):/work:z ...`)
3. **Build custom container images** with buildah for optimized workflows
4. **Push/pull to registries** for storing reusable images

This avoids the need to install language toolchains permanently inside the pi image itself, keeping it lean while enabling any environment on demand.

### Example Workflow

Instead of:
```bash
# Bad - installs dependencies in ephemeral container that gets destroyed
pip install pandas && python analyze.py
```

Use:
```bash
podman run --rm \
  -v $(pwd):/work:z \
  python:3.12-slim \
  sh -c "cd /work && pip install pandas && python analyze.py"
```

## Container Orchestration Skill

The `skills/container-orchestration/SKILL.md` file documents how the pi agent can use these capabilities. When loaded, it teaches pi:

- How to spin up runtime containers for specific language versions
- Buildah commands for creating custom images  
- Security considerations (rootless operation, volume mounts)
- Common patterns and troubleshooting tips

## Building and Using

### Step 1: Build the Enhanced Container

```bash
podman build -t localhost/pi-code-buildah:latest -f Containerfile-pi-buildah .
```

### Step 2: Run the pi Agent

Also see `pi-code.inc.sh` for an alias function that you can use in your .bashrc/.zshrc to invoke pi using podman.


```bash
# Interactive mode
podman run --rm -it \
  -v $(pwd):/work:z \
  localhost/pi-code-buildah:latest

# With arguments  
podman run --rm -it \
  -v /path/to/project:/project:z \
  -w /project \
  --security-opt label=disable \
  --device /dev/fuse:rw \
  --userns=keep-id \
  localhost/pi-code-buildah:latest "explain this codebase"
```

### Step 3: Verify Container Capabilities

Inside the running pi agent, test podman/buildah:

```bash
# Check versions
podman --version
buildah version

# Pull a runtime image
podman pull python:3.12-slim

# Run code in ephemeral container
podman run --rm -v $(pwd):/work:z python:3.12-slim python -c "print('Hello from Python!')"
```

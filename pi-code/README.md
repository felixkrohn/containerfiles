# TL;DR
- build the container image locally using the containerfile: `buildah bud --layers -t localhost/pi-code-buildah:latest Containerfile`
- copy pi-code.inc.sh into your $HOME/.bashrc.d/ directory: `cp pi-code.inc.sh $HOME/.bashrc.d/*`
- reload bash: `exec bash`
- (if you use a different shell, you will probably know what to do)
- start pi with `pi-code` (or adapt the shell function if you want a different name)
- the wrapper will automatically mount the directory you're currently in into the container at the same path, and use it as working directory.
- it will also mount your ~/.pi directory, but not your complete home - if a LLM goes havoc your files not mounted into the container are safe.
- ~/bin/ will also be mounted into the container and is added to $PATH - if you have static binaries in your ~/bin pi can use them in the container as well (kubectl, krew, or whatever)
- if you start pi-code in your /home/<username> the wrapper will automatically switch to /home/<username>/git in order to preserve your home
- Ctrl+d or ESC-ESC will quit pi as well as the container
- copy the skill file into your pi config dir to use it: `cp -r ./container-orchestration/ ~/.pi/agent/skills/`. It will tell pi and your model how to use podman/buildah within the container to use third-party tools, libraries or whatever in a container (within the pi container)


# pi-code Container with Buildah/Podman Support
Fedora-based container using the upstream buildah/podman container pattern as a foundation. Provides:

- **buildah & podman**: Full container building and orchestration capabilities  
- **Nested container support**: Run containers inside this container (requires `--privileged`)
- **Dynamic environment support**: Can spin up Python, Node.js, Rust, Go, or any other language runtime on-demand via ephemeral containers

**Note:** Nested podman/buildah operations require running the pi-code container with `--privileged`. See upstream documentation:
https://github.com/containers/image_build/blob/main/podman/README.md

**Build:**
```bash
podman build -t localhost/pi-code-buildah:latest -f Containerfile .
```

## How It Works

The pi agent runs as a non-root user (UID 1000) inside an ephemeral container. With this image, it can now:

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

### Step 1: Build the Container image

```bash
podman build -t localhost/pi-code-buildah:latest -f Containerfile .
```

### Step 2: Run the pi Agent

Also see `pi-code.inc.sh` for an alias function that you can use in your .bashrc/.zshrc to invoke pi using podman.

**Important:** To enable nested container operations (podman inside podman), run with `--privileged`:

```bash
# Interactive mode without nested containers
podman run --rm -it \
  -v $(pwd):/work:z \
  localhost/pi-code-buildah:latest

# With nested container support (required for podman build/run inside)
podman run --rm -it \
  -v /path/to/project:/project:z \
  -w /project \
  --privileged \
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

# Run code in ephemeral container (requires parent to be run with --privileged)
podman run --rm -v $(pwd):/work:z python:3.12-slim python -c "print('Hello from Python!')"
```

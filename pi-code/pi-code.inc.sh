# Pi-code agent container launcher
# Usage: pi-code [directory] [--] [pi-agent-args...]
# Examples:
#   pi-code                    # Work on current directory
#   pi-code /path/to/project   # Work on specific directory  
#   pi-code . "explain this"   # Pass arguments to pi agent

# Note: This launcher enables nested container support (podman/buildah inside) using --privileged.
# See upstream podman/stable image for reference:
# https://github.com/containers/image_build/blob/main/podman/README.md
#
# Required because crun needs to mount /proc, manipulate cgroups, and create namespaces
# for child containers. The container's containers.conf uses host namespaces.

pi-code() {
    local target_dir="${1:-$PWD}"
    
    if [[ "$target_dir" == "--" ]]; then
        shift && target_dir="$PWD"
    elif [[ ! -d "$target_dir" ]]; then
        target_dir="$PWD"
    fi
    
    podman --log-level=info run --rm -it \
        -v "${target_dir}:${target_dir}:z" \
        -v "$HOME/.pi/agent:/home/piuser/.pi/agent:rw,z" \
        -w "$(realpath "$target_dir")" \
        --privileged \
        localhost/pi-code-buildah:latest \
        "${@}"
}

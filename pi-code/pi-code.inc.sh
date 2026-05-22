# Pi-code agent container launcher
# Usage: pi-code [directory] [--] [pi-agent-args...]
# Examples:
#   pi-code                    # Work on current directory
#   pi-code /path/to/project   # Work on specific directory  
#   pi-code . "explain this"   # Pass arguments to pi agent

pi-code() {
    local target_dir="${1:-$PWD}"
    
    if [[ "$target_dir" == "--" ]]; then
        shift && target_dir="$PWD"
    elif [[ ! -d "$target_dir" ]]; then
        target_dir="$PWD"
    fi
    
    podman run --rm -it \
        -v "${target_dir}:${target_dir}:z" \
        -v "$HOME/.pi/agent:/home/piuser/.pi/agent:rw,z" \
        -w "$(realpath "$target_dir")" \
        --net=host \
        --security-opt label=disable \
        --device /dev/fuse:rw \
        --userns=keep-id \
        localhost/pi-code-buildah:latest \
        "${@}"
}

# Pi-code agent container function
# Usage: pi-code [directory] [pi-agent-args...]
# Examples:
#   pi-code                    # Work on current directory
#   pi-code /path/to/project   # Work on specific directory
#   pi-code . "explain this"   # Work on current directory and pass args to pi
pi-code() {
    # Determine target directory (first arg or $PWD)
    local target_dir
    if [ $# -gt 0 ]; then
        # Check if first argument is a directory (not a flag)
        if [[ "$1" != --* ]] && [[ "$1" != -* ]]; then
            target_dir="$1"
            shift  # Remove first argument from "$@"
        else
            target_dir="$PWD"
        fi
    else
        target_dir="$PWD"
    fi
    
    # Convert to absolute path
    target_dir=$(realpath "$target_dir")
    
    # Run podman with appropriate mounts for rootless operation
    podman run --rm -it \
        -v "$target_dir:$target_dir:z" \
        -v "$HOME/.pi/agent:$HOME/.pi/agent:z" \
        -w "$target_dir" \
        localhost/pi-code:latest \
        pi "$@"
}

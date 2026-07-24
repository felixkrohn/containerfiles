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
    local settings="${HOME}/.claude/settings.json"
    local extra_flags=""
    mkdir -p ~/.pi/.aws ~/bin

    # Load env vars from ~/.claude/settings.json if present (replaces hostname-based detection)
    if [[ -f "$settings" ]] && command -v jq &>/dev/null; then
        # Export every key=value from the .env section into the current shell
        while IFS= read -r assignment; do
            export "${assignment?}"
        done < <(jq -r '.env | to_entries[] | "\(.key)=\(.value)"' "$settings")

        # Refresh credentials if credential-process is configured
        if [[ -n "${AWS_CREDENTIAL_PROCESS:-}" ]]; then
            ${AWS_CREDENTIAL_PROCESS} --refresh-if-needed 2>/dev/null || true
        fi

        # Resolve current credentials and write to a file the container can mount
        # (AWS_CREDENTIAL_PROCESS binary lives on the host, not inside the container)
        if [[ -n "${AWS_PROFILE:-}" ]]; then
            local _key _secret _token
            _key="$(aws configure get aws_access_key_id    --profile "$AWS_PROFILE" 2>/dev/null)"
            _secret="$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE" 2>/dev/null)"
            _token="$(aws configure get aws_session_token    --profile "$AWS_PROFILE" 2>/dev/null)"
            cat > ~/.pi/.aws/credentials <<EOF
[$AWS_PROFILE]
aws_access_key_id = ${_key}
aws_secret_access_key = ${_secret}
aws_session_token = ${_token}
EOF
        fi

        # Build --env flags for every key in settings.json except AWS_CREDENTIAL_PROCESS
        # (that command path is host-specific and meaningless inside the container)
        local env_flags
        env_flags="$(jq -r '.env | keys[] | select(. != "AWS_CREDENTIAL_PROCESS") | "--env \(.)"' "$settings" | tr '\n' ' ')"
        extra_flags="-v ${HOME}/.pi/.aws:/home/piuser/.aws:ro ${env_flags}"
    fi
    
    if [[ "$target_dir" == "--" ]]; then
        shift && target_dir="$PWD"
    elif [[ ! -d "$target_dir" ]]; then
        target_dir="$PWD"
    fi
    
    # default to git dir when invoced from home
    if [[  "$target_dir" == "${HOME}" ]]; then target_dir="${HOME}/git"; fi
    
    podman --log-level=info run --rm -it \
        -v "${target_dir}:${target_dir}:z" \
        -v "${HOME}/bin:/home/piuser/bin:z,ro" \
        -v "$HOME/.pi/agent:/home/piuser/.pi/agent:rw,z" \
        $extra_flags \
        -w "$(realpath "$target_dir")" \
        -e TERM=xterm-256color \
        --privileged \
	--userns=keep-id:uid=1000,gid=1000 \
        localhost/pi-code-buildah:latest \
        "${@}"
}

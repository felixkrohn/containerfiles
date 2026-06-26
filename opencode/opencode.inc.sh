opencode() {
    local target_dir="${1:-$PWD}"
    
    if [[ "$target_dir" == "--" ]]; then
        shift && target_dir="$PWD"
    elif [[ ! -d "$target_dir" ]]; then
        target_dir="$PWD"
    fi
    
    if [[  "$target_dir" == "${HOME}" ]]; then target_dir="${HOME}/git"; fi
    chmod -R g+rw ${target_dir}

    export AWS_PROFILE="claudebedrock-devl-eu-central-1"
    ~/claude-code-with-bedrock/credential-process --profile "${AWS_PROFILE}" --refresh-if-needed
    
    export AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id --profile $AWS_PROFILE)"
    export AWS_SECRET_ACCESS_KEY="$(aws configure get aws_secret_access_key --profile $AWS_PROFILE)"
    export AWS_SESSION_TOKEN="$(aws configure get aws_session_token --profile $AWS_PROFILE)"
    export AWS_REGION=eu-central-1
    #export AWS_BEDROCK_SKIP_AUTH=1
    export AWS_ENDPOINT_URL_BEDROCK_RUNTIME=https://vpce-0487335166f9e8124-unf2l3e4.bedrock-runtime.eu-central-1.vpce.amazonaws.com
    export ANTHROPIC_MODEL="eu.anthropic.claude-sonnet-4-6"
    export ANTHROPIC_SMALL_FAST_MODEL="eu.anthropic.claude-haiku-4-5-20251001-v1:0"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="eu.anthropic.claude-haiku-4-5-20251001-v1:0"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="eu.anthropic.claude-sonnet-4-6"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="eu.anthropic.claude-opus-4-8"
    export ANTHROPIC_BEDROCK_BASE_URL="https://vpce-0487335166f9e8124-unf2l3e4.bedrock-runtime.eu-central-1.vpce.amazonaws.com"

    mkdir -p ~/.opencode/.aws
    cat >~/.opencode/.aws/credentials <<EOF
[$AWS_PROFILE]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
aws_session_token = $AWS_SESSION_TOKEN
EOF

    podman --log-level=info run --rm -it \
        -v "${target_dir}:${target_dir}:z" \
        -w "$(realpath "$target_dir")" \
	-v ${HOME}/.cache/opencode:/home/opencode/.cache/opencode:z,rw \
	-v ${HOME}/.config/opencode:/home/opencode/.config/opencode:z,rw \
	-v ${HOME}/.local/share/opencode:/home/opencode/.local/share/opencode:rw,z \
	-v ${HOME}/.local/state/opencode:/home/opencode/.local/state/opencode:rw,z \
	-v "$HOME/.opencode/.aws:/home/opencode/.aws:ro" \
	--env AWS_PROFILE \
	--env AWS_REGION \
	--env ANTHROPIC_* \
	-e TERM=xterm-256color -e OC_TOKEN="$(oc whoami -t)" \
        --privileged \
	--security-opt label=disable \
        localhost/opencode:latest \
        "${@}"
}

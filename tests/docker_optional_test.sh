#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assert_contains() {
    local path="$1"
    local pattern="$2"
    rg -Fq "$pattern" "$path" || {
        printf 'expected %s to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    }
}

assert_not_contains() {
    local path="$1"
    local pattern="$2"
    ! rg -Fq "$pattern" "$path" || {
        printf 'expected %s not to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    }
}

make_fakebin() {
    local root="$1"
    mkdir -p "$root/fakebin"
}

test_configure_machine_generates_expected_config() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    mkdir -p "$HOME"

    printf '2\n2\n' | bash home/dot_local/bin/executable_configure-machine >/dev/null

    rg -Fq 'DOTFILES_DOCKER_MODE=engine' "$HOME/.config/dotfiles/machine.env"
    rg -Fq 'DOTFILES_DOCKER_GPU=nvidia' "$HOME/.config/dotfiles/machine.env"
}

test_configure_machine_preserves_unrelated_keys() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    mkdir -p "$HOME/.config/dotfiles"
    cat > "$HOME/.config/dotfiles/machine.env" <<'EOF'
# existing comment
EXTRA_KEY=keep
DOTFILES_DOCKER_MODE=none
DOTFILES_DOCKER_GPU=none
EOF

    printf '1\n' | bash home/dot_local/bin/executable_configure-machine >/dev/null

    rg -Fq '# existing comment' "$HOME/.config/dotfiles/machine.env"
    rg -Fq 'EXTRA_KEY=keep' "$HOME/.config/dotfiles/machine.env"
    rg -Fq 'DOTFILES_DOCKER_MODE=none' "$HOME/.config/dotfiles/machine.env"
}

test_setup_optional_requires_machine_config() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    mkdir -p "$HOME"

    if bash home/dot_local/bin/executable_setup-optional >/dev/null 2>&1; then
        printf 'setup-optional should fail without machine config\n' >&2
        exit 1
    fi
}

test_setup_optional_invokes_setup_docker_engine() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    mkdir -p "$HOME/.config/dotfiles" "$HOME/.local/bin"
    cat > "$HOME/.config/dotfiles/machine.env" <<'EOF'
DOTFILES_DOCKER_MODE=engine
DOTFILES_DOCKER_GPU=nvidia
EOF
    cat > "$HOME/.local/bin/setup-docker-engine" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'invoked\n' > "$HOME/docker-invoked.txt"
EOF
    chmod +x "$HOME/.local/bin/setup-docker-engine"

    bash home/dot_local/bin/executable_setup-optional >/dev/null

    rg -Fq 'invoked' "$HOME/docker-invoked.txt"
}

test_setup_docker_engine_rejects_invalid_gpu_mode_before_install() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    mkdir -p "$HOME/.config/dotfiles"
    cat > "$HOME/.config/dotfiles/machine.env" <<'EOF'
DOTFILES_DOCKER_GPU=bogus
EOF

    if bash home/dot_local/bin/executable_setup-docker-engine >/dev/null 2>&1; then
        printf 'setup-docker-engine should fail for invalid GPU mode\n' >&2
        exit 1
    fi
}

test_setup_docker_engine_rejects_nvidia_without_wsl2_runtime() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    export HOME="$test_root/home"
    make_fakebin "$test_root"
    export PATH="$test_root/fakebin:$PATH"
    mkdir -p "$HOME/.config/dotfiles"
    cat > "$HOME/.config/dotfiles/machine.env" <<'EOF'
DOTFILES_DOCKER_GPU=nvidia
EOF
    cat > "$test_root/fakebin/uname" <<'EOF'
#!/usr/bin/env bash
printf '5.15.0-generic\n'
EOF
    cat > "$test_root/fakebin/grep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "$test_root/fakebin/uname" "$test_root/fakebin/grep"

    if bash home/dot_local/bin/executable_setup-docker-engine >/dev/null 2>&1; then
        printf 'setup-docker-engine should reject NVIDIA outside WSL2 runtime\n' >&2
        exit 1
    fi
}

assert_contains "home/dot_local/bin/executable_setup-optional" "Run 'configure-machine' first."
assert_contains "home/dot_local/bin/executable_setup-optional" '"$HOME/.local/bin/setup-docker-engine"'

assert_contains "home/dot_local/bin/executable_setup-docker-engine" 'require_wsl2_nvidia_runtime()'
assert_contains "home/dot_local/bin/executable_setup-docker-engine" '/usr/lib/wsl/lib/nvidia-smi'
assert_contains "home/dot_local/bin/executable_setup-docker-engine" 'sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'

assert_contains "home/dot_local/bin/executable_configure-machine" "Docker setup for this machine:"
assert_contains "home/dot_local/bin/executable_configure-machine" "Enable NVIDIA GPU support"

assert_not_contains "home/dot_local/bin/executable_setup-system" "setup-docker-engine"
assert_not_contains "home/dot_local/bin/executable_setup-system" "configure-machine"

test_configure_machine_generates_expected_config
test_configure_machine_preserves_unrelated_keys
test_setup_optional_requires_machine_config
test_setup_optional_invokes_setup_docker_engine
test_setup_docker_engine_rejects_invalid_gpu_mode_before_install
test_setup_docker_engine_rejects_nvidia_without_wsl2_runtime

printf 'docker optional checks passed\n'

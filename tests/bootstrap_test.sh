#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

make_fakebin() {
    local root="$1"
    mkdir -p "$root/fakebin"

    cat > "$root/fakebin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

    cat > "$root/fakebin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

url="${@: -1}"

if [[ "$url" == "https://mise.run" ]]; then
  cat <<'SCRIPT'
#!/bin/sh
set -eu
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/mise" <<'EOF_MISE'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "install" ]]; then
  exit 0
fi

if [[ "${1:-}" == "which" && "${2:-}" == "gh" ]]; then
  printf '%s\n' "$HOME/.local/bin/gh"
  exit 0
fi

if [[ "${1:-}" == "exec" || "${1:-}" == "x" ]]; then
  exit 0
fi

exit 0
EOF_MISE
chmod +x "$HOME/.local/bin/mise"
cat > "$HOME/.local/bin/gh" <<'EOF_GH'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "login" ]]; then
  : > "$HOME/.local/share/gh-authenticated"
  exit 0
fi

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  if [[ -f "$HOME/.local/share/gh-authenticated" ]]; then
    exit 0
  fi
  exit 1
fi

if [[ "${1:-}" == "auth" && "${2:-}" == "token" ]]; then
  if [[ -f "$HOME/.local/share/gh-authenticated" ]]; then
    printf 'fake-token\n'
    exit 0
  fi
  exit 1
fi

exit 0
EOF_GH
chmod +x "$HOME/.local/bin/gh"
SCRIPT
  exit 0
fi

if [[ "$url" == "get.chezmoi.io" ]]; then
  cat <<'SCRIPT'
#!/bin/sh
set -eu

target=""
while [ $# -gt 0 ]; do
  case "$1" in
    -b)
      shift
      target="$1"
      ;;
  esac
  shift || true
done

mkdir -p "$target"
cat > "$target/chezmoi" <<'EOF_CHEZMOI'
#!/usr/bin/env bash
set -euo pipefail

source_dir="$HOME/.local/share/chezmoi-source"
behavior_file="$HOME/.local/share/chezmoi-behavior"

behavior="success"
if [[ -f "$behavior_file" ]]; then
  behavior="$(cat "$behavior_file")"
fi

case "${1:-}" in
  init)
    mkdir -p "$source_dir/home/.chezmoiscripts"
    cat > "$source_dir/home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" <<'TEMPLATE'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/self" "$HOME/work" "$HOME/explore"
TEMPLATE
    ;;
  apply)
    cat > "$HOME/.local/bin/setup-system" <<'SETUP'
#!/usr/bin/env bash
set -euo pipefail
: > "$HOME/.local/share/setup-system-ran"
exit 0
SETUP
    chmod +x "$HOME/.local/bin/setup-system"
    ;;
  source-path)
    printf '%s\n' "$source_dir/home"
    ;;
  execute-template)
    if [[ "$behavior" == "fail-execute-template" ]]; then
      exit 17
    fi
    cat
    ;;
esac
EOF_CHEZMOI
chmod +x "$target/chezmoi"
SCRIPT
  exit 0
fi

printf 'unexpected curl invocation: %s\n' "$*" >&2
exit 1
EOF

    chmod +x "$root/fakebin/sudo" "$root/fakebin/curl"
}

run_bootstrap() {
    local test_root="$1"
    export HOME="$test_root/home"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    export PATH="$test_root/fakebin:$PATH"
    bash "$repo_root/scripts/bootstrap.sh" >/dev/null 2>&1
}

test_creates_workspace_directories() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    make_fakebin "$test_root"
    run_bootstrap "$test_root"

    [[ -d "$test_root/home/self" ]]
    [[ -d "$test_root/home/work" ]]
    [[ -d "$test_root/home/explore" ]]
}

test_runs_setup_system_after_bootstrap_authentication() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    make_fakebin "$test_root"
    run_bootstrap "$test_root"

    [[ -f "$test_root/home/.local/share/gh-authenticated" ]]
    [[ -f "$test_root/home/.local/share/setup-system-ran" ]]
}

test_fails_when_template_rendering_fails() {
    local test_root
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' RETURN

    make_fakebin "$test_root"
    mkdir -p "$test_root/home/.local/share"
    printf 'fail-execute-template' > "$test_root/home/.local/share/chezmoi-behavior"

    if run_bootstrap "$test_root"; then
        printf 'bootstrap should fail when execute-template fails\n' >&2
        return 1
    fi
}

test_creates_workspace_directories
test_runs_setup_system_after_bootstrap_authentication
test_fails_when_template_rendering_fails

printf 'bootstrap tests passed\n'

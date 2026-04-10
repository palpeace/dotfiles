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

assert_not_contains "home/dot_config/mise/config.toml" '"npm:@anthropic-ai/claude-code" = "latest"'

assert_contains "home/dot_local/bin/executable_setup-system" 'https://claude.ai/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v claude >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v claude >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'claude update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://claude.ai/install.sh'

printf 'claude code installation checks passed\n'

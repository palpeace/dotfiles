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

# Ensure AI CLI tools are NOT managed via mise's config.toml (since they are custom-installed/updated)
assert_not_contains "home/dot_config/mise/config.toml" '"npm:@anthropic-ai/claude-code" = "latest"'
assert_not_contains "home/dot_config/mise/config.toml" '"npm:@google/gemini-cli" = "latest"'

# --- Claude Code Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://claude.ai/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v claude >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v claude >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'claude update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://claude.ai/install.sh'

# --- Kiro CLI Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://cli.kiro.dev/install'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v kiro-cli >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v kiro-cli >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'kiro-cli update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://cli.kiro.dev/install'

# --- Antigravity CLI Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://antigravity.google/cli/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v agy >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v agy >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'agy upgrade'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://antigravity.google/cli/install.sh'

printf 'AI tools installation checks passed\n'

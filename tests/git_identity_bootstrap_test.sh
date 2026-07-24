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
    if rg -Fq "$pattern" "$path"; then
        printf 'did not expect %s to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    fi
}

assert_contains "home/dot_gitconfig.tmpl" 'path = ~/.gitconfig.local'
assert_not_contains "home/dot_gitconfig.tmpl" '[includeIf "gitdir:~/work/"]'

assert_not_contains "home/dot_gitconfig.tmpl" 'ssh://git@github.com/'

assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'prompt_value'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'self_gitconfig_path'

assert_not_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'ssh-keygen'

assert_contains "home/dot_local/bin/executable_setup-system" 'gh auth setup-git'
assert_not_contains "home/dot_local/bin/executable_setup-system" 'ssh-keyscan'

printf 'git identity bootstrap checks passed\n'

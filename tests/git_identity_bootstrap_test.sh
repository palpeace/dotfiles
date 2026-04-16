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

assert_contains "home/dot_gitconfig.tmpl" '[includeIf "gitdir:~/work/"]'
assert_not_contains "home/dot_gitconfig.tmpl" 'git@github-self'
assert_not_contains "home/dot_gitconfig.tmpl" 'ssh://git@github.com/'

assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'ensure_git_identity_file'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" '入力が読み取れませんでした。対話可能な端末で再実行してください。'
assert_not_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'ssh-keygen'

assert_contains "home/dot_local/bin/executable_setup-system" 'gh auth setup-git'
assert_not_contains "home/dot_local/bin/executable_setup-system" 'ssh-keyscan'

printf 'git identity bootstrap checks passed\n'

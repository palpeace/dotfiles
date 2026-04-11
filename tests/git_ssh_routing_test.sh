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

assert_contains "home/dot_gitconfig.tmpl" '[url "git@github-self:"]'
assert_contains "home/dot_gitconfig.tmpl" 'insteadOf = git@github.com:'
assert_contains "home/dot_gitconfig.tmpl" 'insteadOf = ssh://git@github.com/'

assert_contains "home/private_dot_ssh/private_config.tmpl" 'Host github-self'
assert_contains "home/private_dot_ssh/private_config.tmpl" 'Host github-work'

assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" 'append_work_github_routing'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" '入力が読み取れませんでした。対話可能な端末で再実行してください。'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" 'insteadOf = https://github.com/$owner/'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" 'insteadOf = https://www.github.com/$owner/'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" 'insteadOf = git@github-self:$owner/'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" 'insteadOf = ssh://git@github.com/$owner/'

printf 'git ssh routing checks passed\n'

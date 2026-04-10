#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assert_file_exists() {
    local path="$1"
    [ -f "$path" ] || {
        printf 'expected file to exist: %s\n' "$path" >&2
        exit 1
    }
}

assert_file_absent() {
    local path="$1"
    [ ! -e "$path" ] || {
        printf 'expected path to be absent: %s\n' "$path" >&2
        exit 1
    }
}

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

assert_file_exists "home/dot_config/mise/config.toml"
assert_contains "home/dot_config/mise/config.toml" 'tmux = "latest"'
assert_not_contains "home/dot_config/mise/config.toml" 'zellij = "latest"'

assert_file_exists "home/dot_tmux.conf"
assert_contains "home/dot_tmux.conf" 'set -g prefix C-Space'
assert_contains "home/dot_tmux.conf" 'bind-key -T prefix p switch-client -T pane-mode'
assert_contains "home/dot_tmux.conf" "bind-key -T pane-mode n split-window -c '#{pane_current_path}'"
assert_contains "home/dot_tmux.conf" "bind-key -T tab-mode n new-window -c '#{pane_current_path}'"
assert_contains "home/dot_tmux.conf" 'bind-key -T resize-mode h resize-pane -L 5'
assert_contains "home/dot_tmux.conf" 'bind-key -T move-mode h swap-pane -s'
assert_contains "home/dot_tmux.conf" 'bind-key -n M-h select-pane -L'
assert_contains "home/dot_tmux.conf" 'bind-key -T session-mode w choose-tree -Zs'
assert_contains "home/dot_tmux.conf" 'bind-key -T scroll-mode f command-prompt'
assert_contains "home/dot_tmux.conf" 'bind-key -T scroll-mode e run-shell'

assert_file_exists "home/dot_local/bin/executable_tmux-edit-scrollback"
assert_contains "home/dot_local/bin/executable_tmux-edit-scrollback" 'tmux capture-pane'

assert_file_absent "home/dot_config/zellij"

printf 'tmux migration checks passed\n'

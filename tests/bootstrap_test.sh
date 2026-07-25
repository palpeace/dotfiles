#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_all_scripts_syntax() {
    local script
    while IFS= read -r script; do
        bash -n "$script" || {
            printf 'Syntax check failed for: %s\n' "$script" >&2
            exit 1
        }
    done < <(find home/dot_local/bin scripts tests -type f 2>/dev/null)
}

(test_all_scripts_syntax)

printf 'bootstrap tests passed\n'

#!/usr/bin/env bash
# 使わない言い回しを機械的に拾う。拾えるのは文字列の一致だけで、判断は人がする。
#
#   check-ng.sh [--all] FILE...
#     既定は hard（ほぼ常に誤りの型）だけを出す。--all で soft（文脈で判断する候補）も出す。
#     hard が1件以上あれば終了コード 1、それ以外は 0。
#     パターン表は同じディレクトリの ng-patterns.tsv。
set -uo pipefail

self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
patterns="$self_dir/ng-patterns.tsv"

usage() { sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

show_all=0
files=()
for a in "$@"; do
  case "$a" in
    --all) show_all=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "不明な引数: $a" >&2; usage >&2; exit 2 ;;
    *) files+=("$a") ;;
  esac
done

[ "${#files[@]}" -eq 0 ] && { usage >&2; exit 2; }
[ -f "$patterns" ] || { echo "パターン表が無い: $patterns" >&2; exit 2; }

hits=$(mktemp)
trap 'rm -f "$hits"' EXIT

for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "$f: 読めない" >&2
    continue
  fi
  while IFS=$'\t' read -r sev re hint; do
    [ -z "${sev:-}" ] && continue
    case "$sev" in \#*) continue ;; esac
    [ -z "${re:-}" ] && continue
    if [ "$show_all" -eq 0 ] && [ "$sev" != hard ]; then continue; fi
    grep -noE -- "$re" "$f" 2>/dev/null | while IFS=: read -r ln m; do
      [ -z "${ln:-}" ] && continue
      printf '%s\t%s\t%s\t%s\t%s\n' "$f" "$ln" "$sev" "$m" "$hint"
    done
  done < "$patterns"
done >> "$hits"

sort -t$'\t' -k1,1 -k2,2n "$hits" | while IFS=$'\t' read -r f ln sev m hint; do
  printf '%s:%s: [%s] 「%s」 → %s\n' "$f" "$ln" "$sev" "$m" "$hint"
done

hard_total=$(cut -f3 "$hits" | grep -c '^hard$' || true)
soft_total=$(cut -f3 "$hits" | grep -c '^soft$' || true)

if [ "$hard_total" -eq 0 ] && [ "$soft_total" -eq 0 ]; then
  echo "検出なし"
  exit 0
fi

printf 'hard %d 件 / soft %d 件\n' "$hard_total" "$soft_total"
[ "$hard_total" -gt 0 ] && exit 1
exit 0

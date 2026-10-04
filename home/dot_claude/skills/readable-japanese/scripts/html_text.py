#!/usr/bin/env python3
"""HTML の本文を、行番号を保ったまま Markdown に近いテキストにする。

  html_text.py FILE

  measure.py・compare.py・check-ng.sh が .html を読むときに使う。script・style・head・svg・pre・
  コメントは中身を消して改行だけを残すので、出した行番号は元の HTML の行番号と同じになる。
  見出しは「#」、箇条書きの項は「- 」、太字は「**」、表の行は「| … |」に置き換え、
  ほかのタグは外す。1行に収まらない段落は行ごとに別の行として読まれる。
"""
import html
import re
import sys


def _keep_newlines(m):
    return "\n" * m.group(0).count("\n")


def to_text(src):
    s = re.sub(r"<!--.*?-->", _keep_newlines, src, flags=re.S)
    s = re.sub(r"<(script|style|head|svg|pre)\b.*?</\1\s*>", _keep_newlines, s, flags=re.S | re.I)
    s = re.sub(r"</?code\b[^>]*>", "`", s, flags=re.I)
    s = re.sub(r"<h([1-6])\b[^>]*>", lambda m: "#" * int(m.group(1)) + " ", s, flags=re.I)
    s = re.sub(r"<li\b[^>]*>", "- ", s, flags=re.I)
    s = re.sub(r"</?(b|strong)\b[^>]*>", "**", s, flags=re.I)
    s = re.sub(r"<t[dh]\b[^>]*>", "| ", s, flags=re.I)
    s = re.sub(r"</tr\s*>", " |", s, flags=re.I)
    s = re.sub(r"<br\s*/?>", " ", s, flags=re.I)
    s = re.sub(r"<[^>]*>", "", s)
    # タグを外したあとの行頭の空白は、字下げしたコードと読まれないように外す
    return "\n".join(html.unescape(line).strip() for line in s.split("\n"))


def is_html(path):
    return path.lower().endswith((".html", ".htm"))


def read_text(path):
    """ファイルを読み、HTML なら本文のテキストにして返す。"""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return to_text(text) if is_html(path) else text


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0 if len(sys.argv) == 2 else 2)
    sys.stdout.write(read_text(sys.argv[1]))

#!/usr/bin/env python3
"""元の文と直した文を比べ、直したときに動きやすいものを出す。

  compare.py ORIGINAL REWRITE

  出すのは4つである。文末の種類が変わった文、言い回しの種類（依頼・勧め・義務・評価・
  可能・推量・強調・否定対比）の数の増減、直した文で増えた語と消えた語（数は別に出す）、
  文・段落・箇条書きの数の変化。どれも候補で、意味が動いたかどうかは人が読んで決める。
  終了コードは常に 0。
"""
import difflib
import os
import re
import sys

# 文末に付いた補足のカッコ。文末の種類を見る前に外す
TRAIL_PAREN = re.compile(r"\s*[(（][^()（）]*[)）]\s*$")

sys.dont_write_bytecode = True  # スキルの置き場所に __pycache__ を作らない
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure import classify, sentences, strip_inline  # noqa: E402
from html_text import read_text  # noqa: E402

# 言い回しの種類。書き直しで増えたら足した、減ったら消したことになる
MARKERS = [
    ("依頼", r"(て|で)ください|(て|で)ほしい|お願い"),
    ("勧め", r"ましょう|(と|ば|たら)(よい|いい)(です|だろう|でしょう)?(?=[。、]|$)|をおすすめ|を勧め"),
    ("義務", r"なければ(ならな|なりませ)|なくては(ならな|なりませ)|必要があ|べき|必須"),
    ("評価", r"重要|大切|大事|不可欠|欠かせ|肝心|肝要|鍵(だ|です|になる|となる)"),
    ("可能", r"でき(る|ます|ない|ません|た|ました)|可能(?!性)"),
    ("推量", r"かもしれ|だろう|でしょう|と思(う|い|われ)|と考え(る|られ|ます)|はず|おそれ|恐れ|ようだ|ようです|らしい|可能性"),
    ("強調", r"必ず|絶対|常に|まさに|こそ|非常に|極めて|大幅に|圧倒的"),
    ("否定対比", r"ではなく|ではない。|のではな"),
]

TOKEN = re.compile(r"[一-龥々〆ヶ]{2,}|[ァ-ヴー]{2,}|[A-Za-z][A-Za-z0-9_.+#/-]*")
NUMBER = re.compile(r"[0-9０-９][0-9０-９,.]*(?:[%％]|件|回|秒|分|時間|日|週|月|年|字|行|人|名|個|本|倍|点|割|円|MB|GB|ms|s)?")


def ending_kind(s):
    """文末の働き。直したときに変わると、文の働き（依頼・評価・推量など）が変わる。"""
    t = re.sub(r"[。．！？!?\s]+$", "", s)
    t = TRAIL_PAREN.sub("", t)
    if not t:
        return ""
    rules = [
        ("依頼", r"(て|で)ください$|(て|で)ほしい(です)?$|お願い(します|いたします|します)?$"),
        ("勧め", r"ましょう$|(と|ば|たら)(よい|いい)(です|だろう)?$|をおすすめします$"),
        ("推量", r"(でしょう|だろう|かもしれない|かもしれません|と思う|と思います|と考える|と考えます|はずだ|はずです|ようだ|ようです)$"),
        ("義務", r"(なければならない|なければなりません|必要がある|必要があります|べきだ|べきです|べきである)$"),
        ("評価", r"(重要|大切|大事|不可欠|肝心|肝要)(だ|です|である)?$|欠かせない$|欠かせません$"),
        ("過去", r"(た|だ|ました|でした|ませんでした|なかった)$"),
        ("可能", r"(できる|できます|できない|できません|られる|られます)$"),
        ("敬体の述語", r"(ます|ません|です)$"),
        ("常体の述語", r"(だ|である|ない|[うくすつぬふむゆるぐずぶ])$"),
    ]
    for name, pat in rules:
        if re.search(pat, t):
            return name
    return "体言止めほか"


def load(path):
    text = read_text(path)
    rows = classify(text.split("\n"))
    sents = [s for _, s, _, _ in sentences(rows)]
    plain = "\n".join(strip_inline(t) for _, k, t in rows if k in ("body", "list", "heading", "table", "quote"))
    paras = 0
    prev = "blank"
    for _, k, _ in rows:
        if k != "blank" and prev == "blank":
            paras += 1
        prev = k
    lists = sum(1 for _, k, _ in rows if k == "list")
    heads = sum(1 for _, k, _ in rows if k == "heading")
    return sents, plain, {"文": len(sents), "段落": paras, "箇条書きの行": lists, "見出し": heads}


def short(s, n=44):
    s = s.strip()
    return s if len(s) <= n else s[:n] + "…"


def main(argv):
    if len(argv) != 2 or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0 if argv and argv[0] in ("-h", "--help") else 2
    try:
        o_sents, o_plain, o_shape = load(argv[0])
        r_sents, r_plain, r_shape = load(argv[1])
    except OSError as e:
        print(f"読めない: {e.filename} ({e.strerror})", file=sys.stderr)
        return 2
    out = []

    # 1. 文末の種類が変わった文。直した文ごとに、いちばん似ている元の文と組にする
    changed = []
    for r in r_sents:
        best, score = None, 0.0
        for o in o_sents:
            sc = difflib.SequenceMatcher(None, o, r, autojunk=False).ratio()
            if sc > score:
                best, score = o, sc
        if best is not None and score >= 0.4:
            ko, kr = ending_kind(best), ending_kind(r)
            if ko and kr and ko != kr:
                changed.append(f"- {ko} → {kr}: 「{short(r)}」（元: 「{short(best)}」）")
    if changed:
        out.append("■ 文末の種類が変わった文（文の働きが変わっていないか、文書の立場に合う向きか）")
        out += changed

    # 2. 言い回しの種類の増減
    lines = []
    for name, pat in MARKERS:
        a = [m.group(0) for m in re.finditer(pat, o_plain)]
        b = [m.group(0) for m in re.finditer(pat, r_plain)]
        if len(a) != len(b):
            lines.append(f"- {name}: {len(a)} → {len(b)}（元: {'、'.join(a) or 'なし'} / 後: {'、'.join(b) or 'なし'}）")
    if lines:
        out.append("■ 言い回しの種類の増減（増えたら足した、減ったら消した。言い切りの強さと比重が動いていないか）")
        out += lines

    # 3. 増えた語・消えた語。数は別に出す
    o_num = NUMBER.findall(o_plain)
    r_num = NUMBER.findall(r_plain)
    new_num = sorted({n for n in r_num if n not in o_num})
    lost_num = sorted({n for n in o_num if n not in r_num})
    if new_num or lost_num:
        out.append("■ 数の変化（元に無い数は足してはいけない。消えた数は条件か範囲が落ちていないか）")
        if new_num:
            out.append("- 増えた: " + "、".join(new_num))
        if lost_num:
            out.append("- 消えた: " + "、".join(lost_num))
    r_tok = sorted({t for t in TOKEN.findall(r_plain) if t not in o_plain})
    o_tok = sorted({t for t in TOKEN.findall(o_plain) if t not in r_plain})
    if r_tok:
        out.append("■ 元に無い語（元に無い主体・条件・例を足していないか。言い換えなら残してよい）")
        out.append("- " + "、".join(r_tok))
    if o_tok:
        out.append("■ 消えた語（前提・条件・固有名が落ちていないか）")
        out.append("- " + "、".join(o_tok))

    # 4. 形の変化
    diffs = [f"{k} {o_shape[k]} → {r_shape[k]}" for k in o_shape if o_shape[k] != r_shape[k]]
    if diffs:
        out.append("■ 形の変化: " + "、".join(diffs))
        if o_shape["箇条書きの行"] and not r_shape["箇条書きの行"]:
            out.append("- 箇条書きを地の文にした。各項に元に無い評価や義務を足していないか")
        if r_shape["段落"] < o_shape["段落"]:
            out.append("- 段落をまとめた。まとめた段落の話題が1つか")

    print("\n".join(out) if out else "変化の候補なし")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

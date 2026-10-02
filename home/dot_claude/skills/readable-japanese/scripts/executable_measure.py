#!/usr/bin/env python3
"""文書の形を数で測り、読み手が詰まりやすい箇所を行番号つきで出す。

  measure.py [--stats] FILE...

  文の長さ・読点・太字・箇条書きの比率・文末の種類を数え、目安を外れた箇所と、
  形で拾える型（文末のコロン、和欧文の空白の不揃い、予告だけの文など）を出す。
  拾えるのは形だけで、直すかどうかは人が決める。
  --stats は数の要約だけを出す。指摘が1件以上あれば終了コード 1、無ければ 0。
"""
import re
import sys

# 目安。どれも「これを超えたら読み直す」の値で、超えたら誤りという値ではない。
LONG_SENTENCE = 90      # 1文の字数。これを超える文は、命題が2つ入っていないかを見る
MANY_COMMAS = 4         # 1文の読点。これ以上あると、どこで区切って読むかを読み手が探す
BOLD_PER_1000 = 4.0     # 本文1000字あたりの太字。超えると強調が強調でなくなる
LIST_RATIO = 0.5        # 本文の行に占める箇条書きの行。超えると論の筋が切れていないかを見る
MIN_CHARS_FOR_RATIO = 400  # これより短い文書では比率を見ない（数行の PR 説明などで振れるため）

JP = r"[\u3040-\u30ff\u3400-\u9fff\uff66-\uff9f々〆ー]"  # かな・漢字・半角カナ
LATIN = r"[A-Za-z]"  # 数字は数えない。「9月28日 20:05」のように日付と時刻のあいだは空けるのがふつうなため

CONNECTIVES = ("また", "さらに", "そして", "しかし", "ただし", "一方", "つまり", "そのため",
               "したがって", "なお", "加えて", "そこで", "だから", "それでも", "ところが")
# 段落の頭で前を指す代名詞。「この資料」のように名詞が続くものは、指す先を名前で書いているので数えない
DEMONSTRATIVE = re.compile(r"^(これ|それ|上記|前述)(は|が|を|に|で|も|ら|により|によって|の)")
PREVIEW = [
    # 中身を言わずに、中身があることだけを告げる文（「押さえる点は3つある」「次のとおりである」）
    re.compile(r"(は|が)、?(主に|大きく)?(次の|以下の)?([0-9０-９]+|[一二三四五六七八九十]+)(つ|点|個)"
               r"(の[一-龥ァ-ヴー]{1,8})?(が)?(ある|あります|です|だ|である)。?$"),
    re.compile(r"(次|以下)の(とおり|通り|ような|ように)(だ|です|である|なります|なる)?。?$"),
    re.compile(r"^.{0,24}(点|ポイント|こと)が(ある|あります)。?$"),
]
RESTATE_PAREN = re.compile(r"[（(](いわゆる|つまり|すなわち|要するに|言い換えると|＝|=)")
ACRONYM_DEF = re.compile(r"[（(]([A-Z][A-Z0-9]{1,9})[）)]")
LIST_MARK = r"^([-*+]\s+|・\s*|\d+[.)]\s+)"
LABELED_ITEM = re.compile(r"^\*\*[^*]+\*\*\s*[:：]|^[^。、]{1,15}\*\*\s*[:：]")
TRAILING_COLON = re.compile(r"[：:]\s*$")


def width(s):
    """字数。空白を数えない。"""
    return len(re.sub(r"\s", "", s))


def strip_inline(s):
    """インラインのコード・リンク・太字の印を外した本文を返す。コードは「〓」1字に置き換える。"""
    s = re.sub(r"`[^`]*`", "〓", s)
    s = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    s = re.sub(r"https?://\S+", "〓", s)
    s = s.replace("**", "").replace("__", "")
    return s


def classify(lines):
    """各行を (行番号, 種類, 本文) にする。種類は body・list・heading・table・quote。"""
    out = []
    in_code = False
    start = 0
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                start = i + 1
                break
    for i in range(start, len(lines)):
        raw = lines[i].rstrip("\n")
        st = raw.strip()
        if st.startswith("```") or st.startswith("~~~"):
            in_code = not in_code
            continue
        # 字下げしたコード。字下げした箇条書きの項は本文として読む
        if in_code or ((raw.startswith("    ") or raw.startswith("\t")) and not re.match(LIST_MARK, st)):
            continue
        if not st:
            out.append((i + 1, "blank", ""))
            continue
        if st.startswith("<!--") or st.startswith("<"):
            continue
        if st.startswith("#"):
            out.append((i + 1, "heading", re.sub(r"^#+\s*", "", st)))
        elif st.startswith("|"):
            out.append((i + 1, "table", st))
        elif st.startswith(">"):
            out.append((i + 1, "quote", st.lstrip("> ")))
        elif re.match(LIST_MARK, st) and not re.match(r"^[-*_]{3,}$", st):
            out.append((i + 1, "list", re.sub(LIST_MARK, "", st)))
        elif re.match(r"^[-*_]{3,}$", st):
            continue
        else:
            out.append((i + 1, "body", st))
    return out


def sentences(rows):
    """本文と箇条書きを文に切る。(行番号, 文, 段落の頭か, 種類) を返す。"""
    out = []
    prev_kind = None      # 直前の空行でない行の種類
    blank_before = False  # 直前に空行があったか
    seen_body = False     # 前に段落があったか
    for ln, kind, text in rows:
        if kind == "blank":
            blank_before = True
            continue
        if kind in ("body", "list"):
            plain = strip_inline(text)
            parts = [p for p in re.split(r"(?<=[。！？])|(?<=[!?])\s", plain) if p.strip()]
            # 段落の頭で、指す先が別の段落か見出しの向こうにあるもの。直前が箇条書きなら同じ画面にある
            far = kind == "body" and seen_body and (prev_kind == "heading" or (prev_kind == "body" and blank_before))
            for n, p in enumerate(parts):
                out.append((ln, p.strip(), far and n == 0, kind))
            if kind == "body":
                seen_body = True
        prev_kind = kind
        blank_before = False
    return out


def ending(s):
    """文末の種類。敬体・常体・体言止めほか・会話（」で閉じる）を返す。"""
    t = re.sub(r"[。．！？!?\s]+$", "", s)
    t = re.sub(r"[（(][^（）()]*[）)]$", "", t).strip()
    if not t or t.endswith(("」", "』", "〓")):
        return "その他"
    if re.search(r"(です|ます|ません|ました|でした|ましょう|ください|でしょう|ませんか)$", t):
        return "敬体"
    if re.search(r"(だ|である|ではない|でない|だった|であった|だろう|ない|た)$", t):
        return "常体"
    if re.search(r"[うくすつぬふむゆるぐずづぶぷい]$", t):
        return "常体"
    return "体言止めほか"


def check_spacing(rows):
    """和欧文の境目の空白。空ける境目と空けない境目の数と、少ない側の行を返す。"""
    spaced, tight = [], []
    punct_space = []
    for ln, kind, text in rows:
        if kind in ("table",):
            continue
        s = strip_inline(text)
        for m in re.finditer(rf"(?:{JP} {LATIN})|(?:{LATIN} {JP})", s):
            spaced.append(ln)
        for m in re.finditer(rf"(?:{JP}{LATIN})|(?:{LATIN}{JP})", s):
            tight.append(ln)
        if re.search(rf"[、。「（] +{LATIN}|{LATIN} +[、。」）]", s):
            punct_space.append(ln)
    return spaced, tight, punct_space


def analyze(path):
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    rows = classify(lines)
    sents = sentences(rows)
    findings = []

    body_rows = [r for r in rows if r[1] in ("body", "list")]
    rows = [r for r in rows if r[1] != "blank"]
    body_chars = sum(width(strip_inline(t)) for _, _, t in body_rows)
    list_lines = sum(1 for r in body_rows if r[1] == "list")
    bold = sum(len(re.findall(r"\*\*[^*]+\*\*", t)) for _, _, t in body_rows)

    # 文の長さと読点はカッコの中を数えない。読み手はカッコを飛ばして文の骨を読めるため
    lens = [width(re.sub(r"[（(][^（）()]*[）)]", "", s)) for _, s, _, _ in sents]
    commas = [len(re.findall(r"[、，]", re.sub(r"[（(][^（）()]*[）)]", "", s))) for _, s, _, _ in sents]

    # 1文の長さと読点
    for (ln, s, _, _), n, c in zip(sents, lens, commas):
        if n > LONG_SENTENCE:
            findings.append((ln, "長い文", f"{n}字", s, "命題が2つあれば切る。切るなら前後の関係を後ろの文の頭の接続語で残す"))
        elif c >= MANY_COMMAS:
            findings.append((ln, "読点が多い", f"読点{c}", s, "並列なら箇条書きか「AとBとC」に、従属が重なっているなら文を分ける"))

    # 文末の種類（文として閉じたものだけ。箇条書きの断片は数えない）
    kinds = {}
    closed = [(ln, s) for ln, s, _, _ in sents if s.endswith("。")]
    for ln, s in closed:
        kinds.setdefault(ending(s), []).append((ln, s))
    kei, jo = kinds.get("敬体", []), kinds.get("常体", [])
    if kei and jo:
        minority, name = (kei, "敬体") if len(kei) < len(jo) else (jo, "常体")
        if len(minority) * 4 <= len(kei) + len(jo):
            for ln, s in minority:
                findings.append((ln, "文末の不揃い", name, s, "地の文の敬体と常体をそろえる。文書の立場（勧め・決まり・説明）に合う形にする"))

    # 段落の頭の指示語・予告だけの文
    for ln, s, head, kind in sents:
        if head and DEMONSTRATIVE.match(s):
            findings.append((ln, "段落の頭の指示語", "", s, "指す先が前の段落か見出しの向こうにある。名前で書く"))
        if kind == "body" and any(p.search(s) for p in PREVIEW):
            findings.append((ln, "予告だけの文", "", s, "中身の文に重みを移して1文にする。まとめると意味が変わるなら残す"))

    # 文頭のつなぎ語の連打（3文続けて文頭がつなぎ語）
    run = 0
    for ln, s, _, _ in sents:
        if s.startswith(CONNECTIVES):
            run += 1
            if run == 3:
                findings.append((ln, "つなぎ語の連打", "", s, "3文続けて文頭がつなぎ語。それぞれ何と何をつないでいるかを確かめ、要らないものを外す"))
        else:
            run = 0

    # ラベルと説明に分けた箇条書き（「**速度**: 〜」）
    for ln, kind, text in rows:
        if kind == "list" and LABELED_ITEM.search(text):
            findings.append((ln, "ラベルつきの項", "", text, "太字のラベルとコロンで分けず、主語と述語のある1文にする"))

    # 文末のコロン
    for ln, kind, text in rows:
        if kind in ("body", "list", "heading") and TRAILING_COLON.search(strip_inline(text)):
            findings.append((ln, "文末のコロン", "", text, "句点で閉じるか、前置きを消して中身から書く"))

    # 言い換えだけのカッコ・略語の定義の繰り返し
    seen = {}
    for ln, kind, text in rows:
        if kind not in ("body", "list", "heading"):
            continue
        s = strip_inline(text)
        if RESTATE_PAREN.search(s):
            findings.append((ln, "言い換えのカッコ", "", text, "情報が増えないカッコは外す。要るなら地の文に入れる"))
        for m in ACRONYM_DEF.finditer(s):
            a = m.group(1)
            if a in seen:
                findings.append((ln, "略語の再定義", a, text, f"L{seen[a]} で定義済み。2回目からは略語だけで書く"))
            else:
                seen[a] = ln

    # 和欧文の空白
    spaced, tight, punct_space = check_spacing(rows)
    for ln in sorted(set(punct_space)):
        findings.append((ln, "句読点の横の空白", "", lines[ln - 1].strip(), "句読点・括弧と英字のあいだは空けない"))
    total = len(spaced) + len(tight)
    if spaced and tight and total >= 6:
        minority, name = (spaced, "空ける") if len(spaced) < len(tight) else (tight, "空けない")
        if len(minority) * 4 <= total:
            for ln in sorted(set(minority)):
                findings.append((ln, "和欧文の空白の不揃い", name, lines[ln - 1].strip(),
                                 f"文書の多数は{'空けない' if name == '空ける' else '空ける'}側。どちらかにそろえる"))

    # 文書全体の比率
    if body_chars >= MIN_CHARS_FOR_RATIO:
        bpk = bold / body_chars * 1000
        if bpk > BOLD_PER_1000:
            findings.append((1, "太字が多い", f"1000字あたり{bpk:.1f}", "", "誤読を防ぐ否定と判断が要る点だけを残す"))
        ratio = list_lines / len(body_rows) if body_rows else 0
        if ratio > LIST_RATIO:
            findings.append((1, "箇条書きが多い", f"{ratio:.0%}", "", "理由や因果でつながる項は地の文に戻す。並列の項だけを箇条書きにする"))

    stats = {
        "文": len(sents),
        "平均の文長": round(sum(lens) / len(lens), 1) if lens else 0,
        "1文の読点": round(sum(commas) / len(commas), 2) if commas else 0,
        "本文の字数": body_chars,
        "太字/1000字": round(bold / body_chars * 1000, 1) if body_chars else 0,
        "箇条書きの行": f"{list_lines}/{len(body_rows)}",
        "文末": {k: len(v) for k, v in kinds.items()},
        "和欧文の空白": f"空ける{len(spaced)}・空けない{len(tight)}",
    }
    return stats, sorted(findings, key=lambda x: x[0])


def short(s, n=40):
    s = s.strip()
    return s if len(s) <= n else s[:n] + "…"


def main(argv):
    args = [a for a in argv if not a.startswith("-")]
    if not args or "-h" in argv or "--help" in argv:
        print(__doc__.strip())
        return 0 if args or "-h" in argv or "--help" in argv else 2
    stats_only = "--stats" in argv
    any_finding = False
    for path in args:
        try:
            stats, findings = analyze(path)
        except OSError as e:
            print(f"{path}: 読めない ({e.strerror})", file=sys.stderr)
            continue
        if not stats_only:
            for ln, kind, val, s, hint in findings:
                extra = f"（{val}）" if val else ""
                body = f" 「{short(s)}」" if s else ""
                print(f"{path}:{ln}: [{kind}{extra}]{body} → {hint}")
        endings = "・".join(f"{k}{v}" for k, v in stats["文末"].items())
        print(f"{path}: 文{stats['文']} 平均{stats['平均の文長']}字 読点{stats['1文の読点']}/文 "
              f"太字{stats['太字/1000字']}/1000字 箇条書き{stats['箇条書きの行']}行 "
              f"文末[{endings}] 和欧文[{stats['和欧文の空白']}] 指摘{len(findings)}")
        any_finding = any_finding or bool(findings)
    return 1 if any_finding else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

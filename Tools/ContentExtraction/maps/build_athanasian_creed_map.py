"""Generates maps/athanasian_creed.json.

The Creed of St Athanasius (Quicunque vult) occupies extraction pages 24-25.
Page 24 carries two book pages whose lines the extractor interleaved, and it
also split many words across physical lines ("Almig" / "hty"). The left book
page holds the rubric, the title and verses 1-8; the right book page holds
verses 9-22. Page 25 (verses 23-40 and the Gloria) is in reading order.

This script reads the normalized source, cuts page 24 at the start of each
verse (named below by exact source text, in extraction order) and emits the
fragments in reading order. Whether two fragments join with or without a
space is taken from the whitespace in the source line, never guessed. Every
unit built this way is marked for review against the PDF page images.

Run: python3 maps/build_athanasian_creed_map.py
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

from lux_extract.__main__ import _source  # noqa: E402
from lux_extract import decisions as dec  # noqa: E402
from lux_extract.normalize import normalize  # noqa: E402

FIRST, LAST = 1462, 1607  # page 24 text lines
HEADS = [1461, 1609, 1652]  # running heads ("St. ATHANASIUS's Creed.")

# (label, raw line, exact text that opens the piece, optional text it follows)
MARKERS = [
    ("v9", 1462, "The Father incomprehen", None),
    ("rubric", 1471, "¶ Upon", None),
    ("v10", 1495, "The Father etern", None),
    ("v11", 1499, "And yet there are not three etern", None),
    ("v12", 1501, "As alſo there are not three", None),
    ("title", 1511, "Quicunque vult.", None),
    ("v1", 1512, "WHOSOEVER", None),
    ("v13", 1515, "So likewiſe the Father is Almig", None),
    ("v2", 1520, "Which F", None),
    ("v14", 1531, "And yet there are not three Almig", None),
    ("v15", 1534, "So the Father is God", None),
    ("v3", 1538, "And the Catholick F", None),
    ("v16", 1543, "And y", None),
    ("v4", 1546, "Neither confounding", None),
    ("v17", 1549, "So likewiſe the F", None),
    ("v5", 1553, "For t", None),
    ("v18", 1563, "And yet not three Lords", None),
    ("v19", 1563, "For like as we ar", None),
    ("v6", 1576, "But the Godhead", None),
    ("v20", 1583, "S", "co-eternal. "),
    ("v7", 1589, "Such as the F", None),
    ("v21", 1591, "The Father is made of none", None),
    ("v8", 1594, "The Father u", None),
    ("v22", 1603, "The S", None),
]

# Spaces the extractor inserted inside words on page 24, and word spaces lost
# where a line ended a word without a trailing space. Each is recorded in the
# unit's provenance.
RUBRIC_REPLACE = [["day,ſhall", "day, ſhall"], ["thisConfeſſion", "this Confeſſion"], ["St.Athanaſius", "St. Athanaſius"]]
CREED_REPLACE = [["Sub stance", "Substance"], ["Per ſon", "Perſon"], ["Gho st", "Ghost"], ["Son,and", "Son, and"],
                 ["Gloryequal", "Glory equal"], ["Christianverity", "Christian verity"], ["himſelfto", "himſelf to"],
                 ["created,nor", "created, nor"]]


def main() -> None:
    source, _ = _source()
    text = normalize(source, dec.decisions(dec.load_table(dec.LIGATURES_PATH)),
                     dec.decisions(dec.load_table(dec.JOINS_PATH)),
                     json.loads((HERE.parent / "data" / "spaces.json").read_text(encoding="utf-8"))["edits"])
    by_raw = {l.raw_start: l for l in text.lines}
    page24 = [r for r in sorted(by_raw) if FIRST <= r <= LAST and r not in HEADS]

    # Cut points as (index into page24, column in the line).
    cuts = []
    for label, raw, opening, after in MARKERS:
        line = by_raw[raw].text
        base = line.find(after) + len(after) if after else 0
        col = line.find(opening, base)
        assert col >= 0, (label, raw, opening)
        cuts.append((page24.index(raw), col, label))
    assert cuts == sorted(cuts), "markers are not in extraction order"

    pieces: dict[str, list[tuple[int, str]]] = {}  # label -> [(raw, unstripped text)]
    for k, (li, col, label) in enumerate(cuts):
        end_li, end_col = (cuts[k + 1][0], cuts[k + 1][1]) if k + 1 < len(cuts) else (len(page24) - 1, None)
        out = []
        for j in range(li, end_li + 1):
            raw = page24[j]
            line = by_raw[raw].text
            a = col if j == li else 0
            b = end_col if (j == end_li and end_col is not None) else len(line)
            if b <= a:
                continue
            out.append((raw, line[a:b], a))
        pieces[label] = out

    def fragments(label: str) -> list[dict]:
        frags = []
        pending_space = False
        for raw, piece, col in pieces[label]:
            body = piece.strip()
            if not body:
                pending_space = pending_space or bool(piece)
                continue
            line = by_raw[raw].text
            start = col + (len(piece) - len(piece.lstrip()))
            assert line.find(body) == start, (label, raw, body)  # first occurrence is the one meant
            f = {"raw": raw, "from": body, "to": body}
            if frags:
                f["join"] = " " if (pending_space or piece[:1].isspace()) else ""
            frags.append(f)
            pending_space = piece[-1:].isspace()
        return frags

    units = [
        {"id": "ath.rubric", "kind": "rubric", "fragments": fragments("rubric"), "replace": RUBRIC_REPLACE},
        {"id": "ath.title", "kind": "heading", "latin": "Quicunque vult.", "fragments": fragments("title")},
    ]
    creed = []
    for n in range(1, 23):
        frags = fragments(f"v{n}")
        if creed:
            frags[0]["join"] = "\n "
        creed += frags
    # Page 25: verses open on a line beginning with a space, or after a
    # double space inside a line.
    prev_space = True
    for raw in sorted(by_raw):
        if not (1610 <= raw <= 1700) or raw in HEADS:
            continue
        line = by_raw[raw].text
        parts = line.split("  ")
        first_part = True
        for p, part in enumerate(parts):
            body = part.strip()
            if not body:
                continue
            assert line.find(body) == line.index(part) + (len(part) - len(part.lstrip())), (raw, body)
            new_verse = p > 0 or (first_part and line[:1].isspace())
            f = {"raw": raw, "from": body, "to": body, "join": "\n " if new_verse else (" " if prev_space else "")}
            creed.append(f)
            first_part = False
            prev_space = part[-1:].isspace()
    units.append({"id": "ath.creed", "kind": "canticle", "role": "all", "fragments": creed,
                  "replace": CREED_REPLACE})

    spec = {
        "schemaVersion": 1,
        "id": "athanasian-creed",
        "title": "Quicunque vult, commonly called the Creed of Saint Athanasius",
        "section": {"start": "St. ATHANASIUS’s Creed. St. ATHANASIUS’s Creed.", "end": "world without end. Amen."},
        "ignore": [{"raw": r, "text": by_raw[r].text.strip()} for r in HEADS],
        "units": units,
    }
    (HERE / "athanasian_creed.json").write_text(json.dumps(spec, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()

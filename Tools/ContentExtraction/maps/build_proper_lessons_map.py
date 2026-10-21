"""Generate maps/proper_lessons.json from the TCP cells of the 1693 tables.

Run by hand from Tools/ContentExtraction when the map changes:

    python3 maps/build_proper_lessons_map.py

The tables are printed as rows of [label] [Mattins] [Evensong]; days with
second lessons have a "1 Leſſon" row and a "2 Leſſon" row under the label.
The specification below names, row by row, the observance each label
belongs to and the label as printed. The generator walks the cell stream,
checks every label against it, and records the XML line and exact text of
every lesson cell. The build re-checks each one against the witness.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

from lux_extract.__main__ import TRADITION  # noqa: E402
from lux_extract.tcp import load_divisions  # noqa: E402

# Rows: ("head", text) is a heading row of the table (label and two cells,
# empty or column titles); (label, observance) is a row of first lessons;
# (label, observance, "both") is a label row followed by "1 Leſſon" and
# "2 Leſſon" rows; (label, observance, "split") is a label row whose
# Mattins cell is printed in the label's cell (the TCP merges them).
SUNDAYS = [
    ("head3", "Sundays of Advent."),
    ("The firſt", "advent-1"), ("2", "advent-2"), ("3", "advent-3"), ("4", "advent-4"),
    ("head3", "Sundays after Chriſtmas."),
    ("The firſt", "christmas-1"), ("2", "christmas-2"),
    ("head3", "Sundays after the Epiphany."),
    ("The firſt", "epiphany-1"), ("2", "epiphany-2"), ("3", "epiphany-3"), ("4", "epiphany-4"),
    ("5", "epiphany-5"), ("6", "epiphany-6"),
    ("Septuageſima.", "septuagesima"), ("Sexageſima.", "sexagesima"),
    # The label cell joins "Quinquageſima" with the next heading, "Lent".
    ("Quinquageſima Lent.", "quinquagesima"),
    ("Firſt Sunday", "lent-1"), ("2", "lent-2"), ("3", "lent-3"), ("4", "lent-4"),
    ("5", "lent-5", "padded"),
    ("6", "palm-sunday", "both-inline"),
    ("Eaſter-day.", "easter", "both"),
    ("head3", "Sundays after Eaſter."),
    ("The firſt", "easter-1"), ("2", "easter-2"), ("3", "easter-3"), ("4", "easter-4"), ("5", "easter-5"),
    ("Sunday after Aſcenſion-day.", "ascension-sunday"),
    ("Whitſunday.", "whitsunday", "both"),
    ("Trinity Sunday.", "trinity", "both"),
    ("head3", "Sundays after Trinity."),
    ("The firſt", "trinity-1"), ("2", "trinity-2"), ("3", "trinity-3"), ("4", "trinity-4"), ("5", "trinity-5"),
    ("6", "trinity-6"), ("7", "trinity-7"), ("8", "trinity-8"), ("9", "trinity-9"), ("10", "trinity-10"),
    ("11", "trinity-11"), ("12", "trinity-12"), ("13", "trinity-13"), ("14", "trinity-14"), ("15", "trinity-15"),
    ("head3", "Sund. after Trin."),
    ("16", "trinity-16"), ("17", "trinity-17"), ("18", "trinity-18"), ("19", "trinity-19"), ("20", "trinity-20"),
    ("21", "trinity-21"), ("22", "trinity-22", "split"), ("23", "trinity-23"), ("24", "trinity-24"),
    ("25", "trinity-25"), ("26", "trinity-26"),
]

HOLY_DAYS = [
    ("head3", ""),
    ("S. Andrew", "andrew"), ("S. Thomas the Apoſtle.", "thomas"),
    ("Nativity of CHRIST.", "christmas", "both"), ("S. Stephen.", "stephen", "both"),
    ("S. John.", "john-evangelist", "both"), ("Innocents day.", "innocents"),
    ("Circumciſion.", "circumcision", "both"), ("Epiphany.", "epiphany", "both"),
    ("Converſion of St. Paul.", "conversion-of-paul", "both"),
    ("Purification of the Virgin Mary.", "purification"), ("S. Matthias.", "matthias"),
    ("Annunciation of our Lady.", "annunciation"),
    ("Wedneſday before Eaſter.", "wednesday-before-easter", "both"),
    ("Thurſday before Eaſter.", "thursday-before-easter", "both"),
    ("Good Friday.", "good-friday", "both"), ("Eaſter Even.", "easter-even", "both"),
    ("Munday in Eaſter week.", "easter-monday", "both"), ("Tueſday in Eaſter week.", "easter-tuesday", "both"),
    ("S. Mark.", "mark"),
    # The label row of St Philip and St James carries the column titles again.
    ("S. Philip and S. Jacob.", "philip-and-james", "both"),
    ("Aſcenſion-day.", "ascension", "both"),
    ("Munday in Whitſun-week.", "whit-monday", "both"), ("Tueſday in Whitſun week.", "whit-tuesday", "both"),
    ("S. Barnabas.", "barnabas", "both"), ("S. John Baptiſt.", "john-baptist", "both"),
    ("S. Peter.", "peter", "both"), ("S. James.", "james"), ("S. Bartholomew.", "bartholomew"),
    ("S. Matthew.", "matthew"), ("S. Michael.", "michael", "both"), ("S. Luke.", "luke"),
    ("S. Simon and S. Jude.", "simon-and-jude"), ("All Saints.", "all-saints", "both"),
]

PSALM_DAYS = [
    ("¶ Chriſtmas-day.", "christmas"), ("¶ Aſhwedneſday.", "ash-wednesday"), ("¶ Good Friday.", "good-friday"),
    ("¶ Eaſterday.", "easter"), ("¶ Aſcenſion day.", "ascension"), ("¶ Whitſunday.", "whitsunday"),
]

COLUMN_TITLES = {"¶ Mattins.", "¶ Evenſong."}


def cell_ref(cell, read=None):
    entry = {"line": cell.line, "text": cell.text}
    if read is not None:
        entry["read"] = read
    return entry


def walk(cells, spec, table):
    out = []
    i = 0

    def take(expected=None):
        nonlocal i
        cell = cells[i]
        if expected is not None and cell.text != expected:
            raise SystemExit(f"{table}: expected {expected!r} at line {cell.line}, found {cell.text!r}")
        i += 1
        return cell

    def lessons(row, label=None):
        morning, evening = take(), take()
        row["morning"][label or "first"] = cell_ref(morning) if morning.text else None
        row["evening"][label or "first"] = cell_ref(evening) if evening.text else None

    for item in spec:
        if item[0] == "head3":
            take(item[1] or None)
            for _ in range(2):
                c = take()
                if c.text and c.text not in COLUMN_TITLES:
                    raise SystemExit(f"{table}: unexpected heading cell {c.text!r} at line {c.line}")
            continue
        label, observance = item[0], item[1]
        mode = item[2] if len(item) > 2 else "first"
        row = {"observance": observance, "label": None, "morning": {}, "evening": {}}
        lab = take(None if mode == "split" else label)
        row["label"] = {"line": lab.line, "text": lab.text}
        if mode == "first":
            lessons(row)
        elif mode == "padded":
            # Each lesson cell is followed by an empty cell in the same row.
            m = take()
            take("")
            e = take()
            take("")
            row["morning"]["first"], row["evening"]["first"] = cell_ref(m), cell_ref(e)
        elif mode == "split":
            text = lab.text
            assert text.startswith(label + " "), text
            row["label"] = {"line": lab.line, "text": text, "labelPart": label}
            row["morning"]["first"] = cell_ref(lab, read=text[len(label) + 1:])
            e = take()
            row["evening"]["first"] = cell_ref(e)
        elif mode in ("both", "both-inline"):
            if mode == "both":
                for _ in range(2):
                    c = take()
                    if c.text and c.text not in COLUMN_TITLES:
                        raise SystemExit(f"{table}: unexpected cell {c.text!r} at line {c.line}")
            take("1 Leſſon")
            lessons(row, "first")
            c = take()
            if c.text not in ("2 Leſſon", "2 Leſſon."):
                raise SystemExit(f"{table}: expected the second-lesson row at line {c.line}, found {c.text!r}")
            lessons(row, "second")
        out.append(row)
    if i != len(cells):
        raise SystemExit(f"{table}: {len(cells) - i} cells left over, from line {cells[i].line}")
    return out


def main():
    meta = json.loads((TRADITION / "Witness" / "sources.json").read_text(encoding="utf-8"))
    tcp = next(s for s in meta["sources"] if s["id"] == "bcp1662-london1693-tcp")
    div = load_divisions(TRADITION / "Witness" / tcp["file"], tcp["sha256"], {"order_of_lessons"})["order_of_lessons"]
    sundays, holy, psalms = div.tables
    psalm_rows = []
    cells = psalms.cells
    if [c.text for c in cells[:3]] != ["", "¶ Mattins.", "¶ Evenſong."]:
        raise SystemExit("Proper Psalms: column titles not found")
    i = 3
    for label, observance in PSALM_DAYS:
        lab, m, e = cells[i:i + 3]
        if lab.text != label:
            raise SystemExit(f"Proper Psalms: expected {label!r}, found {lab.text!r}")
        psalm_rows.append({"observance": observance, "label": {"line": lab.line, "text": lab.text},
                           "morning": cell_ref(m), "evening": cell_ref(e)})
        i += 3
    out = {
        "_comment": "Generated by maps/build_proper_lessons_map.py from the TCP transcription of the 1693 printing. "
                    "Each entry locates one printed cell by its XML line and exact text; Lux's observance "
                    "identifiers are the only things added. Do not edit by hand.",
        "source": tcp["id"],
        "sundays": {"head": {"line": sundays.line, "text": sundays.head}, "rows": walk(sundays.cells, SUNDAYS, "Sundays")},
        "holyDays": {"head": {"line": holy.line, "text": holy.head}, "rows": walk(holy.cells, HOLY_DAYS, "Holidays")},
        "properPsalms": {"head": {"line": psalms.line, "text": psalms.head}, "rows": psalm_rows},
    }
    path = HERE / "proper_lessons.json"
    path.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {path.name}: {len(out['sundays']['rows'])} Sundays, {len(out['holyDays']['rows'])} holy days, "
          f"{len(psalm_rows)} days with proper psalms")


if __name__ == "__main__":
    main()

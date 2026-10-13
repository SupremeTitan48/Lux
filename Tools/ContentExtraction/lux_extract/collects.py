"""The Collects of the Christian year (extraction pages 36-143).

Each observance is printed as a title, "The Collect." (Good Friday: "The
Collects."), the collect, any rubric governing its use, then the Epistle and
the Gospel. This stage extracts the collects and their governing rubrics. The
Epistles and Gospels are located (their headings and references are recorded)
but their text is left for a later stage.

The catalogue ``maps/collects.json`` names each observance and the raw line of
its collect heading; the text always comes from the source.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from .normalize import Line
from .text import assign_dropcaps, collapse, restore_initial

_heading = re.compile(r"(?:^|\. )The Collects?\.\s*$")
_lesson_heading = re.compile(r"^(The Epi[sſ]tle|For the Epi[sſ]tle|The Go[sſ]pel)\b(.*)$")
_amen_end = re.compile(r"Amen\.\s*$")


class CollectError(Exception):
    pass


def _head_texts(lines: list[Line]) -> set[str]:
    return {l.text.strip() for l in lines if l.head}


def extract_notes(lines: list[Line], catalogue_path: Path) -> list[dict]:
    """General notes printed at the head of the section (the eve rule)."""
    catalogue = json.loads(catalogue_path.read_text(encoding="utf-8"))
    by_raw = {line.raw_start: line for line in lines}
    out = []
    for item in catalogue.get("notes", []):
        line = by_raw[item["raw"]]
        out.append({"id": item["id"], "text": collapse(line.text),
                    "provenance": {"rawLines": [line.raw_start, line.raw_end], "extractionPages": [line.page]}})
    return out


def extract_collects(lines: list[Line], catalogue_path: Path, dropcap_table: dict[str, dict]) -> tuple[list[dict], list[dict]]:
    catalogue = json.loads(catalogue_path.read_text(encoding="utf-8"))
    by_raw = {line.raw_start: i for i, line in enumerate(lines)}
    first = by_raw[catalogue["section"]["firstRaw"]]
    last = by_raw[catalogue["section"]["lastRaw"]]
    heads = _head_texts(lines)
    issues: list[dict] = []

    def is_head(i: int) -> bool:
        line = lines[i]
        return line.head or line.dropcaps or (line.text.strip() in heads)

    # Drop-capital sites: the first text line after a Collect, Epistle or
    # Gospel heading, after the end of each of several collects under one
    # heading, and the openings listed in the catalogue (Easter anthems).
    extra_sites = set(catalogue.get("extraDropcapSites", []))
    sites: list[int] = []
    expect = False
    multi = False
    for i in range(first, last + 1):
        if is_head(i):
            continue
        text = lines[i].text.strip()
        if _heading.search(text):
            expect, multi = True, text.endswith("Collects.")
            continue
        if _lesson_heading.match(text):
            expect, multi = True, False
            continue
        if lines[i].raw_start in extra_sites:
            sites.append(i)
            continue
        if expect:
            sites.append(i)
            expect = False
            if not multi:
                continue
        if multi and _amen_end.search(text):
            expect = True
        if text.startswith("¶") or text.startswith("The Epi"):
            multi = False
    letters, mismatches = assign_dropcaps(lines[: last + 2], [s for s in sites if s <= last])
    unpaired = {s for s in sites if s not in letters}
    for s in sorted(unpaired):
        entry = dropcap_table.get(str(lines[s].raw_start))
        if entry is not None:
            if not lines[s].text.strip().startswith(entry["opening"]):
                raise CollectError(f"dropcaps.json entry {lines[s].raw_start} expects {entry['opening']!r}")
            letters[s] = entry["letter"]
            issues.append({"kind": "dropcap-restored", "basis": entry["basis"], "letter": entry["letter"], "rawLine": lines[s].raw_start})

    observances = []
    for entry in catalogue["observances"]:
        h = by_raw.get(entry["heading"])
        if h is None or not _heading.search(lines[h].text):
            raise CollectError(f"{entry['id']}: raw line {entry['heading']} is not a collect heading")
        count = entry.get("collects", 1)
        body_lines: list[tuple[int, str]] = []
        rubrics: list[dict] = []
        i = h + 1
        while i <= last:
            if is_head(i):
                i += 1
                continue
            text = lines[i].text.strip()
            if _lesson_heading.match(text) or _heading.search(text):
                break
            if text.startswith("¶"):
                # A rubric governing the collect; it runs until the next
                # heading or a line that ends a sentence and is followed by a
                # heading.
                start = i
                rub = [text]
                i += 1
                while i <= last and not is_head(i) and not _lesson_heading.match(lines[i].text.strip()) \
                        and not lines[i].text.strip().startswith("¶") and not rub[-1].rstrip().endswith((".", ":")):
                    rub.append(lines[i].text.strip())
                    i += 1
                rubrics.append({"text": collapse(" ".join(rub))[1:].strip(),
                                "provenance": {"rawLines": [lines[start].raw_start, lines[i - 1].raw_end],
                                               "extractionPages": sorted({lines[k].page for k in range(start, i)})}})
                continue
            if rubrics:
                break  # text after a rubric belongs to the next observance title
            body_lines.append((i, lines[i].text))
            i += 1
        collects = _split(body_lines, count, letters, lines, entry["id"], issues)
        if entry.get("titleRaw"):
            a, b = entry["titleRaw"]
            title = collapse(" ".join(l.text for l in lines if a <= l.raw_start <= b and not l.head))
        else:
            title = re.sub(r"\s*The Collects?\.\s*$", "", lines[h].text.strip())
        obs = {"id": entry["id"], "title": title, "collects": collects}
        if rubrics:
            obs["rubrics"] = rubrics
        observances.append(obs)
    by_id = {o["id"]: o for o in observances}
    for item in catalogue.get("trailingRubrics", []):
        line = lines[by_raw[item["raw"]]]
        if not line.text.strip().startswith("¶"):
            raise CollectError(f"trailing rubric at raw {item['raw']} does not begin with a pilcrow")
        by_id[item["observance"]].setdefault("rubrics", []).append({
            "text": collapse(line.text)[1:].strip(),
            "position": "after-gospel",
            "provenance": {"rawLines": [line.raw_start, line.raw_end], "extractionPages": [line.page]},
        })
    for m in mismatches:
        issues.append({"kind": "dropcap-mismatch", **m.as_json()})
    unresolved = [lines[s].raw_start for s in unpaired if s not in letters]
    return observances, issues + [{"kind": "dropcap-unresolved", "rawLine": r} for r in unresolved]


def _split(body: list[tuple[int, str]], count: int, letters: dict[int, str], lines: list[Line], oid: str, issues: list[dict]) -> list[dict]:
    groups: list[list[tuple[int, str]]] = [[]]
    for index, text in body:
        groups[-1].append((index, text))
        if _amen_end.search(text) and len(groups) < count:
            groups.append([])
    groups = [g for g in groups if g]
    if len(groups) != count:
        raise CollectError(f"{oid}: expected {count} collect(s), found {len(groups)}")
    out = []
    for g in groups:
        first_index = g[0][0]
        text = collapse(" ".join(t for _, t in g))
        tail = re.search(r"Amen\.\s*(.+)$", text)
        if tail and re.fullmatch(r"[A-Z .,’'\-]{3,40}", tail.group(1)):
            # An unmarked running head ("E PIPHANY .") printed after the collect.
            issues.append({"kind": "running-head-removed", "observance": oid, "text": tail.group(1)})
            text = text[: tail.start(1)].rstrip()
        if first_index in letters:
            text = restore_initial(text, letters[first_index])
        else:
            issues.append({"kind": "dropcap-missing", "observance": oid, "rawLine": lines[first_index].raw_start})
        if not text.endswith("Amen."):
            issues.append({"kind": "collect-without-amen", "observance": oid, "rawLine": lines[first_index].raw_start})
        out.append({
            "text": text,
            "provenance": {
                "rawLines": [lines[g[0][0]].raw_start, lines[g[-1][0]].raw_end],
                "extractionPages": sorted({lines[i].page for i, _ in g}),
            },
        })
    return out

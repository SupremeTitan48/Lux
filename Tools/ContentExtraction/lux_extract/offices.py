"""Structured services (Morning Prayer, Evening Prayer) from editorial maps.

A service map (``maps/*.json``) is the editorial description of a service:
an ordered list of units, each naming its kind, its speaker, and the exact
source text where it begins and ends. The text itself always comes from the
normalized source; the map never supplies liturgical wording.

Coverage is enforced: between consecutive units only whitespace may remain,
so no source text is skipped without an explicit unit. Each drop capital a map
declares is checked against the page's orphan-letter line, in order.

Two ways to locate a unit's text:

* ``"start"``/``"end"``: a contiguous span, from the first occurrence of
  ``start`` after the previous unit to the end of the first ``end`` after it.
* ``"fragments"``: for pages whose two columns the extractor interleaved, an
  ordered list of exact strings, each of which must occur exactly once in the
  section. Fragment-built units are marked for review against the PDF.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

from .normalize import Line, dropcap_letters
from .text import collapse, restore_initial

SPEAKERS = {
    "Anſw.": "people",
    "Prieſt.": "priest",
    "Priest.": "priest",
    "Miniſter.": "minister",
    "Minister.": "minister",
}
_speaker = re.compile(r"(?:^|\n|(?<=\s))(Anſw\.|Prieſt\.|Priest\.|Miniſter\.|Minister\.)\s")
_verse_break = re.compile(r"\n (?=\S)|\s{2,}(?=\S)")
_gloria = ("Glory be to the Father",)
_gloria_2 = ("As it was in the beginning",)


class MapError(Exception):
    pass


@dataclass
class Stream:
    text: str
    offsets: list[tuple[int, Line]]  # (offset of line start, line)
    dropcaps: list[tuple[int, list[str]]]  # (offset, letters)

    def line_at(self, offset: int) -> Line:
        found = self.offsets[0][1]
        for off, line in self.offsets:
            if off <= offset:
                found = line
            else:
                break
        return found


def build_stream(lines: list[Line], first: int, last: int) -> Stream:
    parts: list[str] = []
    offsets: list[tuple[int, Line]] = []
    dropcaps: list[tuple[int, list[str]]] = []
    length = 0
    for line in lines[first: last + 1]:
        if line.head:
            continue
        if line.dropcaps:
            dropcaps.append((length, dropcap_letters(line)))
            continue
        offsets.append((length, line))
        text = line.text.rstrip() + "\n"
        parts.append(text)
        length += len(text)
    return Stream("".join(parts), offsets, dropcaps)


def find_section(lines: list[Line], start: str, end: str) -> tuple[int, int]:
    first = next(i for i, l in enumerate(lines) if l.text.strip().startswith(start))
    last = next(i for i in range(first, len(lines)) if end in lines[i].text)
    # The book page's orphan drop-capital line follows its last text line.
    while last + 1 < len(lines) and lines[last + 1].dropcaps:
        last += 1
    return first, last


def _provenance(stream: Stream, begin: int, finish: int, extra: dict | None = None) -> dict:
    lines = [line for off, line in stream.offsets if off < finish and off + len(line.text.rstrip()) + 1 > begin]
    if not lines:
        lines = [stream.line_at(begin)]
    prov = {
        "rawLines": [min(l.raw_start for l in lines), max(l.raw_end for l in lines)],
        "extractionPages": sorted({l.page for l in lines}),
    }
    if extra:
        prov.update(extra)
    return prov


def _verses(text: str) -> list[str]:
    return [v for v in (collapse(p) for p in _verse_break.split(text)) if v]


def _halves(verse: str) -> dict:
    if verse.count(":") == 1:
        a, b = verse.split(":")
        return {"first": a.strip(), "second": b.strip()}
    return {"text": verse}


def _versicles(text: str, initial: str) -> list[dict]:
    out = []
    pos = 0
    speaker = initial
    for m in _speaker.finditer(text):
        chunk = collapse(text[pos: m.start()])
        if chunk:
            out.append({"speaker": speaker, "text": chunk})
        speaker = SPEAKERS[m.group(1)]
        pos = m.end()
    chunk = collapse(text[pos:])
    if chunk:
        out.append({"speaker": speaker, "text": chunk})
    return out


def _strip_pilcrow(text: str) -> str:
    return re.sub(r"^¶\s*", "", text)


def build_unit(spec: dict, text: str, letter: str | None) -> dict:
    kind = spec["kind"]
    unit = {"id": spec["id"], "kind": kind}
    for key in ("title", "role", "citation", "latin", "reference"):
        if key in spec:
            unit[key] = spec[key]
    if kind in ("rubric", "heading", "colophon", "title"):
        body = _strip_pilcrow(collapse(text))
        if letter:
            body = restore_initial(body, letter)
        unit["text"] = body
    elif kind in ("prayer", "sentence", "exhortation", "creed", "blessing"):
        body = collapse(text)
        if letter:
            body = restore_initial(body, letter)
        if "citation" in spec:
            if not body.endswith(spec["citation"]):
                raise MapError(f"{spec['id']}: citation {spec['citation']!r} is not the end of {body[-60:]!r}")
            body = body[: -len(spec["citation"])].rstrip()
        unit["text"] = body
    elif kind == "lines":
        unit["lines"] = [collapse(l) for l in text.split("\n") if l.strip()]
    elif kind == "versicles":
        unit["lines"] = _versicles(text, spec.get("speaker", "minister"))
    elif kind == "canticle":
        verses = _verses(text)
        if letter:
            verses[0] = restore_initial(verses[0], letter)
        gloria = []
        while verses and (verses[-1].startswith(_gloria_2) or verses[-1].startswith(_gloria)):
            gloria.insert(0, verses.pop())
            if gloria[0].startswith(_gloria):
                break
        unit["verses"] = [_halves(v) for v in verses]
        if gloria:
            unit["gloria"] = [_halves(v) for v in gloria]
    else:
        raise MapError(f"{spec['id']}: unknown kind {kind}")
    return unit


def extract_service(lines: list[Line], map_path: Path) -> tuple[dict, list[dict]]:
    spec = json.loads(map_path.read_text(encoding="utf-8"))
    first, last = find_section(lines, spec["section"]["start"], spec["section"]["end"])
    stream = build_stream(lines, first, last)
    text = stream.text
    cursor = 0
    units: list[dict] = []
    issues: list[dict] = []
    declared: list[tuple[int, str, str]] = []  # (offset, letter, unit id)
    fragment_mode = False

    by_raw = {line.raw_start: line for _, line in stream.offsets}
    covered: dict[int, list[tuple[int, int]]] = {}

    for u in spec["units"]:
        if "fragments" in u:
            fragment_mode = True
            body = ""
            used_lines: list[Line] = []
            for k, frag in enumerate(u["fragments"]):
                piece, line = _fragment(by_raw, frag, covered, u["id"])
                used_lines.append(line)
                if k == 0:
                    body = piece
                else:
                    join = frag.get("join", {"canticle": "\n ", "lines": "\n"}.get(u["kind"], " "))
                    body = body + join + piece
            for old, new in u.get("replace", []):
                if old not in body:
                    raise MapError(f"{u['id']}: replace target {old!r} not found")
                body = body.replace(old, new, 1)
            letter = u.get("dropcap")
            unit = build_unit(u, body, letter)
            if u.get("closeUp"):
                _close_up(unit)
            prov = {
                "rawLines": [min(l.raw_start for l in used_lines), max(l.raw_end for l in used_lines)],
                "extractionPages": sorted({l.page for l in used_lines}),
                "review": "reading-order-reconstructed",
            }
            if u.get("replace"):
                prov["editorial"] = [f"{o!r} -> {n!r}" for o, n in u["replace"]]
            unit["provenance"] = prov
            units.append(unit)
            continue
        s = text.find(u["start"], cursor)
        if s < 0:
            raise MapError(f"{u['id']}: start not found after offset {cursor}: {u['start']!r}")
        gap = text[cursor:s]
        if gap.strip() and not fragment_mode:
            raise MapError(f"{u['id']}: uncovered source text before unit: {gap.strip()[:120]!r}")
        e = text.find(u["end"], s)
        if e < 0:
            raise MapError(f"{u['id']}: end not found: {u['end']!r}")
        e += len(u["end"])
        if u["kind"] == "artifact":
            # An extraction artifact (an unflagged running head or orphan
            # drop capital): covered, so not reported as skipped, but not
            # emitted as liturgical text.
            issues.append({"kind": "artifact-skipped", "unit": u["id"], "text": collapse(text[s:e]),
                           "note": u.get("note", ""), **_provenance(stream, s, e)})
            cursor = e
            continue
        body = text[s:e]
        letter = u.get("dropcap")
        unit = build_unit(u, body, letter)
        extra = {}
        if u.get("dropcapBasis") == "context":
            extra["dropcap"] = "restored-from-context"
        elif u.get("dropcapBasis") == "unflagged-orphan":
            extra["dropcap"] = "restored-from-unflagged-orphan-line"
        unit["provenance"] = _provenance(stream, s, e, extra or None)
        if letter and u.get("dropcapBasis") not in ("context", "unflagged-orphan"):
            declared.append((s, letter, u["id"]))
        units.append(unit)
        cursor = e
    tail = text[cursor:]
    if tail.strip() and not fragment_mode:
        raise MapError(f"uncovered source text after last unit: {tail.strip()[:120]!r}")

    if fragment_mode:
        _check_fragment_coverage(by_raw, covered, spec.get("ignore", []))
    else:
        _check_dropcaps(stream, declared, issues, strict=True)
    service = {
        "id": spec["id"],
        "title": spec["title"],
        "source": spec.get("source", {}),
        "units": units,
    }
    return service, issues


def _check_dropcaps(stream: Stream, declared: list[tuple[int, str, str]], issues: list[dict], strict: bool) -> None:
    """Every declared drop capital must appear, in order, on the orphan-letter
    line that closes its book page."""
    declared = sorted(declared)
    queue: list[tuple[int, str]] = []
    for off, letters in stream.dropcaps:
        for ch in letters:
            queue.append((off, ch))
    expected = [(off, letter, uid) for off, letter, uid in declared]
    actual = [ch for _, ch in queue]
    claimed = [letter for _, letter, _ in expected]
    if claimed != actual:
        issue = {"kind": "dropcap-sequence", "declared": "".join(claimed), "orphanLines": "".join(actual)}
        if strict:
            raise MapError(f"drop capitals declared {''.join(claimed)!r} but pages show {''.join(actual)!r}")
        issues.append(issue)


def _fragment(by_raw: dict[int, Line], frag: dict, covered: dict, uid: str) -> tuple[str, Line]:
    """Resolve one fragment: whole lines ``{"raw": [a, b]}`` or a substring of
    one line ``{"raw": n, "from": "...", "to": "..."}`` (both inclusive)."""
    raw = frag["raw"]
    if isinstance(raw, list):
        lines = [by_raw[r] for r in sorted(by_raw) if raw[0] <= r <= raw[1]]
        if not lines:
            raise MapError(f"{uid}: no lines in raw range {raw}")
        for line in lines:
            covered.setdefault(line.raw_start, []).append((0, len(line.text)))
        return "\n".join(line.text.strip() for line in lines), lines[0]
    if raw not in by_raw:
        raise MapError(f"{uid}: no normalized line starts at raw line {raw}")
    line = by_raw[raw]
    text = line.text
    start = 0
    if "from" in frag:
        start = text.find(frag["from"])
        if start < 0:
            raise MapError(f"{uid}: {frag['from']!r} not in raw line {raw}: {text!r}")
    end = len(text)
    if "to" in frag:
        at = text.find(frag["to"], start)
        if at < 0:
            raise MapError(f"{uid}: {frag['to']!r} not after {frag.get('from')!r} in raw line {raw}")
        end = at + len(frag["to"])
    covered.setdefault(raw, []).append((start, end))
    return text[start:end].strip(), line


def _check_fragment_coverage(by_raw: dict[int, Line], covered: dict, ignore: list[dict]) -> None:
    for item in ignore:
        line = by_raw[item["raw"]]
        at = line.text.find(item["text"], line.text.find(item.get("after", "")) if item.get("after") else 0)
        if at < 0:
            raise MapError(f"ignore entry {item} not found")
        covered.setdefault(item["raw"], []).append((at, at + len(item["text"])))
    problems = []
    for raw, line in by_raw.items():
        mask = [False] * len(line.text)
        for a, b in covered.get(raw, []):
            for i in range(a, b):
                mask[i] = True
        left = "".join(ch if not m else " " for ch, m in zip(line.text, mask)).strip()
        if left:
            problems.append(f"raw {raw}: {left[:80]!r}")
    if problems:
        raise MapError("source text not assigned to any unit:\n" + "\n".join(problems))


def _close_up(unit: dict) -> None:
    """Close up a letter-spaced opening ("AL M I G H T Y" -> "ALMIGHTY")."""
    if "text" in unit:
        unit["text"] = restore_initial(unit["text"], "")
    elif unit.get("verses"):
        v = unit["verses"][0]
        key = "first" if "first" in v else "text"
        v[key] = restore_initial(v[key], "")
    elif unit.get("lines"):
        first = unit["lines"][0]
        if isinstance(first, dict):
            first["text"] = restore_initial(first["text"], "")

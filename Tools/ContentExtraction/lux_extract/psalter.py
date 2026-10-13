"""The Psalter: 150 Psalms in Coverdale's translation, pointed, and the
thirty-day course for Morning and Evening Prayer.

Source structure (extraction pages 196-309):

* The section opens with "T H E F I R S T D A Y." and each half-day opens
  with a "M O R N I N G P R A Y E R." or "E V E N I N G P R A Y E R." heading.
  The day is implied by order (each Morning heading begins a new day).
* Each Psalm opens with "PSAL. n" and its Latin incipit. Its first verse is
  unnumbered and opens with a drop capital; later verses are numbered.
* Psalm 119 is printed in twenty-two portions, each opened by its Latin
  incipit on its own line and a drop capital, with verses numbered 1-8 within
  the portion.
* The pointing colon divides each verse into halves.

Verse numbers are matched in sequence. A printed or extracted number that is
out of sequence is reported, never silently trusted or renumbered.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from .normalize import Line
from .text import assign_dropcaps, collapse, restore_initial

START = "T H E F I R S T D A Y."
END_PREFIX = "F O R M S of P R A Y E R"

_half = re.compile(r"^(M O R N I N G|E V E N I N G) P R A Y E R\.+\s*$")
_running_head = re.compile(r"^(The \d+\. Day\. P S A L M S\.|P S A L M S\. The \d+\. Day\.)$")
_psalm = re.compile(r"^P(?:SA|AS)L\.\s*(\d+)\.?\s*(.*)$")  # one heading is printed "PASL."
_incipit = re.compile(r"^[A-Z][A-Za-zſæ ,.!?]+[.!?]$")
_number = re.compile(r"(?:^|(?<=\s))(\d{1,3})\s+(?=[^\d\s])")


class PsalterError(Exception):
    pass


@dataclass
class Verse:
    number: int
    text: str
    raw_line: int

    def halves(self) -> tuple[str, str | None]:
        if self.text.count(":") == 1:
            first, second = self.text.split(":")
            return first.strip(), second.strip()
        return self.text, None


@dataclass
class Block:
    """One Psalm, or one portion of Psalm 119."""

    psalm: int
    portion: int | None
    incipit: str
    raw_start: int
    raw_end: int = 0
    pages: set[int] = field(default_factory=set)
    lines: list[tuple[int, int, str]] = field(default_factory=list)  # (line index, raw line, text)
    verses: list[Verse] = field(default_factory=list)
    half_day: int = 0  # index into course


@dataclass
class HalfDay:
    day: int
    office: str  # "morning" | "evening"
    raw_line: int
    blocks: list[Block] = field(default_factory=list)


@dataclass
class Psalter:
    blocks: list[Block]
    course: list[HalfDay]
    issues: list[dict]


def _section(lines: list[Line]) -> tuple[int, int]:
    start = next(i for i, l in enumerate(lines) if l.text.strip() == START)
    end = next(i for i in range(start, len(lines)) if lines[i].text.strip().startswith(END_PREFIX))
    return start, end


def parse_psalter(lines: list[Line], dropcap_table: dict[str, dict] | None = None) -> Psalter:
    start, end = _section(lines)
    issues: list[dict] = []
    course: list[HalfDay] = []
    blocks: list[Block] = []
    sites: list[int] = []
    current: Block | None = None
    day = 0

    for i in range(start + 1, end):
        line = lines[i]
        text = line.text.strip()
        if line.dropcaps or line.head or not text or _running_head.match(text):
            continue
        if _half.match(text):
            office = "morning" if text.startswith("M") else "evening"
            if office == "morning":
                day += 1
            course.append(HalfDay(day, office, line.raw_start))
            continue
        m = _psalm.match(text)
        if m:
            number = int(m.group(1))
            current = Block(number, 1 if number == 119 else None, m.group(2).strip(), line.raw_start, line.raw_end, {line.page})
            current.half_day = len(course) - 1
            blocks.append(current)
            continue
        if (
            current is not None
            and current.psalm == 119
            and _incipit.match(text)
            and len(text.split()) <= 5
            and _last_number(current) == 8
        ):
            current = Block(119, current.portion + 1, text, line.raw_start, line.raw_end, {line.page})
            current.half_day = len(course) - 1
            blocks.append(current)
            continue
        if text.endswith("The End of the Pſalms."):
            text_before = line.text.replace("The End of the Pſalms.", "")
            if text_before.strip():
                current.lines.append((i, line.raw_start, text_before))
                current.raw_end = line.raw_end
            break
        if current is None:
            raise PsalterError(f"text before the first Psalm at raw line {line.raw_start}")
        if not current.lines:
            sites.append(i)
        current.lines.append((i, line.raw_start, line.text))
        current.raw_end = line.raw_end
        current.pages.add(line.page)

    letters, mismatches = assign_dropcaps(lines[: end], sites)
    stray_fixes: dict[int, tuple[str, str]] = {}
    for mm in mismatches:
        issues.append({"kind": "dropcap-mismatch", **mm.as_json()})
    for site in sites:
        if site not in letters:
            entry = (dropcap_table or {}).get(str(lines[site].raw_start))
            if entry is None:
                continue
            if not lines[site].text.strip().startswith(entry["opening"]):
                raise PsalterError(f"dropcaps.json entry {lines[site].raw_start} expects {entry['opening']!r}")
            letters[site] = entry["letter"]
            if "strayInitial" in entry:
                stray = entry["strayInitial"]
                if stray not in lines[site].text:
                    raise PsalterError(f"dropcaps.json entry {lines[site].raw_start}: stray initial not found")
                stray_fixes[site] = (stray, " " + stray.strip().split(" ", 1)[1])
            issues.append({"kind": "dropcap-restored", "basis": entry["basis"], "letter": entry["letter"],
                           "rawLine": lines[site].raw_start})

    for block in blocks:
        if block.lines and block.lines[0][0] in stray_fixes:
            index, raw, text = block.lines[0]
            before, after = stray_fixes[index]
            block.lines[0] = (index, raw, text.replace(before, after, 1))
        _verses(block, letters, issues)
        course[block.half_day].blocks.append(block)

    _validate(blocks, course, issues)
    return Psalter(blocks, course, issues)


def _last_number(block: Block) -> int:
    joined = " ".join(t for _, _, t in block.lines)
    numbers = [int(n) for n in _number.findall(" " + joined)]
    return numbers[-1] if numbers else 1


def _verses(block: Block, letters: dict[int, str], issues: list[dict]) -> None:
    joined = ""
    offsets: list[tuple[int, int]] = []
    for k, (index, raw, text) in enumerate(block.lines):
        if k == 0:
            if index in letters:
                text = restore_initial(text, letters[index])
            else:
                issues.append({"kind": "dropcap-missing", "psalm": block.psalm, "portion": block.portion, "rawLine": raw})
        offsets.append((len(joined), raw))
        joined += " " + text

    def raw_for(offset: int) -> int:
        found = offsets[0][1]
        for off, raw in offsets:
            if off <= offset:
                found = raw
        return found

    candidates = [(int(m.group(1)), m.start(1), m.end()) for m in _number.finditer(joined)]
    starts: list[tuple[int, int, int]] = [(1, 0, 0)]  # (assigned number, text start, number start)
    expected = 2
    for k, (value, num_start, text_start) in enumerate(candidates):
        if value == expected:
            starts.append((expected, text_start, num_start))
            expected += 1
        elif value == expected + 1:
            following = next((c[0] for c in candidates[k + 1:] if c[0] >= expected), None)
            if following == value:
                # The same number printed twice: this one stands for `expected`.
                issues.append({"kind": "verse-number-misprinted", "psalm": block.psalm, "portion": block.portion,
                               "printed": value, "assigned": expected, "rawLine": raw_for(num_start)})
                starts.append((expected, text_start, num_start))
                expected += 1
            else:
                issues.append({"kind": "verse-number-missing", "psalm": block.psalm, "portion": block.portion,
                               "missing": expected, "rawLine": raw_for(num_start)})
                starts.append((value, text_start, num_start))
                expected = value + 1
    for k, (number, text_start, _) in enumerate(starts):
        text_end = starts[k + 1][2] if k + 1 < len(starts) else len(joined)
        block.verses.append(Verse(number, collapse(joined[text_start:text_end]), raw_for(text_start)))
    for verse in block.verses:
        if verse.halves()[1] is None:
            issues.append({"kind": "verse-pointing", "psalm": block.psalm, "portion": block.portion,
                           "verse": verse.number, "colons": verse.text.count(":"), "rawLine": verse.raw_line})


def _validate(blocks: list[Block], course: list[HalfDay], issues: list[dict]) -> None:
    numbers = [b.psalm for b in blocks if b.portion in (None, 1)]
    if numbers != list(range(1, 151)):
        raise PsalterError(f"Psalms out of order or missing: {numbers[:10]}...")
    portions = [b.portion for b in blocks if b.psalm == 119]
    if portions != list(range(1, 23)):
        raise PsalterError(f"Psalm 119 portions: {portions}")
    days = [(h.day, h.office) for h in course]
    expected = [(d, o) for d in range(1, 31) for o in ("morning", "evening")]
    if days != expected:
        raise PsalterError(f"thirty-day course malformed: {days}")
    for b in blocks:
        if b.psalm == 119 and len(b.verses) != 8:
            issues.append({"kind": "ps119-portion-length", "portion": b.portion, "verses": len(b.verses)})

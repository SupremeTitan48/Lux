"""Stage 1: character normalization and physical-line repair.

The supplied witness is a text-layer extraction of a typeset PDF. It has four
systematic artifacts, each handled here by an explicit, logged rule:

1. U+0002 is emitted where the typesetter placed a discretionary hyphen.
   Rule ``soft-hyphen``: the character is removed.
2. Ligatures are emitted as Private Use Area code points. U+E000 is always
   "ct" and U+E002 is always "st". U+E001 is "ct" in roman type but "st" in
   italic type, and the extraction does not record the font, so each U+E001
   word is resolved through the reviewed table in ``data/ligatures.json``.
   Rule ``ligature``.
3. The extractor starts a new physical line before almost every long s and
   before or after ligature glyphs, splitting words. Rule ``line-join``: such
   a line is joined to the previous line. Whether a space belongs at the join
   is resolved through the reviewed table in ``data/joins.json``.
4. Page boundaries are LF-only lines (every other line ends in CRLF). An empty
   LF-only line is a page break. Rule ``page``: pages are numbered from 1 in
   extraction order. The correspondence between these numbers and PDF page
   indices must be verified against the PDF itself.

The long s (U+017F) is preserved. Modern-s presentation is a separate,
reversible display transform.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from .raw import RawSource

PUA_CT = ""
PUA_AMBIGUOUS = ""
PUA_ST = ""
PUA = (PUA_CT, PUA_AMBIGUOUS, PUA_ST)
SOFT_HYPHEN = "\x02"
LONG_S = "ſ"

LETTER = r"[A-Za-zſæ-]"
_letters_left = re.compile(LETTER + r"*$")
_letters_right = re.compile(r"^" + LETTER + r"*")


class UnresolvedDecision(Exception):
    def __init__(self, kind: str, keys: list[str]):
        self.kind = kind
        self.keys = keys
        super().__init__(
            f"{len(keys)} unresolved {kind} decision(s); run "
            f"`python3 -m lux_extract propose` and review the result. "
            f"First: {keys[:5]}"
        )


@dataclass
class Line:
    text: str
    raw_start: int
    raw_end: int
    page: int
    page_end: bool = False  # last line before a page break
    page_first: bool = False  # first line after a page break
    dropcaps: bool = False  # an orphan line of displaced drop capitals
    head: bool = False  # a running head


@dataclass
class EditEvent:
    rule: str
    raw_line: int
    before: str
    after: str
    note: str = ""

    def as_json(self) -> dict:
        out = {"rule": self.rule, "rawLine": self.raw_line, "before": self.before, "after": self.after}
        if self.note:
            out["note"] = self.note
        return out


@dataclass
class NormalizedText:
    lines: list[Line]
    events: list[EditEvent] = field(default_factory=list)
    page_count: int = 0


def ligature_key(word: str) -> str:
    """Key for a word containing U+E001; other ligatures are already resolved."""
    w = word.replace(PUA_CT, "ct").replace(PUA_ST, "st").replace(LONG_S, "s").lower()
    return w.replace(PUA_AMBIGUOUS, "#")


def join_key(left: str, right: str) -> str:
    def k(s: str) -> str:
        return s.replace(PUA_CT, "ct").replace(PUA_ST, "st").replace(PUA_AMBIGUOUS, "#").replace(LONG_S, "s").lower()

    return f"{k(left)}|{k(right)}"


@dataclass
class _Physical:
    text: str
    raw: int
    has_cr: bool
    page: int


def _physical_lines(source: RawSource) -> tuple[list[_Physical], int]:
    out: list[_Physical] = []
    page = 1
    for raw in source.lines:
        if not raw.has_cr and raw.text.strip() == "":
            page += 1
            continue
        out.append(_Physical(raw.text.replace(SOFT_HYPHEN, ""), raw.number, raw.has_cr, page))
    return out, page


def _starts_joined(text: str) -> bool:
    return text[:1] == LONG_S or text[:1] in PUA


def merge_physical_lines(source: RawSource, decide):
    """Join split physical lines.

    ``decide(left, right, raw_line)`` is called at every join with letters on
    both sides and returns the separator ("" or " "). Returns (lines, pages).
    """
    physical, last_page = _physical_lines(source)
    lines: list[Line] = []
    for p in physical:
        prev = lines[-1] if lines else None
        if prev is not None and prev.page == p.page and (_starts_joined(p.text) or prev.text[-1:] in PUA):
            left = _letters_left.search(prev.text).group(0)
            right = _letters_right.search(p.text).group(0)
            separator = decide(left, right, p.raw) if left and right else ""
            prev.text = prev.text + separator + p.text
            prev.raw_end = p.raw
            prev.page_end = not p.has_cr
            continue
        lines.append(Line(p.text, p.raw, p.raw, p.page, page_end=not p.has_cr))
    return lines, last_page


def normalize(source: RawSource, ligatures: dict[str, str] | None, joins: dict[str, str], spaces: dict[str, list[dict]] | None = None) -> NormalizedText:
    """Run stage 1. ``ligatures=None`` leaves U+E001 unresolved (used only by ``propose``)."""
    unresolved_joins: list[str] = []
    events: list[EditEvent] = []

    def decide(left: str, right: str, raw_line: int) -> str:
        decision = joins.get(join_key(left, right))
        if decision is None:
            unresolved_joins.append(join_key(left, right))
            return ""
        if decision == "space":
            events.append(EditEvent("line-join", raw_line, f"{left}⏎{right}", f"{left} {right}", "space inserted"))
            return " "
        return ""

    lines, last_page = merge_physical_lines(source, decide)
    lines = _split_trailing_dropcaps(lines, events)
    result = NormalizedText(lines, events, last_page)

    if unresolved_joins:
        raise UnresolvedDecision("line-join", sorted(set(unresolved_joins)))

    # Mark page-first lines.
    for i, line in enumerate(result.lines):
        line.page_first = i == 0 or result.lines[i - 1].page != line.page

    if ligatures is not None:
        _resolve_ligatures(result, ligatures)
    if spaces:
        _restore_spaces(result, spaces)
    _mark_dropcaps(result)
    return result


def _restore_spaces(result: NormalizedText, spaces: dict[str, list[dict]]) -> None:
    """Rule ``word-space``: restore word spaces the extractor lost, from the
    reviewed table in ``data/spaces.json``."""
    by_raw = {line.raw_start: line for line in result.lines}
    for raw, edits in spaces.items():
        line = by_raw.get(int(raw))
        if line is None:
            raise UnresolvedDecision("word-space", [f"no line starts at raw {raw}"])
        for edit in edits:
            if edit["before"] not in line.text:
                raise UnresolvedDecision("word-space", [f"{edit['before']!r} not in raw line {raw}"])
            line.text = line.text.replace(edit["before"], edit["after"], 1)
            result.events.append(EditEvent("word-space", int(raw), edit["before"], edit["after"]))


_trailing_caps = re.compile(r"(?<=[a-z.,;:?!’)])\s+((?:[A-Z]{1,3} ?)+)\s*$")


def _split_trailing_dropcaps(lines: list[Line], events: list[EditEvent]) -> list[Line]:
    """On some pages the orphan drop-capital letters share the page's last
    physical line with text ("done? I"). Split them onto their own line."""
    out: list[Line] = []
    for line in lines:
        m = _trailing_caps.search(line.text) if line.page_end else None
        if m:
            letters = m.group(1).strip()
            text = line.text[: m.start()] + " "
            events.append(EditEvent("dropcap-line-split", line.raw_end, line.text.strip(), text.strip(), f"orphan letters {letters!r} moved to their own line"))
            out.append(Line(text, line.raw_start, line.raw_end, line.page, page_end=False))
            out.append(Line(letters, line.raw_end, line.raw_end, line.page, page_end=True))
        else:
            out.append(line)
    return out


_word_with_pua = re.compile(LETTER + r"*[-]" + LETTER + r"*")


def _resolve_ligatures(result: NormalizedText, ligatures: dict[str, str]) -> None:
    unresolved: list[str] = []
    for line in result.lines:
        if not any(ch in line.text for ch in PUA):
            continue

        def repl(match: re.Match) -> str:
            word = match.group(0)
            out = word.replace(PUA_CT, "ct").replace(PUA_ST, "st")
            if PUA_AMBIGUOUS in out:
                key = ligature_key(word)
                decision = ligatures.get(key)
                if decision not in ("ct", "st", "ct ", "st "):
                    unresolved.append(key)
                    return word
                out = out.replace(PUA_AMBIGUOUS, decision)
            result.events.append(EditEvent("ligature", line.raw_start, word, out))
            return out

        line.text = _word_with_pua.sub(repl, line.text)
    if unresolved:
        raise UnresolvedDecision("ligature", sorted(set(unresolved)))


_dropcap_pattern = re.compile(r"^[A-Z](?: ?[A-Z])*$")
_digits = re.compile(r"\d+")


def _head_key(text: str) -> str:
    return _digits.sub("N", text.strip())


def _mark_dropcaps(result: NormalizedText) -> None:
    """Mark running heads and orphan lines of displaced drop capitals.

    Each PDF page of the reproduction carries two book pages side by side.
    The extractor emits each book page's drop capitals, in order, as one line
    of capitals at the end of that book page, followed either by the PDF page
    break or directly by the next book page's running head.

    A running head is a line that, at least twice, opens a PDF page or follows
    a line of capitals. A capitals-only line is a drop-capital line when it
    ends a PDF page or is followed by a running head.
    """
    lines = result.lines
    caps = [bool(_dropcap_pattern.match(l.text.strip())) for l in lines]
    counts: dict[str, int] = {}
    for i, line in enumerate(lines):
        if line.page_first or (i > 0 and caps[i - 1]):
            key = _head_key(line.text)
            counts[key] = counts.get(key, 0) + 1
    heads = {k for k, v in counts.items() if v >= 2 and len(k) <= 80}
    for i, line in enumerate(lines):
        after_caps = i > 0 and caps[i - 1]
        if (line.page_first or after_caps) and _head_key(line.text) in heads:
            line.head = True
    for i, line in enumerate(lines):
        if not caps[i]:
            continue
        nxt = lines[i + 1] if i + 1 < len(lines) else None
        if line.page_end or (nxt is not None and nxt.head):
            line.dropcaps = True


def dropcap_letters(line: Line) -> list[str]:
    return [ch for ch in line.text if ch.isalpha()]

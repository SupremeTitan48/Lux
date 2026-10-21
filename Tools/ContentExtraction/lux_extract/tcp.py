"""Read tables from a Text Creation Partnership (EEBO-TCP) TEI transcription.

The lectionary tables are missing from the Baskerville text layer, so they
are taken from the TCP keyboarding of the 1693 London printing (A28758).
The TCP flattens each printed table into one cell per row, in reading order,
dropping some empty cells. This module only recovers that cell stream with
the XML line of every cell, the page image it sits on, and the footnotes and
gaps inside it. Interpreting the cells is ``lectionary.py``'s job.

The XML file is never modified; its SHA-256 is checked like the primary
witness's.
"""

from __future__ import annotations

import re
import xml.parsers.expat
from dataclasses import dataclass, field
from pathlib import Path

from .raw import ChecksumMismatch, sha256_of


@dataclass
class Cell:
    line: int  # 1-based line of the <cell> start tag in the XML
    page: str  # facs of the preceding <pb>, e.g. "tcp:48041:6"
    text: str = ""  # cell text with tags removed, whitespace collapsed, footnotes excluded
    notes: list[str] = field(default_factory=list)  # footnotes printed against the cell
    gaps: list[str] = field(default_factory=list)  # TCP <gap> reasons (illegible letters)


@dataclass
class Table:
    line: int
    head: str
    cells: list[Cell]


@dataclass
class Division:
    type: str
    line: int
    head: str
    tables: list[Table]


def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def load_divisions(path: Path, expected_sha256: str, types: set[str]) -> dict[str, Division]:
    """The tables of every TEI ``div`` whose ``type`` is in ``types``."""
    digest = sha256_of(path)
    if digest != expected_sha256:
        raise ChecksumMismatch(f"{path} has SHA-256 {digest}, expected {expected_sha256}.")

    parser = xml.parsers.expat.ParserCreate()
    out: dict[str, Division] = {}
    state = {"page": "", "div": None, "div_depth": 0, "depth": 0}
    stack: list[str] = []
    table: list[Table] = []
    cell: list[Cell] = []
    text_target: list[list[str]] = []  # where character data goes
    head_parts: list[str] = []

    def start(name, attrs):
        stack.append(name)
        line = parser.CurrentLineNumber
        if name == "pb":
            state["page"] = attrs.get("facs", "")
        if name == "div" and state["div"] is None and attrs.get("type") in types:
            state["div"] = Division(attrs["type"], line, "", [])
            state["div_depth"] = len(stack)
        div = state["div"]
        if div is None:
            return
        if name == "head":
            head_parts.clear()
            text_target.append(head_parts)
        elif name == "table":
            table.append(Table(line, "", []))
        elif name == "cell":
            cell.append(Cell(line, state["page"]))
            text_target.append([])
        elif name == "note" and cell:
            text_target.append([])
        elif name == "gap" and cell:
            cell[-1].gaps.append(attrs.get("reason", "") + (f" ({attrs['extent']})" if "extent" in attrs else ""))
            text_target.append([])  # gap descriptions are not text
        elif name == "g" and attrs.get("ref") == "char:EOLhyphen":
            pass  # end-of-line hyphen: words are rejoined

    def end(name):
        div = state["div"]
        stack_len = len(stack)
        stack.pop()
        if div is None:
            return
        if name == "head":
            text_target.pop()
            head = _clean("".join(head_parts))
            if table and not table[-1].cells and not table[-1].head:
                table[-1].head = head
            elif not div.head:
                div.head = head
        elif name == "cell":
            parts = text_target.pop()
            c = cell.pop()
            c.text = _clean("".join(parts))
            table[-1].cells.append(c)
        elif name == "note" and cell:
            cell[-1].notes.append(_clean("".join(text_target.pop())))
        elif name == "gap" and cell:
            text_target.pop()
            text_target[-1].append("␣")  # an illegible letter, marked visibly
        elif name == "table":
            div.tables.append(table.pop())
        elif name == "div" and stack_len == state["div_depth"]:
            out[div.type] = div
            state["div"] = None

    def chars(data):
        if state["div"] is not None and text_target:
            text_target[-1].append(data)

    parser.StartElementHandler = start
    parser.EndElementHandler = end
    parser.CharacterDataHandler = chars
    parser.Parse(path.read_bytes(), True)
    missing = types - out.keys()
    if missing:
        raise RuntimeError(f"divisions not found in {path.name}: {sorted(missing)}")
    return out

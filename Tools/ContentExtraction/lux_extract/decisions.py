"""Reviewed decision tables for ambiguous extraction artifacts.

The build never consults a dictionary. It reads only the checked-in tables in
``data/``. The ``propose`` command fills missing entries with dictionary-aided
proposals and marks each one with its basis, so a reviewer can see which
entries were machine-proposed, which were ambiguous, and which a person has
confirmed.

Table entry shape::

    "key": {"decision": "...", "basis": "lexicon|ambiguous|unknown|reviewed", "example": "..."}
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from .normalize import (
    LETTER,
    PUA_AMBIGUOUS,
    join_key,
    merge_physical_lines,
    ligature_key,
)
from .raw import RawSource

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
LIGATURES_PATH = DATA_DIR / "ligatures.json"
JOINS_PATH = DATA_DIR / "joins.json"

# Early-modern forms common in the 1662 text and absent from modern word lists.
ARCHAIC = """
hast hath doth dost didst wast wert art shalt wilt canst couldst wouldst shouldst
mayest mightest knowest seest hearest givest makest sayest sheweth shew shewed shewn
alway holpen unto thee thou thy thine ye spake sware brake bare clave
publick catholick musick rubrick rubricks heretick schismatick
chrysostom athanasius ghost hallowed trespasses
""".split()

_word = re.compile(r"[a-zæ]+")


def _fold(word: str) -> str:
    return word.replace("ſ", "s").lower()


class Lexicon:
    def __init__(self, words: set[str]):
        self.words = words

    def __contains__(self, word: str) -> bool:
        w = _fold(word)
        if not w:
            return False
        if w in self.words:
            return True
        for suffix, replacements in (
            ("eth", ("", "e")),
            ("est", ("", "e")),
            ("edst", ("ed",)),
            ("st", ("",)),
            ("th", ("",)),
            ("s", ("",)),
            ("'s", ("",)),
        ):
            if w.endswith(suffix) and len(w) > len(suffix) + 2:
                stem = w[: -len(suffix)]
                if any(stem + r in self.words for r in replacements):
                    return True
        return False


def build_lexicon(source: RawSource, extra_word_lists: list[Path]) -> Lexicon:
    words: set[str] = set(ARCHAIC)
    for path in extra_word_lists:
        if path.exists():
            words.update(w.strip().lower() for w in path.read_text(errors="ignore").split())
    # Words attested intact inside a single raw line, away from line edges,
    # at least three times (a single occurrence may be an extraction error).
    counts: dict[str, int] = {}
    for raw in source.lines:
        text = raw.text.replace("\x02", "")
        tokens = re.findall(LETTER + "+", text)
        for token in tokens[1:-1]:
            if not re.search("[\ue000-\ue002]", token):
                key = _fold(token)
                counts[key] = counts.get(key, 0) + 1
    words.update(k for k, n in counts.items() if n >= 3)
    return Lexicon(words)


def load_table(path: Path) -> dict[str, dict]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def decisions(table: dict[str, dict]) -> dict[str, str]:
    return {k: v["decision"] for k, v in table.items()}


def save_table(path: Path, table: dict[str, dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    ordered = {k: table[k] for k in sorted(table)}
    path.write_text(json.dumps(ordered, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def propose_joins(source: RawSource, lexicon: Lexicon, table: dict[str, dict]) -> dict[str, int]:
    stats = {"existing": 0, "join": 0, "space": 0, "unknown": 0, "pruned": 0}
    used: set[str] = set()

    def decide(left: str, right: str, raw_line: int) -> str:
        key = join_key(left, right)
        used.add(key)
        if key in table:
            stats["existing"] += 1
        else:
            l, r = (part.replace("#", "ct") for part in key.split("|"))
            if (l + r) in lexicon:
                entry = {"decision": "join", "basis": "lexicon"}
            elif l in lexicon and r in lexicon:
                entry = {"decision": "space", "basis": "lexicon"}
            else:
                entry = {"decision": "join", "basis": "unknown"}
            stats[entry["decision"] if entry["basis"] == "lexicon" else "unknown"] += 1
            entry["example"] = f"raw line {raw_line}"
            table[key] = entry
        return " " if table[key]["decision"] == "space" else ""

    merge_physical_lines(source, decide)
    for key in [k for k in table if k not in used]:
        del table[key]
        stats["pruned"] += 1
    return stats


def propose_ligatures(source: RawSource, lexicon: Lexicon, table: dict[str, dict], joined_text: list[str]) -> dict[str, int]:
    stats = {"existing": 0, "lexicon": 0, "ambiguous": 0, "unknown": 0, "pruned": 0}
    used: set[str] = set()
    pattern = re.compile(LETTER + r"*" + PUA_AMBIGUOUS + LETTER + r"*")
    for line_no, text in enumerate(joined_text, start=1):
        for match in pattern.finditer(text):
            key = ligature_key(match.group(0))
            used.add(key)
            if key in table:
                stats["existing"] += 1
                continue
            ct = key.replace("#", "ct") in lexicon
            st = key.replace("#", "st") in lexicon
            if ct and not st:
                entry = {"decision": "ct", "basis": "lexicon"}
                stats["lexicon"] += 1
            elif st and not ct:
                entry = {"decision": "st", "basis": "lexicon"}
                stats["lexicon"] += 1
            elif ct and st:
                entry = {"decision": "ct", "basis": "ambiguous"}
                stats["ambiguous"] += 1
            else:
                entry = {"decision": "ct", "basis": "unknown"}
                stats["unknown"] += 1
            entry["example"] = text[max(0, match.start() - 30): match.end() + 30].strip()
            table[key] = entry
    for key in [k for k in table if k not in used]:
        del table[key]
        stats["pruned"] += 1
    return stats

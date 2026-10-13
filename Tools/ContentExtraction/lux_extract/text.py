"""Shared helpers for turning normalized lines into liturgical text."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .normalize import Line, dropcap_letters

_space_run = re.compile(r"\s+")
_spaced_caps_start = re.compile(r"^(?:[A-Z]+ )*[A-Z]+(?=[\s,.;:!?’'()]|$)")


def collapse(text: str) -> str:
    """Join wrapped physical lines: collapse whitespace runs to one space."""
    return _space_run.sub(" ", text).strip()


def restore_initial(text: str, letter: str) -> str:
    """Restore a displaced drop capital to the start of ``text``.

    The extractor removed the drop capital and, for most openings, letter-spaced
    the small capitals that follow it ("L M I G H T Y" for ALMIGHTY). Rules:

    * Leading capitals (spaced or not) are closed up and the letter prefixed:
      "L M I G H T Y and" -> "ALMIGHTY and", "EARLY" -> "DEARLY".
    * Otherwise, when the letter is a whole word (O, I, A) it is prefixed as a
      word: "Lord, our heavenly" -> "O Lord, our heavenly".
    * Otherwise the letter is prefixed to the first word: "E praiſe" is handled
      by the first rule ("E" is a capitals run) giving "WE praiſe".
    """
    body = text.lstrip()
    match = _spaced_caps_start.match(body)
    if match:
        word = match.group(0).replace(" ", "")
        rest = body[match.end():]
        # "LO R D , now" -> the comma belongs to the word.
        rest = re.sub(r"^ (?=[,.;:!?])", "", rest)
        return letter + word + rest
    if letter in ("O", "I", "A"):
        return f"{letter} {body}"
    return letter + body


@dataclass
class DropcapMismatch:
    raw_line: int
    letters: list[str]
    sites: list[int]

    def as_json(self) -> dict:
        return {"rawLine": self.raw_line, "letters": "".join(self.letters), "sites": self.sites}


def assign_dropcaps(lines: list[Line], sites: list[int]) -> tuple[dict[int, str], list[DropcapMismatch]]:
    """Pair drop-capital sites with the displaced letters on their book page.

    ``sites`` are indices into ``lines`` of text lines that open with a drop
    capital, in reading order. Sites between two drop-capital lines take the
    letters of the later line, in order. Any book page where the number of
    sites differs from the number of letters is reported rather than guessed.
    """
    assigned: dict[int, str] = {}
    mismatches: list[DropcapMismatch] = []
    pending: list[int] = []
    site_set = set(sites)
    for index, line in enumerate(lines):
        if index in site_set:
            pending.append(index)
        if line.dropcaps:
            letters = dropcap_letters(line)
            if len(letters) == len(pending):
                for site, letter in zip(pending, letters):
                    assigned[site] = letter
            elif pending:
                mismatches.append(DropcapMismatch(line.raw_start, letters, [lines[s].raw_start for s in pending]))
            pending = []
    if pending:
        mismatches.append(DropcapMismatch(lines[pending[0]].raw_start, [], [lines[s].raw_start for s in pending]))
    return assigned, mismatches

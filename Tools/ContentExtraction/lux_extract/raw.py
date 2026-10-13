"""Stage 0: load the raw source witness exactly as supplied.

The raw extraction is never modified. Every later stage refers back to it by
1-based raw line number, so provenance survives every transformation.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class RawLine:
    number: int  # 1-based line number in the raw file
    text: str  # line text without its terminator
    has_cr: bool  # True when the line ended with CRLF


@dataclass(frozen=True)
class RawSource:
    path: Path
    sha256: str
    lines: tuple[RawLine, ...]


class ChecksumMismatch(Exception):
    pass


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_raw(path: Path, expected_sha256: str | None = None) -> RawSource:
    digest = sha256_of(path)
    if expected_sha256 is not None and digest != expected_sha256:
        raise ChecksumMismatch(
            f"{path} has SHA-256 {digest}, expected {expected_sha256}. "
            "The pipeline refuses to run against a different witness."
        )
    data = path.read_bytes().decode("utf-8")
    parts = data.split("\n")
    lines = []
    for index, part in enumerate(parts, start=1):
        has_cr = part.endswith("\r")
        lines.append(RawLine(index, part[:-1] if has_cr else part, has_cr))
    # A trailing newline produces one empty final element; drop it.
    if lines and lines[-1].text == "" and not lines[-1].has_cr and data.endswith("\n"):
        lines.pop()
    return RawSource(path, digest, tuple(lines))

"""The King James Version, for the text of the lessons.

The witness is eBible.org's PDF of the King James Version with the
Apocrypha ("the standardized text of 1769", from the CrossWire Bible
Society), recorded in ``Scripture/KJV/Witness/sources.json`` and committed
unchanged. Only the books Lux's lectionary reads are generated
(``data/books.json``); the Psalms are read from the Coverdale psalter of the
prayer book instead.

The PDF is read character by character with PDFium (``pypdfium2``, pinned in
``requirements.txt``), which reports the font of every glyph. The layout of
the edition is regular, and each line is classified by its fonts:

* running heads and page numbers (8 pt) and book titles (bold, 15.9 pt and
  larger) are left out;
* a chapter number is a line of bold 17.9 pt digits;
* a verse begins with its number in 9 pt, followed by 12 pt text;
* 12 pt text continues the current verse; italic 12 pt text is a word the
  translators supplied, and becomes a supplied segment;
* the translators' marginal notes are printed as 9 pt footnotes, with
  reference marks (* † ‡ §) in the text. Both are left out of the verse, and
  every footnote is kept in the transcription.

Lines are joined with a single space; the edition does not hyphenate at line
ends, which the build checks. Nothing else is changed: spelling,
punctuation and the paragraph marks (¶) are as printed.

Every line read is written to ``Provenance/transcription.txt`` with its PDF
page, and verse provenance points at those lines. Every chapter is checked
against the verse counts of another edition (``data/kjv-verse-counts.json``).
A verse the witness lacks, or one it has that the counts do not expect, fails
the build unless it is settled in ``data/kjv.json``; missing verses are then
shown as placeholders, never filled from another edition.
"""

from __future__ import annotations

import ctypes
import hashlib
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data"

SCHEMA_VERSION = 1
RUNTIME_DIR = Path("Sources/LuxKJV/Resources/Content")
PROVENANCE_DIR = Path("Provenance")

# Running-head names that differ from Lux's canonical book names.
HEAD_NAMES = {"Sirach": "Ecclesiasticus", "Bel": "Bel and the Dragon"}

MARKS = set("*†‡§")
SPACE_GAP = 0.2


class KJVError(Exception):
    pass


# MARK: Reading the PDF

@dataclass
class Glyph:
    char: str
    font: str  # "" for spaces and line breaks PDFium generates
    size: float
    inferred: bool = False  # a space Lux inferred from the gap between glyphs

    @property
    def italic(self) -> bool:
        return "Italic" in self.font


@dataclass
class Line:
    page: int  # 1-based PDF page
    glyphs: list[Glyph]
    kind: str = ""
    number: int = 0  # line of the transcription

    @property
    def text(self) -> str:
        return "".join(g.char for g in self.glyphs)

    def marked(self) -> str:
        """The line with italic runs in braces, for the transcription."""
        out, italic = [], False
        for g in self.glyphs:
            if g.font and g.italic != italic:
                out.append("{" if g.italic else "}")
                italic = g.italic
            out.append(g.char)
        if italic:
            out.append("}")
        return "".join(out)


def read_pdf(path: Path, expected_sha256: str) -> list[Line]:
    """Every text line of the PDF, with the font of every glyph."""
    import pypdfium2 as pdfium
    import pypdfium2.raw as raw

    data = path.read_bytes()
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected_sha256:
        raise KJVError(f"{path.name}: SHA-256 {actual} does not match the recorded {expected_sha256}")
    pdf = pdfium.PdfDocument(data)
    buf = ctypes.create_string_buffer(256)
    flags = ctypes.c_int()
    left, right, bottom, top = (ctypes.c_double() for _ in range(4))
    fonts: dict[bytes, str] = {}
    lines: list[Line] = []
    for index in range(len(pdf)):
        page = pdf[index]
        textpage = page.get_textpage()
        count = textpage.count_chars()
        text = textpage.get_text_range(0, count)
        if len(text) != count:
            raise KJVError(f"page {index + 1}: PDFium returned {len(text)} characters for {count}")
        current: list[Glyph] = []
        previous_right = None
        i = 0
        while i < count:
            if text.startswith("\r\n", i):
                lines.append(Line(index + 1, current))
                current = []
                previous_right = None
                i += 2
                continue
            n = raw.FPDFText_GetFontInfo(textpage.raw, i, buf, 256, ctypes.byref(flags))
            font = ""
            if n:
                key = buf.value
                font = fonts.setdefault(key, key.decode("latin-1").split("+")[-1])
            size = round(raw.FPDFText_GetFontSize(textpage.raw, i), 1) if font else 0.0
            if font:
                raw.FPDFText_GetCharBox(textpage.raw, i, ctypes.byref(left), ctypes.byref(right),
                                        ctypes.byref(bottom), ctypes.byref(top))
                # PDFium does not always report a space between two italic
                # words; a gap of a fifth of an em between glyphs is one.
                if previous_right is not None and left.value - previous_right > SPACE_GAP * size:
                    current.append(Glyph(" ", "", 0.0, inferred=True))
                previous_right = right.value
            else:
                previous_right = None
            current.append(Glyph(text[i], font, size))
            i += 1
        if current:
            lines.append(Line(index + 1, current))
        textpage.close()
        page.close()
    pdf.close()
    for number, line in enumerate(lines, start=1):
        line.number = number
    return lines


def verse_number(line: Line) -> tuple[int, int] | None:
    """The verse number a line begins with (9 pt digits followed by 12 pt
    text), and the index of the first glyph after it."""
    i = 0
    digits = ""
    while i < len(line.glyphs) and line.glyphs[i].size == 9.0 and line.glyphs[i].char.isdigit() \
            and "Regular" in line.glyphs[i].font:
        digits += line.glyphs[i].char
        i += 1
    if not digits:
        return None
    j = i
    while j < len(line.glyphs) and not line.glyphs[j].font:
        j += 1
    if j < len(line.glyphs) and line.glyphs[j].size == 12.0:
        return int(digits), i
    return None


def classify(line: Line) -> str:
    glyphs = [g for g in line.glyphs if g.font and not g.char.isspace()]
    if not glyphs:
        return "blank"
    if all(g.size == 8.0 for g in glyphs):
        return "head"
    if all("ExtraBold" in g.font and g.size >= 15.9 for g in glyphs):
        return "chapter" if line.text.strip().isdigit() else "title"
    body = [g for g in glyphs if g.size == 12.0 and g.char not in MARKS]
    if body and verse_number(line):
        return "verse"
    if body and all(g.size in (12.0, 9.0) for g in glyphs) and not any("ExtraBold" in g.font for g in glyphs):
        if any(g.size == 9.0 and g.char not in MARKS for g in glyphs):
            return "mixed"
        return "text"
    return "note"


# MARK: Verses

@dataclass
class Verse:
    chapter: int
    verse: int
    lines: list[int] = field(default_factory=list)
    pages: list[int] = field(default_factory=list)
    segments: list = field(default_factory=list)  # [text, supplied]

    def add(self, glyphs: list[Glyph], line: Line) -> None:
        if line.number not in self.lines:
            self.lines.append(line.number)
        if line.page not in self.pages:
            self.pages.append(line.page)
        if self.segments:
            self._put(" ", self.segments[-1][1])
        for g in glyphs:
            if g.char in MARKS:
                continue
            if not g.font:
                self._put(" ", self.segments[-1][1] if self.segments else False)
            else:
                self._put(g.char, g.italic)

    def _put(self, text: str, supplied: bool) -> None:
        if self.segments and self.segments[-1][1] == supplied:
            self.segments[-1][0] += text
        else:
            self.segments.append([text, supplied])

    def tidy(self) -> None:
        # A space between two runs belongs to the plain text, not to the
        # supplied words (``darkness {was} upon``).
        segs = self.segments
        for k, seg in enumerate(segs):
            if seg[1]:
                while seg[0].startswith(" "):
                    seg[0] = seg[0][1:]
                    if k > 0:
                        segs[k - 1][0] += " "
                while seg[0].endswith(" "):
                    seg[0] = seg[0][:-1]
                    if k + 1 < len(segs):
                        segs[k + 1][0] = " " + segs[k + 1][0]
        for seg in segs:
            seg[0] = re.sub(r" {2,}", " ", seg[0])
        if segs:
            segs[0][0] = segs[0][0].lstrip()
            segs[-1][0] = segs[-1][0].rstrip()
        merged: list = []
        for seg in segs:
            if not seg[0]:
                continue
            if merged and merged[-1][1] == seg[1]:
                merged[-1][0] = re.sub(r" {2,}", " ", merged[-1][0] + seg[0])
            else:
                merged.append(seg)
        self.segments = merged


@dataclass
class Book:
    name: str
    verses: list[Verse] = field(default_factory=list)
    notes: int = 0
    outside: list = field(default_factory=list)  # (chapter, Line) of text before a chapter's first verse


def read_books(lines: list[Line]) -> tuple[dict[str, Book], list[tuple[str, str]]]:
    """Group the lines into books, chapters and verses."""
    books: dict[str, Book] = {}
    issues: list[tuple[str, str]] = []  # (book, issue)
    book: Book | None = None
    chapter = 0
    verse: Verse | None = None
    head_book: dict[int, str] = {}
    for line in lines:
        line.kind = classify(line)
        if line.kind == "head" and line.page not in head_book:
            # "Genesis 1:1 17 Genesis 1:21": the book of the page's last verse.
            # Single-chapter books give the verse alone ("Jude 1 1679 Jude 25").
            m = re.match(r"^.+? \d+(?::\d+)? \S+ (.+?) \d+(?::\d+)?\s*$", line.text)
            if m:
                head_book[line.page] = HEAD_NAMES.get(m.group(1), m.group(1))
    previous = ""
    for line in lines:
        kind = line.kind
        if kind == "title":
            if previous != "title":
                name = head_book.get(line.page)
                if name is None:
                    issues.append(("", f"line {line.number}: a title on a page without a running head"))
                    book = None
                else:
                    if name in books:
                        # A title within a book (the Epistle of Jeremy, Baruch 6).
                        book, verse = books[name], None
                        book.outside.append((chapter, line))
                    else:
                        book = books[name] = Book(name)
                        chapter, verse = 1, None
        elif kind == "chapter":
            chapter, verse = int(line.text.strip()), None
        elif kind == "verse" and book is not None:
            number, start = verse_number(line)
            verse = Verse(chapter, number)
            book.verses.append(verse)
            verse.add(line.glyphs[start:], line)
        elif kind in ("text", "mixed") and book is not None:
            if verse is None:
                # A heading or argument printed before the first verse (the
                # prologue of Ecclesiasticus), never part of a verse.
                book.outside.append((chapter, line))
            else:
                verse.add(line.glyphs, line)
                if kind == "mixed":
                    issues.append((book.name, f"line {line.number}: 9 pt text inside {book.name} {verse.chapter}:{verse.verse}"))
        elif kind == "note" and book is not None:
            if line.glyphs and line.glyphs[0].char in MARKS:
                book.notes += 1
        if kind not in ("blank", "head"):
            previous = kind
        if kind in ("verse", "text") and line.text.rstrip().endswith("-") and not line.text.rstrip().endswith("--"):
            issues.append((book.name if book else "", f"line {line.number}: ends with a hyphen"))
    for b in books.values():
        for v in b.verses:
            v.tidy()
    return books, issues


# MARK: Build

def _slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def build_kjv(meta: dict, lines: list[Line], books_path: Path = DATA / "books.json",
              counts_path: Path = DATA / "kjv-verse-counts.json",
              reviewed_path: Path = DATA / "kjv.json") -> tuple[dict[str, dict], dict]:
    """Generate the runtime content, {relative path: JSON}, and a report."""
    wanted = [b["book"] for b in json.loads(books_path.read_text(encoding="utf-8"))["books"]]
    counts = json.loads(counts_path.read_text(encoding="utf-8"))["books"]
    reviewed = json.loads(reviewed_path.read_text(encoding="utf-8"))
    missing_ok = {(m["book"], m["chapter"], m["verse"]) for m in reviewed.get("missingVerses", [])}
    review_notes = {(r["book"], r["chapter"], r["verse"]): r["note"] for r in reviewed.get("verseNotes", [])}
    for c in reviewed.get("verseCounts", []):
        # The witness divides a chapter differently from the edition the
        # counts come from.
        counts[c["book"]][c["chapter"] - 1] = c["verses"]

    books, issues = read_books(lines)
    problems: list[str] = []
    used_missing = set()
    out: dict[str, dict] = {}
    index = []
    report = {"books": len(wanted), "verses": 0, "supplied": 0, "footnoteLinesOmitted": 0, "missingVerses": []}
    for name in wanted:
        book = books.get(name)
        if book is None:
            problems.append(f"{name}: not in the witness")
            continue
        report["footnoteLinesOmitted"] += book.notes
        by_chapter: dict[int, dict[int, Verse]] = {}
        for v in book.verses:
            if v.verse in by_chapter.setdefault(v.chapter, {}):
                problems.append(f"{name} {v.chapter}:{v.verse} appears twice")
            if not v.segments:
                problems.append(f"{name} {v.chapter}:{v.verse} is empty")
            by_chapter[v.chapter][v.verse] = v
        expected = counts[name]
        if sorted(by_chapter) != list(range(1, len(expected) + 1)):
            problems.append(f"{name}: chapters {sorted(by_chapter)} where {len(expected)} are expected")
            continue
        chapters = []
        for n, count in enumerate(expected, start=1):
            verses = by_chapter[n]
            extra = sorted(set(verses) - set(range(1, count + 1)))
            if extra:
                problems.append(f"{name} {n}: verses {extra} beyond the expected {count}")
            missing = []
            for v in range(1, count + 1):
                if v in verses:
                    continue
                if (name, n, v) in missing_ok:
                    used_missing.add((name, n, v))
                    missing.append(v)
                    report["missingVerses"].append(f"{name} {n}:{v}")
                else:
                    problems.append(f"{name} {n}:{v} is missing from the witness and not reviewed")
            entries = []
            for k in sorted(verses):
                v = verses[k]
                report["supplied"] += sum(1 for _, s in v.segments if s)
                entry = {"verse": k,
                         "segments": [t if not s else {"supplied": t} for t, s in v.segments],
                         "lines": [min(v.lines), max(v.lines)],
                         "pages": sorted(v.pages)}
                if (name, n, k) in review_notes:
                    entry["review"] = review_notes[(name, n, k)]
                entries.append(entry)
            chapters.append({"chapter": n, "verseCount": count, "missing": missing, "verses": entries})
            report["verses"] += len(verses)
        path = f"books/{_slug(name)}.json"
        out[path] = {"schemaVersion": SCHEMA_VERSION, "book": name, "chapters": chapters}
        index.append({"book": name, "path": path, "chapters": len(chapters)})
    report["layoutIssues"] = [i for b, i in issues if b in wanted]
    if report["layoutIssues"]:
        problems += report["layoutIssues"]
    # Text outside the verses must be known: each block is listed in
    # data/kjv.json with its first words.
    expected_outside = {(o["book"], o["chapter"], o["begins"]): o["lines"] for o in reviewed.get("textOutsideVerses", [])}
    found_outside = {}
    for name in wanted:
        if name not in books:
            continue
        block_start, last = None, None
        for chapter, line in books[name].outside:
            if last is None or line.number != last + 1:
                block_start = (name, chapter, line.text.strip()[:40])
                found_outside[block_start] = 0
            found_outside[block_start] += 1
            last = line.number
    if found_outside != expected_outside:
        for key in sorted(set(found_outside) | set(expected_outside)):
            if found_outside.get(key) != expected_outside.get(key):
                problems.append(f"text outside the verses {key}: {found_outside.get(key)} lines found, "
                                f"{expected_outside.get(key)} reviewed")
    report["textOutsideVerses"] = len(found_outside)
    unused = missing_ok - used_missing
    if unused:
        problems.append(f"reviewed missing verses that the witness has: {sorted(unused)}")
    if problems:
        raise KJVError("The KJV witness does not match the expected verses:\n" + "\n".join(problems))
    out["index.json"] = {"schemaVersion": SCHEMA_VERSION, "books": index}
    return out, report


def _dump(path: Path, data) -> bytes:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, dict) and "chapters" in data and "book" in data:
        # A book: one verse per line, so diffs show verses.
        chapters = []
        for c in data["chapters"]:
            head = json.dumps({k: v for k, v in c.items() if k != "verses"}, ensure_ascii=False)[:-1]
            verses = ",\n".join("   " + json.dumps(v, ensure_ascii=False) for v in c["verses"])
            chapters.append(f'  {head}, "verses": [\n{verses}\n  ]}}')
        text = (f'{{"schemaVersion": {data["schemaVersion"]}, "book": {json.dumps(data["book"], ensure_ascii=False)}, '
                f'"chapters": [\n' + ",\n".join(chapters) + "\n]}\n")
        assert json.loads(text) == data
    else:
        text = json.dumps(data, ensure_ascii=False, indent=1) + "\n"
    raw = text.encode("utf-8")
    path.write_bytes(raw)
    return raw


TRANSCRIPTION_HEADER = 3


def write_package(witness_dir: Path, root: Path) -> dict:
    """Generate the LuxKJV package content under `root` from its witness."""
    meta = json.loads((witness_dir / "sources.json").read_text(encoding="utf-8"))["sources"][0]
    lines = read_pdf(witness_dir / meta["file"], meta["sha256"])
    # Transcription line numbers are file line numbers.
    for line in lines:
        line.number += TRANSCRIPTION_HEADER
    content, report = build_kjv(meta, lines)
    files = []
    for rel in sorted(content):
        raw = _dump(root / RUNTIME_DIR / rel, content[rel])
        files.append({"path": rel, "sha256": hashlib.sha256(raw).hexdigest()})
    _dump(root / RUNTIME_DIR / "manifest.json", {
        "schemaVersion": SCHEMA_VERSION,
        "tradition": "kjv",
        "contentVersion": "0.1.0",
        "title": meta["title"],
        "source": {"id": meta["id"], "file": meta["file"], "sha256": meta["sha256"]},
        "files": files,
    })
    prov = root / PROVENANCE_DIR
    prov.mkdir(parents=True, exist_ok=True)
    body = "\n".join(f"p{l.page:04d} {l.kind:<7} {l.marked()}" for l in lines)
    (prov / "transcription.txt").write_text(
        f"# Text lines of {meta['file']} (sha256 {meta['sha256']}) as read by PDFium, one per line.\n"
        "# Columns: PDF page, line kind (head, title, chapter, verse, text, mixed, note, blank), text; italic in {braces}.\n"
        "# Verse provenance in the content gives line numbers of this file.\n"
        + body + "\n", encoding="utf-8")
    report = {"schemaVersion": SCHEMA_VERSION, "source": meta["id"], **report}
    _dump(prov / "report.json", report)
    return report

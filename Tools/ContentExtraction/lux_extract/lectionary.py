"""The lectionary: the Kalendar's lessons, the Proper Lessons and Proper Psalms.

These tables are absent from the Baskerville text layer. They are read from
the TCP transcription of the 1693 London printing of the 1662 book (see
``tcp.py``), recorded in ``Witness/sources.json`` as a second witness.

Printed references are kept exactly as printed, and also resolved into a
structured reference. Two printing conventions are applied, each recorded in
``data/lectionary.json`` rather than in code:

* A cell giving only a number continues the book of the entry above it in
  the same column ("Gen. 1" then "3" is Genesis 3).
* "to v. 20" marks where a lesson stops; whether verse 20 is read is a
  reviewed decision (``toVerse``).

The Kalendar is printed as eight columns (golden number, day, dominical
letter, name of the day, and four lessons), but the TCP keys it as a single
stream of cells and drops some empty ones. Each day's cells are assigned to
columns by the continuity of the four courses of reading (each column reads
on from the chapter before). Every assignment that is not clear-cut, and
every cell the TCP could not read, must be settled by a reviewed entry in
``data/lectionary.json``; the build fails otherwise.
"""

from __future__ import annotations

import itertools
import json
import re
from dataclasses import dataclass
from pathlib import Path

from .tcp import Cell, Division

DATA = Path(__file__).resolve().parent.parent / "data"

MONTHS = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER",
          "NOVEMBER", "DECEMBER"]
DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
COLUMNS = ["morning.first", "morning.second", "evening.first", "evening.second"]


class LectionaryError(Exception):
    pass


# MARK: Books and references

class Books:
    def __init__(self, path: Path = DATA / "books.json"):
        table = json.loads(path.read_text(encoding="utf-8"))["books"]
        self.chapters = {b["book"]: b["chapters"] for b in table}
        self.course = {b["book"]: b["course"] for b in table}
        self.printed = {p: b["book"] for b in table for p in b["printed"]}
        # Longest printed forms first, so "1 Cor." wins over a bare number.
        self._forms = sorted(self.printed, key=len, reverse=True)

    def split(self, text: str) -> tuple[str | None, str]:
        """Split a cell into its printed book (if any) and the rest."""
        for form in self._forms:
            if text == form or text.startswith(form + " ") or (form.endswith(".") and text.startswith(form)):
                return form, text[len(form):].strip()
        return None, text


_V = r"(?:v\.|ver\.|verſ\.|verſe)"

# Shapes of the chapter-and-verse part of a printed reference, after the book.
# Each yields (chapter, verse, toChapter, toVerse); None where not printed.
_SHAPES: list[tuple[re.Pattern, callable]] = [
    (re.compile(r"^(\d+)\.?$"), lambda m: (int(m[1]), None, None, None)),
    # "17, 18": two whole chapters.
    (re.compile(r"^(\d+), ?(\d+)\.?$"), lambda m: (int(m[1]), None, int(m[2]), None)),
    # "1 to 39", "9 to verſ. 20", "Iſai. 9. to ver. 8.": from the start of the chapter.
    (re.compile(rf"^(\d+)[.,]? to (?:{_V} ?)?(\d+)[.,]?$"), lambda m: (int(m[1]), None, None, int(m[2]))),
    # "1. 39", "2. v. 22.", "10. v. 34.", "1.39": from a verse to the end of the chapter.
    (re.compile(rf"^(\d+)\.? ?(?:{_V} ?)?(\d+)\.?$"), lambda m: (int(m[1]), int(m[2]), None, None)),
    # "7. ver. 10. to ver. 17.", "11. v. 16. to v. 30.", "49.13" style ranges.
    (re.compile(rf"^(\d+)\.? (?:{_V} ?)?(\d+)\.? to (?:{_V} ?)?(\d+)\.?$"), lambda m: (int(m[1]), int(m[2]), None, int(m[3]))),
    # "6. verſ. 8. and ch. 7. to verſ. 30.": into the next chapter.
    (re.compile(rf"^(\d+)\.? {_V} ?(\d+)\.? and ch\. (\d+)\.? to {_V} ?(\d+)\.?$"),
     lambda m: (int(m[1]), int(m[2]), int(m[3]), int(m[4]))),
    # "11. v. 33. &c. 12. to v. 7.": the same, printed with "&c.".
    (re.compile(rf"^(\d+)\.? {_V} ?(\d+)\.? &c\. (\d+)\.? to {_V} ?(\d+)\.?$"),
     lambda m: (int(m[1]), int(m[2]), int(m[3]), int(m[4]))),
]
# Single-chapter books are printed without a chapter: "Philem.", "Jud. v. 6. to v. 16."
_SINGLE = [
    (re.compile(r"^$"), lambda m: (1, None, None, None)),
    (re.compile(rf"^{_V} ?(\d+)\.? to {_V} ?(\d+)\.?$"), lambda m: (1, int(m[1]), None, int(m[2]))),
]


@dataclass
class Reading:
    """A printed lesson reference and what it resolves to."""
    printed: str
    book: str
    chapter: int
    verse: int | None = None
    to_chapter: int | None = None
    to_verse: int | None = None  # the printed "to" verse, before the toVerse convention
    book_from: int | None = None  # XML line of the cell that names the book, when not this one
    notes: tuple[str, ...] = ()

    def last_chapter(self) -> int:
        return self.to_chapter or self.chapter


def parse_reading(text: str, books: Books, current: str | None) -> list[Reading] | None:
    """Resolve one printed cell. ``current`` is the book a bare number continues.

    Returns ``None`` when the cell is not a reference. "2, 3 John" (the second
    and third Epistles of St John, read together) yields two readings.
    """
    text = text.strip()
    if text in ("2, 3 John", "2, 3 John."):
        return [Reading(text, "2 John", 1), Reading(text, "3 John", 1)]
    form, rest = books.split(text)
    if form is None:
        if current is None:
            return None
        book, inherited = current, True
    else:
        book, inherited = books.printed[form], False
    shapes = _SHAPES + (_SINGLE if books.chapters[book] == 1 else [])
    for pattern, make in shapes:
        m = pattern.match(rest)
        if m:
            chapter, verse, to_chapter, to_verse = make(m)
            if chapter > books.chapters[book] or (to_chapter or 0) > books.chapters[book]:
                return None
            reading = Reading(text, book, chapter, verse, to_chapter, to_verse)
            reading.book_from = -1 if inherited else None
            return [reading]
    return None


# MARK: Kalendar

def dominical_letter(month: int, day: int) -> str:
    """The Kalendar's dominical letter: A on 1 January, then b to g, repeating."""
    if month == 2 and day == 29:
        return ""
    doy = sum(DAYS_IN_MONTH[: month - 1]) + day
    return "Abcdefg"[(doy - 1) % 7]


@dataclass
class DayCells:
    month: int
    day: int
    anchor: Cell
    body: list[Cell]  # cells after the dominical letter, up to the next day's day number


def kalendar_days(calendar: Division, issues: list[dict]) -> list[DayCells]:
    """Split each month's cell stream into days, anchored on day number and letter."""
    if len(calendar.tables) != 12:
        raise LectionaryError(f"expected 12 months in the Kalendar, found {len(calendar.tables)}")
    days: list[DayCells] = []
    for month, table in enumerate(calendar.tables, start=1):
        if not table.head.upper().startswith(MONTHS[month - 1]):
            raise LectionaryError(f"Kalendar table {month} is headed {table.head!r}")
        cells = table.cells
        # The column heads end with the fourth "Leſſon" cell.
        heads = [i for i, c in enumerate(cells) if c.text.endswith("Leſſon")]
        if len(heads) != 4:
            raise LectionaryError(f"{MONTHS[month - 1]}: column heads not found")
        i = heads[-1] + 1
        count = DAYS_IN_MONTH[month - 1] + (1 if month == 2 else 0)
        anchors = []
        for day in range(1, count + 1):
            letter = dominical_letter(month, day)
            j = i
            while j < len(cells) and not (cells[j].text == str(day) and j + 1 < len(cells)
                                          and cells[j + 1].text == letter):
                j += 1
            if j >= len(cells):
                # The day number may be missing from the TCP: take the first
                # empty cell followed by the expected letter, and report it.
                j = i
                while j < len(cells) and not (cells[j].text == "" and j + 1 < len(cells)
                                              and cells[j + 1].text == letter):
                    j += 1
                if j >= len(cells):
                    raise LectionaryError(f"{MONTHS[month - 1]} {day}: day not found in the Kalendar")
                issues.append({"key": f"{month:02d}-{day:02d}", "kind": "kalendar-day-number-missing",
                               "xmlLine": cells[j].line})
            anchors.append(j)
            i = j + 2
        for n, a in enumerate(anchors):
            end = anchors[n + 1] if n + 1 < len(anchors) else len(cells)
            days.append(DayCells(month, n + 1, cells[a], cells[a + 2:end]))
    return days


@dataclass
class Assignment:
    cost: float
    slots: dict[str, int]  # slot name -> index into body; lessons named by COLUMNS


# The Old Testament is read through at Morning and Evening Prayer as one
# course; the second lessons at Morning Prayer (the Gospels and Acts) and at
# Evening Prayer (the Epistles) are each a course of their own.
COURSE_OF = {"morning.first": "old", "evening.first": "old", "morning.second": "gospels", "evening.second": "epistles"}


class Courses:
    """Where each course of reading has reached, and the book each printed column last named."""

    def __init__(self):
        self.course: dict[str, Reading] = {}  # course -> last reading
        self.column: dict[str, tuple[str, int]] = {}  # column -> (book last printed in it, XML line)

    def copy(self) -> "Courses":
        c = Courses()
        c.course, c.column = dict(self.course), dict(self.column)
        return c

    def book_above(self, column: str) -> str | None:
        return self.column[column][0] if column in self.column else None

    def read(self, column: str, cell: Cell, books: Books) -> list[Reading] | None:
        """Resolve a lesson cell in its column (a bare number continues the book above)."""
        readings = parse_reading(cell.text, books, self.book_above(column))
        if readings is None:
            return None
        for r in readings:
            if r.book_from == -1:
                r.book_from = self.column[column][1]
        return readings

    def cost(self, column: str, readings: list[Reading], books: Books) -> float:
        """How well a reading continues its course. 0 is the expected next chapter."""
        reading = readings[0]
        if books.course[reading.book] != COURSE_OF[column]:
            return 30.0  # a book that is not read in this column's course
        prev = self.course.get(COURSE_OF[column])
        if prev is None:
            return 1.0
        if reading.book != prev.book:
            if reading.book_from is not None:
                return 8.0  # a bare number continuing a different book from the course
            return 1.0 if reading.chapter == 1 else 2.0
        nxt = prev.last_chapter() + 1
        if reading.chapter == nxt:
            return 0.0
        if reading.chapter == prev.last_chapter() and reading.verse is not None:
            return 0.0  # the rest of a chapter divided between two days
        if reading.chapter > nxt:
            return 1.0 + min(reading.chapter - nxt, 20) / 20  # chapters passed over
        return 8.0

    def advance(self, column: str, cell: Cell, readings: list[Reading]) -> None:
        self.course[COURSE_OF[column]] = readings[-1]
        if readings[0].book_from is None:
            self.column[column] = (readings[-1].book, cell.line)


def assign_day(day: DayCells, courses: Courses, books: Books) -> list[Assignment]:
    """Every way to read the day's cells as [name] [four lessons] [next golden number], best first."""
    body = day.body
    slots = ["name"] + COLUMNS + ["golden"]
    results: list[Assignment] = []
    # Choose which slots are present (the TCP drops some empty cells), in order.
    for present in itertools.product([True, False], repeat=len(slots)):
        used = [s for s, p in zip(slots, present) if p]
        if len(used) != len(body):
            continue
        state = courses.copy()
        cost = 0.0
        ok = True
        for slot, cell in zip(used, body):
            text = cell.text
            if slot == "name":
                if text and parse_reading(text, books, None):
                    cost += 4.0  # a reference read as the name of the day
                elif re.fullmatch(r"\d+", text):
                    ok = False
                    break
            elif slot == "golden":
                if text and not (re.fullmatch(r"\d+", text) and 1 <= int(text) <= 19):
                    ok = False
                    break
                cost += 0.25
            elif not text:
                cost += 3.0  # a blank lesson (a holy day with proper lessons)
            else:
                readings = state.read(slot, cell, books)
                if readings is None:
                    ok = False
                    break
                cost += state.cost(slot, readings, books)
                state.advance(slot, cell, readings)
        if not ok:
            continue
        for slot, p in zip(slots, present):
            if not p:
                cost += 0.5 if slot in ("name", "golden") else 3.0
        results.append(Assignment(cost, {s: i for i, s in enumerate(used)}))
    results.sort(key=lambda a: a.cost)
    return results


# MARK: Building the lectionary content

ROMAN = {"i": 1, "v": 5, "x": 10, "l": 50, "c": 100}


def roman(numeral: str) -> int:
    """A lower-case Roman numeral as printed, with the final j for i ("cxviij")."""
    s = numeral.lower().replace("j", "i")
    if not s or any(ch not in ROMAN for ch in s):
        raise LectionaryError(f"not a Roman numeral: {numeral!r}")
    total = 0
    for a, b in zip(s, s[1:] + " "):
        v = ROMAN[a]
        total += -v if b != " " and ROMAN.get(b, 0) > v else v
    return total


def parse_psalms(text: str) -> list[int]:
    """"Pſal. xix. xlv. lxxxv." -> [19, 45, 85]."""
    body = text.removeprefix("Pſal.").strip()
    return [roman(n) for n in body.rstrip(".").split(". ")]


_ONLY_TO = re.compile(r"^(?:Note, That )?(.+?)\.? (\d+)\.? (?:is to be read )?only to verſe (\d+)")


class Builder:
    """Turns TCP cells into lessons.json, collecting what needs review."""

    def __init__(self, source_id: str, decisions: dict, books: Books):
        self.source_id = source_id
        self.decisions = decisions
        self.books = books
        self.exclusive = decisions["conventions"]["toVerse"]["decision"] == "exclusive"
        self.review: list[dict] = []
        self.used_cells: set[str] = set()

    def reference(self, r: Reading) -> dict:
        ref = {"book": r.book, "startChapter": r.chapter}
        end_verse = r.to_verse
        if end_verse is not None and self.exclusive:
            end_verse -= 1
        if r.verse is not None:
            ref["startVerse"] = r.verse
        elif end_verse is not None:
            ref["startVerse"] = 1
        if r.to_chapter is not None:
            ref["endChapter"] = r.to_chapter
        if end_verse is not None:
            ref["endVerse"] = end_verse
        return ref

    def lesson(self, cell: Cell, readings: list[Reading], *, read: str | None = None, editorial: list[str] | None = None,
               review: str | None = None) -> dict:
        editorial = list(editorial or [])
        if readings[0].book_from is not None:
            editorial.append(f"Book named in the cell above (XML line {readings[0].book_from}), as the table is set.")
        notes = []
        for note in cell.notes:
            notes.append(note)
            m = _ONLY_TO.match(note)
            if not m:
                raise LectionaryError(f"unrecognised footnote at XML line {cell.line}: {note!r}")
            name = m[1].rstrip(".")
            book = name if name in self.books.chapters else (self.books.printed.get(name) or self.books.printed.get(name + "."))
            r = readings[0]
            if book != r.book or int(m[2]) != r.chapter:
                raise LectionaryError(f"footnote at XML line {cell.line} names {m[1]} {m[2]}, not the cell's reading")
            r.to_verse = int(m[3])
            editorial.append(f"The footnote limits the lesson: “{note}”")
        preserved = self.decisions.get("readingsPreserved", {}).get(str(cell.line))
        if preserved:
            review = review or "reading-preserved"
            editorial.append(preserved["note"])
        out = {"printed": cell.text, "references": [self.reference(r) for r in readings],
               "provenance": {"xmlLine": cell.line, "page": cell.page}}
        if read is not None and read != cell.text:
            out["provenance"]["readAs"] = read
        if notes:
            out["footnotes"] = notes
        if review:
            out["provenance"]["review"] = review
        if editorial:
            out["provenance"]["editorial"] = editorial
        return out

    # Kalendar

    def kalendar(self, calendar: Division) -> list[dict]:
        issues: list[dict] = []
        days = kalendar_days(calendar, issues)
        accepted = self.decisions.get("kalendarDays", {})
        for issue in issues:
            entry = accepted.get(issue["key"])
            if not entry or entry.get("issue") != issue["kind"]:
                raise LectionaryError(f"Kalendar {issue['key']}: {issue['kind']} at XML line {issue['xmlLine']} "
                                      "needs a reviewed entry in data/lectionary.json")
            self.review.append({"area": "lectionary", "kind": issue["kind"], "day": issue["key"],
                                "xmlLine": issue["xmlLine"], "note": entry["note"]})
        corrections = self.decisions.get("kalendarCells", {})
        courses = Courses()
        out = []
        for day in days:
            key = f"{day.month:02d}-{day.day:02d}"
            originals = {}
            for cell in day.body:
                fix = corrections.get(str(cell.line))
                if fix:
                    if fix["text"] != cell.text:
                        raise LectionaryError(f"data/lectionary.json expects {fix['text']!r} at XML line {cell.line}, "
                                              f"the witness has {cell.text!r}")
                    originals[cell.line] = cell.text
                    cell.text = fix["reading"]
                    self.used_cells.add(str(cell.line))
                elif cell.gaps:
                    raise LectionaryError(f"Kalendar {key}: illegible cell at XML line {cell.line} needs a reviewed "
                                          "entry in data/lectionary.json")
            options = assign_day(day, courses, self.books)
            if not options:
                raise LectionaryError(f"Kalendar {key}: the cells {[c.text for c in day.body]} cannot be read as "
                                      "four lessons; add a reviewed entry to data/lectionary.json")
            best = options[0]
            if len(options) > 1 and options[1].cost - best.cost < 1.0:
                raise LectionaryError(f"Kalendar {key}: the cells {[c.text for c in day.body]} can be read more "
                                      "than one way; add a reviewed entry to data/lectionary.json")
            entry = {"month": day.month, "day": day.day, "provenance": {"xmlLine": day.anchor.line, "page": day.anchor.page}}
            if "name" in best.slots and day.body[best.slots["name"]].text:
                entry["printedName"] = day.body[best.slots["name"]].text
            for column in COLUMNS:
                office, which = column.split(".")
                cell = day.body[best.slots[column]] if column in best.slots else None
                slot = entry.setdefault(office, {})
                if cell is None or not cell.text:
                    slot[which] = None
                    continue
                readings = courses.read(column, cell, self.books)
                cost = courses.cost(column, readings, self.books)
                courses.advance(column, cell, readings)
                if cell.line in originals:
                    fix = corrections[str(cell.line)]
                    printed = Cell(cell.line, cell.page, originals[cell.line], cell.notes, cell.gaps)
                    lesson = self.lesson(printed, readings, read=fix["reading"], review="tcp-reading-corrected",
                                         editorial=[fix["note"]])
                    self.review.append({"area": "lectionary", "kind": "tcp-reading-corrected", "day": key,
                                        "xmlLine": cell.line, "printed": originals[cell.line], "readAs": fix["reading"]})
                else:
                    lesson = self.lesson(cell, readings)
                if cost >= 8:
                    raise LectionaryError(f"Kalendar {key} {column}: {cell.text!r} breaks the course of reading")
                slot[which] = lesson
            out.append(entry)
        unused = set(corrections) - self.used_cells
        if unused:
            raise LectionaryError(f"data/lectionary.json corrects cells not in the Kalendar: {sorted(unused)}")
        return out

    # Proper Lessons and Psalms

    def propers(self, table_map: dict, division: Division) -> dict:
        cells = {c.line: c for t in division.tables for c in t.cells}

        def locate(entry: dict) -> Cell:
            cell = cells.get(entry["line"])
            if cell is None or cell.text != entry["text"]:
                raise LectionaryError(f"maps/proper_lessons.json: XML line {entry['line']} does not hold "
                                      f"{entry['text']!r} (found {cell.text if cell else None!r})")
            return cell

        def rows(section: str) -> list[dict]:
            above: dict[str, tuple[str, int]] = {}  # physical column (morning/evening) -> book, line
            out = []
            for row in table_map[section]["rows"]:
                locate(row["label"])
                entry = {"observance": row["observance"], "label": row["label"]["text"],
                         "provenance": {"xmlLine": row["label"]["line"], "page": cells[row["label"]["line"]].page}}
                for office in ("morning", "evening"):
                    slot = {}
                    for which in ("first", "second"):
                        if which not in row[office]:
                            continue
                        ref = row[office][which]
                        if ref is None:
                            slot[which] = None
                            continue
                        cell = locate(ref)
                        text = ref.get("read", cell.text)
                        book_above = above.get(office, (None, None))
                        readings = parse_reading(text, self.books, book_above[0])
                        if readings is None:
                            raise LectionaryError(f"Proper Lessons: cannot read {text!r} at XML line {cell.line}")
                        if readings[0].book_from == -1:
                            readings[0].book_from = book_above[1]
                        else:
                            above[office] = (readings[-1].book, cell.line)
                        editorial = []
                        if "read" in ref:
                            editorial.append(f"The TCP keys the row label and this lesson in one cell ({cell.text!r}).")
                        slot[which] = self.lesson(cell, readings, read=ref.get("read"), editorial=editorial)
                    entry[office] = slot
                out.append(entry)
            return out

        psalms = []
        for row in table_map["properPsalms"]["rows"]:
            locate(row["label"])
            entry = {"observance": row["observance"], "label": row["label"]["text"]}
            for office in ("morning", "evening"):
                cell = locate(row[office])
                entry[office] = {"printed": cell.text, "psalms": parse_psalms(cell.text),
                                 "provenance": {"xmlLine": cell.line, "page": cell.page}}
                preserved = self.decisions.get("readingsPreserved", {}).get(str(cell.line))
                if preserved:
                    entry[office]["provenance"].update({"review": "reading-preserved", "editorial": [preserved["note"]]})
            psalms.append(entry)
        return {"sundays": rows("sundays"), "holyDays": rows("holyDays"), "properPsalms": psalms}


def build_lectionary(source: dict, witness: Path, maps: Path) -> tuple[dict, list[dict]]:
    """The lectionary content and its review items."""
    from .tcp import load_divisions

    decisions = json.loads((DATA / "lectionary.json").read_text(encoding="utf-8"))
    divisions = load_divisions(witness, source["sha256"], {"order_of_lessons", "calendar"})
    table_map = json.loads((maps / "proper_lessons.json").read_text(encoding="utf-8"))
    if table_map["source"] != source["id"]:
        raise LectionaryError("maps/proper_lessons.json was generated from a different source")
    builder = Builder(source["id"], decisions, Books())
    kalendar = builder.kalendar(divisions["calendar"])
    propers = builder.propers(table_map, divisions["order_of_lessons"])
    cells = {c.line: c for d in divisions.values() for t in d.tables for c in t.cells}
    for line, entry in sorted(decisions.get("readingsPreserved", {}).items()):
        cell = cells.get(int(line))
        if cell is None or cell.text != entry["text"]:
            raise LectionaryError(f"data/lectionary.json: XML line {line} does not hold {entry['text']!r}")
        builder.review.append({"area": "lectionary", "kind": "reading-preserved", "xmlLine": int(line),
                               "text": entry["text"], "note": entry["note"]})
    conventions = {k: {"decision": v["decision"], "note": v["note"]} for k, v in decisions["conventions"].items()}
    content = {
        "source": source["id"],
        "conventions": conventions,
        "kalendar": kalendar,
        **propers,
    }
    return content, builder.review

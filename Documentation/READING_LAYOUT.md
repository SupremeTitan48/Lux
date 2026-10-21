# Reading Layout

How the reader sets the text of the lessons. Layout never changes the text:
the words, their order, the italic of supplied words and the edition's
paragraph marks are as the Scripture package gives them.

## Prose and verse

`ScriptureForm.of(book:)` in LuxCore classes each book.

- **Verse**, one line to each verse: Job, Psalms, Proverbs, Ecclesiastes and
  the Song of Solomon, the poetical books as the English Bible has grouped
  them since the sixteenth century; and Wisdom and Ecclesiasticus, the wisdom
  books of the Apocrypha, written in the same parallel lines.
- **Prose**, in paragraphs: every other book.

The class is the book's, not a verse's. Prophets and other books contain
poetry, but the King James Version sets them as prose verses and gives no
line structure to follow, so Lux sets them as prose. Lamentations is left
with the prophets, where the English Bible places it. A finer division (by
passage) would need a source for the line structure, and would be recorded
here.

## Paragraphs

A paragraph begins at the start of the reading, at every verse the edition
opens with ¶, and at every new chapter (`ScripturePassage.paragraphs`). In the
King James Version the ¶ marks stop after Acts 20, so later chapters of the
New Testament read as one paragraph each; Lux does not add paragraph breaks of
its own.

When the ¶ opens a paragraph, the paragraph itself shows it, so the mark is
not printed (`ScriptureVerse.segmentsWithoutParagraphMark`). Verse numbers are
not shown. Both come back with **Verse numbers in the lessons** in settings.

The Psalter of the offices (Coverdale's, from the prayer book) is not a
lesson and keeps its verse numbers and pointing.

## Reading style

Typeface, size and line spacing are set in settings (`ReadingStyle` in
LuxDesignSystem) and apply to the text of the office, not to the interface.
The typefaces are those installed with the operating system (New York,
Baskerville, Georgia, Iowan Old Style, Palatino, Hoefler Text, San
Francisco); Lux bundles no font files for them, and a face a device lacks is
not offered. The size multiplies the system text size, so Dynamic Type still
applies.

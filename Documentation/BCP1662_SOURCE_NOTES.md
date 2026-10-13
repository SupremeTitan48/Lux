# Lux — 1662 BCP Source Notes

## Status of This Document

These are working editorial and engineering notes for the first Lux tradition package. They record the source identity and concerns established during project planning. They are not a completed critical apparatus, and they must be checked against the actual source file before being treated as definitive.

## Working Primary Source

The planned primary source is the 1662 *Book of Common Prayer* as printed by John Baskerville at Cambridge in 1762, in a PDF reproduction attributed in the earlier project notes to Satucket Software.

The earlier notes described the reproduction as 339 PDF pages. Because the PDF was not available while this knowledge package was assembled, verify all of the following from the file itself:

- Exact title-page wording, imprint, and edition identity.
- Reproduction creator and any introductory header.
- PDF page count and the relationship between PDF and printed page numbers.
- Copyright, permission, attribution, and redistribution language.
- Whether the PDF contains a usable text layer or consists principally of page images.

Record the file name and a cryptographic checksum after the source is placed in the repository. The checksum prevents later work from unknowingly relying on a different scan or revision.

## Authority and Scope

Treat the verified PDF as the primary working witness for the initial BCP1662 package. Preserve its historical wording and structure. Where a rule or text cannot be established from this witness alone, consult appropriate authoritative sources and record the additional source rather than guessing.

The application should distinguish among:

1. Text and rubrics present in the historical source.
2. Editorial normalization made for machine processing or contemporary legibility.
3. Corrections supported by another identified authority.
4. Optional contemporary adaptations.

These categories must not be merged silently.

## Source Preservation

Preserve, as source data or traceable structure:

- Original wording, spelling, punctuation, and capitalization.
- Prayer and service divisions.
- Rubrical instructions and their relationship to spoken text.
- Speaker roles and congregational responses.
- Psalm verse and half-verse structure.
- Canticle structure.
- Calendar and lectionary assignments.
- Historical prayers and observances.
- PDF page and printed-page references where both exist.

The reading UI may normalize display according to an explicit editorial policy, but the project should retain a diplomatic or minimally processed transcription from which that presentation can be audited.

## Extraction Model

A direct PDF-to-text conversion is not sufficient evidence of a correct transcription. Historical print and scanned pages may contain:

- Long-s forms and historical ligatures.
- Drop capitals, small capitals, and ornaments.
- Irregular spacing and line breaking.
- Multi-column tables and calendars.
- Running headers, catchwords, signatures, and marginal matter.
- OCR confusion among letters, numerals, punctuation, and abbreviations.
- Page-image skew, bleed-through, or damaged type.

Maintain three separate stages:

```text
source scan and raw extraction
            ↓
reviewed, normalized transcription
            ↓
structured liturgical content and rules
```

Each transformation should be repeatable. Preserve raw OCR or extraction artifacts; never overwrite them with corrections. Store editorial changes in a machine-readable log or version history with source location and rationale.

## Transcription Policy

Before large-scale transcription, write and approve a policy covering:

- Expansion or preservation of ligatures.
- Treatment of the long s.
- Spelling and capitalization.
- Punctuation and quotation marks.
- Italics, small capitals, and display capitals.
- Hyphenation caused by line endings.
- Whitespace and paragraph boundaries.
- Biblical references and abbreviations.
- Obvious typographical errors in the witness.
- Illegible or uncertain characters.

The default should preserve wording while normalizing characters required for reliable search, layout, and accessibility. Any modern-spelling view should be a separate, optional transformation rather than a replacement for the source transcription.

## Provenance Requirements

Every structured liturgical unit should be able to point back to its source. A provenance record should include, where applicable:

- Source ID and edition.
- PDF page index.
- Printed page, section, table, or service heading.
- Bounding region or image reference for difficult pages.
- Raw-extraction version.
- Transcription revision.
- Editorial notes and confidence.
- Reviewer and review status.

Generated offices should preserve the IDs of the source units and rules that selected them.

## Calendar and Tables

Calendar tables require manual and automated verification because column extraction frequently fails. Model the calendar as rules and structured observances, not as screenshots or loosely parsed prose.

Test at least:

- Fixed and movable observances.
- Sundays relative to Easter and other movable dates.
- Leap years and late or early Easter boundaries.
- Coinciding observances and precedence decisions.
- Any vigils, octaves, transfers, or commemorations actually required by the source.
- The effect of historical civil-calendar assumptions, if relevant to dates represented by the application.

Do not infer a complete precedence system from modern Anglican practice without documenting the authority used.

## Monthly Psalter

The 1662 tradition appoints a monthly Psalter cycle, divided between Morning and Evening Prayer. The data model and tests should cover:

- Assignments for every day of the month.
- February and months shorter than 31 days.
- The final day or days of 31-day months.
- The divisions of Psalm 119.
- Proper Psalms that replace ordinary daily assignments.
- Any title, verse, and half-verse conventions needed to reproduce the Coverdale Psalter faithfully.

Preserve the Coverdale wording used by the source. Do not substitute a modern Psalter merely because it is easier to license or parse.

## Lectionary

Transcribe the appointed lessons as canonical references before resolving them to Bible text. Verify:

- Morning and Evening Prayer assignments.
- Ordinary calendar lessons.
- Proper lessons for Sundays and holy days.
- Movable observances and substitutions.
- Alternate or repeated readings, where the source provides them.
- Historical book names, chapter conventions, and verse-range assumptions.

The lectionary dataset should identify the exact source location for each assignment. Scripture text requires a separately licensed edition; a reference in the prayer book does not grant permission to redistribute a Bible translation.

## Morning and Evening Prayer

Implement the offices from their complete texts and rubrics, preserving:

- Service order.
- Minister, clerk, and people roles.
- Opening sentences and seasonal conditions.
- Exhortation, confession, absolution, and alternatives where present.
- Psalms, lessons, canticles, creed, suffrages, collects, and concluding prayers.
- Calendar-dependent selections and lawful omissions or substitutions.

Model alternatives explicitly. The composer should know why a form was chosen and should be able to expose the governing rubric in diagnostics or provenance.

## Historical and Royal Material

The 1762 witness may contain royal prayers, state services, names, political assumptions, and observances belonging to its historical setting. Do not silently replace or omit them in the source package.

A contemporary profile may eventually offer adaptations, but each adaptation must be:

- Clearly named and optional.
- Stored separately from the historical transcription.
- Supported by an identified authority or transparent editorial rationale.
- Visible in provenance and acknowledgements.

## Licensing and Redistribution

Do not infer present-day redistribution rights solely from the age of the underlying 1662 text or the 1762 printing. The scan, transcription, editorial material, fonts, Bible editions, and software are separate works with potentially different terms.

The earlier planning notes reported that the PDF allowed no-fee electronic redistribution provided its header remained intact. This statement must be verified verbatim against the actual PDF before the file is redistributed or committed. Record the result in a repository license inventory.

At minimum, verify and document rights for:

- The PDF reproduction.
- Raw and corrected transcriptions.
- Liturgical data and editorial annotations.
- Scripture translations.
- Typeface files.
- Icons, ornaments, and images.
- Modern adaptations.

## Verification Workflow

Use both automated and human review:

1. Inventory and checksum the source.
2. Extract text and page images reproducibly.
3. Segment services, tables, and Psalms.
4. Review a representative sample and refine extraction rules.
5. Transcribe and normalize under the written policy.
6. Validate structure, references, IDs, and provenance.
7. Double-review high-risk tables and rubrics.
8. Compare composed offices with hand-assembled offices on representative dates.
9. Record uncertainties rather than substituting plausible text.

High-risk material includes calendars, lectionary tables, proper lessons and Psalms, cross-references, small type, multi-column pages, and text obscured by scan quality.

## Minimum Acceptance Criteria for the BCP1662 Package

The package is not complete until:

- The source identity and rights have been verified.
- Morning and Evening Prayer texts and rubrics have been reviewed.
- The full Psalter required by the offices is present and validated.
- Calendar, lectionary, and substitution rules have test coverage.
- Representative ordinary, Sunday, holy-day, leap-year, and boundary-date offices match reviewed expectations.
- Every generated section has usable provenance.
- Known ambiguities are documented and surfaced appropriately.


---

## Findings from the Supplied Source (recorded 2026-10-13)

This section records what was established from the file actually supplied,
superseding the provisional statements above where they differ.

### What was supplied

Jackson uploaded `the-book-of-common-prayer-1662.pdf.txt` to the project on
2026-10-13: the **text layer** of the Satucket Software PDF, not the PDF
itself. It is committed unchanged as
`Traditions/BCP1662/Witness/bcp1662-baskerville1762.txt`.

- SHA-256 `b14a04a52f638571c748b091f4f02b8f8339112203ee6d39b4010dd46a0ecee5`, 976,467 bytes.
- UTF-8, CRLF line endings. Lines ending in a bare LF mark PDF page
  boundaries: there are **339 pages**, matching the earlier notes. Page
  numbers in Lux provenance are these extraction pages. They have not yet
  been checked against PDF page indices or printed page numbers, because the
  PDF is not available.
- The header identifies the witness as the 1662 book "as printed by John
  Baskerville" (Cambridge, 1762; Griffiths 1762/4, Gaskell 19) and states,
  verbatim: "You may redistribute this document electronically provided no
  fee is charged and this header remains part of the document." The header
  is intact in the committed file. Whether this permits redistribution in an
  app (and whether "no fee" constrains a paid app) is a decision recorded in
  `LICENSES.md`.

### Extraction artifacts found

| Artifact | Handling |
| --- | --- |
| U+0002 soft hyphen | removed |
| Private-use ligatures: U+E000 = ct, U+E002 = st | expanded |
| U+E001: ct in roman, st in italic | resolved per word from the reviewed table `data/ligatures.json` |
| Line break before nearly every ſ and around ligature glyphs, splitting words | lines joined; the reviewed table `data/joins.json` decides whether a space belongs at each join |
| Two book pages per PDF page; on some pages (Evening Prayer, the Athanasian Creed) lines of the two pages are interleaved | reading order reconstructed in map files; every such unit is marked `review: reading-order-reconstructed` |
| Drop capitals removed from the text, collected on an orphan line at the end of each book page | restored by pairing each page's opening sites with its orphan letters; unpaired sites use the reviewed table `data/dropcaps.json` |
| Small capitals letter-spaced after a drop capital ("L M I G H T Y") | closed up |
| Running heads in the text flow | detected and removed; unflagged ones are listed in the review queue |
| Word spaces lost on some pages | restored from the reviewed table `data/spaces.json` |

### Missing from the supplied text

The **Calendar with the Table of Lessons, the Tables of Proper Lessons and
Proper Psalms, the Tables and Rules for the Moveable Feasts, and the Table
of Vigils** are not in the text layer (the contents page lists them). They
are presumably tables the extractor could not read. Consequences:

- Lessons cannot be appointed. Offices show a placeholder and a diagnostic.
- On days with Proper Psalms, the psalms are a placeholder (the ordinary
  course is never substituted, per the rubric).
- Fixed holy-day dates, the rules for Advent Sunday and the movable feasts,
  St Matthias in leap years, and which holy days have eves are encoded
  editorially in `BCP1662Calendar` and reported as such, pending the PDF.

### Readings preserved as printed

These are reported in the review queue and not corrected: "In Quires an
Places", "who has made all men" (Good Friday, third collect), "relfect",
"throug-out", "Te Deum Laudamuſ", "EasterDay" in the Venite rubric, and
"Moveable Feats".

### Rules the composer takes from the source

Each is cited in code at the point it is applied: the monthly course and the
31st-day rule; Psalm 119 in portions; the Gloria after every psalm; Venite
omitted on Easter Day (Easter anthems instead) and on the 19th; Cantate not
on the 19th, Deus misereatur not on the 12th; Jubilate on St John Baptist's
Day; the Athanasian Creed on the thirteen named feasts; the Sunday collect
serving the week; the eve rule; the Advent, Lent, Nativity and Circumcision
collect rubrics; the rubric on surplus or missing Sundays after Trinity.

Where the source is silent (a holy day on a Sunday; which omitted Epiphany
Sundays fill extra Sundays after Trinity; the collect between the Epiphany
and its first Sunday), Lux either offers the alternatives or states its
editorial choice in a diagnostic.

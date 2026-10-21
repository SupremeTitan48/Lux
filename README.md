# Lux

Lux is an open-source app for praying the daily offices, built natively for
Apple platforms. Its first tradition is the **1662 Book of Common Prayer**,
taken from John Baskerville's Cambridge printing of 1762.

Lux composes Morning and Evening Prayer for any date from the texts and
rubrics of the book itself, and can show where every line came from.

## Status

This is the foundation. What works today, and is tested on Linux:

- **Source pipeline** (`Tools/ContentExtraction`): turns the supplied text
  extraction of the 1762 printing into structured, provenance-carrying
  content, with reviewed decision tables for every ambiguous artifact.
- **Content** (`Traditions/BCP1662`): the Psalter (150 Psalms, pointed, with
  the thirty-day course), Morning and Evening Prayer, the Creed of St
  Athanasius, the Easter anthems, the collects of all 86 observances with
  their governing rubrics, and the general rubrics for reading the Psalter.
- **Liturgical core** (`Packages/LuxCore`): dates, the Gregorian computus,
  the typed service document, provenance, diagnostics, and the tradition and
  Scripture-provider contracts. No UI dependencies.
- **1662 engine** (`Traditions/BCP1662`): the calendar of Sundays and holy
  days, collect selection (including the Advent, Lent, Christmas,
  Circumcision and eve rules), Psalter assignment, and the canticle, creed
  and invitatory rules, with golden tests of complete offices.
- **Lessons** with their text from the King James Version
  (`Scripture/KJV`, from eBible.org's edition of the standardized text of
  1769 with the Apocrypha), supplied words in italic.
- **Design tokens** (`Packages/LuxDesignSystem`).

Not yet done (see [Documentation/ROADMAP.md](Documentation/ROADMAP.md)):

- **Comparing the lectionary with the Baskerville pages.** The Kalendar,
  Proper Lessons and Proper Psalms come from the 1693 printing until the
  Baskerville PDF is available.
- **The apps** (`Apps/Lux`): SwiftUI sources for iPhone, iPad, Mac, Apple
  Watch and Vision Pro are written but have **not been built or seen**:
  they were written without Xcode. CI builds them on macOS.

## Repository

```text
Packages/LuxCore            platform-independent liturgical core
Packages/LuxDesignSystem    design tokens and SwiftUI bindings
Traditions/BCP1662          the 1662 tradition package
Scripture/KJV               the King James Version as a Scripture provider
  Witness/                  the source witness, unchanged, with its checksum
  Sources/BCP1662/          calendar, rules, composer; bundled content
  Provenance/               normalized transcription, edit log, review queue
Tools/ContentExtraction     source-to-content pipeline (Python 3, no dependencies)
Apps/Lux                    SwiftUI apps (XcodeGen project)
Documentation/              vision, architecture, design, source notes, ADRs
```

## Building and testing

See [Documentation/BUILDING.md](Documentation/BUILDING.md) and
[Documentation/TESTING.md](Documentation/TESTING.md). In short:

```sh
swift test --package-path Packages/LuxCore
swift test --package-path Traditions/BCP1662
cd Tools/ContentExtraction && python3 -m unittest discover -s tests -t . && python3 -m lux_extract check
```

## Licensing

Lux's code is under the Apache License 2.0 (`LICENSE`). The liturgical
texts, the source witness, Scripture, and fonts are separate works with
their own terms, recorded in [LICENSES.md](LICENSES.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Liturgical accuracy comes first:
never add or alter liturgical text without a source.

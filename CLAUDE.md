# Working on Lux

Read `Documentation/PRODUCT_VISION.md`, `ARCHITECTURE.md`, `DESIGN_SYSTEM.md`
and `BCP1662_SOURCE_NOTES.md` before substantial work.

## Non-negotiables

- Never fabricate, paraphrase or "fix" liturgical text. All wording comes
  from the source witness through `Tools/ContentExtraction`. Labels Lux
  writes itself (section titles, observance names) carry no source reference
  and must stay distinguishable from source text.
- When the source is silent or a table is missing, surface it: a placeholder
  element and a `Diagnostic`, never substitute text.
- Every content unit keeps its provenance (raw lines, extraction page, review
  status, editorial notes).
- LuxCore and tradition packages must not import SwiftUI, UIKit, AppKit or
  WatchKit.
- Licensing of texts, Scripture, fonts and the source file is tracked in
  `LICENSES.md`. Do not add a Bible translation, font or image without a
  recorded licence.

## Content pipeline

- The witness file in `Traditions/BCP1662/Witness/` is never edited. Its
  SHA-256 is checked on every run.
- Regenerate content with `cd Tools/ContentExtraction && python3 -m lux_extract build`.
  CI runs `python3 -m lux_extract check`, which fails if committed content is stale.
- Ambiguities are settled in the reviewed tables in `Tools/ContentExtraction/data/`
  (`basis: reviewed` with a note), never in code.
- Service structure lives in `Tools/ContentExtraction/maps/`. Maps select and
  order source text; they never contain liturgical wording, except exact
  strings used to locate it.

## Tests

- `swift test` in `Packages/LuxCore`, `Packages/LuxDesignSystem` and
  `Traditions/BCP1662`; Python tests in `Tools/ContentExtraction/tests`.
- Golden offices live in `Traditions/BCP1662/Tests/BCP1662Tests/Golden`.
  Regenerate with `LUX_RECORD_GOLDEN=1 swift test` only for an intended
  change, and review the diff as a change to liturgical text.
- Every historical exception found gets a regression test.

## Apps

`Apps/Lux/project.yml` is an XcodeGen spec. The `.xcodeproj` is generated,
not committed.

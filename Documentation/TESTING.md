# Testing

| Suite | Command | Covers |
| --- | --- | --- |
| Pipeline unit tests | `cd Tools/ContentExtraction && python3 -m unittest discover -s tests -t .` | normalization rules, drop-capital restoration, invariants and golden passages of the generated content, manifest hashes |
| Content freshness | `cd Tools/ContentExtraction && python3 -m lux_extract check` | committed content equals a fresh build |
| LuxCore | `swift test --package-path Packages/LuxCore` | civil dates, weekdays, Easter dates (published values and 1753–3000 invariants), SHA-256 vectors, orthography |
| BCP 1662 engine | `swift test --package-path Traditions/BCP1662` | Sundays and holy days, surplus and missing Sundays after Trinity, collects (Advent, Lent, Christmas, Circumcision, eve rule, concurrence), Psalter course (31st day, Psalm 119), the 19th and 12th day rules, Easter Day, Athanasian Creed days, Jubilate on St John Baptist's Day, provenance on every element, every day 2020–2059 |
| Golden offices | part of the engine tests | complete offices for seven dates, compared byte for byte |
| Design tokens | `swift test --package-path Packages/LuxDesignSystem` | WCAG AA contrast of text colours in both appearances |

## Golden offices

`Traditions/BCP1662/Tests/BCP1662Tests/Golden/*.json` are the complete
composed documents for: an ordinary weekday (Morning and Evening), Easter
Day, Ash Wednesday evening, St Luke on a Sunday, Christmas Eve and Christmas
Day. A change to any of them is a change to what people pray: regenerate
with `LUX_RECORD_GOLDEN=1 swift test --package-path Traditions/BCP1662` and
review the diff.

## Not yet tested

UI, accessibility, persistence and sync (not yet built).

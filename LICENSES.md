# Licence Inventory

Lux combines works with different owners and terms. Each is listed here with
its status. **Pending** items need a decision before a public release.

| Work | Location | Terms | Status |
| --- | --- | --- | --- |
| Lux source code | everything not listed below | Apache License 2.0 (`LICENSE`) | Chosen by the initial architecture work; confirm before first release |
| Source witness: text layer of the Satucket Software PDF of the 1762 Baskerville printing | `Traditions/BCP1662/Witness/bcp1662-baskerville1762.txt` | Header, verbatim: "You may redistribute this document electronically provided no fee is charged and this header remains part of the document." | **Pending.** Committed unchanged with its header. Whether app distribution (and any paid app) is within "no fee" needs Jackson's decision, ideally with Satucket's confirmation |
| The PDF itself | not in the repository | Same header, presumably | Not supplied |
| Lectionary witness: TCP transcription of the 1693 London printing (EEBO-TCP A28758) | `Traditions/BCP1662/Witness/bcp1662-london1693-tcp-A28758.xml` | CC0 1.0 Public Domain Dedication by the Text Creation Partnership, verbatim in `Witness/sources.json`. The waiver does not cover the EEBO page images, which are not used | Clear for the transcription. Used only for the Kalendar, Proper Lessons and Proper Psalms (chosen by Jackson, 2026-10-20). The underlying 1662 text is under the Crown-rights row below |
| Derived content (normalized transcription, structured JSON, edit log) | `Traditions/BCP1662/Sources/BCP1662/Resources/Content`, `Traditions/BCP1662/Provenance` | Derived from the witness; the witness terms are treated as applying. `lectionary/lessons.json` derives from the CC0 TCP transcription instead | **Pending**, with the witness |
| The 1662 Book of Common Prayer text | as above | In the United Kingdom the Book of Common Prayer is subject to Crown rights administered through the King's Printer (Cambridge University Press) under letters patent. Outside the UK the text is generally regarded as public domain | **Pending**: decide whether UK distribution needs permission |
| Editorial data written for Lux (decision tables, maps, calendar rules, observance names) | `Tools/ContentExtraction/data`, `maps`, `Traditions/BCP1662/Sources/BCP1662/*.swift` | Apache License 2.0 | Lux's own work |
| Scripture for the lessons | none shipped yet | King James Version (Authorized Version) | **Chosen by Jackson, 2026-10-13.** Public domain in most countries; in the UK it is under Crown letters patent, so UK distribution remains an open question. A KJV source text with its own provenance is still to be selected. Lessons are appointed by reference; their text stays a placeholder until it is added |
| Coverdale Psalter | in the content, as printed in the 1662 book | As the 1662 text | Covered by the 1662 text row |
| Reading typeface | not bundled | — | **Pending.** Candidates are SIL Open Font License Baskerville revivals (Libre Baskerville; ANRT Baskervville). The reference PDF's fonts are not assumed redistributable. The app uses the system serif until one is chosen |
| Icons | SF Symbols | Apple's SF Symbols licence (use in apps on Apple platforms) | In use by the app sources |

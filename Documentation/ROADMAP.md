# Roadmap

## Milestone 1: complete Morning and Evening Prayer for any date

Done in this foundation:

- Source witness committed with checksum; extraction pipeline with reviewed
  decision tables and a review queue.
- Psalter, Morning and Evening Prayer, Athanasian Creed, Easter anthems,
  collects, general rubrics.
- Calendar of Sundays and holy days; collect, psalter, canticle, creed and
  invitatory rules; golden tests.

Done from the 1693 printing (the tables are not in the Baskerville text layer):

- The Kalendar's lessons for every day, the Proper Lessons and the Proper
  Psalms, as canonical references with provenance (2026-10-21). The dates of
  the immovable holy days are checked against the Kalendar.

Blocked on the PDF:

- Compare the lectionary with the Baskerville pages (the review queue lists
  every corrected or doubtful cell).
- The Tables and Rules for the Moveable Feasts and the Table of Vigils (also
  in the 1693 transcription, not yet used) to verify the editorial calendar
  rules.

Blocked on a decision:

- A KJV source text (translation chosen 2026-10-13) and a `ScriptureProvider` for it; UK distribution of the KJV.
- Redistribution under the witness's terms; UK Crown rights.
- Reading typeface.

Remaining work:

- Epistles and Gospels (located; not yet extracted).
- The Litany, appointed on Sundays, Wednesdays and Fridays.
- Prayers and Thanksgivings upon several occasions.
- Review every item in the review queue against the page images.

## Milestone 2: the apps

- Build and visually verify the SwiftUI apps on every platform (they have
  never been compiled; CI is the first check).
- Reader: section navigation, reading position, typography controls.
- Bundle the chosen reading face.
- Accessibility pass: VoiceOver order, Dynamic Type at accessibility sizes,
  Full Keyboard Access on macOS.
- Watch: day identity and collect; complications.
- Widgets and App Intents ("Open today's Evening Prayer").

## Milestone 3: user data

- Persistence package: bookmarks, reading position, history (local first).
- Optional CloudKit sync of user data only.

## Later

- The other services of the 1662 book (Holy Communion, the occasional offices).
- Further traditions, through the same package contract.
- A contemporary profile with clearly separated, optional adaptations (for
  example the state prayers), only with an identified authority.

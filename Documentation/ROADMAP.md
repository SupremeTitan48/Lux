# Roadmap

## Milestone 1: complete Morning and Evening Prayer for any date

Done in this foundation:

- Source witness committed with checksum; extraction pipeline with reviewed
  decision tables and a review queue.
- Psalter, Morning and Evening Prayer, Athanasian Creed, Easter anthems,
  collects, general rubrics.
- Calendar of Sundays and holy days; collect, psalter, canticle, creed and
  invitatory rules; golden tests.

Blocked on the PDF (the tables are not in the text layer):

- Calendar with the Table of Lessons, Proper Lessons, Proper Psalms; the
  Tables and Rules for the Moveable Feasts; the Table of Vigils. With these,
  verify the editorial calendar rules and add the lectionary as canonical
  references.

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

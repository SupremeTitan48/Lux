# Service Options

Settings that change how an office is composed. They are handled by the
tradition package, not by the app: a tradition publishes its options
(`LiturgicalTradition.serviceOptions`), the app shows them, and the person's
selections come back in `CompositionOptions`. An app that knows nothing about
the 1662 book can still offer every choice it makes.

## Principles

- No option changes a word of the source. An option selects among texts the
  book prints as alternatives, leaves out a prayer the person chooses not to
  say, or leaves out what the book reserves to a priest.
- The rubrics win. A choice the rubrics forbid on a given day is overridden,
  and the office says why in a diagnostic.
- Composing with no selections gives the office as printed: every lawful
  alternative offered, nothing optional left out, a priest officiating. The
  golden offices are composed this way. The app's starting values (each
  option's `defaultChoice`) are a separate matter.
- Everything an option leaves out or adds is reported in the office's notes.

## The officiant

`Officiant` is `priest`, `deacon` or `layPerson` (a lay reader, or anyone
saying the office in private devotion).

In Morning and Evening Prayer the 1662 book reserves one text to a priest:
the Absolution, "to be pronounced by the Priest alone, standing; the People
still kneeling" (the rubric before it, at both offices). When the officiant is
not a priest, Lux leaves out that rubric and the Absolution, titles the
section "Confession", and reports `absolution-not-priest`.

The book makes no provision for the offices without a priest, so it says
nothing about what, if anything, stands in the Absolution's place. Two
practices are documented, and both are offered:

- **Leave it out** (the default). The office goes straight from the Confession
  to the Lord's Prayer.
- **The Collect for the twenty-first Sunday after Trinity** ("Grant, we
  beseech thee, merciful Lord, to thy faithful people pardon and peace..."),
  which asks for the pardon the Absolution declares. Saying it in place of the
  Absolution is a custom of deacons and lay officiants at the Prayer Book
  offices; see the Church Times, "Out of the Question", 13 April 2018,
  <https://www.churchtimes.co.uk/articles/2018/13-april/regulars/out-of-the-question/why-do-clergy-use-you-in-the-blessing-at-the-end-of-morning-prayer-but-lay-ministers-use-us>
  ("a deacon or lay officiant uses the collect for Trinity 21 (1662) in place
  of the absolution"). The collect's text is the Baskerville witness's, with
  its provenance. Its heading is Lux's label and carries no source reference.
  The diagnostic `absolution-trinity-21` says it is a custom, not a rubric.

Everything else is said as printed. The rubrics that name "the Priest" for
the versicles and suffrages are kept word for word. The speaker labels
over those versicles are a different matter: they are Lux's, drawn from the
speaker the book assigns, and with a deacon or lay officiant the parts the
book gives to "the Priest" are labelled **Minister**. This is an editorial
adaptation (`Speaker.saidBy(_:)` in LuxCore): the composed document keeps
the printed speaker, only the label changes, and the office notes say so
(`officiant-labels`).

Still to research: whether a lay officiant in private devotion should say
"The Lord be with you" and its answer. Lux gives them as printed.

## The prayers for the King and the Royal Family

`state-prayers`: **Include** (the default) or **Leave out**. The Baskerville
printing prays for King George and Queen Charlotte. Lux gives the prayers as
printed or leaves them out; it never changes the names. At Morning Prayer the
rubric before them still speaks of "these five Prayers", and the notes say two
were left out by choice (`state-prayers-omitted`).

A modern form naming the present royal family would be a separate text from a
separate source (the form the Church of England currently authorises), with
its own provenance and licence entry. It is not included; the decision is the
maintainer's.

## Canticles

Four options, one for each pair of canticles the book prints with "Or":

| Option | First (default) | Second |
| --- | --- | --- |
| `mp.first-canticle` | Te Deum | Benedicite |
| `mp.second-canticle` | Benedictus | Jubilate Deo |
| `ep.first-canticle` | Magnificat | Cantate Domino |
| `ep.second-canticle` | Nunc dimittis | Deus misereatur |

Each can also be **Choose in the office** (`both`), which gives the inline
choice the reader showed before. With a canticle chosen, only that canticle is
given, and the notes name the alternative (`canticle-chosen`).

The rubrics override the choice:

- The Jubilate is said when the Benedictus is read in the second lesson or for
  the Gospel on St John Baptist's Day, whatever is chosen.
- Cantate Domino is not said on the 19th of the month, nor Deus misereatur on
  the 12th, when they are read in the course of the Psalms.

## Tests

`Traditions/BCP1662/Tests/BCP1662Tests/ServiceOptionsTests.swift`: the default
composition is unchanged; without a priest the Absolution, and only the
Absolution, is gone; the Trinity 21 collect is the source text in the right
place; the state prayers can be left out; chosen canticles replace the
pickers; the rubrics overrule a chosen canticle on the 12th, the 19th, St John
Baptist's Day and 15 October.

# Contributing to Lux

Thank you for helping. Lux is a prayer book first and software second, so
contributions are judged on liturgical accuracy before anything else.

## Ground rules

1. **No liturgical text without a source.** Text enters Lux only through the
   content pipeline from an identified witness. Corrections need an
   authority, recorded in the reviewed decision tables or the map with a note.
2. **Show uncertainty.** If the source is ambiguous or missing, add a
   diagnostic and, if needed, an entry in the review queue. Do not guess.
3. **Keep the layers apart.** Rules in the tradition package, presentation in
   the apps. Views never decide liturgical questions.
4. **Licences are recorded.** New fonts, Bible editions, images or texts need
   an entry in `LICENSES.md` before they are merged.

## Workflow

- Branch from `main`; open a pull request.
- Run the tests (`Documentation/TESTING.md`). CI must be green.
- If generated content or golden offices change, say why in the pull request
  and point to the source lines involved.

## Reviewing content

The review queue (`Traditions/BCP1662/Provenance/review-queue.json`) lists
everything that should be checked against the page images: reconstructed
reading order, restored drop capitals, unusual readings, and pointing
anomalies. Checking items against the PDF is one of the most useful things a
contributor can do. Record a confirmed item by changing the relevant table
entry's `basis` to `reviewed` with a note giving the PDF page.

## Code style

Swift 6, strict concurrency, `swift-format` defaults. Python 3.10+, standard
library only in the pipeline. Comments explain why, and cite the rubric when
code applies one.

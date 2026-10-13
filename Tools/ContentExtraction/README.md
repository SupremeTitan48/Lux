# Content extraction

Turns the source witness into Lux's structured content. Python 3.10+,
standard library only.

```text
lux_extract/
  raw.py        load the witness, verify its SHA-256
  normalize.py  stage 1: page breaks, joins, ligatures, drop capitals, running heads
  decisions.py  the reviewed decision tables, and proposals for new entries
  text.py       shared helpers (drop-capital restoration)
  psalter.py    the Psalter and the thirty-day course
  offices.py    services from editorial maps (span and fragment modes)
  collects.py   the collects and their governing rubrics
  build.py      writes the content package, transcription, edit log, review queue
data/           reviewed decision tables (ligatures, joins, drop capitals, spaces)
maps/           service maps and the scripts that generate the complex ones
tests/          unit tests and content invariants
```

Commands: `python3 -m lux_extract build | check | propose` (see
`Documentation/BUILDING.md`). The map generators
(`maps/build_*.py`) are run by hand when a map changes; their output is
committed and verified by every build.

# Provenance

Every element of a composed office carries a `SourceReference`:

- `sourceID`: the witness (`bcp1662-baskerville1762-satucket`).
- `rawLines`: first and last line of the witness file (1-based).
- `pages`: extraction pages (LF-delimited pages of the text layer; 339 in all).
- `review`: set when the unit needs checking against the page image, for
  example `reading-order-reconstructed`.
- `editorial`: plain-language list of interventions, for example a restored
  word space or a drop capital restored from context.

Labels written by Lux (section titles, "The Collect of the Day: …") have no
source reference. Placeholders state what is missing and why.

To check a unit by hand: open the witness at the raw lines given, and the
normalized transcription (`Traditions/BCP1662/Provenance/transcription/normalized.txt`),
whose every line begins with its raw line range and page.

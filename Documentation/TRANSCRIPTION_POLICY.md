# Transcription Policy (BCP 1662)

Status: in force for the supplied text layer. Revisit when the PDF and page
images are available.

## Principle

Preserve the witness. The stored text is diplomatic in wording, spelling,
punctuation and capitalization. Only artifacts of the extraction are
normalized, each by a recorded rule. Display choices (such as showing ſ as s)
are made by the reader at render time and never change stored text.

## Rules

| Matter | Policy |
| --- | --- |
| Long s (ſ) | Preserved. The reader can display it as s (`Orthography.modernLetterforms`) |
| ct and st ligatures | Expanded to their letters (ligatures are typographic, not orthographic) |
| Ambiguous ligature glyph (U+E001) | Resolved per word from `data/ligatures.json`; each entry records its basis |
| æ | Preserved |
| Spelling | Preserved, including variants and apparent errors (listed in the review queue) |
| Capitalization | Preserved, except that small capitals letter-spaced by the extractor are closed up |
| Drop capitals | Restored to the start of their word from the page's orphan-letter line; uncertain cases use `data/dropcaps.json` and are marked in provenance |
| Punctuation and quotation marks | Preserved, including the pointing colon in Psalms and canticles, which is kept as structure (two half-verses) |
| Line-end hyphenation | Removed where the extractor's soft hyphen marks it; printed hyphens in compounds are kept |
| Line breaks inside words | Joined. Whether a space belongs at a join is decided by `data/joins.json` |
| Lost word spaces | Restored only from `data/spaces.json`, one reviewed entry per edit |
| Running heads, catchwords, page furniture | Removed from the text flow; listed in the review queue when detected heuristically |
| Italic and small capitals | Not represented in the text layer. Rubrics are identified structurally (by the service maps), not by font |
| Biblical references | Kept as printed and attached to their unit as a citation |
| Illegible or uncertain text | Never guessed. Reported in the review queue |

## Records

- `Traditions/BCP1662/Provenance/transcription/normalized.txt`: every
  normalized line with its raw line range and page.
- `Traditions/BCP1662/Provenance/transcription/edits.jsonl`: every edit.
- `Traditions/BCP1662/Provenance/review-queue.json`: everything to check
  against the page images.

Reviewer and date are recorded in the note of each reviewed table entry.

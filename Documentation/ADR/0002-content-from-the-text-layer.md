# ADR 0002: Build content from the supplied text layer

Date: 2026-10-13. Status: accepted.

## Context

Only the PDF's text layer was supplied. It carries systematic extraction
artifacts (split words around ſ, private-use ligature glyphs, displaced drop
capitals, interleaved columns) and lacks the calendar tables.

## Decision

Treat the text layer as the witness: commit it unchanged with its checksum,
and derive everything else by a reproducible pipeline. Every ambiguous
decision lives in a reviewed table, not in code; every structural decision
lives in a map that selects source text by exact strings or raw lines. The
build is deterministic and CI fails if committed content is stale.

## Consequences

The content can be audited line by line back to the witness. When the PDF
arrives, page images can be used to review the queue and the missing tables
can be added without disturbing what exists.

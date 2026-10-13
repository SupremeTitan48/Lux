# ADR 0003: Diplomatic text, display orthography

Date: 2026-10-13. Status: accepted.

## Decision

Content stores the text as printed (including ſ). Showing ſ as s is a
reader setting (`Orthography`), applied at render time. Modern spelling, if
ever offered, would be a separate, optional, documented transformation.

## Consequences

One stored text serves both readers who want the printed page and those who
want easier reading, and the stored text stays auditable.

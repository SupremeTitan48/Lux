# Adding a Tradition

A tradition is a Swift package that depends on `LuxCore` and conforms to
`LiturgicalTradition`. The app never needs to know a tradition's rules.

1. **Source.** Put the witness in `Traditions/<Name>/Witness/` unchanged, with
   a `sources.json` giving its checksum and terms. Record the terms in
   `LICENSES.md`.
2. **Pipeline.** Reuse `Tools/ContentExtraction` where the source is similar,
   or add a tool that produces structured content with provenance on every
   unit. Generated content must be reproducible and checked in CI.
3. **Content.** Bundle the generated JSON as package resources with a
   `manifest.json` listing each file's SHA-256 (`ContentManifest` verifies it
   at load).
4. **Rules.** Implement the calendar and composition in the package. Return a
   `ServiceDocument`: typed elements, each with a `SourceReference`;
   `alternatives` where the tradition allows a choice or is silent;
   `placeholder` plus a `Diagnostic` for anything that cannot be supplied.
5. **Tests.** Calendar tests on boundary years, rule tests for every
   exception, and golden offices.

Do not add 1662 concepts to LuxCore to suit a new tradition, or the reverse:
`Office`, `DayDescription.season` and `ServiceElement.text(kind:)` are open
strings for that reason.

# Lux — Technical Architecture

## Architectural Aim

Lux must separate liturgical knowledge from platform presentation. A date, tradition, and user configuration should produce the same structured office on every device. Platform applications then render that office according to their own native conventions.

The architecture should be modular enough to support additional traditions and platforms, while remaining concrete enough to deliver a complete 1662 implementation without speculative machinery.

## System Boundaries

Lux has four principal layers:

1. A platform-independent liturgical core.
2. Versioned tradition packages containing rules and content.
3. Native Apple applications and a shared design system.
4. Local persistence with optional synchronization.

Dependencies should point inward: applications may depend on the core and content interfaces; the core must never depend on SwiftUI, UIKit, AppKit, WatchKit, or visionOS presentation APIs.

## 1. Liturgical Core

Implement the core as a testable Swift package using portable language features and Foundation only where appropriate. Its responsibilities include:

- Civil and liturgical date calculations.
- Calendar and observance resolution.
- Precedence, concurrence, and transfer rules where the tradition requires them.
- Psalter and lectionary assignment.
- Rubrical decisions and lawful alternatives.
- Scripture-reference resolution through an abstract provider.
- Office composition into a typed, ordered document model.
- Validation diagnostics and source traceability.

Suggested domain services include:

- `LiturgicalCalendar`
- `ObservanceResolver`
- `PrecedenceResolver`
- `LectionaryResolver`
- `PsalterResolver`
- `RubricEngine`
- `OfficeComposer`
- `ScriptureResolver`

Names may evolve after repository inspection, but responsibilities should remain explicit and independently testable.

### Core input

The composition boundary should accept:

- A tradition identifier and version.
- A civil date and calendar/time-zone context.
- An office identifier.
- Explicit user options permitted by the tradition.
- A content repository and, when needed, a Scripture provider.

### Core output

The engine should return an immutable, structured service rather than preformatted prose. A service is an ordered sequence of typed sections such as heading, rubric, versicle-and-response, Psalm, lesson, canticle, creed, collect, and prayer. Every section should carry stable identifiers and provenance sufficient for navigation, accessibility, testing, and source inspection.

The result should also include diagnostics when a rule is ambiguous, content is missing, or a fallback was used. The engine must not silently invent content.

### Determinism

Given the same tradition version, date, office, configuration, and Scripture source, composition should be deterministic. Current clock and locale dependencies must enter through explicit interfaces so tests can control them.

## 2. Tradition Packages

Each liturgical tradition should implement a documented package contract. A conceptual package may contain:

```text
Traditions/
  BCP1662/
    manifest.json
    calendar.json
    lectionary.json
    psalter.json
    rubrics.json
    services.json
    texts/
    sources/
    schemas/
    tests/
```

The exact file split may change as the model matures. The important properties are that packages are:

- Versioned and self-describing.
- Validated before loading.
- Independently testable.
- Explicit about source editions and licenses.
- Capable of complete offline operation.
- Data-driven where rules can be expressed safely as data.
- Unable to execute arbitrary code when obtained from an untrusted source.

### Package manifest

A manifest should identify the tradition, package version, schema version, languages, source editions, supported offices, calendar system, required Scripture capabilities, licenses, checksums, and compatibility range.

### No Anglican universalism

The shared contract must not assume that every tradition has Anglican terminology, a two-office daily cycle, the same feast ranks, the same Psalter, or the same choice points. Prefer a small set of general primitives and tradition-owned rules over a large inheritance hierarchy derived from the 1662 book.

### Schema evolution

Schemas should be versioned. Migration and compatibility behavior must be deliberate. Reject an incompatible package with a useful explanation instead of interpreting it approximately.

### Content safety

Future downloadable packages should be signed or otherwise integrity-checked. Package loading must constrain paths, reject undeclared executable content, validate resource sizes, and avoid dynamic evaluation.

## 3. Content and Editorial Pipeline

Source processing is a build-time or editorial concern, not a runtime shortcut. Keep three distinct representations:

1. **Raw source:** original PDF, images, OCR output, and extraction artifacts.
2. **Normalized transcription:** corrected text with documented editorial normalization.
3. **Structured content:** typed sections and rules used by the application.

Transformations should be reproducible. Editorial changes should carry a reason, reviewer, date, and source location. Generated resources should be validated in continuous integration.

Every user-visible liturgical unit should retain provenance such as source edition, PDF page, printed page or section, extraction version, and editorial notes where available.

## 4. Apple Applications

Use Swift and SwiftUI for native Apple clients. Share domain models, content access, persistence abstractions, design tokens, and genuinely reusable components. Permit separate platform implementations wherever behavior or information architecture differs.

A plausible repository shape is:

```text
Lux/
  Packages/
    LiturgicalCore/
    BCP1662/
    ContentLibrary/
    Persistence/
    LuxDesignSystem/
  Apps/
    iOS/
    macOS/
    watchOS/
    visionOS/
  Extensions/
    Widgets/
    AppIntents/
  Tools/
    ContentPipeline/
  Tests/
```

This is a direction, not a mandate to reorganize a healthy existing repository. Preserve valuable implementation work and refactor only with evidence.

### Platform responsibilities

Platform layers own navigation, window management, command menus, input methods, adaptive layouts, widgets, notifications, accessibility adaptations, and platform lifecycle. The macOS application should use desktop conventions rather than presenting a stretched mobile shell.

### View-model boundary

Presentation models may adapt a composed service for display, but they should not recalculate liturgical rules. UI state and domain state should remain distinguishable.

## 5. Persistence and Synchronization

Treat installed liturgical content and user data as separate stores.

**Content data** includes bundled or downloaded tradition packages, package versions, validation status, and indexes.

**User data** includes preferences, bookmarks, favorites, reading positions, prayer history, installed-tradition choices, and notification settings.

Local storage is authoritative for the offline experience. Optional CloudKit synchronization may replicate user data, but basic prayer must never require an Apple account. Synchronization should use stable identifiers, tolerate partial availability, and resolve conflicts without losing bookmarks or corrupting reading position.

Do not synchronize source texts as user records. Content packages have their own version and update lifecycle.

## 6. Scripture Providers

Scripture references and Scripture text are separate concerns. The lectionary should store canonical references in a documented representation. A provider resolves them through a licensed local edition or another approved source.

The system must:

- Identify translation and edition.
- Preserve verse boundaries and omitted ranges.
- Work offline for bundled editions.
- Expose license and attribution requirements.
- Fail visibly when a passage cannot be resolved.

Do not ship a translation merely because its text is easy to obtain.

## 7. Cross-Platform Future

The first core may be written in portable Swift, but serialized tradition data, schemas, fixtures, and expected-output tests should be language-neutral. A future client on Android, Windows, Linux, or the web should be able to consume the same packages or implement the same documented contract without embedding an Apple UI runtime.

Native Apple quality remains the immediate priority; future portability should be protected through boundaries and data formats, not by replacing native interfaces with a web wrapper or cross-platform UI framework.

## 8. Testing Strategy

Required automated coverage includes:

- Date, season, and movable-feast calculations.
- Calendar boundary and leap-year cases.
- Observance precedence and exceptional rules.
- Monthly Psalter assignments and substitutions.
- Ordinary and proper lesson selection.
- Schema and content validation.
- Golden tests for fully composed offices on representative and difficult dates.
- Provenance completeness checks.
- Persistence migration and synchronization-conflict tests.
- Platform UI, accessibility, Dynamic Type, and keyboard-navigation tests.
- Offline launch and prayer-flow tests.

Every discovered historical exception should receive a regression test. Golden tests should be human-reviewable, versioned, and updated only with an explicit editorial reason.

## 9. Operational Quality

All targets should compile independently. Continuous integration should validate packages, run core tests, and build supported app targets. Diagnostics must distinguish invalid source content, unsupported schema versions, missing Scripture, and programming defects.

Avoid placeholder liturgical content in production paths. Do not label a service complete until its texts, assignments, exceptions, and provenance have been verified.

## Architectural Decision Rule

Prefer the smallest design that faithfully implements the 1662 office while preserving clean boundaries for future traditions. Every abstraction should answer a demonstrated domain need, and every shortcut should be evaluated for whether it silently compromises liturgical integrity, native experience, or future migration.


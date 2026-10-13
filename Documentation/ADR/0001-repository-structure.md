# ADR 0001: Repository structure and code licence

Date: 2026-10-13. Status: accepted (licence to be confirmed by the maintainer).

## Decision

- Swift packages for the core (`Packages/LuxCore`) and design tokens
  (`Packages/LuxDesignSystem`); each tradition is its own package under
  `Traditions/`, depending on LuxCore only.
- Apps in `Apps/Lux`, described by an XcodeGen spec rather than a committed
  `.xcodeproj`, so the project file never conflicts in review.
- Code under the Apache License 2.0: permissive, with an explicit patent
  grant, suitable for an open-source app others may package.

## Consequences

The core and traditions build and test on Linux, which keeps them honest
about platform independence and lets CI run cheaply. The apps need Xcode.

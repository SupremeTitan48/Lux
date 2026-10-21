# Lux — Design System

## Design Thesis

Lux should feel like a beautifully printed breviary that happens to live on an Apple device. It should be historic without becoming theatrical, modern without becoming generic, and reverent without becoming difficult to use.

The visual system should support sustained reading and prayer. The ideal impression is quiet confidence: warm materials, exact typography, generous rhythm, restrained color, and controls that appear when needed and recede when not.

## Character

The Lux design language is:

- Editorial.
- Sacred.
- Quiet.
- Warm.
- Precise.
- Tactile but not skeuomorphic.
- Timeless rather than nostalgic.

Avoid generic dashboards, repeated cards, gratuitous gradients, crowded toolbars, decorative glass effects, and visual treatments that compete with the text.

One deliberate exception (requested by the maintainer, 2026-10-21): on Today, Morning and Evening Prayer are two cards under a dawn and a dusk sky (`Sky` tokens). They are the only gradients in the app, they never appear in the reader, and their titles are tested for contrast in both appearances.

## Design Principles

### The text is the interface

In the prayer reader, typography and document structure should do most of the work. Do not place each prayer in a separate container merely to signal hierarchy.

### Restraint communicates reverence

Use few colors, few typefaces, and a disciplined spacing scale. Variation should communicate role, sequence, or liturgical meaning.

### Historical influence, contemporary readability

Baskerville and historic prayer-book composition may inspire proportion, italic rubrics, capitals, ornament, and pacing. Never reproduce historical typesetting habits that reduce legibility or accessibility.

### Native adaptation

Lux should be recognizably one product across Apple platforms, but it must honor each platform's established behaviors. Shared visual tokens should not force identical layouts.

### Accessibility is structural

Dynamic Type, VoiceOver order, contrast, keyboard control, motion preferences, and adaptable layout are design inputs from the beginning.

## Color System

Build colors as semantic tokens, not hard-coded values. Initial roles may include:

- `surfacePrimary`: a neutral page that matches the system surfaces (white in light mode, the system's dark grey in dark mode). The first warm ivory and charcoal read as tinted next to the rest of the interface and were made neutral on 2026-10-21 at the maintainer's request.
- `surfaceSecondary`: a subtle tonal step for sidebars, sheets, or marginal matter.
- `textPrimary`: near-black in light mode; warm off-white in dark mode.
- `textSecondary`: a quieter neutral for metadata.
- `rubric`: muted liturgical red.
- `accent`: a restrained application accent that meets contrast requirements.
- `divider`: low-contrast rule color.
- `selection`, `focus`, `link`, and semantic status colors.

Liturgical green, violet, red, white or gold, and black may identify seasons or observances when the active tradition defines those meanings. They should usually appear as small accents, not saturated page backgrounds.

Color must never be the sole carrier of liturgical rank, speaker role, selection, or error state.

## Typography

### Reading face

Use an elegant, properly licensed serif for liturgical text. A Baskerville-inspired face is appropriate if it renders well across Apple platforms, has the required styles and characters, supports accessibility scaling, and can be distributed under acceptable terms.

Evaluate typefaces with real offices, not specimen words. Test prose, Psalms, italics, small capitals, numerals, punctuation, long readings, and large accessibility sizes.

### Interface face

Use the platform's native sans serif for navigation, controls, settings, and compact metadata unless testing establishes a compelling reason otherwise.

### Typographic roles

Define semantic styles for:

- Service title and liturgical day.
- Section heading and subsection heading.
- Body prayer text.
- Rubric.
- Versicle and response.
- Psalm number, title, verse number, and text.
- Canticle title and subtitle.
- Scripture citation and lesson text.
- Marginal source note.
- Control label and supporting metadata.

Styles should specify typeface, weight, optical size where available, line spacing, paragraph spacing, indentation, and scaling behavior.

### Reading measure and rhythm

Favor a comfortable line length, roughly 45–75 characters where the platform and type size permit. Use generous leading and consistent paragraph rhythm. At large Dynamic Type sizes, allow the measure and layout to adapt rather than shrinking content or clipping roles.

Use drop capitals, small capitals, decorative initials, or ornaments only as optional enhancements. They must not damage text selection, VoiceOver order, or reflow.

## The Prayer Reader

The reader is the most important component in Lux and should receive the highest design and testing investment.

### Structure

Present the office as one continuous document with clear sections. Use hierarchy, whitespace, alignment, and occasional subtle rules. Rubrics should be distinct but readable; responses should be easy to locate; Psalm verses should preserve their structure without awkward tabular rigidity.

### Interaction

- Restore the user's reading position reliably.
- Allow optional navigation by service section.
- Make typography controls easy to reach but visually secondary. Typeface, size and line spacing are reader settings (see READING_LAYOUT.md).
- Let navigation chrome recede during sustained reading.
- Preserve selection, copying, and accessibility behavior where licensing permits.
- Avoid gestures that conflict with platform navigation or assistive technologies.

### Alternatives and rubrics

Do not silently collapse lawful alternatives into one text. Where a choice is necessary, present it before prayer or use an unobtrusive inline control that preserves the document flow. Clearly distinguish rubrics from words to be said.

### Progress

Progress indicators, if used, should be calm and optional. They must never turn prayer into a streak, score, or performance metric.

## Layout by Platform

### iPhone

Use a focused single column with comfortable margins, thumb-reachable controls, predictable navigation, and strong behavior at every Dynamic Type size. Today should make the next appropriate office immediately clear.

### iPad

Use adaptive sidebars and reading columns. A facing-page or book-like layout may be offered in sufficiently wide contexts, but it must reflow gracefully in Split View, Stage Manager, portrait orientation, and larger text sizes.

### macOS

Use native sidebars, toolbars, menus, commands, keyboard shortcuts, focus behavior, and multiple windows. Support a wide range of window sizes without allowing lines to become excessively long. A reading window should feel intentional at both compact and expansive sizes.

### watchOS

Reduce the experience to content suited to the wrist: the day's identity, short offices or sections, collects, reminders, and complications. Use short navigation paths and highly legible text. Do not force the full desktop document onto the watch.

### visionOS

Use comfortable window depth, scale, and placement. Spatial panels may support reference or contemplation, but the main office should remain coherent in one accessible reading flow. Avoid novelty that distracts from prayer.

## Components and Tokens

Create a small shared design package containing semantic color, typography, spacing, corner, divider, motion, and reading-width tokens plus components that genuinely recur across platforms.

Likely shared components include:

- Liturgical day header.
- Office section heading.
- Rubric text.
- Versicle-and-response block.
- Psalm block.
- Lesson header and citation.
- Collect block.
- Source/provenance sheet.
- Empty, loading, and recoverable-error states.

Components should consume structured domain content and expose accessibility semantics. Do not encode calendar or office-composition rules inside views.

## Motion and Feedback

Motion should clarify navigation, state changes, or continuity. Favor short, subtle, system-consistent transitions. Respect Reduce Motion and avoid decorative animation in the reader. Haptics should be rare, meaningful, and platform-appropriate.

## Accessibility Standard

Every major flow must be verified for:

- VoiceOver labels, roles, grouping, and reading order.
- Dynamic Type, including accessibility sizes.
- Sufficient contrast in both appearances.
- Differentiate Without Color.
- Reduce Motion and Reduce Transparency.
- Full Keyboard Access and macOS keyboard navigation.
- Switch Control and other assistive input where applicable.
- Legible focus, selection, error, and disabled states.

Speaker roles, verse numbers, headings, and rubrics should have meaningful semantics rather than being expressed only by visual styling.

## Content States

Loading, missing content, invalid packages, unresolved Scripture, and uncertain liturgical rules require honest, calm states. Never replace unavailable source material with generated or approximate prayer text. A useful error should say what is missing, whether the rest of the office remains usable, and where provenance or diagnostic details can be inspected.

## Quality Bar

Lux should resemble a premium editorial reading application, not a developer utility wearing a historic font. Review real screens on real devices, in light and dark modes, at standard and accessibility sizes, with short and long offices. When ornament conflicts with readability, comprehension, performance, or accessibility, choose the latter.


# Lux — Product Vision

## Purpose

Lux is a free, open-source, extensible application for historic Christian liturgical prayer. Its purpose is to make faithful participation in the Church's daily prayer beautiful, accurate, accessible, and effortless on modern devices.

Lux is not merely a digital prayer-book reader. It is a liturgical platform that can assemble a complete office for a particular date from structured texts, calendars, lectionaries, rubrics, and rules of precedence. Its first complete tradition is the 1662 *Book of Common Prayer*; its architecture should make room for other traditions without flattening their differences.

The defining product idea is:

> A beautifully typeset historic breviary, with the usability of the best native Apple applications and the trustworthiness of a scholarly liturgical reference.

## The Core Experience

When a user opens Lux, the application should already understand the current civil and liturgical date. It should present the day's season, observance, and available offices without requiring the user to consult tables or turn between sections of a book.

Selecting Morning Prayer or Evening Prayer should open one coherent, continuous service containing the appointed material for that date:

- The correct ordinary and seasonal texts.
- The appointed Psalms and lessons.
- Canticles, collects, and prayers in their proper places.
- Rubrics and speaker roles presented clearly but unobtrusively.
- Any lawful alternatives, substitutions, or exceptions identified explicitly.

The result should feel like prayer, not like querying a database. Navigation, controls, and settings should recede while the office is being read.

## Initial Scope

The first release implements the 1662 *Book of Common Prayer*, using the supplied reproduction of John Baskerville's 1762 printing as the principal working source.

Lux begins as a universal native Apple application with targets for:

- iOS and iPadOS.
- macOS.
- watchOS.
- visionOS.

The first implementation priority is a complete, dependable shared liturgical engine and an excellent iPhone, iPad, and Mac prayer experience. Watch and Vision experiences should be established deliberately and expanded only after the central reader and 1662 office are sound.

## Intended Users

Lux should serve:

- Christians who pray Morning and Evening Prayer.
- Anglican users seeking a faithful 1662 office.
- Clergy, seminarians, historians, and students of liturgy.
- Readers exploring historic Christian prayer for the first time.
- Communities and developers who wish to preserve and implement additional liturgical traditions.

Expert users need traceability and accuracy. New users need an experience that removes mechanical complexity without concealing the structure or character of the rite.

## Product Principles

### 1. Prayer before productivity

Lux exists to support attentive prayer. Features should be judged by whether they reduce friction, preserve reverence, and help the user inhabit the office.

### 2. Historical fidelity before customization

The first obligation is to represent the source tradition honestly. Modernizations and alternate practices may be supported, but they must be optional, documented, and clearly distinguished from the historical text.

### 3. Accuracy that can be inspected

Every assembled office should be traceable to source texts and governing rules. The application should preserve edition, page, transcription, and editorial provenance wherever practical.

### 4. Beauty without display

Typography, spacing, color, and motion should create a quiet and dignified reading environment. Ornament is welcome only when it serves hierarchy, identity, or comprehension.

### 5. Depth without interface complexity

Lux may contain a sophisticated calendar and composition engine, but the primary experience should remain direct: open the app, understand the day, begin the office.

### 6. Native experiences on every platform

Share domain logic and design language, not every screen. Each Apple platform should use its own navigation, windowing, inputs, and accessibility conventions.

### 7. Offline first and private by default

The complete primary prayer experience must work without a network connection or account. User activity should remain local unless the user explicitly enables synchronization.

### 8. Open and maintainable

Code, content transformations, schemas, tests, editorial decisions, and known uncertainties should be documented and version-controlled. The project should be understandable and repairable by future contributors.

### 9. Extensible without premature generalization

The 1662 implementation must be excellent in its own right. Stable package boundaries and documented data contracts should enable future traditions without forcing all traditions into Anglican assumptions.

## Primary Product Areas

### Today

The opening view should show the current date, liturgical season, observance, and appropriate offices. It may show unobtrusive reading progress and provide quick access to another date.

### Prayer Reader

The reader is the center of Lux. It should offer a continuous, beautifully typeset office; reliable position restoration; accessible type controls; optional section navigation; and a distraction-free reading state.

### Calendar

The calendar should expose the shape of the liturgical year, allow date navigation, explain observances and precedence, and open the services appointed for a selected day.

### Library

The library should make the full contents of installed tradition packages browsable and searchable. Users should be able to inspect services, Psalms, canticles, collects, rubrics, and source references independently of an assembled office.

### Settings

Settings should cover appearance, typography, accessibility, notifications, synchronization, installed traditions, Scripture editions, and source acknowledgements. Defaults should be sound enough that configuration is never a prerequisite for prayer.

## Platform Character

- **iPhone:** immersive, single-column reading with simple navigation and useful widgets or reminders.
- **iPad:** adaptive navigation and book-inspired layouts, including a facing-page option where it remains readable.
- **Mac:** a true desktop application with resizable windows, sidebars, menus, keyboard shortcuts, and multiwindow support.
- **Apple Watch:** a deliberately condensed experience for the day's information, collects, reminders, and appropriately scoped prayer.
- **Apple Vision Pro:** comfortable native windows and optional spatial reading features, never required for the core experience.

## Explicit Non-Goals

Lux is not intended to provide:

- Advertising or engagement-driven design.
- Social networking, streaks, or competitive gamification.
- Subscription barriers around core prayer texts.
- AI-generated prayers presented as liturgical source material.
- Mandatory accounts or unnecessary cloud dependencies.
- Silent modernization of historic texts.
- A generic dashboard or card-based interface imposed on the prayer book.

## Long-Term Direction

Lux should eventually support multiple Books of Common Prayer, Roman office traditions, Ordinariate books, additional languages and Scripture editions, chant and audio, custom calendars, and community-maintained tradition packages. Structured content should be portable enough to support future native applications on Android, Windows, Linux, and the web.

Expansion is successful only if each tradition retains its own theology, calendar, rubrics, office structure, and textual integrity.

## Definition of Success

Lux succeeds when a user can select a day and pray the complete, correctly assembled office through an exceptional native interface; when the application works offline; when the text and governing rules are inspectable and trustworthy; and when the underlying engine can serve new traditions without compromising the first one.


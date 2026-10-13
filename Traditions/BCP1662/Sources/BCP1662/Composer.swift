import Foundation
import LuxCore

/// Composes Morning and Evening Prayer for a date from the bundled content.
///
/// The order of each office is the order of its units in the content, which
/// is the order of the printed office. The composer only chooses among
/// printed texts and fills the slots the rubrics leave open (psalms,
/// lessons, the collect of the day); it never supplies wording of its own
/// except labels, which carry no source reference.
struct Composer {
    let content: BCP1662Content
    let calendar: BCP1662Calendar

    private var source: String { content.sourceID }

    // MARK: Sections

    private struct SectionSpec {
        let id: String
        let title: String?
        let firstUnit: String
    }

    private static let morningSections: [SectionSpec] = [
        .init(id: "sentences", title: "The Sentences", firstUnit: "mp.sentences.rubric"),
        .init(id: "confession", title: "Confession and Absolution", firstUnit: "mp.exhortation"),
        .init(id: "lords-prayer", title: "The Lord’s Prayer", firstUnit: "mp.lordsprayer.rubric"),
        .init(id: "preces", title: nil, firstUnit: "mp.preces.rubric"),
        .init(id: "invitatory", title: "Venite", firstUnit: "mp.venite.rubric"),
        .init(id: "psalms", title: "The Psalms", firstUnit: "mp.psalms.rubric"),
        .init(id: "first-lesson", title: "The First Lesson", firstUnit: "mp.firstlesson.rubric"),
        .init(id: "first-canticle", title: "Te Deum", firstUnit: "mp.tedeum.title"),
        .init(id: "second-lesson", title: "The Second Lesson", firstUnit: "mp.secondlesson.rubric"),
        .init(id: "second-canticle", title: "Benedictus", firstUnit: "mp.benedictus.title"),
        .init(id: "creed", title: "The Creed", firstUnit: "mp.creed.rubric"),
        .init(id: "prayers", title: "The Prayers", firstUnit: "mp.prayers.rubric"),
        .init(id: "collects", title: "The Collects", firstUnit: "mp.collects.rubric"),
        .init(id: "intercessions", title: nil, firstUnit: "mp.anthem.rubric"),
        .init(id: "ending", title: nil, firstUnit: "mp.colophon"),
    ]

    private static let eveningSections: [SectionSpec] = [
        .init(id: "sentences", title: "The Sentences", firstUnit: "ep.sentences.rubric"),
        .init(id: "confession", title: "Confession and Absolution", firstUnit: "ep.exhortation"),
        .init(id: "lords-prayer", title: "The Lord’s Prayer", firstUnit: "ep.lordsprayer.rubric"),
        .init(id: "preces", title: nil, firstUnit: "ep.preces.rubric"),
        .init(id: "psalms", title: "The Psalms", firstUnit: "ep.psalms-lesson.rubric"),
        .init(id: "first-canticle", title: "Magnificat", firstUnit: "ep.magnificat.title"),
        .init(id: "second-lesson", title: "The Second Lesson", firstUnit: "ep.nt-lesson.rubric"),
        .init(id: "second-canticle", title: "Nunc dimittis", firstUnit: "ep.nuncdimittis.title"),
        .init(id: "creed", title: "The Creed", firstUnit: "ep.creed.rubric"),
        .init(id: "prayers", title: "The Prayers", firstUnit: "ep.prayers.rubric"),
        .init(id: "collects", title: "The Collects", firstUnit: "ep.collects.rubric"),
        .init(id: "intercessions", title: nil, firstUnit: "ep.anthem.rubric"),
        .init(id: "ending", title: nil, firstUnit: "ep.colophon"),
    ]

    // MARK: Composition

    func compose(_ office: Office, on date: CivilDate) throws -> ServiceDocument {
        guard BCP1662Calendar.supportedYears.contains(date.year) else {
            throw CompositionError.dateOutOfRange(date, reason: "The 1662 rules are computed on the Gregorian calendar, adopted in Great Britain in 1752.")
        }
        let file: ServiceFile
        let specs: [SectionSpec]
        switch office {
        case .morningPrayer: (file, specs) = (content.morningPrayer, Composer.morningSections)
        case .eveningPrayer: (file, specs) = (content.eveningPrayer, Composer.eveningSections)
        default: throw CompositionError.unsupportedOffice(office)
        }

        var context = Context(office: office, date: date, day: describe(date))
        context.diagnostics.append(Diagnostic(.info, code: "calendar-editorial",
            message: "The Calendar and the Tables and Rules for the Feasts are not in the supplied source text. Lux places the holy days and movable feasts by the 1662 rules as editorially encoded, pending verification against the printed tables."))

        var sections: [ServiceSection] = []
        for (index, spec) in specs.enumerated() {
            guard let start = file.units.firstIndex(where: { $0.id == spec.firstUnit }) else {
                throw CompositionError.contentMissing(spec.firstUnit)
            }
            let end = index + 1 < specs.count ? file.units.firstIndex(where: { $0.id == specs[index + 1].firstUnit }) ?? file.units.count : file.units.count
            let units = Array(file.units[start..<end])
            let elements = try build(section: spec.id, units: units, context: &context)
            if !elements.isEmpty {
                sections.append(ServiceSection(id: spec.id, title: spec.title, elements: elements))
            }
        }
        let title = office == .morningPrayer ? "Morning Prayer" : "Evening Prayer"
        return ServiceDocument(traditionID: BCP1662Tradition.identifier, office: office, date: date, title: title,
                               day: context.day, sections: sections, diagnostics: context.diagnostics)
    }

    private struct Context {
        let office: Office
        let date: CivilDate
        let day: DayDescription
        var diagnostics: [Diagnostic] = []
        var prefix: String { office == .morningPrayer ? "mp" : "ep" }
    }

    // MARK: Day description

    func describe(_ date: CivilDate) -> DayDescription {
        let candidates = calendar.collectCandidates(on: date).ids
        let proper = calendar.properDays(on: date)
        let season = calendar.season(of: date).rawValue
        if date.weekday == .sunday || !proper.isEmpty {
            let primary = candidates.first!
            return DayDescription(title: ObservanceNames.name(primary), observanceID: primary.rawValue, season: season,
                                  concurrent: candidates.dropFirst().map(\.rawValue))
        }
        let governing = candidates.first!
        let sunday = date.previous(.sunday)
        let after = calendar.sundayProper(sunday).map { ObservanceNames.name($0.id) }
        let weekday = ObservanceNames.weekdayName(date.weekday)
        let title: String
        if let after, governing == calendar.sundayProper(sunday)?.id {
            title = "\(weekday) after \(after.prefix(1).lowercased() + after.dropFirst())"
        } else {
            title = "\(weekday) after \(ObservanceNames.name(governing).prefix(1).lowercased() + ObservanceNames.name(governing).dropFirst())"
        }
        return DayDescription(title: title, observanceID: governing.rawValue, season: season)
    }

    /// Observances kept on the day itself (for proper psalms and the creed).
    private func keptToday(_ date: CivilDate) -> Set<ObservanceID> {
        var ids = Set(calendar.properDays(on: date))
        if date.weekday == .sunday, let sunday = calendar.sundayProper(date) { ids.insert(sunday.id) }
        return ids
    }

    // MARK: Sections

    private func build(section: String, units: [ServiceFile.Unit], context: inout Context) throws -> [ServiceElement] {
        switch section {
        case "invitatory": return invitatory(units, context: &context)
        case "psalms": return try psalms(units, context: &context)
        case "first-lesson": return units.map(element) + [lessonPlaceholder("first", context: &context)]
        case "second-lesson": return units.map(element) + [lessonPlaceholder("second", context: &context)]
        case "first-canticle", "second-canticle": return canticles(section, units, context: &context)
        case "creed": return creed(units, context: &context)
        case "collects": return try collects(units, context: &context)
        case "intercessions":
            if context.office == .morningPrayer && [.sunday, .wednesday, .friday].contains(context.date.weekday) {
                context.diagnostics.append(Diagnostic(.info, code: "litany-not-included",
                    message: "The Litany is appointed after Morning Prayer on Sundays, Wednesdays and Fridays, when only the last two of these prayers are read here. Lux does not yet include the Litany, so the prayers are given as on other days."))
            }
            context.diagnostics.append(Diagnostic(.info, code: "state-prayers-as-printed",
                message: "The prayers for the King and the Royal Family are given as printed in 1762."))
            return units.map(element)
        default: return units.map(element)
        }
    }

    private func invitatory(_ units: [ServiceFile.Unit], context: inout Context) -> [ServiceElement] {
        let rubric = units.filter { $0.kind == "rubric" }.map(element)
        let venite = units.filter { $0.kind != "rubric" }.map(element)
        let today = keptToday(context.date)
        if today.contains(ObservanceID("easter")) {
            // Source: "except on Easter-day, upon which another Anthem is appointed".
            context.diagnostics.append(Diagnostic(.info, code: "easter-anthems", message: "On Easter Day the Easter anthems are said instead of the Venite."))
            return rubric + content.easterAnthems.units.map(element)
        }
        if context.date.day == 19 {
            // Source: "on the Nineteenth Day of every Month it is not to be read here".
            context.diagnostics.append(Diagnostic(.info, code: "venite-in-course",
                message: "On the nineteenth day of the month the Venite is not said here: it is read in the ordinary course of the Psalms."))
            return rubric
        }
        return rubric + venite
    }

    private func psalms(_ units: [ServiceFile.Unit], context: inout Context) throws -> [ServiceElement] {
        var out: [ServiceElement] = []
        let glorias = units.filter { $0.kind == "versicles" }
        out += units.filter { $0.kind == "rubric" }.map(element)
        let gloria = glorias.first.map(gloriaVerses) ?? morningGloria()
        let today = keptToday(context.date)
        if let day = today.first(where: { BCP1662Calendar.properPsalmDays.contains($0) }) {
            context.diagnostics.append(Diagnostic(.warning, code: "proper-psalms-unavailable",
                message: "Proper Psalms are appointed for \(ObservanceNames.name(day)), and the psalms of the ordinary course are then omitted. The Table of Proper Psalms is not in the supplied source, so the psalms cannot be given.",
                elementID: "\(context.prefix).psalms.proper"))
            out.append(.placeholder(id: "\(context.prefix).psalms.proper", kind: "proper-psalms", label: "The Proper Psalms",
                                    reason: "The Table of Proper Psalms is not in the supplied source."))
        } else {
            let courseDay = min(context.date.day, 30)
            guard let day = content.psalter.course.first(where: { $0.day == courseDay }) else {
                throw CompositionError.contentMissing("psalter course day \(courseDay)")
            }
            if context.date.day == 31 {
                context.diagnostics.append(Diagnostic(.info, code: "psalter-31st",
                    message: "On the thirty-first day the psalms of the day before are read again, so that the Psalter begins again on the first day of the next month."))
            }
            let half = context.office == .morningPrayer ? day.morning : day.evening
            for reference in half.psalms {
                out.append(try psalmElement(reference, gloria: gloria))
            }
        }
        if context.office == .eveningPrayer {
            out.append(lessonPlaceholder("first", context: &context))
        }
        return out
    }

    private func morningGloria() -> [Verse] {
        content.morningPrayer.units.first { $0.id == "mp.psalms.gloria" }.map(gloriaVerses) ?? []
    }

    private func gloriaVerses(_ unit: ServiceFile.Unit) -> [Verse] {
        (unit.lines ?? []).map { line in
            let parts = line.text.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            return Verse(first: parts[0], second: parts.count > 1 ? parts[1] : nil)
        }
    }

    func psalmElement(_ reference: PsalterFile.Reference, gloria: [Verse]) throws -> ServiceElement {
        guard let psalm = content.psalter.psalms.first(where: { $0.number == reference.psalm }) else {
            throw CompositionError.contentMissing("Psalm \(reference.psalm)")
        }
        var verses = psalm.verses
        var title = "Psalm \(psalm.number)"
        var incipit = psalm.incipit
        var provenance = psalm.provenance
        var id = "psalm.\(psalm.number)"
        if let portion = reference.portion, let part = psalm.portions?.first(where: { $0.portion == portion }) {
            verses = verses.filter { (part.firstVerse...part.lastVerse).contains($0.n) }
            title = "Psalm \(psalm.number), verses \(part.firstVerse)–\(part.lastVerse)"
            incipit = part.incipit
            provenance = part.provenance
            id += ".\(portion)"
        }
        return .psalm(id: id, title: title, latin: incipit,
                      verses: verses.map { Verse(number: $0.printed ?? $0.n, first: $0.first ?? $0.text ?? "", second: $0.second) },
                      gloria: gloria, source: provenance?.reference(source: source))
    }

    private func lessonPlaceholder(_ which: String, context: inout Context) -> ServiceElement {
        let id = "\(context.prefix).lesson.\(which)"
        context.diagnostics.append(Diagnostic(.warning, code: "lessons-unavailable",
            message: "The \(which) lesson is appointed in the Calendar with the Table of Lessons (or the Table of Proper Lessons), which is not in the supplied source. No Scripture translation has been chosen for Lux yet.",
            elementID: id))
        return .placeholder(id: id, kind: "lesson", label: which == "first" ? "The First Lesson" : "The Second Lesson",
                            reason: "The Table of Lessons is not in the supplied source.")
    }

    /// A pair of canticles, the second introduced by its "Or …" rubric.
    private func canticles(_ section: String, _ units: [ServiceFile.Unit], context: inout Context) -> [ServiceElement] {
        guard let split = units.firstIndex(where: { $0.kind == "rubric" }) else { return units.map(element) }
        let first = Array(units[..<split])
        let second = Array(units[split...])
        func label(_ group: [ServiceFile.Unit]) -> String {
            let heading = group.first { $0.kind == "heading" }
            return heading?.latin ?? heading?.text ?? ""
        }
        var options = [ServiceElement.Option(label: label(first), elements: first.map(element)),
                       ServiceElement.Option(label: label(second), elements: second.map(element))]
        let id = "\(context.prefix).\(section)"
        let today = keptToday(context.date)
        switch (context.office, section) {
        case (.morningPrayer, "second-canticle"):
            if today.contains(ObservanceID("john-baptist")) {
                // Source: Benedictus is said "except when that shall happen to
                // be read in the Chapter for the day, or for the gospel on St.
                // John Baptist's Day."
                options.reverse()
                context.diagnostics.append(Diagnostic(.info, code: "jubilate-on-john-baptist",
                    message: "On St John Baptist’s Day the Benedictus is read in the Gospel, so the Jubilate is said.", elementID: id))
            } else {
                context.diagnostics.append(Diagnostic(.info, code: "benedictus-lesson-unknown",
                    message: "The Jubilate is said instead of the Benedictus when the Benedictus is read in the second lesson. The lessons are not available, so this cannot be checked.", elementID: id))
            }
        case (.eveningPrayer, "first-canticle") where context.date.day == 19:
            options.removeLast()
            context.diagnostics.append(Diagnostic(.info, code: "cantate-in-course",
                message: "Cantate Domino is not said on the nineteenth day of the month, when it is read in the ordinary course of the Psalms.", elementID: id))
        case (.eveningPrayer, "second-canticle") where context.date.day == 12:
            options.removeLast()
            context.diagnostics.append(Diagnostic(.info, code: "deus-misereatur-in-course",
                message: "Deus misereatur is not said on the twelfth day of the month, when it is read in the ordinary course of the Psalms.", elementID: id))
        default: break
        }
        if options.count == 1 { return options[0].elements }
        return [.alternatives(id: id, label: options.map(\.label).joined(separator: " or "), options: options)]
    }

    private func creed(_ units: [ServiceFile.Unit], context: inout Context) -> [ServiceElement] {
        guard context.office == .morningPrayer else { return units.map(element) }
        let today = keptToday(context.date)
        guard let feast = today.first(where: { BCP1662Calendar.athanasianCreedDays.contains($0) }) else {
            return units.map(element)
        }
        context.diagnostics.append(Diagnostic(.info, code: "athanasian-creed",
            message: "On \(ObservanceNames.name(feast)) the Creed of St Athanasius is said instead of the Apostles’ Creed."))
        let rubric = units.filter { $0.kind == "rubric" }.map(element)
        return rubric + content.athanasianCreed.units.map(element)
    }

    private func collects(_ units: [ServiceFile.Unit], context: inout Context) throws -> [ServiceElement] {
        let plan = calendar.collectPlan(for: context.office, on: context.date)
        context.diagnostics += plan.diagnostics
        guard let rubricIndex = units.firstIndex(where: { $0.kind == "rubric" }) else {
            throw CompositionError.contentMissing("collects rubric")
        }
        var out = [element(units[rubricIndex])]
        var said: Set<String> = []

        func collectElements(_ id: ObservanceID, includeRubrics: Bool, label: String) throws -> [ServiceElement] {
            guard let observance = content.observance(id) else { throw CompositionError.contentMissing("collect \(id)") }
            var elements: [ServiceElement] = [.heading(id: "collect.\(id).heading", text: label, latin: nil, reference: nil, source: nil)]
            for (n, collect) in observance.collects.enumerated() {
                said.insert(collect.text)
                elements.append(.text(id: "collect.\(id).\(n + 1)", kind: "collect", speaker: .minister, text: collect.text,
                                      citation: nil, source: collect.provenance.reference(source: source)))
            }
            if includeRubrics {
                for (n, rubric) in (observance.rubrics ?? []).enumerated() {
                    elements.append(.rubric(id: "collect.\(id).rubric.\(n + 1)", text: rubric.text,
                                            source: rubric.provenance.reference(source: source)))
                }
            }
            return elements
        }

        let dayLabel = plan.eveOf != nil ? "The Collect of the Day (said on the eve)" : "The Collect of the Day"
        if plan.ofTheDay.count == 1 {
            out += try collectElements(plan.ofTheDay[0], includeRubrics: true, label: "\(dayLabel): \(ObservanceNames.name(plan.ofTheDay[0]))")
        } else {
            var options: [ServiceElement.Option] = []
            for id in plan.ofTheDay {
                options.append(.init(label: ObservanceNames.name(id), elements: try collectElements(id, includeRubrics: true, label: ObservanceNames.name(id))))
            }
            out.append(.alternatives(id: "collect.of-the-day", label: dayLabel, options: options))
        }
        if plan.eveOf != nil {
            context.diagnostics.append(Diagnostic(.info, code: "eve-collect",
                message: "The collect of the following day is said at this Evening Prayer (the eve rule printed at the head of the Collects).", elementID: "collect.of-the-day"))
        }
        for id in plan.following {
            guard let observance = content.observance(id), !observance.collects.allSatisfy({ said.contains($0.text) }) else { continue }
            out += try collectElements(id, includeRubrics: false, label: "Then: \(ObservanceNames.name(id))")
        }
        out += units[(rubricIndex + 1)...].map(element)
        return out
    }

    // MARK: Units

    func element(_ unit: ServiceFile.Unit) -> ServiceElement {
        let reference = unit.provenance.reference(source: source)
        switch unit.kind {
        case "rubric", "colophon":
            return .rubric(id: unit.id, text: unit.text ?? "", source: reference)
        case "heading", "title":
            return .heading(id: unit.id, text: unit.text ?? "", latin: unit.latin, reference: unit.reference, source: reference)
        case "versicles":
            return .versicles(id: unit.id, lines: (unit.lines ?? []).map {
                VersicleLine(speaker: Speaker(rawValue: $0.speaker ?? "minister") ?? .minister, text: $0.text)
            }, source: reference)
        case "lines":
            return .text(id: unit.id, kind: "lines", speaker: nil, text: (unit.lines ?? []).map(\.text).joined(separator: "\n"),
                         citation: nil, source: reference)
        case "canticle":
            return .psalm(id: unit.id, title: nil, latin: nil, verses: (unit.verses ?? []).map(\.verse),
                          gloria: (unit.gloria ?? []).map(\.verse), source: reference)
        default:
            return .text(id: unit.id, kind: unit.kind, speaker: unit.role.flatMap(Speaker.init(rawValue:)), text: unit.text ?? "",
                         citation: unit.citation, source: reference)
        }
    }
}

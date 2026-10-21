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
    /// Where the text of the lessons comes from; without one, lessons are
    /// given by reference with a placeholder for their text.
    var scripture: (any ScriptureProvider)? = nil
    /// The officiant and the choices of ``BCP1662Tradition/serviceOptions``.
    var options: CompositionOptions = .standard

    private var source: String { content.sourceID }
    private var lectionary: Lectionary { Lectionary(lessons: content.lessons, calendar: calendar) }

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
            message: "The Tables and Rules for the Feasts are not in the supplied source text. Lux places the movable feasts by the 1662 rules as editorially encoded; the dates of the holy days agree with the Kalendar of the 1693 printing."))
        context.diagnostics.append(Diagnostic(.info, code: "lectionary-1693",
            message: "The Kalendar, the Proper Lessons and the Proper Psalms are not in the supplied text of the Baskerville printing. They are taken from the London printing of 1693 (Text Creation Partnership transcription A28758), pending comparison with the Baskerville pages."))

        var sections: [ServiceSection] = []
        for (index, spec) in specs.enumerated() {
            guard let start = file.units.firstIndex(where: { $0.id == spec.firstUnit }) else {
                throw CompositionError.contentMissing(spec.firstUnit)
            }
            let end = index + 1 < specs.count ? file.units.firstIndex(where: { $0.id == specs[index + 1].firstUnit }) ?? file.units.count : file.units.count
            let units = Array(file.units[start..<end])
            let elements = try build(section: spec.id, units: units, context: &context)
            if !elements.isEmpty {
                // Without the Absolution the section is the Confession alone.
                let title = spec.id == "confession" && !options.officiant.isPriest ? "Confession" : spec.title
                sections.append(ServiceSection(id: spec.id, title: title, elements: elements))
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
        case "confession": return confession(units, context: &context)
        case "invitatory": return invitatory(units, context: &context)
        case "psalms": return try psalms(units, context: &context)
        case "first-lesson": return units.map(element) + lessonElements(.first, context: &context)
        case "second-lesson": return units.map(element) + lessonElements(.second, context: &context)
        case "first-canticle", "second-canticle": return canticles(section, units, context: &context)
        case "creed": return creed(units, context: &context)
        case "collects": return try collects(units, context: &context)
        case "intercessions":
            if context.office == .morningPrayer && [.sunday, .wednesday, .friday].contains(context.date.weekday) {
                context.diagnostics.append(Diagnostic(.info, code: "litany-not-included",
                    message: "The Litany is appointed after Morning Prayer on Sundays, Wednesdays and Fridays, when only the last two of these prayers are read here. Lux does not yet include the Litany, so the prayers are given as on other days."))
            }
            return statePrayers(units, context: &context)
        default: return units.map(element)
        }
    }

    /// The Confession, and the Absolution if a priest is officiating: it is
    /// "to be pronounced by the Priest alone".
    private func confession(_ units: [ServiceFile.Unit], context: inout Context) -> [ServiceElement] {
        guard !options.officiant.isPriest else { return units.map(element) }
        let absolution: Set<String> = ["\(context.prefix).absolution.rubric", "\(context.prefix).absolution"]
        var out: [ServiceElement] = []
        var replaced = false
        for unit in units {
            guard absolution.contains(unit.id) else {
                out.append(element(unit))
                continue
            }
            guard !replaced else { continue }
            replaced = true
            context.diagnostics.append(Diagnostic(.info, code: "absolution-not-priest",
                message: "The Absolution is “to be pronounced by the Priest alone”, so it is left out when a deacon or lay person says the office.",
                elementID: "\(context.prefix).absolution"))
            if options.choices[BCP1662Tradition.OptionID.absolution] == "trinity-21" {
                out += trinity21Collect(context: &context)
            }
        }
        return out
    }

    /// The Collect for the twenty-first Sunday after Trinity, which a deacon or
    /// lay officiant may say where the Absolution stands. The 1662 book makes
    /// no such provision: it is a custom, chosen in settings and reported.
    private func trinity21Collect(context: inout Context) -> [ServiceElement] {
        let id = ObservanceID("trinity-21")
        guard let collect = content.observance(id)?.collects.first else {
            context.diagnostics.append(Diagnostic(.warning, code: "absolution-substitute-missing",
                message: "The Collect for the twenty-first Sunday after Trinity is not in the content, so nothing is said in place of the Absolution."))
            return []
        }
        let elementID = "\(context.prefix).absolution.trinity-21"
        context.diagnostics.append(Diagnostic(.info, code: "absolution-trinity-21",
            message: "In place of the Absolution the Collect for the twenty-first Sunday after Trinity is said, as chosen in settings. This is a custom of deacons and lay readers, not a rubric of the 1662 book, which makes no provision for Morning or Evening Prayer without a priest.",
            elementID: elementID))
        return [.heading(id: elementID + ".heading", text: "In place of the Absolution: the Collect for the Twenty-first Sunday after Trinity",
                         latin: nil, reference: nil, source: nil),
                .text(id: elementID, kind: "collect", speaker: .minister, text: collect.text, citation: nil,
                      source: collect.provenance.reference(source: source))]
    }

    /// The prayers for the King and the Royal Family, as printed in 1762, or
    /// left out when chosen in settings.
    private func statePrayers(_ units: [ServiceFile.Unit], context: inout Context) -> [ServiceElement] {
        guard options.choices[BCP1662Tradition.OptionID.statePrayers] == "omit" else {
            context.diagnostics.append(Diagnostic(.info, code: "state-prayers-as-printed",
                message: "The prayers for the King and the Royal Family are given as printed in 1762."))
            return units.map(element)
        }
        let state = ["king", "royalfamily"].flatMap { ["\(context.prefix).prayer.\($0).title", "\(context.prefix).prayer.\($0)"] }
        context.diagnostics.append(Diagnostic(.info, code: "state-prayers-omitted",
            message: "The prayers for the King and the Royal Family are left out, as chosen in settings."))
        return units.filter { !state.contains($0.id) }.map(element)
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
        if let proper = lectionary.properPsalms(on: context.date, observances: today, office: context.office) {
            let id = "\(context.prefix).psalms.proper"
            let name = ObservanceNames.name(proper.id)
            context.diagnostics.append(Diagnostic(.info, code: "proper-psalms",
                message: "Proper Psalms are appointed for \(name) (Table of Proper Psalms, “\(proper.cell.printed)”), so the psalms of the ordinary course are omitted.",
                elementID: id))
            if proper.cell.provenance.review != nil {
                context.diagnostics.append(Diagnostic(.warning, code: "proper-psalms-review",
                    message: (proper.cell.provenance.editorial ?? []).joined(separator: " "), elementID: id))
            }
            out.append(.heading(id: id, text: "The Proper Psalms for \(name)", latin: nil, reference: proper.cell.printed, source: nil))
            for number in proper.cell.psalms {
                out.append(try psalmElement(PsalterFile.Reference(psalm: number, portion: nil, verses: nil), gloria: gloria))
            }
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
            out += lessonElements(.first, context: &context)
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

    /// The lesson appointed for a slot: its reference, then a placeholder for
    /// its text (Lux does not yet include a text of the Scriptures).
    private func lessonElements(_ which: Lectionary.Which, context: inout Context) -> [ServiceElement] {
        let id = "\(context.prefix).lesson.\(which.rawValue)"
        let title = which == .first ? "The First Lesson" : "The Second Lesson"
        let slot = lectionary.slot(which, office: context.office, on: context.date)
        context.diagnostics += slot.diagnostics.map { d in
            var d = d
            d.elementID = d.elementID ?? id
            return d
        }
        guard !slot.options.isEmpty else {
            context.diagnostics.append(Diagnostic(.warning, code: "lesson-not-appointed",
                message: "Neither the Kalendar nor the Table of Proper Lessons appoints \(title.lowercased()) for this day (the Kalendar leaves it blank for a holy day kept on another date in this year). The source does not say what is read.",
                elementID: id))
            return [.placeholder(id: id, kind: "lesson", label: title, reason: "No lesson is appointed in the tables for this day.")]
        }
        func elements(_ lesson: LessonsFile.Lesson, id: String) -> [ServiceElement] {
            let reference = lesson.provenance.reference(source: content.lessons.source)
            if lesson.provenance.review != nil {
                context.diagnostics.append(Diagnostic(.info, code: "lesson-reference-review",
                    message: "\(title) (“\(lesson.printed)”): " + (lesson.provenance.editorial ?? []).filter { !$0.hasPrefix("Book named") }.joined(separator: " "),
                    elementID: id))
            }
            let lessonElement = ServiceElement.lesson(id: id, printed: lesson.printed, references: lesson.references, source: reference)
            return [lessonElement] + text(of: lesson, title: title, id: id, context: &context)
        }
        if slot.options.count == 1 { return elements(slot.options[0].lesson, id: id) }
        let options = slot.options.enumerated().map { n, option in
            ServiceElement.Option(label: option.label, elements: elements(option.lesson, id: "\(id).\(n + 1)"))
        }
        return [.alternatives(id: id, label: title, options: options)]
    }

    /// The text of a lesson from the Scripture provider: one reading per run
    /// of verses, and a placeholder wherever the provider lacks the text.
    private func text(of lesson: LessonsFile.Lesson, title: String, id: String, context: inout Context) -> [ServiceElement] {
        guard let scripture else {
            context.diagnostics.append(Diagnostic(.warning, code: "lesson-text-unavailable",
                message: "\(title) is appointed but its text cannot be given: no text of the Scriptures was chosen for this office.",
                elementID: id + ".text"))
            return [.placeholder(id: id + ".text", kind: "lesson-text", label: lesson.references.map(\.description).joined(separator: "; "),
                                 reason: "No text of the Scriptures was chosen.")]
        }
        var out: [ServiceElement] = []
        for (n, reference) in lesson.references.enumerated() {
            let part = lesson.references.count == 1 ? id + ".text" : "\(id).text.\(n + 1)"
            let passage: ScripturePassage?
            do {
                passage = try scripture.passage(reference)
            } catch {
                passage = nil
                context.diagnostics.append(Diagnostic(.error, code: "lesson-text-failed",
                    message: "The \(scripture.title) could not be read for \(reference): \(error)", elementID: part))
            }
            guard let passage else {
                context.diagnostics.append(Diagnostic(.warning, code: "lesson-text-missing",
                    message: "The \(scripture.title) bundled with Lux does not contain \(reference).", elementID: part))
                out.append(.placeholder(id: part, kind: "lesson-text", label: reference.description,
                                        reason: "This passage is not in the bundled \(scripture.title)."))
                continue
            }
            // Split the passage where verses are missing from the source.
            var run: [ScriptureVerse] = []
            var runs = 0
            func flush() {
                guard !run.isEmpty else { return }
                runs += 1
                var piece = passage
                piece.verses = run
                piece.missing = []
                out.append(.reading(id: runs == 1 ? part : "\(part).\(runs)", passage: piece))
                run = []
            }
            var gaps = passage.missing[...]
            for verse in passage.verses {
                let at = VerseLocation(chapter: verse.chapter, verse: verse.number)
                if let gap = gaps.first, gap < at {
                    flush()
                    var group: [VerseLocation] = []
                    while let next = gaps.first, next < at { group.append(next); gaps.removeFirst() }
                    out.append(missingPlaceholder(group, in: reference, id: "\(part).missing.\(group[0])", context: &context))
                }
                if let review = verse.review {
                    context.diagnostics.append(Diagnostic(.info, code: "lesson-text-review",
                        message: "\(reference.book) \(at): \(review)", elementID: part))
                }
                run.append(verse)
            }
            flush()
            if !gaps.isEmpty {
                let group = Array(gaps)
                out.append(missingPlaceholder(group, in: reference, id: "\(part).missing.\(group[0])", context: &context))
            }
        }
        return out
    }

    private func missingPlaceholder(_ verses: [VerseLocation], in reference: ScriptureReference, id: String,
                                    context: inout Context) -> ServiceElement {
        let list = verses.map { "\(reference.book) \($0)" }.joined(separator: ", ")
        context.diagnostics.append(Diagnostic(.warning, code: "lesson-verse-missing",
            message: "\(list): the source of the \(scripture?.title ?? "Scripture text") lacks \(verses.count == 1 ? "this verse" : "these verses"); it is not supplied from elsewhere.",
            elementID: id))
        return .placeholder(id: id, kind: "lesson-verse", label: list, reason: "This verse is missing from the source of the bundled text.")
    }

    /// Whether the second lesson at Morning Prayer includes the Benedictus
    /// (Luke 1:68–79).
    private func benedictusInSecondLesson(_ date: CivilDate) -> Bool {
        guard let lesson = lectionary.slot(.second, office: .morningPrayer, on: date).options.first?.lesson else { return false }
        return lesson.references.contains { r in
            guard r.book == "Luke" else { return false }
            let start = (r.startChapter, r.startVerse ?? 1)
            let end = (r.endChapter ?? r.startChapter, r.endVerse ?? Int.max)
            return start <= (1, 68) && (1, 68) <= end
        }
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
        let printed = [ServiceElement.Option(label: label(first), elements: first.map(element)),
                       ServiceElement.Option(label: label(second), elements: second.map(element))]
        // The canticles that may be said, in the order offered, as indices
        // into `printed`; `forced` when the rubric requires the first of them.
        var order = [0, 1]
        var forced = false
        let id = "\(context.prefix).\(section)"
        let today = keptToday(context.date)
        switch (context.office, section) {
        case (.morningPrayer, "second-canticle"):
            if today.contains(ObservanceID("john-baptist")) {
                // Source: Benedictus is said "except when that shall happen to
                // be read in the Chapter for the day, or for the gospel on St.
                // John Baptist's Day."
                (order, forced) = ([1, 0], true)
                context.diagnostics.append(Diagnostic(.info, code: "jubilate-on-john-baptist",
                    message: "On St John Baptist’s Day the Benedictus is read in the Gospel, so the Jubilate is said.", elementID: id))
            } else if benedictusInSecondLesson(context.date) {
                // Source: the Benedictus is said "except when that shall
                // happen to be read in the Chapter for the day".
                (order, forced) = ([1, 0], true)
                context.diagnostics.append(Diagnostic(.info, code: "jubilate-benedictus-in-lesson",
                    message: "The Benedictus is read in the second lesson today, so the Jubilate is said.", elementID: id))
            }
        case (.eveningPrayer, "first-canticle") where context.date.day == 19:
            order = [0]
            context.diagnostics.append(Diagnostic(.info, code: "cantate-in-course",
                message: "Cantate Domino is not said on the nineteenth day of the month, when it is read in the ordinary course of the Psalms.", elementID: id))
        case (.eveningPrayer, "second-canticle") where context.date.day == 12:
            order = [0]
            context.diagnostics.append(Diagnostic(.info, code: "deus-misereatur-in-course",
                message: "Deus misereatur is not said on the twelfth day of the month, when it is read in the ordinary course of the Psalms.", elementID: id))
        default: break
        }
        // The canticle chosen in settings, unless the rubric requires another.
        if let option = BCP1662Tradition.options.first(where: { $0.id == id }),
           let choice = options.choices[id], let chosen = option.choices.prefix(2).firstIndex(where: { $0.id == choice }) {
            let said = forced || !order.contains(chosen) ? order[0] : chosen
            if said == chosen, order.count > 1 {
                context.diagnostics.append(Diagnostic(.info, code: "canticle-chosen",
                    message: "\(option.choices[said].label) is said, as chosen in settings; the book allows \(option.choices[1 - said].label) instead.", elementID: id))
            }
            return printed[said].elements
        }
        let offered = order.map { printed[$0] }
        if offered.count == 1 { return offered[0].elements }
        return [.alternatives(id: id, label: offered.map(\.label).joined(separator: " or "), options: offered)]
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

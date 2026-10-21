import Foundation
import LuxCore

/// Browsing the book's texts outside a composed office: the Psalter and the
/// Collects, for the Library screen.
extension BCP1662Tradition {
    /// Psalm numbers, 1 to 150.
    public var psalmNumbers: [Int] { content.psalter.psalms.map(\.number) }

    /// A whole psalm (Psalm 119 with all its portions), with its Gloria.
    public func psalm(_ number: Int) -> [ServiceElement] {
        let composer = Composer(content: content, calendar: calendar)
        guard let psalm = content.psalter.psalms.first(where: { $0.number == number }) else { return [] }
        let refs: [PsalterFile.Reference] = psalm.portions.map { portions in
            portions.map { PsalterFile.Reference(psalm: number, portion: $0.portion, verses: nil) }
        } ?? [PsalterFile.Reference(psalm: number, portion: nil, verses: nil)]
        return refs.compactMap { try? composer.libraryPsalm($0) }
    }

    /// Observances with proper collects, in the order of the book.
    public var collectObservances: [ObservanceID] { content.collects.observances.map { ObservanceID($0.id) } }

    /// A run of the Collects in the order of the book, under a heading Lux
    /// gives it (an editorial label, not a title the book prints).
    public struct CollectGroup: Hashable, Sendable, Identifiable {
        public var id: String
        public var title: String
        /// The season it belongs to (`Season` raw value), or `saints` for the
        /// holy days that follow the Sundays.
        public var season: String
        public var observances: [ObservanceID]
    }

    /// The Collects in groups: each group runs from its first observance
    /// up to the next group's.
    public var collectGroups: [CollectGroup] {
        let starts: [(id: String, title: String, season: String, first: String)] = [
            ("advent", "Advent", "advent", "advent-1"),
            ("christmas", "Christmas", "christmas", "christmas"),
            ("epiphany", "The Epiphany", "epiphany", "epiphany"),
            ("before-lent", "Before Lent", "septuagesima", "septuagesima"),
            ("lent", "Lent and Holy Week", "lent", "ash-wednesday"),
            ("easter", "Easter and Ascension", "easter", "easter"),
            ("whitsun", "Whitsuntide", "whitsun", "whitsunday"),
            ("trinity", "Trinity", "trinity", "trinity"),
            ("saints", "Saints’ Days", "saints", "andrew"),
        ]
        let all = collectObservances
        var groups: [CollectGroup] = []
        for (n, start) in starts.enumerated() {
            guard let from = all.firstIndex(of: ObservanceID(start.first)) else { continue }
            let to = starts.dropFirst(n + 1).lazy.compactMap { all.firstIndex(of: ObservanceID($0.first)) }.first ?? all.endIndex
            groups.append(CollectGroup(id: start.id, title: start.title, season: start.season, observances: Array(all[from..<to])))
        }
        return groups
    }

    /// The psalms of a day of the monthly course (1 to 30), as the book
    /// appoints them for Morning or Evening Prayer.
    public func psalms(day: Int, office: Office) -> [ServiceElement] {
        guard let course = content.psalter.course.first(where: { $0.day == day }) else { return [] }
        let composer = Composer(content: content, calendar: calendar)
        let half = office == .morningPrayer ? course.morning : course.evening
        return half.psalms.compactMap { try? composer.libraryPsalm($0) }
    }

    /// The psalm numbers read on a day of the course, for an index.
    public func psalmNumbers(day: Int, office: Office) -> [Int] {
        guard let course = content.psalter.course.first(where: { $0.day == day }) else { return [] }
        var numbers: [Int] = []
        for reference in (office == .morningPrayer ? course.morning : course.evening).psalms where numbers.last != reference.psalm {
            numbers.append(reference.psalm)
        }
        return numbers
    }

    /// The collect (or collects) of an observance and its governing rubrics.
    public func collects(for id: ObservanceID) -> [ServiceElement] {
        guard let observance = content.observance(id) else { return [] }
        var out: [ServiceElement] = observance.collects.enumerated().map { n, collect in
            .text(id: "collect.\(id).\(n + 1)", kind: "collect", speaker: .minister, text: collect.text, citation: nil,
                  source: collect.provenance.reference(source: content.sourceID))
        }
        out += (observance.rubrics ?? []).enumerated().map { n, rubric in
            .rubric(id: "collect.\(id).rubric.\(n + 1)", text: rubric.text, source: rubric.provenance.reference(source: content.sourceID))
        }
        return out
    }

    /// The Creed of St Athanasius, with its rubric.
    public var athanasianCreed: [ServiceElement] {
        let composer = Composer(content: content, calendar: calendar)
        return content.athanasianCreed.units.map(composer.element)
    }
}

extension Composer {
    func libraryPsalm(_ reference: PsalterFile.Reference) throws -> ServiceElement {
        let gloria = content.morningPrayer.units.first { $0.id == "mp.psalms.gloria" }.map { unit in
            (unit.lines ?? []).map { line -> Verse in
                let parts = line.text.split(separator: ":", maxSplits: 1)
                return Verse(first: parts[0].trimmingCharacters(in: .whitespaces),
                             second: parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil)
            }
        } ?? []
        return try psalmElement(reference, gloria: gloria)
    }
}

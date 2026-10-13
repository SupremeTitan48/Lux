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

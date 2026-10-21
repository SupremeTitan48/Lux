import Foundation
import LuxCore
import Testing
@testable import BCP1662

/// The officiant and the choices offered in settings.
@Suite struct ServiceOptionsTests {
    static let tradition = try! BCP1662Tradition.bundled()
    typealias ID = BCP1662Tradition.OptionID

    func compose(_ office: Office, _ date: CivilDate, officiant: Officiant = .priest,
                 _ choices: [String: String] = [:]) throws -> ServiceDocument {
        try ServiceOptionsTests.tradition.compose(office, on: date, options: CompositionOptions(officiant: officiant, choices: choices))
    }

    func ids(_ doc: ServiceDocument) -> [String] {
        func walk(_ e: ServiceElement) -> [String] {
            if case let .alternatives(id, _, options) = e { return [id] + options.flatMap { $0.elements.flatMap(walk) } }
            return [e.id]
        }
        return doc.elements.flatMap(walk)
    }

    func alternatives(_ doc: ServiceDocument) -> [String] {
        doc.elements.compactMap { if case let .alternatives(id, _, _) = $0 { return id } else { return nil } }
    }

    /// Every text in the document, to check nothing is reworded.
    func texts(_ doc: ServiceDocument) -> [String: String] {
        var out: [String: String] = [:]
        func walk(_ e: ServiceElement) {
            switch e {
            case let .text(id, _, _, text, _, _), let .rubric(id, text, _): out[id] = text
            case let .alternatives(_, _, options): options.forEach { $0.elements.forEach(walk) }
            default: break
            }
        }
        doc.elements.forEach(walk)
        return out
    }

    @Test func optionsAreWellFormed() {
        let options = ServiceOptionsTests.tradition.serviceOptions
        #expect(Set(options.map(\.id)).count == options.count)
        for option in options {
            #expect(option.choices.contains { $0.id == option.defaultChoice })
        }
        let absolution = options.first { $0.id == ID.absolution }!
        #expect(!absolution.applies(to: .priest) && absolution.applies(to: .deacon) && absolution.applies(to: .layPerson))
    }

    @Test func defaultCompositionIsUnchanged() throws {
        let date = CivilDate(2026, 10, 13)
        for office in [Office.morningPrayer, .eveningPrayer] {
            #expect(try compose(office, date) == ServiceOptionsTests.tradition.compose(office, on: date))
        }
    }

    // MARK: The officiant

    @Test(arguments: [Officiant.deacon, .layPerson])
    func absolutionIsLeftOutWithoutAPriest(officiant: Officiant) throws {
        for office in [Office.morningPrayer, .eveningPrayer] {
            let prefix = office == .morningPrayer ? "mp" : "ep"
            let priest = try compose(office, CivilDate(2026, 10, 13))
            let doc = try compose(office, CivilDate(2026, 10, 13), officiant: officiant)
            let all = ids(doc)
            #expect(!all.contains("\(prefix).absolution") && !all.contains("\(prefix).absolution.rubric"))
            #expect(all.contains("\(prefix).confession") && all.contains("\(prefix).lordsprayer"))
            #expect(doc.diagnostics.contains { $0.code == "absolution-not-priest" })
            #expect(doc.diagnostics.contains { $0.code == "officiant-labels" })
            #expect(doc.sections.first { $0.id == "confession" }?.title == "Confession")
            // Only the Absolution is gone; every other text is as printed.
            var expected = texts(priest)
            expected["\(prefix).absolution"] = nil
            expected["\(prefix).absolution.rubric"] = nil
            #expect(texts(doc) == expected)
        }
    }

    @Test func trinity21CollectInPlaceOfTheAbsolution() throws {
        let doc = try compose(.morningPrayer, CivilDate(2026, 10, 13), officiant: .layPerson, [ID.absolution: "trinity-21"])
        let all = ids(doc)
        let at = all.firstIndex(of: "mp.absolution.trinity-21")!
        #expect(all.firstIndex(of: "mp.confession")! < at && at < all.firstIndex(of: "mp.lordsprayer")!)
        let collect = doc.elements.first { $0.id == "mp.absolution.trinity-21" }!
        guard case let .text(_, _, _, text, _, source) = collect else { Issue.record("not a text"); return }
        #expect(text == ServiceOptionsTests.tradition.content.observance(ObservanceID("trinity-21"))!.collects[0].text)
        #expect(source != nil)
        // The heading is Lux's label, without a source reference.
        guard case let .heading(_, _, _, _, headingSource) = doc.elements.first(where: { $0.id == "mp.absolution.trinity-21.heading" })! else {
            Issue.record("no heading"); return
        }
        #expect(headingSource == nil)
        #expect(doc.diagnostics.contains { $0.code == "absolution-trinity-21" })
    }

    @Test func priestIgnoresTheAbsolutionOption() throws {
        let doc = try compose(.morningPrayer, CivilDate(2026, 10, 13), officiant: .priest, [ID.absolution: "trinity-21"])
        #expect(ids(doc).contains("mp.absolution"))
        #expect(!ids(doc).contains("mp.absolution.trinity-21"))
    }

    // MARK: State prayers

    @Test func statePrayersCanBeLeftOut() throws {
        for office in [Office.morningPrayer, .eveningPrayer] {
            let prefix = office == .morningPrayer ? "mp" : "ep"
            let doc = try compose(office, CivilDate(2026, 10, 13), [ID.statePrayers: "omit"])
            let all = ids(doc)
            for id in ["king", "royalfamily"] {
                #expect(!all.contains("\(prefix).prayer.\(id)") && !all.contains("\(prefix).prayer.\(id).title"))
            }
            #expect(all.contains("\(prefix).prayer.clergy") && all.contains("\(prefix).prayer.chrysostom") && all.contains("\(prefix).grace"))
            #expect(doc.diagnostics.contains { $0.code == "state-prayers-omitted" })
            #expect(!doc.diagnostics.contains { $0.code == "state-prayers-as-printed" })
        }
    }

    @Test func statePrayersAreIncludedByDefault() throws {
        let doc = try compose(.morningPrayer, CivilDate(2026, 10, 13), [ID.statePrayers: "include"])
        #expect(ids(doc).contains("mp.prayer.king") && ids(doc).contains("mp.prayer.royalfamily"))
    }

    // MARK: Canticles

    @Test func chosenCanticlesReplaceThePickers() throws {
        let morning = try compose(.morningPrayer, CivilDate(2026, 10, 13),
                                  [ID.morningFirstCanticle: "benedicite", ID.morningSecondCanticle: "jubilate"])
        #expect(alternatives(morning).filter { $0.hasSuffix("canticle") }.isEmpty)
        let m = ids(morning)
        #expect(m.contains("mp.benedicite") && !m.contains("mp.tedeum"))
        #expect(m.contains("mp.jubilate") && !m.contains("mp.benedictus"))
        #expect(morning.diagnostics.filter { $0.code == "canticle-chosen" }.count == 2)

        let evening = try compose(.eveningPrayer, CivilDate(2026, 10, 13),
                                  [ID.eveningFirstCanticle: "magnificat", ID.eveningSecondCanticle: "deus-misereatur"])
        let e = ids(evening)
        #expect(e.contains("ep.magnificat") && !e.contains("ep.cantate"))
        #expect(e.contains("ep.deus") && !e.contains("ep.nuncdimittis"))
    }

    @Test func bothLeavesTheChoiceInTheOffice() throws {
        let doc = try compose(.eveningPrayer, CivilDate(2026, 10, 13),
                              [ID.eveningFirstCanticle: BCP1662Tradition.bothCanticles, ID.eveningSecondCanticle: BCP1662Tradition.bothCanticles])
        #expect(alternatives(doc).contains("ep.first-canticle") && alternatives(doc).contains("ep.second-canticle"))
    }

    /// The rubrics overrule a chosen canticle.
    @Test func rubricsOverruleTheChoice() throws {
        // Deus misereatur is not said on the 12th, Cantate not on the 19th.
        let twelfth = ids(try compose(.eveningPrayer, CivilDate(2026, 10, 12), [ID.eveningSecondCanticle: "deus-misereatur"]))
        #expect(twelfth.contains("ep.nuncdimittis") && !twelfth.contains("ep.deus"))
        let nineteenth = ids(try compose(.eveningPrayer, CivilDate(2026, 10, 19), [ID.eveningFirstCanticle: "cantate"]))
        #expect(nineteenth.contains("ep.magnificat") && !nineteenth.contains("ep.cantate"))
        // On St John Baptist's Day the Jubilate is said even when the Benedictus is chosen.
        let baptist = try compose(.morningPrayer, CivilDate(2026, 6, 24), [ID.morningSecondCanticle: "benedictus"])
        #expect(ids(baptist).contains("mp.jubilate") && !ids(baptist).contains("mp.benedictus"))
        #expect(!baptist.diagnostics.contains { $0.code == "canticle-chosen" })
        // So too when the second lesson contains the Benedictus (Luke 1, 15 October).
        let lesson = ids(try compose(.morningPrayer, CivilDate(2026, 10, 15), [ID.morningSecondCanticle: "benedictus"]))
        #expect(lesson.contains("mp.jubilate") && !lesson.contains("mp.benedictus"))
    }
}

import Foundation
import LuxCore
import Testing
@testable import BCP1662

@Suite struct ComposerTests {
    static let tradition = try! BCP1662Tradition.bundled()

    func compose(_ office: Office, _ y: Int, _ m: Int, _ d: Int) throws -> ServiceDocument {
        try ComposerTests.tradition.compose(office, on: CivilDate(y, m, d))
    }

    func ids(_ doc: ServiceDocument) -> [String] {
        func walk(_ e: ServiceElement) -> [String] {
            if case let .alternatives(id, _, options) = e { return [id] + options.flatMap { $0.elements.flatMap(walk) } }
            return [e.id]
        }
        return doc.elements.flatMap(walk)
    }

    func psalms(_ doc: ServiceDocument) -> [String] {
        doc.sections.first { $0.id == "psalms" }!.elements.compactMap {
            if case let .psalm(id, _, _, _, _, _) = $0 { return id }
            return nil
        }
    }

    @Test func contentVerifiesAgainstManifest() throws {
        _ = try BCP1662Content.bundled(verify: true)
    }

    @Test func composesEveryDayOfAYear() throws {
        var date = CivilDate(2026, 1, 1)
        while date.year == 2026 {
            for office in ComposerTests.tradition.offices {
                let doc = try ComposerTests.tradition.compose(office, on: date)
                #expect(!doc.sections.isEmpty)
                #expect(!doc.diagnostics.contains { $0.severity == .error })
                let allIDs = ids(doc)
                #expect(Set(allIDs).count == allIDs.count, "duplicate element ids on \(date)")
            }
            date = date.adding(days: 1)
        }
    }

    @Test func ordinaryMorningPrayer() throws {
        let doc = try compose(.morningPrayer, 2026, 10, 13)
        #expect(doc.day.title == "Tuesday after the Nineteenth Sunday after Trinity")
        #expect(psalms(doc) == ["psalm.68"])
        let all = ids(doc)
        #expect(all.contains("mp.venite"))
        #expect(all.contains("mp.creed"))
        #expect(!all.contains("ath.creed"))
        #expect(all.contains("collect.trinity-19.1"))
        #expect(all.contains("mp.lesson.first") && all.contains("mp.lesson.second"))
        #expect(doc.diagnostics.contains { $0.code == "lesson-text-unavailable" && $0.severity == .warning })
        // Order of the office as printed.
        let order = ["mp.sentences.rubric", "mp.confession", "mp.absolution", "mp.lordsprayer", "mp.venite", "psalm.68",
                     "mp.lesson.first", "mp.tedeum", "mp.lesson.second", "mp.benedictus", "mp.creed", "mp.suffrages",
                     "collect.trinity-19.1", "mp.collect.peace", "mp.collect.grace", "mp.prayer.chrysostom", "mp.grace"]
        let positions = order.map { all.firstIndex(of: $0)! }
        #expect(positions == positions.sorted())
    }

    @Test func eveningPsalmsAndCanticles() throws {
        let doc = try compose(.eveningPrayer, 2026, 10, 13)
        #expect(psalms(doc) == ["psalm.69", "psalm.70"])
        let all = ids(doc)
        for id in ["ep.magnificat", "ep.cantate", "ep.nuncdimittis", "ep.deus", "ep.collect.aid"] { #expect(all.contains(id)) }
    }

    @Test func psalm119IsReadInPortions() throws {
        let doc = try compose(.eveningPrayer, 2026, 10, 24)
        #expect(psalms(doc) == ["psalm.119.1", "psalm.119.2", "psalm.119.3", "psalm.119.4"])
        guard case let .psalm(_, title, latin, verses, gloria, _) = doc.sections.first(where: { $0.id == "psalms" })!
            .elements.first(where: { $0.id == "psalm.119.2" })! else { Issue.record("not a psalm"); return }
        #expect(title == "Psalm 119, verses 9–16")
        #expect(latin == "In quo corriget?")
        #expect(verses.count == 8)
        #expect(verses.first?.number == 1)  // numbered within the portion, as printed
        #expect(gloria.count == 2)
    }

    @Test func thirtyFirstRepeatsTheThirtieth() throws {
        let thirtieth = try compose(.morningPrayer, 2026, 10, 30)
        let thirtyFirst = try compose(.morningPrayer, 2026, 10, 31)
        #expect(psalms(thirtieth) == psalms(thirtyFirst))
        #expect(thirtyFirst.diagnostics.contains { $0.code == "psalter-31st" })
    }

    @Test func nineteenthDay() throws {
        let morning = try compose(.morningPrayer, 2026, 10, 19)
        #expect(!ids(morning).contains("mp.venite"))
        #expect(ids(morning).contains("mp.venite.rubric"))
        #expect(psalms(morning) == ["psalm.95", "psalm.96", "psalm.97"])
        let evening = try compose(.eveningPrayer, 2026, 10, 19)
        #expect(!ids(evening).contains("ep.cantate"))
        #expect(ids(evening).contains("ep.magnificat"))
        #expect(psalms(evening).contains("psalm.98"))
    }

    @Test func twelfthDay() throws {
        let evening = try compose(.eveningPrayer, 2026, 10, 12)
        #expect(!ids(evening).contains("ep.deus"))
        #expect(psalms(evening).contains("psalm.67"))
    }

    @Test func easterDay() throws {
        let doc = try compose(.morningPrayer, 2026, 4, 5)
        let all = ids(doc)
        #expect(!all.contains("mp.venite"))
        #expect(all.contains("easter.anthem.1-cor-5-7"))
        #expect(all.contains("ath.creed"))
        #expect(!all.contains("mp.creed"))
        #expect(all.contains("mp.psalms.proper"))
        #expect(psalms(doc) == ["psalm.2", "psalm.57", "psalm.111"])
        #expect(doc.diagnostics.contains { $0.code == "proper-psalms" })
    }

    @Test func athanasianCreedOnlyAtMorningPrayer() throws {
        #expect(ids(try compose(.morningPrayer, 2026, 11, 30)).contains("ath.creed"))  // St Andrew
        #expect(!ids(try compose(.eveningPrayer, 2026, 11, 30)).contains("ath.creed"))
        #expect(ids(try compose(.morningPrayer, 2026, 5, 31)).contains("ath.creed"))  // Trinity Sunday
        #expect(!ids(try compose(.morningPrayer, 2026, 6, 7)).contains("ath.creed"))
    }

    @Test func jubilateOnStJohnBaptist() throws {
        let doc = try compose(.morningPrayer, 2026, 6, 24)
        guard case let .alternatives(_, _, options) = doc.sections.first(where: { $0.id == "second-canticle" })!.elements[0] else {
            Issue.record("expected alternatives"); return
        }
        #expect(options[0].elements.contains { $0.id == "mp.jubilate" })
    }

    @Test func goodFridayHasThreeCollectsThenAshWednesday() throws {
        let all = ids(try compose(.morningPrayer, 2026, 4, 3))
        let wanted = ["collect.good-friday.1", "collect.good-friday.2", "collect.good-friday.3", "collect.ash-wednesday.1", "mp.collect.peace"]
        let positions = wanted.map { all.firstIndex(of: $0)! }
        #expect(positions == positions.sorted())
    }

    @Test func sundayAfterChristmasDoesNotRepeatTheSameCollect() throws {
        // The collect for the Sunday after Christmas is printed as the
        // Christmas collect; it is said once.
        let doc = try compose(.morningPrayer, 2026, 12, 27)
        let collects = doc.sections.first { $0.id == "collects" }!.elements.compactMap { element -> String? in
            if case let .text(_, "collect", _, text, _, _) = element { return text }
            return nil
        }
        #expect(Set(collects).count == collects.count)
    }

    @Test func refusesDatesBeforeTheGregorianCalendar() {
        #expect(throws: CompositionError.self) { try ComposerTests.tradition.compose(.morningPrayer, on: CivilDate(1700, 1, 1)) }
    }

    @Test func noElementWithoutSourceExceptLabelsAndPlaceholders() throws {
        let doc = try compose(.eveningPrayer, 2026, 12, 24)
        func check(_ e: ServiceElement) {
            switch e {
            case let .rubric(id, _, source), let .text(id, _, _, _, _, source), let .versicles(id, _, source),
                 let .psalm(id, _, _, _, _, source):
                #expect(source != nil, "\(id) has no source")
            case let .alternatives(_, _, options):
                options.forEach { $0.elements.forEach(check) }
            case let .heading(id, _, _, _, source):
                #expect(source != nil || id.hasPrefix("collect.") || id.hasSuffix(".psalms.proper"), "\(id) has no source")
            case let .lesson(id, _, _, source):
                #expect(source != nil, "\(id) has no source")
            case .placeholder:
                break
            }
        }
        doc.elements.forEach(check)
    }
}

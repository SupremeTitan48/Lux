import BCP1662
import LuxCore
import Testing
import LuxKJV

/// Every lesson the 1662 lectionary appoints is in the bundled text.
@Suite struct LectionaryCoverageTests {
    @Test func everyLessonOfTwoYearsResolves() throws {
        let kjv = try KJVProvider.bundled()
        let tradition = try BCP1662Tradition.bundled(scripture: [kjv])
        let options = CompositionOptions(scriptureTranslationID: KJVProvider.identifier)
        // 2026 has St Luke on a Sunday; 2028 is a leap year.
        for year in [2026, 2028] {
            var date = CivilDate(year, 1, 1)
            while date.year == year {
                for office in tradition.offices {
                    let doc = try tradition.compose(office, on: date, options: options)
                    let problems = doc.diagnostics.filter {
                        ["lesson-text-missing", "lesson-text-failed", "lesson-verse-missing", "lesson-text-unavailable"].contains($0.code)
                    }
                    #expect(problems.isEmpty, "\(date) \(office.rawValue): \(problems.map(\.message))")
                }
                date = date.adding(days: 1)
            }
        }
    }

    @Test func readingsFollowTheLesson() throws {
        let tradition = try BCP1662Tradition.bundled(scripture: [try KJVProvider.bundled()])
        let doc = try tradition.compose(.morningPrayer, on: CivilDate(2026, 12, 25),
                                        options: CompositionOptions(scriptureTranslationID: KJVProvider.identifier))
        let second = doc.sections.first { $0.id == "second-lesson" }!.elements
        guard case let .reading(_, passage) = second.first(where: { if case .reading = $0 { true } else { false } }) else {
            Issue.record("no reading"); return
        }
        // Christmas Day, Morning Prayer: Luke 2 to verse 15 (printed), read to verse 14.
        #expect(passage.reference.book == "Luke")
        #expect(passage.verses.map(\.number) == Array(1...14))
        #expect(passage.verses.last?.text.hasPrefix("Glory to God in the highest") == true)
    }
}

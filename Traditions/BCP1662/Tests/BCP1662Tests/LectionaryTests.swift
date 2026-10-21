import Foundation
import LuxCore
import Testing
@testable import BCP1662

/// Lessons and Proper Psalms (from the tables of the 1693 printing).
@Suite struct LectionaryTests {
    static let tradition = try! BCP1662Tradition.bundled()
    static let lectionary = Lectionary(lessons: tradition.content.lessons, calendar: tradition.calendar)

    func compose(_ office: Office, _ y: Int, _ m: Int, _ d: Int) throws -> ServiceDocument {
        try LectionaryTests.tradition.compose(office, on: CivilDate(y, m, d))
    }

    /// The lessons in a section, as "printed → resolved" for each option.
    func lessons(_ doc: ServiceDocument, _ section: String) -> [[String]] {
        func walk(_ e: ServiceElement) -> [[String]] {
            switch e {
            case let .lesson(_, _, references, _): return [references.map(\.description)]
            case let .alternatives(_, _, options): return options.flatMap { $0.elements.flatMap(walk) }
            default: return []
            }
        }
        return doc.sections.first { $0.id == section }!.elements.flatMap(walk)
    }

    func secondCanticleFirstOption(_ doc: ServiceDocument) -> String? {
        guard case let .alternatives(_, _, options) = doc.sections.first(where: { $0.id == "second-canticle" })!.elements[0] else { return nil }
        return options[0].elements.first { $0.id == "mp.jubilate" || $0.id == "mp.benedictus" }?.id
    }

    @Test func kalendarBlanksFallOnTheHolyDays() {
        // The Kalendar leaves a lesson blank exactly where the Table of
        // Proper Lessons appoints one for an immovable holy day. This checks
        // the holy-day dates Lux encodes against the printed Kalendar.
        let lessons = LectionaryTests.tradition.content.lessons
        var blankDays = Set<String>()
        for day in lessons.kalendar {
            for office in [day.morning, day.evening] {
                if (office.first ?? nil) == nil || (office.second ?? nil) == nil { blankDays.insert("\(day.month)-\(day.day)") }
            }
        }
        let fixed = Set(BCP1662Calendar.fixedHolyDays.map { "\($0.month)-\($0.day)" })
        #expect(blankDays == fixed)
        for feast in BCP1662Calendar.fixedHolyDays {
            let day = lessons.kalendar.first { $0.month == feast.month && $0.day == feast.day }!
            let row = lessons.holyDays.first { $0.observance == feast.id }!
            for (kalendar, proper) in [(day.morning, row.morning), (day.evening, row.evening)] {
                #expect(((kalendar.first ?? nil) == nil) == ((proper.first ?? nil) != nil), "\(feast.id) first lesson")
                // St Michael is the one exception: the Kalendar also prints
                // second lessons (recorded in data/lectionary.json).
                if feast.id != "michael" {
                    #expect(((kalendar.second ?? nil) == nil) == ((proper.second ?? nil) != nil), "\(feast.id) second lesson")
                }
            }
        }
    }

    @Test func properPsalmDaysMatchTheTable() {
        let table = Set(LectionaryTests.tradition.content.lessons.properPsalms.map { ObservanceID($0.observance) })
        #expect(table == BCP1662Calendar.properPsalmDays)
    }

    @Test func whitsundayEvensongPsalmsAsPrinted() throws {
        // The 1693 table reads "civ. cxiv."; later printings read civ, cxlv.
        // Preserved as printed and flagged (data/lectionary.json).
        let doc = try compose(.eveningPrayer, 2026, 5, 24)
        let psalms = doc.sections.first { $0.id == "psalms" }!.elements.compactMap { e -> String? in
            if case let .psalm(id, _, _, _, _, _) = e { return id }
            return nil
        }
        #expect(psalms == ["psalm.104", "psalm.114"])
        #expect(doc.diagnostics.contains { $0.code == "proper-psalms-review" && $0.severity == .warning })
    }

    @Test func ordinaryWeekdayFromTheKalendar() throws {
        // 13 October: Wisdom 1 and Mark 16 at Morning Prayer, Wisdom 2 and
        // 2 Corinthians 12 at Evening Prayer.
        let morning = try compose(.morningPrayer, 2026, 10, 13)
        #expect(lessons(morning, "first-lesson") == [["Wisdom 1"]])
        #expect(lessons(morning, "second-lesson") == [["Mark 16"]])
        let evening = try compose(.eveningPrayer, 2026, 10, 13)
        #expect(lessons(evening, "psalms") == [["Wisdom 2"]])
        #expect(lessons(evening, "second-lesson") == [["2 Corinthians 12"]])
    }

    @Test func sundayFirstLessonsKalendarSecondLessons() throws {
        // Advent Sunday 2026 (29 November): Isaiah 1 and 2; the second
        // lessons are the Kalendar's for 29 November.
        let morning = try compose(.morningPrayer, 2026, 11, 29)
        #expect(lessons(morning, "first-lesson") == [["Isaiah 1"]])
        #expect(lessons(morning, "second-lesson") == [["John 21"]])
        let evening = try compose(.eveningPrayer, 2026, 11, 29)
        #expect(lessons(evening, "psalms") == [["Isaiah 2"]])
    }

    @Test func easterDay() throws {
        let morning = try compose(.morningPrayer, 2026, 4, 5)
        #expect(lessons(morning, "first-lesson") == [["Exodus 12"]])
        #expect(lessons(morning, "second-lesson") == [["Romans 6"]])
        let evening = try compose(.eveningPrayer, 2026, 4, 5)
        #expect(lessons(evening, "psalms") == [["Exodus 14"]])
        #expect(lessons(evening, "second-lesson") == [["Acts 2:22–end"]])
        let psalms = evening.sections.first { $0.id == "psalms" }!.elements.compactMap { e -> String? in
            if case let .psalm(id, _, _, _, _, _) = e { return id }
            return nil
        }
        #expect(psalms == ["psalm.113", "psalm.114", "psalm.118"])
    }

    @Test func holyDayOnASundayOffersBoth() throws {
        // St Luke on the twentieth Sunday after Trinity, 2026.
        let doc = try compose(.morningPrayer, 2026, 10, 18)
        let first = doc.sections.first { $0.id == "first-lesson" }!.elements.last!
        guard case let .alternatives(_, _, options) = first else { Issue.record("expected alternatives"); return }
        #expect(options.map(\.label) == ["Saint Luke the Evangelist", "The Twentieth Sunday after Trinity"])
        #expect(lessons(doc, "first-lesson") == [["Ecclesiasticus 51"], ["Joel 2"]])
        #expect(doc.diagnostics.contains { $0.code == "lessons-concurrent" })
    }

    @Test func christmasDayLessonsAndPsalms() throws {
        let doc = try compose(.morningPrayer, 2026, 12, 25)
        #expect(lessons(doc, "first-lesson") == [["Isaiah 9:1–7"]])
        #expect(lessons(doc, "second-lesson") == [["Luke 2:1–14"]])
        #expect(doc.elements.contains { $0.id == "psalm.85" })
    }

    @Test func wednesdayBeforeEaster() throws {
        // A proper second lesson in the morning only; the evening's is the Kalendar's.
        let morning = try compose(.morningPrayer, 2026, 4, 1)
        #expect(lessons(morning, "second-lesson") == [["John 11:45–end"]])
        let evening = try compose(.eveningPrayer, 2026, 4, 1)
        #expect(lessons(evening, "psalms") == [["Hosea 14"]])
        #expect(lessons(evening, "second-lesson") == [["Hebrews 3"]])
    }

    @Test func leapYear() throws {
        // The Kalendar's 29th of February serves in leap years.
        #expect(lessons(try compose(.morningPrayer, 2028, 2, 29), "first-lesson") == [["Deuteronomy 13"]])
        // In a leap year St Matthias is kept on the 25th, so the Kalendar's
        // blank on the 24th is filled by nothing: Lux says so.
        let doc = try compose(.morningPrayer, 2028, 2, 24)
        #expect(doc.diagnostics.contains { $0.code == "lesson-not-appointed" })
        #expect(lessons(try compose(.morningPrayer, 2028, 2, 25), "first-lesson") == [["Wisdom 19"]])
    }

    @Test func twentySeventhSundayAfterTrinity() throws {
        // 2008 had twenty-seven Sundays after Trinity; the table stops at the
        // twenty-sixth, so the Kalendar's lessons are read.
        let doc = try compose(.morningPrayer, 2008, 11, 23)
        #expect(doc.diagnostics.contains { $0.code == "lessons-beyond-table" })
        #expect(!lessons(doc, "first-lesson").isEmpty)
    }

    @Test func jubilateWhenTheBenedictusIsInTheLesson() throws {
        // 18 February reads Luke 1 from verse 39, which includes the Benedictus.
        #expect(secondCanticleFirstOption(try compose(.morningPrayer, 2026, 2, 18)) == "mp.jubilate")
        #expect(secondCanticleFirstOption(try compose(.morningPrayer, 2026, 2, 17)) == "mp.benedictus")
    }

    @Test func everyLessonHasProvenance() throws {
        var date = CivilDate(2026, 1, 1)
        while date.year == 2026 {
            for office in LectionaryTests.tradition.offices {
                let doc = try LectionaryTests.tradition.compose(office, on: date)
                func walk(_ e: ServiceElement) {
                    switch e {
                    case let .lesson(id, printed, references, source):
                        #expect(source?.sourceID == "bcp1662-london1693-tcp", "\(id) on \(date)")
                        #expect(!printed.isEmpty && !references.isEmpty)
                    case let .alternatives(_, _, options): options.forEach { $0.elements.forEach(walk) }
                    default: break
                    }
                }
                doc.elements.forEach(walk)
                let count = doc.sections.flatMap(\.elements).filter {
                    if case .lesson = $0 { return true }
                    if case let .alternatives(id, _, _) = $0 { return id.contains(".lesson.") }
                    return false
                }.count
                #expect(count == 2, "\(office.rawValue) on \(date) has \(count) lessons")
            }
            date = date.adding(days: 1)
        }
    }
}

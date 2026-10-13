import Testing
@testable import LuxCore

@Suite struct CivilDateTests {
    @Test func rejectsImpossibleDates() {
        #expect(CivilDate(year: 2025, month: 2, day: 29) == nil)
        #expect(CivilDate(year: 2024, month: 2, day: 29) != nil)
        #expect(CivilDate(year: 1900, month: 2, day: 29) == nil)
        #expect(CivilDate(year: 2000, month: 2, day: 29) != nil)
        #expect(CivilDate(year: 2025, month: 4, day: 31) == nil)
        #expect(CivilDate(year: 2025, month: 13, day: 1) == nil)
    }

    @Test func dayNumberRoundTrips() {
        var date = CivilDate(1752, 1, 1)
        for _ in 0..<(366 * 300) {
            #expect(CivilDate(dayNumber: date.dayNumber) == date)
            let next = date.adding(days: 1)
            #expect(next.dayNumber == date.dayNumber + 1)
            #expect(next > date)
            date = next
        }
    }

    @Test(arguments: [
        (CivilDate(2026, 10, 13), Weekday.tuesday),
        (CivilDate(2000, 1, 1), Weekday.saturday),
        (CivilDate(1762, 4, 11), Weekday.sunday),  // Easter Day 1762
        (CivilDate(1752, 9, 14), Weekday.thursday),  // first Gregorian day in Great Britain
        (CivilDate(2024, 12, 25), Weekday.wednesday),
    ])
    func weekdays(date: CivilDate, weekday: Weekday) {
        #expect(date.weekday == weekday)
    }

    @Test func nextAndPrevious() {
        let tuesday = CivilDate(2026, 10, 13)
        #expect(tuesday.next(.sunday) == CivilDate(2026, 10, 18))
        #expect(tuesday.previous(.sunday) == CivilDate(2026, 10, 11))
        #expect(tuesday.next(.tuesday) == tuesday)
        #expect(tuesday.next(.tuesday, includingSelf: false) == CivilDate(2026, 10, 20))
        #expect(tuesday.previous(.tuesday, includingSelf: false) == CivilDate(2026, 10, 6))
    }

    @Test func isoText() throws {
        #expect(CivilDate(1762, 4, 1).description == "1762-04-01")
        #expect(CivilDate("2026-10-13") == CivilDate(2026, 10, 13))
        #expect(CivilDate("2026-02-30") == nil)
        #expect(CivilDate("today") == nil)
    }
}

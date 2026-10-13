import LuxCore
import Testing
@testable import BCP1662

@Suite struct CalendarTests {
    let calendar = BCP1662Calendar()

    func sunday(_ y: Int, _ m: Int, _ d: Int) -> String? {
        calendar.sundayProper(CivilDate(y, m, d))?.id.rawValue
    }

    @Test func anchors2026() {
        #expect(calendar.easter(2026) == CivilDate(2026, 4, 5))
        #expect(calendar.adventSunday(2026) == CivilDate(2026, 11, 29))
        #expect(calendar.septuagesima(2026) == CivilDate(2026, 2, 1))
        #expect(calendar.trinitySunday(2026) == CivilDate(2026, 5, 31))
        #expect(calendar.epiphanySundayCount(2026) == 3)
        #expect(calendar.trinitySundayCount(2026) == 25)
    }

    @Test func adventSundayIsNearestStAndrew() {
        for year in 1753...2400 {
            let advent = calendar.adventSunday(year)
            #expect(advent.weekday == .sunday)
            #expect(abs(advent.days(to: CivilDate(year, 11, 30))) <= 3)
        }
    }

    @Test func sundaysOf2026() {
        #expect(sunday(2026, 1, 4) == nil)  // takes the Circumcision collect
        #expect(sunday(2026, 1, 11) == "epiphany-1")
        #expect(sunday(2026, 1, 25) == "epiphany-3")
        #expect(sunday(2026, 2, 1) == "septuagesima")
        #expect(sunday(2026, 2, 15) == "quinquagesima")
        #expect(sunday(2026, 2, 22) == "lent-1")
        #expect(sunday(2026, 3, 22) == "lent-5")
        #expect(sunday(2026, 3, 29) == "palm-sunday")
        #expect(sunday(2026, 4, 5) == "easter")
        #expect(sunday(2026, 5, 10) == "easter-5")
        #expect(sunday(2026, 5, 17) == "ascension-sunday")
        #expect(sunday(2026, 5, 24) == "whitsunday")
        #expect(sunday(2026, 5, 31) == "trinity")
        #expect(sunday(2026, 6, 7) == "trinity-1")
        #expect(sunday(2026, 10, 11) == "trinity-19")
        #expect(sunday(2026, 11, 22) == "trinity-25")
        #expect(sunday(2026, 11, 29) == "advent-1")
        #expect(sunday(2026, 12, 20) == "advent-4")
        #expect(sunday(2026, 12, 27) == "christmas-1")
    }

    @Test func extraSundaysAfterTrinityTakeOmittedEpiphanySundays() {
        // Easter 23 March 2008: one Sunday after the Epiphany, 27 after Trinity.
        #expect(calendar.epiphanySundayCount(2008) == 1)
        #expect(calendar.trinitySundayCount(2008) == 27)
        #expect(sunday(2008, 11, 2) == "trinity-24")
        #expect(sunday(2008, 11, 9) == "epiphany-5")
        #expect(sunday(2008, 11, 16) == "epiphany-6")
        #expect(sunday(2008, 11, 23) == "trinity-25")
        #expect(calendar.sundayProper(CivilDate(2008, 11, 9))?.basis == .editorial)
    }

    @Test func fewerSundaysAfterTrinityOmitTheOverplus() {
        // Easter 25 April 2038: 22 Sundays after Trinity.
        #expect(calendar.trinitySundayCount(2038) == 22)
        #expect(sunday(2038, 11, 14) == "trinity-21")
        #expect(sunday(2038, 11, 21) == "trinity-25")
    }

    @Test func everySundayHasAProperOrARule() {
        let ids = Set((try! BCP1662Content.bundled(verify: false)).collects.observances.map(\.id))
        for year in 1753...2300 {
            var date = CivilDate(year, 1, 1).next(.sunday)
            while date.year == year {
                if let proper = calendar.sundayProper(date) {
                    #expect(ids.contains(proper.id.rawValue), "\(date): \(proper.id)")
                } else {
                    // Only Christmas Day, 2 to 6 January.
                    #expect((date.month == 12 && date.day == 25) || (date.month == 1 && date.day <= 6), "\(date)")
                }
                date = date.adding(days: 7)
            }
        }
    }

    @Test func properDays() {
        #expect(calendar.properDays(on: CivilDate(2026, 11, 30)) == [ObservanceID("andrew")])
        #expect(calendar.properDays(on: CivilDate(2026, 2, 18)) == [ObservanceID("ash-wednesday")])
        #expect(calendar.properDays(on: CivilDate(2026, 4, 3)) == [ObservanceID("good-friday")])
        #expect(calendar.properDays(on: CivilDate(2026, 5, 14)) == [ObservanceID("ascension")])
        #expect(calendar.properDays(on: CivilDate(2026, 2, 24)) == [ObservanceID("matthias")])
        #expect(calendar.properDays(on: CivilDate(2028, 2, 24)) == [])
        #expect(calendar.properDays(on: CivilDate(2028, 2, 25)) == [ObservanceID("matthias")])
        #expect(calendar.properDays(on: CivilDate(2026, 10, 13)) == [])
    }

    @Test func seasons() {
        #expect(calendar.season(of: CivilDate(2026, 10, 13)) == .trinity)
        #expect(calendar.season(of: CivilDate(2026, 12, 1)) == .advent)
        #expect(calendar.season(of: CivilDate(2026, 12, 25)) == .christmas)
        #expect(calendar.season(of: CivilDate(2027, 1, 3)) == .christmas)
        #expect(calendar.season(of: CivilDate(2027, 1, 10)) == .epiphany)
        #expect(calendar.season(of: CivilDate(2026, 2, 10)) == .septuagesima)
        #expect(calendar.season(of: CivilDate(2026, 2, 18)) == .lent)
        #expect(calendar.season(of: CivilDate(2026, 4, 12)) == .easter)
        #expect(calendar.season(of: CivilDate(2026, 5, 26)) == .whitsun)
    }
}

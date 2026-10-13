import LuxCore
import Testing
@testable import BCP1662

@Suite struct CollectTests {
    let calendar = BCP1662Calendar()

    func plan(_ office: Office, _ y: Int, _ m: Int, _ d: Int) -> CollectPlan {
        calendar.collectPlan(for: office, on: CivilDate(y, m, d))
    }

    func ids(_ list: [ObservanceID]) -> [String] { list.map(\.rawValue) }

    @Test func sundayCollectServesTheWeek() {
        let p = plan(.morningPrayer, 2026, 10, 13)
        #expect(ids(p.ofTheDay) == ["trinity-19"])
        #expect(p.following.isEmpty)
    }

    @Test func eveningBeforeSundayTakesSundaysCollect() {
        let p = plan(.eveningPrayer, 2026, 10, 10)
        #expect(ids(p.ofTheDay) == ["trinity-19"])
        #expect(p.eveOf == CivilDate(2026, 10, 11))
        #expect(ids(plan(.morningPrayer, 2026, 10, 10).ofTheDay) == ["trinity-18"])
    }

    @Test func holyDayOnSundayOffersBoth() {
        // St Luke, Sunday 18 October 2026.
        let p = plan(.morningPrayer, 2026, 10, 18)
        #expect(ids(p.ofTheDay) == ["luke", "trinity-20"])
        #expect(p.diagnostics.contains { $0.code == "concurrent-observances" })
    }

    @Test func eveOfHolyDay() {
        // St Andrew, Monday 30 November 2026; Advent Sunday the day before.
        let p = plan(.eveningPrayer, 2026, 11, 29)
        #expect(ids(p.ofTheDay) == ["andrew"])
        #expect(ids(p.following) == ["advent-1"])
        #expect(ids(plan(.morningPrayer, 2026, 11, 29).ofTheDay) == ["advent-1"])
        #expect(plan(.morningPrayer, 2026, 11, 29).following.isEmpty)
    }

    @Test func adventCollectRepeatedUntilChristmasEve() {
        #expect(ids(plan(.morningPrayer, 2026, 12, 9).ofTheDay) == ["advent-2"])
        #expect(ids(plan(.morningPrayer, 2026, 12, 9).following) == ["advent-1"])
        #expect(ids(plan(.morningPrayer, 2026, 12, 24).following) == ["advent-1"])
        let christmasEve = plan(.eveningPrayer, 2026, 12, 24)
        #expect(ids(christmasEve.ofTheDay) == ["christmas"])
        #expect(christmasEve.following.isEmpty)
    }

    @Test func nativityCollectFollowsUntilNewYearsEve() {
        #expect(ids(plan(.morningPrayer, 2026, 12, 26).ofTheDay) == ["stephen"])
        #expect(ids(plan(.morningPrayer, 2026, 12, 26).following) == ["christmas"])
        #expect(ids(plan(.morningPrayer, 2026, 12, 30).ofTheDay) == ["christmas-1"])
        #expect(ids(plan(.eveningPrayer, 2026, 12, 31).ofTheDay) == ["circumcision"])
        #expect(plan(.morningPrayer, 2027, 1, 1).following.isEmpty)
    }

    @Test func circumcisionServesUntilEpiphany() {
        #expect(ids(plan(.morningPrayer, 2027, 1, 4).ofTheDay) == ["circumcision"])
        #expect(ids(plan(.morningPrayer, 2026, 1, 4).ofTheDay) == ["circumcision"])  // a Sunday
        #expect(ids(plan(.eveningPrayer, 2027, 1, 5).ofTheDay) == ["epiphany"])
        #expect(ids(plan(.morningPrayer, 2027, 1, 8).ofTheDay) == ["epiphany"])
    }

    @Test func ashWednesdayCollectEveryDayInLent() {
        #expect(ids(plan(.morningPrayer, 2026, 2, 18).ofTheDay) == ["ash-wednesday"])
        #expect(plan(.morningPrayer, 2026, 2, 18).following.isEmpty)
        #expect(ids(plan(.morningPrayer, 2026, 2, 19).ofTheDay) == ["quinquagesima"])
        #expect(ids(plan(.morningPrayer, 2026, 2, 19).following) == ["ash-wednesday"])
        #expect(ids(plan(.morningPrayer, 2026, 4, 3).ofTheDay) == ["good-friday"])
        #expect(ids(plan(.morningPrayer, 2026, 4, 3).following) == ["ash-wednesday"])
        let easterEve = plan(.eveningPrayer, 2026, 4, 4)
        #expect(ids(easterEve.ofTheDay) == ["easter"])
        #expect(easterEve.following.isEmpty)
    }

    @Test func easterWeek() {
        #expect(ids(plan(.morningPrayer, 2026, 4, 6).ofTheDay) == ["easter-monday"])
        #expect(ids(plan(.eveningPrayer, 2026, 4, 5).ofTheDay) == ["easter"])  // no eve for Easter Monday
        #expect(ids(plan(.morningPrayer, 2026, 4, 8).ofTheDay) == ["easter"])
    }

    @Test func everyDayHasACollect() throws {
        let content = try BCP1662Content.bundled(verify: false)
        let known = Set(content.collects.observances.map(\.id))
        var date = CivilDate(2020, 1, 1)
        while date.year < 2060 {
            for office in [Office.morningPrayer, .eveningPrayer] {
                let p = calendar.collectPlan(for: office, on: date)
                #expect(!p.ofTheDay.isEmpty, "\(date)")
                for id in p.ofTheDay + p.following { #expect(known.contains(id.rawValue), "\(date) \(id)") }
            }
            date = date.adding(days: 1)
        }
    }
}

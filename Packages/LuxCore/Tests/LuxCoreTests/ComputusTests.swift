import Testing
@testable import LuxCore

@Suite struct ComputusTests {
    /// Published Gregorian Easter dates, including the earliest (22 March)
    /// and latest (25 April) possible.
    @Test(arguments: [
        (1762, 4, 11), (1818, 3, 22), (1943, 4, 25), (2000, 4, 23), (2008, 3, 23), (2011, 4, 24),
        (2019, 4, 21), (2024, 3, 31), (2025, 4, 20), (2026, 4, 5), (2027, 3, 28), (2038, 4, 25), (2285, 3, 22),
    ])
    func knownEasters(year: Int, month: Int, day: Int) {
        #expect(Computus.gregorianEaster(year) == CivilDate(year, month, day))
    }

    @Test func alwaysASundayInRange() {
        for year in 1753...3000 {
            let easter = Computus.gregorianEaster(year)!
            #expect(easter.weekday == .sunday)
            #expect(easter >= CivilDate(year, 3, 22) && easter <= CivilDate(year, 4, 25))
        }
    }

    @Test func undefinedBeforeTheReform() {
        #expect(Computus.gregorianEaster(1582) == nil)
    }
}

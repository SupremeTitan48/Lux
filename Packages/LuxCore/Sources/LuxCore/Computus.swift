/// Calculation of the date of Easter.
public enum Computus {
    /// The first year in which the Gregorian computus is defined (the reform
    /// took effect in October 1582).
    public static let firstGregorianYear = 1583

    /// Easter Day in the Gregorian calendar, by the anonymous Gregorian
    /// algorithm (Meeus/Jones/Butcher). Returns `nil` before 1583.
    ///
    /// This is the reckoning the 1662 Book of Common Prayer follows after
    /// Great Britain adopted the Gregorian calendar in 1752, when the tables
    /// for finding Easter were recast accordingly.
    public static func gregorianEaster(_ year: Int) -> CivilDate? {
        guard year >= firstGregorianYear else { return nil }
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = (h + l - 7 * m + 114) % 31 + 1
        return CivilDate(year, month, day)
    }
}

import Foundation

/// A calendar date in the proleptic Gregorian calendar, with no time of day
/// and no time zone.
///
/// Liturgical calculations work on dates, not instants. ``CivilDate`` keeps
/// date arithmetic exact and independent of the device's calendar settings.
/// Conversion from an instant needs an explicit time zone
/// (``init(_:in:)``).
public struct CivilDate: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Creates a date, or returns `nil` when the components do not name a
    /// real day.
    public init?(year: Int, month: Int, day: Int) {
        guard (1...12).contains(month), day >= 1, day <= CivilDate.daysIn(month: month, year: year) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Creates a date from components known to be valid. Traps otherwise.
    public init(_ year: Int, _ month: Int, _ day: Int) {
        guard let date = CivilDate(year: year, month: month, day: day) else {
            preconditionFailure("invalid date \(year)-\(month)-\(day)")
        }
        self = date
    }

    /// The date at `instant` as seen in `timeZone`.
    public init(_ instant: Date, in timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: instant)
        self.init(parts.year!, parts.month!, parts.day!)
    }

    public static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    public static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 2: return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    public var isLeapYear: Bool { CivilDate.isLeapYear(year) }
    public var daysInMonth: Int { CivilDate.daysIn(month: month, year: year) }

    /// Days since 1 January of year 1 (proleptic Gregorian), day 0.
    public var dayNumber: Int {
        // Algorithm from Howard Hinnant's days_from_civil, shifted so the
        // count is non-negative for all supported years.
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 306
    }

    public init(dayNumber: Int) {
        let z = dayNumber + 306
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let y = yoe + era * 400 + (m <= 2 ? 1 : 0)
        self.init(y, m, d)
    }

    public func adding(days: Int) -> CivilDate {
        CivilDate(dayNumber: dayNumber + days)
    }

    /// Whole days from `self` to `other` (positive when `other` is later).
    public func days(to other: CivilDate) -> Int {
        other.dayNumber - dayNumber
    }

    public var weekday: Weekday {
        // 1 January of year 1 (day 0) was a Monday in the proleptic Gregorian calendar.
        let index = ((dayNumber % 7) + 7) % 7  // 0 = Monday
        return Weekday(rawValue: (index + 1) % 7 + 1)!
    }

    /// The first date on or after `self` that falls on `weekday`.
    public func next(_ weekday: Weekday, includingSelf: Bool = true) -> CivilDate {
        var offset = (weekday.rawValue - self.weekday.rawValue + 7) % 7
        if offset == 0 && !includingSelf { offset = 7 }
        return adding(days: offset)
    }

    /// The last date on or before `self` that falls on `weekday`.
    public func previous(_ weekday: Weekday, includingSelf: Bool = true) -> CivilDate {
        var offset = (self.weekday.rawValue - weekday.rawValue + 7) % 7
        if offset == 0 && !includingSelf { offset = 7 }
        return adding(days: -offset)
    }

    public static func < (lhs: CivilDate, rhs: CivilDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

/// Days of the week, numbered as Foundation numbers them (1 = Sunday).
public enum Weekday: Int, CaseIterable, Sendable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

extension CivilDate: CustomStringConvertible, LosslessStringConvertible {
    /// ISO 8601 calendar date, `YYYY-MM-DD`.
    public var description: String {
        let y = String(year).leftPadded(to: 4)
        return "\(y)-\(String(month).leftPadded(to: 2))-\(String(day).leftPadded(to: 2))"
    }

    public init?(_ description: String) {
        let parts = description.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        self.init(year: y, month: m, day: d)
    }
}

extension CivilDate: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let date = CivilDate(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "not a YYYY-MM-DD date: \(text)")
        }
        self = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension String {
    fileprivate func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: "0", count: width - count) + self
    }
}

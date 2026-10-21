import LuxCore

/// An observance with proper collects in the 1662 book, by the identifier
/// the content uses (`advent-1`, `andrew`, `trinity-25`).
public struct ObservanceID: Hashable, Sendable, Codable, RawRepresentable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

/// Seasons of the 1662 year, as Lux groups its Sundays.
public enum Season: String, Sendable, Codable, CaseIterable {
    case advent, christmas, epiphany, septuagesima, lent, easter, whitsun, trinity
}

/// How a calendar fact was established. Rules printed in the supplied
/// source are `.source`; rules Lux applies because the relevant table is
/// missing from the supplied text are `.editorial` and are reported.
public enum RuleBasis: String, Sendable, Codable {
    case source, editorial
}

/// The 1662 calendar of Sundays and holy days with proper collects.
///
/// The Calendar, the Tables and Rules for the Moveable Feasts and the Table
/// of Vigils are not in the supplied text extraction. Their content that the
/// engine needs (the fixed dates of the holy days, the rules for placing the
/// movable feasts relative to Easter and Advent) is encoded here and marked
/// editorial, to be verified against the printed tables.
public struct BCP1662Calendar: Sendable {
    /// Great Britain adopted the Gregorian calendar in September 1752; the
    /// 1662 rules are computed on it from 1753.
    public static let supportedYears = 1753...9999

    public init() {}

    // MARK: Fixed and movable holy days

    /// Immovable holy days with their own collects. The Calendar is not in the
    /// supplied text; a test checks these dates against the Kalendar of the
    /// 1693 printing, which leaves its lessons blank on each of them.
    static let fixedHolyDays: [(month: Int, day: Int, id: String)] = [
        (1, 1, "circumcision"), (1, 6, "epiphany"), (1, 25, "conversion-of-paul"), (2, 2, "purification"),
        (2, 24, "matthias"), (3, 25, "annunciation"), (4, 25, "mark"), (5, 1, "philip-and-james"),
        (6, 11, "barnabas"), (6, 24, "john-baptist"), (6, 29, "peter"), (7, 25, "james"), (8, 24, "bartholomew"),
        (9, 21, "matthew"), (9, 29, "michael"), (10, 18, "luke"), (10, 28, "simon-and-jude"), (11, 1, "all-saints"),
        (11, 30, "andrew"), (12, 21, "thomas"), (12, 25, "christmas"), (12, 26, "stephen"),
        (12, 27, "john-evangelist"), (12, 28, "innocents"),
    ]

    /// Days with proper collects fixed relative to Easter (in days).
    static let easterRelativeDays: [(offset: Int, id: String)] = [
        (-46, "ash-wednesday"), (-2, "good-friday"), (-1, "easter-even"), (1, "easter-monday"), (2, "easter-tuesday"),
        (39, "ascension"), (50, "whit-monday"), (51, "whit-tuesday"),
    ]

    /// Holy days in the sense of the eve rule ("any Holyday that hath a Vigil
    /// or Eve"): the fixed feasts and Ascension Day. Fasts (Ash Wednesday,
    /// Good Friday, Easter Even) and the Monday and Tuesday in Easter and
    /// Whitsun weeks are excluded (editorial; the Table of Vigils is not in
    /// the supplied text).
    static let holyDaysWithEves: Set<String> = Set(fixedHolyDays.map(\.id)).union(["ascension"])

    /// Feasts on which the Creed of St Athanasius replaces the Apostles'
    /// Creed at Morning Prayer (source: the rubric before Quicunque vult).
    public static let athanasianCreedDays: Set<ObservanceID> = Set([
        "christmas", "epiphany", "matthias", "easter", "ascension", "whitsunday", "john-baptist", "james",
        "bartholomew", "matthew", "simon-and-jude", "andrew", "trinity",
    ].map { ObservanceID($0) })

    /// Days for which the Table of Proper Psalms appoints psalms in place of
    /// the ordinary course (the table of the 1693 printing; a test checks this
    /// set against it).
    public static let properPsalmDays: Set<ObservanceID> = Set([
        "christmas", "ash-wednesday", "good-friday", "easter", "ascension", "whitsunday",
    ].map { ObservanceID($0) })

    // MARK: Year anchors

    public func easter(_ year: Int) -> CivilDate {
        Computus.gregorianEaster(year)!
    }

    /// Advent Sunday: the Sunday nearest St Andrew's Day (30 November), that
    /// is, the Sunday from 27 November to 3 December (editorial: from the
    /// Rules for the Moveable Feasts).
    public func adventSunday(_ year: Int) -> CivilDate {
        CivilDate(year, 11, 27).next(.sunday)
    }

    /// The first Sunday after the Epiphany.
    func firstSundayAfterEpiphany(_ year: Int) -> CivilDate {
        CivilDate(year, 1, 7).next(.sunday)
    }

    func septuagesima(_ year: Int) -> CivilDate { easter(year).adding(days: -63) }
    func trinitySunday(_ year: Int) -> CivilDate { easter(year).adding(days: 56) }

    /// Number of Sundays after the Epiphany before Septuagesima.
    func epiphanySundayCount(_ year: Int) -> Int {
        firstSundayAfterEpiphany(year).days(to: septuagesima(year)) / 7
    }

    /// Number of Sundays after Trinity before Advent.
    func trinitySundayCount(_ year: Int) -> Int {
        trinitySunday(year).days(to: adventSunday(year)) / 7 - 1
    }

    // MARK: Sundays

    /// The proper of a Sunday, by the order of the Collects, Epistles and
    /// Gospels. Returns `nil` for Sundays with no Sunday proper (Christmas
    /// Day and the Epiphany falling on a Sunday, and Sundays from 2 to 5
    /// January, which take the Circumcision's collect by rubric).
    public func sundayProper(_ sunday: CivilDate) -> (id: ObservanceID, basis: RuleBasis, note: String?)? {
        precondition(sunday.weekday == .sunday)
        let year = sunday.year
        let easter = easter(year)
        let advent = adventSunday(year)

        if sunday >= advent {
            let week = advent.days(to: sunday) / 7
            if week < 4 { return (ObservanceID("advent-\(week + 1)"), .source, nil) }
            if sunday.month == 12 && sunday.day >= 26 { return (ObservanceID("christmas-1"), .source, nil) }
            return nil  // Christmas Day
        }
        if sunday.month == 1 && sunday.day == 1 { return (ObservanceID("christmas-1"), .source, nil) }
        if sunday.month == 1 && sunday.day <= 6 { return nil }

        let offset = easter.days(to: sunday)
        if sunday < septuagesima(year) {
            let n = firstSundayAfterEpiphany(year).days(to: sunday) / 7 + 1
            return (ObservanceID("epiphany-\(n)"), .source, nil)
        }
        switch offset {
        case -63: return (ObservanceID("septuagesima"), .source, nil)
        case -56: return (ObservanceID("sexagesima"), .source, nil)
        case -49: return (ObservanceID("quinquagesima"), .source, nil)
        case -42, -35, -28, -21, -14: return (ObservanceID("lent-\((offset + 49) / 7)"), .source, nil)
        case -7: return (ObservanceID("palm-sunday"), .source, nil)
        case 0: return (ObservanceID("easter"), .source, nil)
        case 7, 14, 21, 28, 35: return (ObservanceID("easter-\(offset / 7)"), .source, nil)
        case 42: return (ObservanceID("ascension-sunday"), .source, nil)
        case 49: return (ObservanceID("whitsunday"), .source, nil)
        case 56: return (ObservanceID("trinity"), .source, nil)
        default: break
        }
        // Sundays after Trinity. The last before Advent is always the 25th;
        // when there are fewer, the overplus is omitted; when there are more,
        // Sundays omitted after the Epiphany are taken in (source: rubric
        // after the 25th Sunday after Trinity).
        let n = (offset - 56) / 7
        let total = trinitySundayCount(year)
        if n == total { return (ObservanceID("trinity-25"), .source, nil) }
        if n <= 24 { return (ObservanceID("trinity-\(n)"), .source, nil) }
        let omitted = Array((epiphanySundayCount(year) + 1)...6)
        let needed = total - 25
        let fill = omitted.suffix(needed)
        let pick = Array(fill)[n - 25]
        return (ObservanceID("epiphany-\(pick)"), .editorial,
                "The rubric says only that the service of “some of those Sundays that were omitted after the Epiphany” is taken in; Lux uses the last \(needed) omitted, in order.")
    }

    // MARK: Days

    /// Holy days and other days with their own collect that fall on `date`
    /// (not counting the Sunday proper).
    public func properDays(on date: CivilDate) -> [ObservanceID] {
        var ids: [ObservanceID] = []
        for feast in BCP1662Calendar.fixedHolyDays where feast.month == date.month {
            var day = feast.day
            // In leap years St Matthias is kept on 25 February (editorial:
            // from the Calendar's note on the intercalary day).
            if feast.id == "matthias" && date.isLeapYear { day = 25 }
            if day == date.day { ids.append(ObservanceID(feast.id)) }
        }
        let offset = easter(date.year).days(to: date)
        for movable in BCP1662Calendar.easterRelativeDays where movable.offset == offset {
            ids.append(ObservanceID(movable.id))
        }
        return ids
    }

    public func season(of date: CivilDate) -> Season {
        let year = date.year
        let easter = easter(year)
        if date >= adventSunday(year) { return date.month == 12 && date.day >= 25 ? .christmas : .advent }
        if date.month == 1 && date.day < 6 { return .christmas }
        if date < septuagesima(year) { return .epiphany }
        if date < easter.adding(days: -46) { return .septuagesima }
        if date < easter { return .lent }
        if date < easter.adding(days: 49) { return .easter }
        if date < trinitySunday(year) { return .whitsun }
        return .trinity
    }

    public func isInLent(_ date: CivilDate) -> Bool {
        let easter = easter(date.year)
        return date >= easter.adding(days: -46) && date < easter
    }

    /// Advent Sunday to Christmas Eve.
    public func isInAdvent(_ date: CivilDate) -> Bool {
        date >= adventSunday(date.year) && date <= CivilDate(date.year, 12, 24)
    }
}

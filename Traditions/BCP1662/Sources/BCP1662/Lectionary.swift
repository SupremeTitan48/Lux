import LuxCore

/// Which lessons and Proper Psalms are read on a day.
///
/// The rules are those of the Preface ("The Order how the rest of holy
/// Scripture is appointed to be read"): the lessons of each day stand in the
/// Kalendar, "Except only the Moveable Feasts, which are not in the
/// Kalendar, and the immoveable, where there is a blank left in the Column of
/// Lessons; the proper Lessons for all which days are to be found in the
/// Table of proper Lessons"; and "whensoever proper Psalms or Lessons are
/// appointed; then the Psalms and Lessons of ordinary course appointed in the
/// Psalter and Kalendar (if they be different) shall be omitted for that
/// time."
///
/// The tables are those of the 1693 printing (see `LessonsFile.source`), as
/// the Baskerville text layer does not contain them.
struct Lectionary {
    let lessons: LessonsFile
    let calendar: BCP1662Calendar

    enum Which: String { case first, second }

    /// One lesson slot of an office.
    struct Slot {
        /// The candidates, labelled by where they come from. More than one
        /// means the source does not settle which is read; none means nothing
        /// is appointed.
        var options: [(label: String, lesson: LessonsFile.Lesson)]
        var diagnostics: [Diagnostic]
    }

    // MARK: Days

    /// The Kalendar's entry for a date. The Kalendar prints a 29th of
    /// February, which serves only in leap years.
    func kalendarDay(_ date: CivilDate) -> LessonsFile.KalendarDay? {
        lessons.kalendar.first { $0.month == date.month && $0.day == date.day }
    }

    /// The row of the Sunday table for a Sunday, if the table has one.
    ///
    /// The table names its Sundays as the Collects do, with two differences:
    /// it has a second Sunday after Christmas (2 to 5 January, when the
    /// Collects use the Circumcision's), and it numbers the Sundays after
    /// Trinity up to the twenty-sixth, without the rubric that moves the
    /// twenty-fifth Sunday's collect to the Sunday next before Advent.
    func sundayRow(_ sunday: CivilDate) -> (id: ObservanceID, note: String?)? {
        let year = sunday.year
        if sunday.month == 1 && (2...5).contains(sunday.day) { return (ObservanceID("christmas-2"), nil) }
        let trinity = calendar.trinitySunday(year)
        if sunday > trinity && sunday < calendar.adventSunday(year) {
            let n = trinity.days(to: sunday) / 7
            if n <= 26 { return (ObservanceID("trinity-\(n)"), nil) }
            return nil
        }
        return calendar.sundayProper(sunday).map { (id: $0.id, note: nil) }
    }

    /// Days with Proper Lessons that are not holy days with a collect:
    /// the Wednesday and Thursday before Easter.
    func lessonOnlyDays(on date: CivilDate) -> [ObservanceID] {
        switch calendar.easter(date.year).days(to: date) {
        case -4: return [ObservanceID("wednesday-before-easter")]
        case -3: return [ObservanceID("thursday-before-easter")]
        default: return []
        }
    }

    /// Rows of the Table of Proper Lessons kept on a date: holy days first,
    /// then the Sunday (the order in which the collects are offered).
    func properRows(on date: CivilDate) -> [(id: ObservanceID, row: LessonsFile.ProperDay)] {
        var out: [(ObservanceID, LessonsFile.ProperDay)] = []
        for id in calendar.properDays(on: date) + lessonOnlyDays(on: date) {
            if let row = lessons.holyDays.first(where: { $0.observance == id.rawValue }) { out.append((id, row)) }
        }
        if date.weekday == .sunday, let sunday = sundayRow(date),
           let row = lessons.sundays.first(where: { $0.observance == sunday.id.rawValue }),
           !out.contains(where: { $0.0 == sunday.id }) {
            out.append((sunday.id, row))
        }
        return out
    }

    // MARK: Lessons

    func slot(_ which: Which, office: Office, on date: CivilDate) -> Slot {
        var diagnostics: [Diagnostic] = []
        func pick(_ o: LessonsFile.Office) -> LessonsFile.Lesson? {
            switch which {
            case .first: return o.first ?? nil
            case .second: return o.second ?? nil
            }
        }
        func half(_ row: LessonsFile.ProperDay) -> LessonsFile.Office { office == .morningPrayer ? row.morning : row.evening }

        let rows = properRows(on: date)
        let propers = rows.compactMap { item in pick(half(item.row)).map { (label: ObservanceNames.name(item.id), lesson: $0) } }
        if !propers.isEmpty {
            if propers.count > 1 {
                diagnostics.append(Diagnostic(.info, code: "lessons-concurrent",
                    message: "Proper lessons are appointed for more than one observance on this day. The source gives no rule of precedence, so each is offered as an alternative."))
            }
            return Slot(options: propers, diagnostics: diagnostics)
        }
        if date.weekday == .sunday, sundayRow(date) == nil, calendar.trinitySunday(date.year) < date,
           date < calendar.adventSunday(date.year) {
            diagnostics.append(Diagnostic(.info, code: "lessons-beyond-table",
                message: "The Table of Proper Lessons goes no further than the twenty-sixth Sunday after Trinity, so the lessons of this Sunday are those of the Kalendar."))
        }
        guard let day = kalendarDay(date) else { return Slot(options: [], diagnostics: diagnostics) }
        let kalendar = pick(office == .morningPrayer ? day.morning : day.evening)
        return Slot(options: kalendar.map { [(label: "The Kalendar", lesson: $0)] } ?? [], diagnostics: diagnostics)
    }

    // MARK: Psalms

    /// The Proper Psalms of a day, if the table appoints any.
    func properPsalms(on date: CivilDate, observances: Set<ObservanceID>, office: Office)
        -> (id: ObservanceID, cell: LessonsFile.PsalmCell)? {
        for row in lessons.properPsalms where observances.contains(ObservanceID(row.observance)) {
            return (ObservanceID(row.observance), office == .morningPrayer ? row.morning : row.evening)
        }
        return nil
    }
}

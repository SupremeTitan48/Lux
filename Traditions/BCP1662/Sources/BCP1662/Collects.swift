import LuxCore

/// Which collects are said on a day, and why.
struct CollectPlan: Hashable, Sendable {
    /// The collect of the day. More than one entry means the source does not
    /// settle which is said, and the candidates are offered as alternatives.
    var ofTheDay: [ObservanceID]
    /// Collects said after the collect of the day by rubric (Advent, Lent,
    /// the Nativity after St Stephen).
    var following: [ObservanceID]
    /// Set when the collect of the day is that of the following day (the eve rule).
    var eveOf: CivilDate?
    var diagnostics: [Diagnostic]
}

extension BCP1662Calendar {
    /// The observances whose collect is the collect of the day on `date`
    /// (Morning Prayer, or Evening Prayer when no eve applies).
    func collectCandidates(on date: CivilDate) -> (ids: [ObservanceID], diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        let proper = properDays(on: date)
        if date.weekday == .sunday {
            var ids = proper
            if let sunday = sundayProper(date) {
                if !ids.contains(sunday.id) { ids.append(sunday.id) }
                if let note = sunday.note {
                    diagnostics.append(Diagnostic(.info, code: "sunday-supplied", message: note))
                }
            }
            if ids.isEmpty {
                // Sundays from 2 to 5 January.
                ids = [ObservanceID("circumcision")]
            }
            return (ids, diagnostics)
        }
        if !proper.isEmpty { return (proper, diagnostics) }

        // Weekdays without a proper of their own.
        if date.month == 1 && (2...5).contains(date.day) {
            // Source: "The same Collect, Epistle, and Gospel shall serve for
            // every day after unto the Epiphany."
            return ([ObservanceID("circumcision")], diagnostics)
        }
        if date.month == 1 && date.day > 6 && date < firstSundayAfterEpiphany(date.year) {
            diagnostics.append(Diagnostic(.info, code: "epiphany-week",
                message: "No rubric says which collect serves between the Epiphany and the following Sunday; Lux uses the collect of the Epiphany."))
            return ([ObservanceID("epiphany")], diagnostics)
        }
        if date.month == 12 && date.day >= 26 {
            let sunday = date.previous(.sunday)
            if sunday.month == 12 && sunday.day >= 26 { return ([ObservanceID("christmas-1")], diagnostics) }
            return ([ObservanceID("christmas")], diagnostics)
        }
        // Source: "the Collect, Epistle, and Gospel appointed for the Sunday
        // shall serve all the Week after, where it is not in this book
        // otherwise ordered."
        let sunday = date.previous(.sunday)
        if let proper = sundayProper(sunday) {
            return ([proper.id], diagnostics)
        }
        return (collectCandidates(on: sunday).ids, diagnostics)
    }

    /// Source: "the Collect appointed for every Sunday, or for any Holyday
    /// that hath a Vigil or Eve, shall be said at the Evening Service next
    /// before." Returns the observances of the following day whose collect
    /// is said at Evening Prayer on `date`, if any.
    func eveCandidates(before date: CivilDate) -> (ids: [ObservanceID], diagnostics: [Diagnostic])? {
        let next = date.adding(days: 1)
        let holyDays = properDays(on: next).filter { BCP1662Calendar.holyDaysWithEves.contains($0.rawValue) }
        var diagnostics: [Diagnostic] = []
        if !holyDays.isEmpty {
            diagnostics.append(Diagnostic(.info, code: "eve-of-holy-day",
                message: "The collect of the holy day is said at Evening Prayer on its eve. The Table of Vigils is not in the supplied text; Lux applies the eve rule to every holy day except the Monday and Tuesday in Easter and Whitsun weeks."))
        }
        if next.weekday == .sunday {
            let candidates = collectCandidates(on: next)
            return (candidates.ids, diagnostics + candidates.diagnostics)
        }
        return holyDays.isEmpty ? nil : (holyDays, diagnostics)
    }

    func collectPlan(for office: Office, on date: CivilDate) -> CollectPlan {
        var effective = date
        var eveOf: CivilDate?
        var candidates = collectCandidates(on: date)
        if office == .eveningPrayer, let eve = eveCandidates(before: date) {
            candidates = eve
            eveOf = date.adding(days: 1)
            effective = date.adding(days: 1)
        }
        var diagnostics = candidates.diagnostics
        if candidates.ids.count > 1 {
            diagnostics.append(Diagnostic(.info, code: "concurrent-observances",
                message: "More than one observance with its own collect falls on this day. The supplied text gives no rule of precedence, so each collect is offered as an alternative."))
        }
        var following: [ObservanceID] = []
        // Source: Advent Sunday's collect "is to be repeated every day with
        // the other Collects in Advent, until Christmas Eve".
        if isInAdvent(effective) { following.append(ObservanceID("advent-1")) }
        // Source (after St Stephen's collect): "Then shall follow the Collect
        // of the Nativity, which shall be said continually unto New-year's Eve."
        if effective.month == 12 && effective.day >= 26 { following.append(ObservanceID("christmas")) }
        // Source: Ash Wednesday's collect "is to be read every day in Lent
        // after the Collect appointed for the day."
        if isInLent(effective) { following.append(ObservanceID("ash-wednesday")) }
        following.removeAll { candidates.ids.contains($0) }
        return CollectPlan(ofTheDay: candidates.ids, following: following, eveOf: eveOf, diagnostics: diagnostics)
    }
}

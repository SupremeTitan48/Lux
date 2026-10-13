import LuxCore

/// The 1662 Book of Common Prayer, as printed by John Baskerville in 1762.
public struct BCP1662Tradition: LiturgicalTradition {
    public static let identifier = "bcp1662"

    public let id = BCP1662Tradition.identifier
    public let title = "The Book of Common Prayer (1662)"
    public let offices: [Office] = [.morningPrayer, .eveningPrayer]
    public let calendar = BCP1662Calendar()
    public let content: BCP1662Content

    public init(content: BCP1662Content) {
        self.content = content
    }

    /// The tradition with its bundled, verified content.
    public static func bundled() throws -> BCP1662Tradition {
        BCP1662Tradition(content: try .bundled())
    }

    public func describe(_ date: CivilDate) throws -> DayDescription {
        guard BCP1662Calendar.supportedYears.contains(date.year) else {
            throw CompositionError.dateOutOfRange(date, reason: "Before the Gregorian calendar in Great Britain.")
        }
        return Composer(content: content, calendar: calendar).describe(date)
    }

    public func compose(_ office: Office, on date: CivilDate, options: CompositionOptions = .standard) throws -> ServiceDocument {
        try Composer(content: content, calendar: calendar).compose(office, on: date)
    }
}

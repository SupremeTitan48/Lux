import LuxCore

/// The 1662 Book of Common Prayer, as printed by John Baskerville in 1762.
public struct BCP1662Tradition: LiturgicalTradition {
    public static let identifier = "bcp1662"

    public let id = BCP1662Tradition.identifier
    public let title = "The Book of Common Prayer (1662)"
    public let offices: [Office] = [.morningPrayer, .eveningPrayer]
    public let calendar = BCP1662Calendar()
    public let content: BCP1662Content
    /// Editions of the Scriptures the lessons can be read from, chosen per
    /// composition by `CompositionOptions.scriptureTranslationID`.
    public let scripture: [any ScriptureProvider]

    public init(content: BCP1662Content, scripture: [any ScriptureProvider] = []) {
        self.content = content
        self.scripture = scripture
    }

    /// The tradition with its bundled, verified content.
    public static func bundled(scripture: [any ScriptureProvider] = []) throws -> BCP1662Tradition {
        BCP1662Tradition(content: try .bundled(), scripture: scripture)
    }

    public func describe(_ date: CivilDate) throws -> DayDescription {
        guard BCP1662Calendar.supportedYears.contains(date.year) else {
            throw CompositionError.dateOutOfRange(date, reason: "Before the Gregorian calendar in Great Britain.")
        }
        return Composer(content: content, calendar: calendar).describe(date)
    }

    public func compose(_ office: Office, on date: CivilDate, options: CompositionOptions = .standard) throws -> ServiceDocument {
        let provider = scripture.first { $0.translationID == options.scriptureTranslationID }
        return try Composer(content: content, calendar: calendar, scripture: provider, options: options).compose(office, on: date)
    }
}

/// A liturgical tradition: its calendar, rules and texts.
///
/// Conforming types live in tradition packages (for example `BCP1662`) and
/// depend on LuxCore only. The app talks to traditions through this
/// protocol, so a new tradition is a new package, not a change to the app.
public protocol LiturgicalTradition: Sendable {
    /// Stable identifier, e.g. `bcp1662`.
    var id: String { get }
    var title: String { get }
    var offices: [Office] { get }

    /// What the day is in this tradition's calendar.
    func describe(_ date: CivilDate) throws -> DayDescription

    /// Compose an office for a date.
    func compose(_ office: Office, on date: CivilDate, options: CompositionOptions) throws -> ServiceDocument
}

public struct CompositionOptions: Hashable, Sendable {
    /// Where Scripture lessons come from. `nil` leaves lessons as placeholders.
    public var scriptureTranslationID: String?

    public init(scriptureTranslationID: String? = nil) {
        self.scriptureTranslationID = scriptureTranslationID
    }

    public static let standard = CompositionOptions()
}

public enum CompositionError: Error, Hashable, Sendable {
    case unsupportedOffice(Office)
    case dateOutOfRange(CivilDate, reason: String)
    case contentMissing(String)
}

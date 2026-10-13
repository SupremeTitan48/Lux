/// Something a reader or maintainer should know about a composed service:
/// a rule that could not be applied, content that is missing from the
/// source, or an editorial choice made where the source is silent.
public struct Diagnostic: Hashable, Sendable, Codable {
    public enum Severity: String, Sendable, Codable, Comparable {
        /// An editorial choice or note; the service is complete.
        case info
        /// Part of the service could not be supplied; a placeholder stands in its place.
        case warning
        /// The service could not be composed correctly.
        case error

        private var rank: Int { self == .info ? 0 : self == .warning ? 1 : 2 }
        public static func < (a: Severity, b: Severity) -> Bool { a.rank < b.rank }
    }

    public var severity: Severity
    /// Stable machine-readable code, such as `lessons-unavailable`.
    public var code: String
    /// Plain-language explanation.
    public var message: String
    /// The element the diagnostic concerns, when there is one.
    public var elementID: String?

    public init(_ severity: Severity, code: String, message: String, elementID: String? = nil) {
        self.severity = severity
        self.code = code
        self.message = message
        self.elementID = elementID
    }
}

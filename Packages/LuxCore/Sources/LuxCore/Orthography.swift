/// How historic letterforms are shown. Content keeps the source's
/// letterforms; this is a display choice and never changes stored text.
public enum Orthography: String, Sendable, Codable, CaseIterable {
    /// As printed, with long s (ſ).
    case asPrinted
    /// Long s shown as round s. Spelling, capitals and punctuation are unchanged.
    case modernLetterforms

    public func render(_ text: String) -> String {
        switch self {
        case .asPrinted: return text
        case .modernLetterforms: return text.replacingLongS()
        }
    }
}

extension String {
    public func replacingLongS() -> String {
        String(unicodeScalars.map { $0 == "\u{017F}" ? "s" : Character($0) })
    }
}

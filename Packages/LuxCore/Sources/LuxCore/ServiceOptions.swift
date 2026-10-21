/// Who leads an office. Traditions reserve some parts of a service to a
/// priest; composing for another officiant leaves those parts out (or uses
/// what the tradition documents in their place) and says so in a diagnostic.
public enum Officiant: String, Hashable, Sendable, Codable, CaseIterable {
    case priest
    case deacon
    /// A lay reader, or anyone saying the office in private devotion.
    case layPerson = "lay"

    public var isPriest: Bool { self == .priest }
}

/// A choice a tradition lets the person praying settle before the office:
/// which of two canticles to say, whether to include a historical prayer.
///
/// A tradition publishes its options (``LiturgicalTradition/serviceOptions``)
/// so an app can offer them without knowing the tradition's rules. The
/// tradition alone decides what a choice does, and the rubrics still win: a
/// choice the rubrics forbid on a given day is overridden, with a diagnostic.
public struct ServiceOption: Hashable, Sendable, Identifiable {
    public var id: String
    /// A short title for settings, e.g. "After the second lesson".
    public var title: String
    /// One or two sentences on what the option does.
    public var summary: String?
    /// Groups options in settings, e.g. "Canticles".
    public var group: String
    /// The offices the option affects.
    public var offices: [Office]
    /// The officiants the option applies to; empty means every officiant.
    public var officiants: [Officiant]
    public var choices: [Choice]
    /// The choice an app starts with. Composing without a selection is not
    /// the same thing: see ``CompositionOptions/choices``.
    public var defaultChoice: String

    public struct Choice: Hashable, Sendable, Identifiable {
        public var id: String
        public var label: String
        public init(id: String, label: String) {
            self.id = id
            self.label = label
        }
    }

    public init(id: String, title: String, summary: String? = nil, group: String, offices: [Office],
                officiants: [Officiant] = [], choices: [Choice], defaultChoice: String) {
        precondition(choices.contains { $0.id == defaultChoice }, "default choice \(defaultChoice) is not a choice of \(id)")
        self.id = id
        self.title = title
        self.summary = summary
        self.group = group
        self.offices = offices
        self.officiants = officiants
        self.choices = choices
        self.defaultChoice = defaultChoice
    }

    public func applies(to officiant: Officiant) -> Bool {
        officiants.isEmpty || officiants.contains(officiant)
    }
}

/// The structured, render-ready form of a composed service.
///
/// A tradition package composes a ``ServiceDocument`` for an office and a
/// date. The document carries text exactly as the source prints it, with the
/// provenance of every element; presentation (orthography, typography,
/// layout) is the renderer's business.
public struct ServiceDocument: Hashable, Sendable, Codable {
    public var traditionID: String
    public var office: Office
    public var date: CivilDate
    public var title: String
    /// What the day is in the tradition's calendar, for headers and the Today screen.
    public var day: DayDescription
    public var sections: [ServiceSection]
    public var diagnostics: [Diagnostic]

    public init(traditionID: String, office: Office, date: CivilDate, title: String, day: DayDescription,
                sections: [ServiceSection], diagnostics: [Diagnostic]) {
        self.traditionID = traditionID
        self.office = office
        self.date = date
        self.title = title
        self.day = day
        self.sections = sections
        self.diagnostics = diagnostics
    }

    /// Every element of the service in order, flattening alternatives to
    /// their first option.
    public var elements: [ServiceElement] { sections.flatMap(\.elements) }
}

/// An office (a kind of service) a tradition can compose.
public struct Office: Hashable, Sendable, Codable, RawRepresentable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let morningPrayer = Office(rawValue: "morning-prayer")
    public static let eveningPrayer = Office(rawValue: "evening-prayer")
}

public struct DayDescription: Hashable, Sendable, Codable {
    /// The governing observance, e.g. "The second Sunday in Advent".
    public var title: String
    /// Observance identifier in the tradition, e.g. `advent-2`.
    public var observanceID: String
    /// Liturgical season, e.g. `advent`.
    public var season: String
    /// Other observances that fall on the same day (a holy day on a Sunday).
    public var concurrent: [String]

    public init(title: String, observanceID: String, season: String, concurrent: [String] = []) {
        self.title = title
        self.observanceID = observanceID
        self.season = season
        self.concurrent = concurrent
    }
}

public struct ServiceSection: Hashable, Sendable, Codable, Identifiable {
    public var id: String
    public var title: String?
    public var elements: [ServiceElement]

    public init(id: String, title: String? = nil, elements: [ServiceElement]) {
        self.id = id
        self.title = title
        self.elements = elements
    }
}

/// Who says a piece of text.
public enum Speaker: String, Hashable, Sendable, Codable {
    case minister, priest, people, all
}

public struct Verse: Hashable, Sendable, Codable {
    public var number: Int?
    /// The verse before the pointing colon, or the whole verse when it is not pointed.
    public var first: String
    /// The verse after the pointing colon.
    public var second: String?

    public init(number: Int? = nil, first: String, second: String? = nil) {
        self.number = number
        self.first = first
        self.second = second
    }
}

public struct VersicleLine: Hashable, Sendable, Codable {
    public var speaker: Speaker
    public var text: String
    public init(speaker: Speaker, text: String) {
        self.speaker = speaker
        self.text = text
    }
}

/// One element of a service. Every case carries an `id` unique within the
/// document and the provenance of its text.
public indirect enum ServiceElement: Hashable, Sendable, Codable {
    /// An instruction, printed in the source in italic (or smaller type).
    case rubric(id: String, text: String, source: SourceReference?)
    case heading(id: String, text: String, latin: String?, reference: String?, source: SourceReference?)
    /// Text said by one party: a prayer, sentence, exhortation, creed or blessing.
    case text(id: String, kind: String, speaker: Speaker?, text: String, citation: String?, source: SourceReference?)
    case versicles(id: String, lines: [VersicleLine], source: SourceReference?)
    /// A psalm or canticle said verse by verse, with its Gloria Patri.
    case psalm(id: String, title: String?, latin: String?, verses: [Verse], gloria: [Verse], source: SourceReference?)
    /// A choice the source allows, or that Lux cannot settle; each option is
    /// a sequence of elements. The first option is the default.
    case alternatives(id: String, label: String, options: [Option])
    /// Something the service needs that Lux cannot supply. Never filled with
    /// substitute text.
    case placeholder(id: String, kind: String, label: String, reason: String)

    public struct Option: Hashable, Sendable, Codable {
        public var label: String
        public var elements: [ServiceElement]
        public init(label: String, elements: [ServiceElement]) {
            self.label = label
            self.elements = elements
        }
    }

    public var id: String {
        switch self {
        case let .rubric(id, _, _), let .heading(id, _, _, _, _), let .text(id, _, _, _, _, _),
             let .versicles(id, _, _), let .psalm(id, _, _, _, _, _), let .alternatives(id, _, _),
             let .placeholder(id, _, _, _):
            return id
        }
    }
}

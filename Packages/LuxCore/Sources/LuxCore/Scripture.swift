/// A Scripture reference as a lectionary gives it: a book and a range of
/// chapters and verses, inclusive.
///
/// A missing `startVerse` means from the start of `startChapter`. A missing
/// `endVerse` means to the end of `endChapter` (or of `startChapter` when
/// `endChapter` is missing). So `Acts 2:22` to the end of the chapter is
/// `startChapter: 2, startVerse: 22`.
public struct ScriptureReference: Hashable, Sendable, Codable, CustomStringConvertible {
    public var book: String
    public var startChapter: Int
    public var startVerse: Int?
    public var endChapter: Int?
    public var endVerse: Int?

    public init(book: String, startChapter: Int, startVerse: Int? = nil, endChapter: Int? = nil, endVerse: Int? = nil) {
        self.book = book
        self.startChapter = startChapter
        self.startVerse = startVerse
        self.endChapter = endChapter
        self.endVerse = endVerse
    }

    /// The reference in a modern form, for example `Genesis 22:1–19`,
    /// `Acts 2:22–end`, `Numbers 23–24` or `Acts 6:8–7:29`.
    public var description: String {
        var s = "\(book) \(startChapter)"
        if let v = startVerse { s += ":\(v)" }
        if let ec = endChapter, ec != startChapter {
            s += "–\(ec)"
            if let ev = endVerse { s += ":\(ev)" }
        } else if let ev = endVerse {
            s += "–\(ev)"
        } else if startVerse != nil {
            s += "–end"
        }
        return s
    }
}

/// A verse of Scripture as an edition prints it.
public struct ScriptureVerse: Hashable, Sendable, Codable {
    public var chapter: Int
    public var number: Int
    /// The verse in order. Words the translators supplied, which the edition
    /// prints in italic, are separate segments marked `supplied`.
    public var segments: [Segment]
    /// Why a reviewer should check this verse against another witness, if
    /// they should. The text itself is never corrected.
    public var review: String?

    public struct Segment: Hashable, Sendable, Codable {
        public var text: String
        public var supplied: Bool
        public init(_ text: String, supplied: Bool = false) {
            self.text = text
            self.supplied = supplied
        }
    }

    public init(chapter: Int, number: Int, segments: [Segment], review: String? = nil) {
        self.chapter = chapter
        self.number = number
        self.segments = segments
        self.review = review
    }

    /// The verse as plain text, without marking supplied words.
    public var text: String { segments.map(\.text).joined() }
}

/// A chapter and verse within one book.
public struct VerseLocation: Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    public var chapter: Int
    public var verse: Int
    public init(chapter: Int, verse: Int) {
        self.chapter = chapter
        self.verse = verse
    }

    public static func < (a: VerseLocation, b: VerseLocation) -> Bool {
        (a.chapter, a.verse) < (b.chapter, b.verse)
    }

    public var description: String { "\(chapter):\(verse)" }
}

/// The text of a reference in one edition.
public struct ScripturePassage: Hashable, Sendable, Codable {
    public var reference: ScriptureReference
    public var translationID: String
    /// The verses the edition gives, in order.
    public var verses: [ScriptureVerse]
    /// Verses within the reference that the edition's source lacks. They are
    /// reported, never filled.
    public var missing: [VerseLocation]
    /// Where the passage stands in the edition's source.
    public var source: SourceReference?

    public init(reference: ScriptureReference, translationID: String, verses: [ScriptureVerse],
                missing: [VerseLocation] = [], source: SourceReference? = nil) {
        self.reference = reference
        self.translationID = translationID
        self.verses = verses
        self.missing = missing
        self.source = source
    }
}

/// Supplies Scripture text. Implementations are licensed separately from
/// Lux and from the liturgical texts, and live in their own packages.
public protocol ScriptureProvider: Sendable {
    var translationID: String { get }
    /// A short name for the edition, e.g. "King James Version".
    var title: String { get }
    /// The passage, or `nil` when the edition does not contain the book or
    /// the chapters the reference names.
    func passage(_ reference: ScriptureReference) throws -> ScripturePassage?
}

/// A Scripture reference as a lectionary gives it: a book and a range of
/// chapters and verses.
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

    public var description: String {
        var s = "\(book) \(startChapter)"
        if let v = startVerse { s += ":\(v)" }
        if let ec = endChapter, ec != startChapter {
            s += "–\(ec)"
            if let ev = endVerse { s += ":\(ev)" }
        } else if let ev = endVerse {
            s += "–\(ev)"
        }
        return s
    }
}

public struct ScripturePassage: Hashable, Sendable, Codable {
    public var reference: ScriptureReference
    public var translationID: String
    public var verses: [Verse]
    public init(reference: ScriptureReference, translationID: String, verses: [Verse]) {
        self.reference = reference
        self.translationID = translationID
        self.verses = verses
    }
}

/// Supplies Scripture text. Implementations are licensed separately from
/// Lux and from the liturgical texts; Lux ships none until a translation and
/// its terms are chosen.
public protocol ScriptureProvider: Sendable {
    var translationID: String { get }
    func passage(_ reference: ScriptureReference) throws -> ScripturePassage?
}

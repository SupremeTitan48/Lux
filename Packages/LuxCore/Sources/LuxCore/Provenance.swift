/// Where a piece of liturgical text came from, precisely enough to find it
/// again in the source witness.
public struct SourceReference: Hashable, Sendable, Codable {
    /// Identifier of the source witness (see the tradition's `Witness/sources.json`).
    public var sourceID: String
    /// First and last raw line of the source extraction (1-based, inclusive).
    public var rawLines: ClosedRange<Int>
    /// Pages of the source extraction the text spans.
    public var pages: [Int]
    /// Set when the text needs checking against the page image (for example,
    /// when its reading order was reconstructed editorially).
    public var review: String?
    /// Editorial interventions applied to this text, in plain words.
    public var editorial: [String]

    public init(sourceID: String, rawLines: ClosedRange<Int>, pages: [Int], review: String? = nil, editorial: [String] = []) {
        self.sourceID = sourceID
        self.rawLines = rawLines
        self.pages = pages
        self.review = review
        self.editorial = editorial
    }

    enum CodingKeys: String, CodingKey { case sourceID, rawLines, pages, review, editorial }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sourceID = try c.decode(String.self, forKey: .sourceID)
        let bounds = try c.decode([Int].self, forKey: .rawLines)
        guard bounds.count == 2, bounds[0] <= bounds[1] else {
            throw DecodingError.dataCorruptedError(forKey: .rawLines, in: c, debugDescription: "rawLines must be [first, last]")
        }
        rawLines = bounds[0]...bounds[1]
        pages = try c.decode([Int].self, forKey: .pages)
        review = try c.decodeIfPresent(String.self, forKey: .review)
        editorial = try c.decodeIfPresent([String].self, forKey: .editorial) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sourceID, forKey: .sourceID)
        try c.encode([rawLines.lowerBound, rawLines.upperBound], forKey: .rawLines)
        try c.encode(pages, forKey: .pages)
        try c.encodeIfPresent(review, forKey: .review)
        if !editorial.isEmpty { try c.encode(editorial, forKey: .editorial) }
    }
}

import LuxCore

// Decodable mirrors of the generated content files. The schema is written by
// Tools/ContentExtraction/lux_extract/build.py; keep the two in step.

struct ContentProvenance: Decodable, Hashable, Sendable {
    var rawLines: [Int]
    var extractionPages: [Int]
    var review: String?
    var editorial: [String]?
    var dropcap: String?

    func reference(source: String) -> SourceReference {
        var notes = editorial ?? []
        if let dropcap { notes.append("drop capital \(dropcap)") }
        return SourceReference(sourceID: source, rawLines: rawLines[0]...rawLines[1], pages: extractionPages,
                               review: review, editorial: notes)
    }
}

struct PsalterFile: Decodable, Sendable {
    struct Psalm: Decodable, Sendable {
        var number: Int
        var incipit: String?
        var verses: [PsalmVerse]
        var portions: [Portion]?
        var provenance: ContentProvenance?
    }

    struct PsalmVerse: Decodable, Sendable {
        var n: Int
        var printed: Int?
        var first: String?
        var second: String?
        var text: String?
        var rawLine: Int
    }

    struct Portion: Decodable, Sendable {
        var portion: Int
        var incipit: String
        var firstVerse: Int
        var lastVerse: Int
        var provenance: ContentProvenance
    }

    struct Reference: Decodable, Hashable, Sendable {
        var psalm: Int
        var portion: Int?
        var verses: [Int]?
    }

    struct HalfDay: Decodable, Sendable {
        var psalms: [Reference]
        var rawLine: Int
    }

    struct Day: Decodable, Sendable {
        var day: Int
        var morning: HalfDay
        var evening: HalfDay
    }

    var schemaVersion: Int
    var source: String
    var psalms: [Psalm]
    var course: [Day]
}

struct CollectsFile: Decodable, Sendable {
    struct Note: Decodable, Sendable {
        var id: String
        var text: String
        var provenance: ContentProvenance
    }

    struct Collect: Decodable, Sendable {
        var text: String
        var provenance: ContentProvenance
    }

    struct Rubric: Decodable, Sendable {
        var text: String
        var position: String?
        var provenance: ContentProvenance
    }

    struct Observance: Decodable, Sendable {
        var id: String
        var title: String
        var collects: [Collect]
        var rubrics: [Rubric]?
    }

    var schemaVersion: Int
    var source: String
    var notes: [Note]
    var observances: [Observance]
}

struct ServiceFile: Decodable, Sendable {
    struct Line: Decodable, Hashable, Sendable {
        var speaker: String?
        var text: String

        init(from decoder: Decoder) throws {
            if let plain = try? decoder.singleValueContainer().decode(String.self) {
                speaker = nil
                text = plain
                return
            }
            let c = try decoder.container(keyedBy: CodingKeys.self)
            speaker = try c.decode(String.self, forKey: .speaker)
            text = try c.decode(String.self, forKey: .text)
        }

        enum CodingKeys: String, CodingKey { case speaker, text }
    }

    struct Half: Decodable, Hashable, Sendable {
        var first: String?
        var second: String?
        var text: String?

        var verse: Verse { Verse(first: first ?? text ?? "", second: second) }
    }

    struct Unit: Decodable, Sendable {
        var id: String
        var kind: String
        var role: String?
        var text: String?
        var citation: String?
        var latin: String?
        var reference: String?
        var lines: [Line]?
        var verses: [Half]?
        var gloria: [Half]?
        var provenance: ContentProvenance
    }

    var schemaVersion: Int
    var source: String
    var id: String
    var title: String
    var units: [Unit]
}

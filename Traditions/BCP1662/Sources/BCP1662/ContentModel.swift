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

/// The lectionary: the Kalendar's lessons for every day, the Proper Lessons
/// for Sundays and holy days, and the Proper Psalms. Taken from another
/// printing than the primary witness (see `source`).
struct LessonsFile: Decodable, Sendable {
    struct Provenance: Decodable, Hashable, Sendable {
        var xmlLine: Int
        var page: String
        var readAs: String?
        var review: String?
        var editorial: [String]?

        func reference(source: String) -> SourceReference {
            // TCP page references read "tcp:48041:6"; the last part is the image.
            let image = page.split(separator: ":").last.flatMap { Int($0) }
            return SourceReference(sourceID: source, rawLines: xmlLine...xmlLine, pages: image.map { [$0] } ?? [],
                                   review: review, editorial: editorial ?? [])
        }
    }

    struct Lesson: Decodable, Hashable, Sendable {
        var printed: String
        var references: [ScriptureReference]
        var footnotes: [String]?
        var provenance: Provenance
    }

    /// The lessons of one office. A key absent from a Proper Lessons row
    /// means the table appoints nothing there; `nil` means a blank cell.
    struct Office: Decodable, Sendable {
        var first: Lesson??
        var second: Lesson??

        enum CodingKeys: String, CodingKey { case first, second }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            first = c.contains(.first) ? .some(try c.decodeIfPresent(Lesson.self, forKey: .first)) : .none
            second = c.contains(.second) ? .some(try c.decodeIfPresent(Lesson.self, forKey: .second)) : .none
        }
    }

    struct KalendarDay: Decodable, Sendable {
        var month: Int
        var day: Int
        var printedName: String?
        var morning: Office
        var evening: Office
        var provenance: Provenance
    }

    struct ProperDay: Decodable, Sendable {
        var observance: String
        var label: String
        var morning: Office
        var evening: Office
        var provenance: Provenance
    }

    struct PsalmCell: Decodable, Sendable {
        var printed: String
        var psalms: [Int]
        var provenance: Provenance
    }

    struct ProperPsalms: Decodable, Sendable {
        var observance: String
        var label: String
        var morning: PsalmCell
        var evening: PsalmCell
    }

    struct Convention: Decodable, Sendable {
        var decision: String
        var note: String
    }

    var schemaVersion: Int
    var source: String
    var conventions: [String: Convention]
    var kalendar: [KalendarDay]
    var sundays: [ProperDay]
    var holyDays: [ProperDay]
    var properPsalms: [ProperPsalms]
}

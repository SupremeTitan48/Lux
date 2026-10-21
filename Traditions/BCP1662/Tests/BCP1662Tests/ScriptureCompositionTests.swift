import Foundation
import LuxCore
import Testing
@testable import BCP1662

/// A Scripture edition for tests: every chapter has ten verses whose text is
/// their location, except for the gaps it is given.
struct StubScripture: ScriptureProvider {
    let translationID = "stub"
    let title = "Stub Version"
    var gaps: Set<String> = []
    var books: Set<String>? = nil

    func passage(_ r: ScriptureReference) throws -> ScripturePassage? {
        if let books, !books.contains(r.book) { return nil }
        let endChapter = r.endChapter ?? r.startChapter
        var verses: [ScriptureVerse] = []
        var missing: [VerseLocation] = []
        for c in r.startChapter...endChapter {
            let from = c == r.startChapter ? (r.startVerse ?? 1) : 1
            let to = c == endChapter ? (r.endVerse ?? 10) : 10
            for v in from...to {
                if gaps.contains("\(r.book) \(c):\(v)") {
                    missing.append(VerseLocation(chapter: c, verse: v))
                } else {
                    verses.append(ScriptureVerse(chapter: c, number: v, segments: [.init("\(r.book) \(c):\(v) "), .init("supplied", supplied: true)]))
                }
            }
        }
        return ScripturePassage(reference: r, translationID: translationID, verses: verses, missing: missing,
                                source: SourceReference(sourceID: "stub", rawLines: 1...2, pages: [7]))
    }
}

@Suite struct ScriptureCompositionTests {
    static let content = try! BCP1662Content.bundled()

    func compose(_ scripture: StubScripture, _ office: Office, _ date: CivilDate) throws -> ServiceDocument {
        let tradition = BCP1662Tradition(content: ScriptureCompositionTests.content, scripture: [scripture])
        return try tradition.compose(office, on: date, options: CompositionOptions(scriptureTranslationID: "stub"))
    }

    func readings(_ doc: ServiceDocument, _ section: String) -> [ServiceElement] {
        doc.sections.first { $0.id == section }!.elements.filter {
            switch $0 {
            case .reading, .placeholder: true
            default: false
            }
        }
    }

    @Test func lessonsAreReadFromTheChosenEdition() throws {
        // 13 October 2026, Morning Prayer: Wisdom 1 and Mark 16.
        let doc = try compose(StubScripture(), .morningPrayer, CivilDate(2026, 10, 13))
        guard case let .reading(id, passage) = readings(doc, "first-lesson").first else { Issue.record("no reading"); return }
        #expect(id == "mp.lesson.first.text")
        #expect(passage.reference.book == "Wisdom")
        #expect(passage.verses.count == 10)
        #expect(passage.verses[0].segments[1].supplied)
        #expect(passage.source?.pages == [7])
        #expect(!doc.diagnostics.contains { $0.code.hasPrefix("lesson-text") || $0.code == "lesson-verse-missing" })
    }

    @Test func withoutAnEditionTheTextIsAPlaceholder() throws {
        let tradition = BCP1662Tradition(content: ScriptureCompositionTests.content, scripture: [StubScripture()])
        let doc = try tradition.compose(.morningPrayer, on: CivilDate(2026, 10, 13))
        #expect(doc.diagnostics.contains { $0.code == "lesson-text-unavailable" })
        #expect(!doc.elements.contains { if case .reading = $0 { true } else { false } })
    }

    @Test func missingVersesArePlaceholdersNotSubstitutes() throws {
        // 13 October 2026, Evening Prayer: 2 Corinthians 12.
        let stub = StubScripture(gaps: ["2 Corinthians 12:4", "2 Corinthians 12:5", "2 Corinthians 12:10"])
        let doc = try compose(stub, .eveningPrayer, CivilDate(2026, 10, 13))
        let parts = readings(doc, "second-lesson")
        #expect(parts.map(\.id) == ["ep.lesson.second.text", "ep.lesson.second.text.missing.12:4", "ep.lesson.second.text.2",
                                     "ep.lesson.second.text.missing.12:10"])
        if case let .reading(_, first) = parts[0] { #expect(first.verses.map(\.number) == [1, 2, 3]) }
        if case let .reading(_, second) = parts[2] { #expect(second.verses.map(\.number) == [6, 7, 8, 9]) }
        let missing = doc.diagnostics.filter { $0.code == "lesson-verse-missing" }
        #expect(missing.count == 2)
        #expect(missing.allSatisfy { $0.severity == .warning })
    }

    @Test func aPassageTheEditionLacksIsReported() throws {
        let doc = try compose(StubScripture(books: ["Mark"]), .morningPrayer, CivilDate(2026, 10, 13))
        #expect(doc.diagnostics.contains { $0.code == "lesson-text-missing" && $0.elementID == "mp.lesson.first.text" })
        guard case .placeholder = readings(doc, "first-lesson").first else { Issue.record("no placeholder"); return }
        guard case .reading = readings(doc, "second-lesson").first else { Issue.record("no reading"); return }
    }

    @Test func alternativesEachCarryTheirText() throws {
        // St Luke on the twentieth Sunday after Trinity (18 October 2026).
        let doc = try compose(StubScripture(), .morningPrayer, CivilDate(2026, 10, 18))
        guard case let .alternatives(_, _, options) = doc.sections.first(where: { $0.id == "first-lesson" })!.elements.last else {
            Issue.record("no alternatives"); return
        }
        for option in options {
            #expect(option.elements.contains { if case .reading = $0 { true } else { false } })
        }
    }
}

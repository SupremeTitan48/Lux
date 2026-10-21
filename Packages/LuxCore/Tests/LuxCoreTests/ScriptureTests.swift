import LuxCore
import Testing

@Suite struct ScriptureReferenceTests {
    @Test func describesRanges() {
        #expect(ScriptureReference(book: "Isaiah", startChapter: 1).description == "Isaiah 1")
        #expect(ScriptureReference(book: "Genesis", startChapter: 22, startVerse: 1, endVerse: 19).description == "Genesis 22:1–19")
        #expect(ScriptureReference(book: "Acts", startChapter: 2, startVerse: 22).description == "Acts 2:22–end")
        #expect(ScriptureReference(book: "Numbers", startChapter: 23, endChapter: 24).description == "Numbers 23–24")
        #expect(ScriptureReference(book: "Acts", startChapter: 6, startVerse: 8, endChapter: 7, endVerse: 29).description == "Acts 6:8–7:29")
    }
}

@Suite struct ScriptureLayoutTests {
    func verse(_ chapter: Int, _ number: Int, _ text: String) -> ScriptureVerse {
        ScriptureVerse(chapter: chapter, number: number, segments: [.init(text)])
    }

    @Test func poeticalBooksAreVerse() {
        for book in ["Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon", "Wisdom", "Ecclesiasticus"] {
            #expect(ScriptureForm.of(book: book) == .verse, "\(book)")
        }
        for book in ["Genesis", "Isaiah", "Lamentations", "Luke", "Acts", "Romans", "Revelation", "Tobit", "Baruch"] {
            #expect(ScriptureForm.of(book: book) == .prose, "\(book)")
        }
    }

    @Test func paragraphsBreakAtMarksAndChapters() {
        let passage = ScripturePassage(
            reference: ScriptureReference(book: "Luke", startChapter: 1, startVerse: 3, endChapter: 2, endVerse: 2),
            translationID: "kjv",
            verses: [verse(1, 3, "It seemed good"), verse(1, 4, "That thou mightest"), verse(1, 5, "¶ There was"),
                     verse(1, 6, "And they were"), verse(2, 1, "And it came to pass"), verse(2, 2, "(And this taxing")])
        #expect(passage.paragraphs.map { $0.map(\.number) } == [[3, 4], [5, 6], [1, 2]])
    }

    @Test func paragraphMarkIsDroppedOnlyWhereItOpensTheVerse() {
        let marked = ScriptureVerse(chapter: 1, number: 5, segments: [.init("¶ There was a priest named Zacharias: and his wife "), .init("was", supplied: true)])
        #expect(marked.opensParagraph)
        #expect(marked.segmentsWithoutParagraphMark == [.init("There was a priest named Zacharias: and his wife "), .init("was", supplied: true)])
        let plain = verse(1, 6, "And they were both righteous")
        #expect(!plain.opensParagraph)
        #expect(plain.segmentsWithoutParagraphMark == plain.segments)
    }
}

@Suite struct OfficiantTests {
    @Test func priestsPartsAreTheMinistersWithoutAPriest() {
        #expect(Speaker.priest.saidBy(.priest) == .priest)
        #expect(Speaker.priest.saidBy(.deacon) == .minister)
        #expect(Speaker.priest.saidBy(.layPerson) == .minister)
        for speaker in [Speaker.minister, .people, .all] {
            for officiant in Officiant.allCases { #expect(speaker.saidBy(officiant) == speaker) }
        }
    }
}

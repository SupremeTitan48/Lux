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

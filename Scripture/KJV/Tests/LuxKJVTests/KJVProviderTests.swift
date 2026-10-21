import Foundation
import LuxCore
import Testing
@testable import LuxKJV

@Suite struct KJVProviderTests {
    static let kjv = try! KJVProvider.bundled()

    func text(_ passage: ScripturePassage?) -> [String] { passage?.verses.map(\.text) ?? [] }

    @Test func contentVerifiesAgainstManifest() throws {
        _ = try KJVProvider.bundled(verify: true)
    }

    @Test func everyBookOfTheLectionary() {
        #expect(KJVProviderTests.kjv.index.books.count == 72)
        #expect(KJVProviderTests.kjv.index.books.contains { $0.book == "Ecclesiasticus" && $0.chapters == 51 })
        #expect(!KJVProviderTests.kjv.index.books.contains { $0.book == "Psalms" })
    }

    @Test func aWholeChapter() throws {
        let p = try KJVProviderTests.kjv.passage(ScriptureReference(book: "Genesis", startChapter: 1))!
        #expect(p.verses.count == 31)
        #expect(p.verses[0].text == "In the beginning God created the heaven and the earth.")
        #expect(p.missing.isEmpty)
        #expect(p.source?.sourceID == "kjv-ebible-2026-09-26")
        #expect(p.source?.pages == [21, 22])
    }

    @Test func suppliedWordsAreMarked() throws {
        let p = try KJVProviderTests.kjv.passage(ScriptureReference(book: "Genesis", startChapter: 1, startVerse: 2, endVerse: 2))!
        #expect(p.verses[0].segments == [.init("And the earth was without form, and void; and darkness "), .init("was", supplied: true),
                                         .init(" upon the face of the deep. And the Spirit of God moved upon the face of the waters.")])
    }

    @Test func versesAcrossChapters() throws {
        // Acts 6:8–7:29 (St Stephen, Evening Prayer).
        let p = try KJVProviderTests.kjv.passage(ScriptureReference(book: "Acts", startChapter: 6, startVerse: 8, endChapter: 7, endVerse: 29))!
        #expect(p.verses.first.map { VerseLocation(chapter: $0.chapter, verse: $0.number) } == VerseLocation(chapter: 6, verse: 8))
        #expect(p.verses.last.map { VerseLocation(chapter: $0.chapter, verse: $0.number) } == VerseLocation(chapter: 7, verse: 29))
        #expect(p.verses.count == 8 + 29)
    }

    @Test func toTheEndOfAChapter() throws {
        let p = try KJVProviderTests.kjv.passage(ScriptureReference(book: "Luke", startChapter: 1, startVerse: 39))!
        #expect(p.verses.first?.number == 39)
        #expect(p.verses.last?.number == 80)
    }

    @Test func versesTheOtherTextLacked() throws {
        // The supplied DaVince text lacked these final verses; this edition has them.
        for (book, chapter, verse) in [("Philippians", 4, 23), ("1 Thessalonians", 5, 28), ("Hebrews", 13, 25), ("Revelation", 22, 21)] {
            let p = try KJVProviderTests.kjv.passage(ScriptureReference(book: book, startChapter: chapter, startVerse: verse, endVerse: verse))
            #expect(p?.verses.count == 1, "\(book) \(chapter):\(verse)")
        }
        #expect(text(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Matthew", startChapter: 5, startVerse: 30, endVerse: 30)))
            .first?.contains("cut it off") == true)
    }

    @Test func theApocrypha() throws {
        // Baruch 6 is the Epistle of Jeremy; Ecclesiasticus 44 has 23 verses in this edition.
        let baruch = try KJVProviderTests.kjv.passage(ScriptureReference(book: "Baruch", startChapter: 6))!
        #expect(baruch.verses.first?.text.hasPrefix("A copy of an epistle, which Jeremy sent") == true)
        #expect(baruch.verses.count == 73)
        #expect(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Ecclesiasticus", startChapter: 44))?.verses.count == 23)
        #expect(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Bel and the Dragon", startChapter: 1))?.verses.count == 42)
    }

    @Test func outOfRangeReferences() throws {
        #expect(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Psalms", startChapter: 1)) == nil)
        #expect(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Joel", startChapter: 4)) == nil)
        #expect(try KJVProviderTests.kjv.passage(ScriptureReference(book: "Jude", startChapter: 1, startVerse: 20, endVerse: 30)) == nil)
    }
}

import Testing
@testable import LuxCore

@Suite struct OrthographyTests {
    @Test func longS() {
        #expect(Orthography.modernLetterforms.render("Bleſſed be the Lord God of Iſrael") == "Blessed be the Lord God of Israel")
        #expect(Orthography.asPrinted.render("Bleſſed") == "Bleſſed")
    }
}

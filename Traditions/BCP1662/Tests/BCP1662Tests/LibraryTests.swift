import LuxCore
import Testing
@testable import BCP1662

@Suite struct LibraryTests {
    let tradition = try! BCP1662Tradition.bundled()

    @Test func psalter() {
        #expect(tradition.psalmNumbers == Array(1...150))
        #expect(tradition.psalm(23).count == 1)
        #expect(tradition.psalm(119).count == 22)
        #expect(tradition.psalm(151).isEmpty)
    }

    @Test func collects() {
        #expect(tradition.collectObservances.count == 86)
        #expect(tradition.collects(for: ObservanceID("good-friday")).filter {
            if case .text = $0 { return true }
            return false
        }.count == 3)
        #expect(tradition.collects(for: ObservanceID("nonexistent")).isEmpty)
    }

    @Test func athanasianCreed() {
        #expect(tradition.athanasianCreed.map(\.id) == ["ath.rubric", "ath.title", "ath.creed"])
    }
}

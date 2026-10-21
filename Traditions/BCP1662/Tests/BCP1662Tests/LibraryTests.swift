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

    @Test func collectGroupsCoverTheBookInOrder() {
        let groups = tradition.collectGroups
        #expect(groups.map(\.id) == ["advent", "christmas", "epiphany", "before-lent", "lent", "easter", "whitsun", "trinity", "saints"])
        #expect(groups.flatMap(\.observances) == tradition.collectObservances)
        #expect(groups.first { $0.id == "lent" }?.observances.first == ObservanceID("ash-wednesday"))
        #expect(groups.first { $0.id == "lent" }?.observances.last == ObservanceID("easter-even"))
        #expect(groups.last?.observances.count == 18)
    }

    @Test func psalmsByDayOfTheMonth() {
        #expect(tradition.psalmNumbers(day: 1, office: .morningPrayer) == [1, 2, 3, 4, 5])
        #expect(tradition.psalmNumbers(day: 13, office: .eveningPrayer) == [69, 70])
        #expect(tradition.psalmNumbers(day: 24, office: .eveningPrayer) == [119])
        #expect(tradition.psalms(day: 24, office: .eveningPrayer).count == 4)
        #expect(tradition.psalms(day: 31, office: .morningPrayer).isEmpty)
        // Every psalm is read once in the month.
        let all = (1...30).flatMap { day in [Office.morningPrayer, .eveningPrayer].flatMap { tradition.psalmNumbers(day: day, office: $0) } }
        #expect(Set(all) == Set(1...150))
    }
}

import Foundation
import LuxCore
import Testing
@testable import BCP1662

/// Golden tests: the complete composed office for chosen dates, compared
/// byte for byte with a reviewed JSON rendering in `Golden/`.
///
/// After an intended change, regenerate with `LUX_RECORD_GOLDEN=1 swift test`
/// and review the diff of `Golden/` like any other change to liturgical text.
@Suite struct GoldenTests {
    static let cases: [(String, Office, CivilDate)] = [
        ("2026-10-13-morning", .morningPrayer, CivilDate(2026, 10, 13)),
        ("2026-10-13-evening", .eveningPrayer, CivilDate(2026, 10, 13)),
        ("2026-04-05-morning-easter-day", .morningPrayer, CivilDate(2026, 4, 5)),
        ("2026-02-18-evening-ash-wednesday", .eveningPrayer, CivilDate(2026, 2, 18)),
        ("2026-10-18-morning-st-luke-on-sunday", .morningPrayer, CivilDate(2026, 10, 18)),
        ("2026-12-24-evening-christmas-eve", .eveningPrayer, CivilDate(2026, 12, 24)),
        ("2026-12-25-morning-christmas-day", .morningPrayer, CivilDate(2026, 12, 25)),
    ]

    static let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Golden")

    @Test(arguments: cases.map(\.0))
    func matchesGolden(name: String) throws {
        let (_, office, date) = GoldenTests.cases.first { $0.0 == name }!
        let doc = try BCP1662Tradition.bundled().compose(office, on: date)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(doc) + Data("\n".utf8)
        let url = GoldenTests.directory.appendingPathComponent("\(name).json")
        if ProcessInfo.processInfo.environment["LUX_RECORD_GOLDEN"] == "1" {
            try data.write(to: url)
            return
        }
        let expected = try Data(contentsOf: url)
        #expect(data == expected, "\(name) differs from Golden/\(name).json; rerun with LUX_RECORD_GOLDEN=1 and review the diff")
    }
}
